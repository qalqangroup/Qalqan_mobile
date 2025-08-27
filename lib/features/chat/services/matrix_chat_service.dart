import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:matrix/matrix.dart' as mx;
import '../models/room.dart';
import '../models/message.dart';
import 'matrix_auth.dart';
import '../services/matrix_sync_service.dart';

class UploadHandle {
  UploadHandle(this._client);
  final http.Client _client;
  bool _cancelled = false;

  void cancel() {
    _cancelled = true;
    _client.close();
  }

  bool get isCancelled => _cancelled;
}

class UploadResult {
  const UploadResult({required this.mxc, required this.handle});
  final String? mxc;
  final UploadHandle handle;
}

class MatrixService {
  static const String _homeServerUrl = 'https://webqalqan.com';
  static const String _mediaApiVer = 'v3';

  static mx.Client get client => AuthService.client!;
  static final Map<String, dynamic> _joinedRoomsSnapshot = <String, dynamic>{};
  static Map<String, dynamic>? _mDirectCache;
  static String? _accessToken;
  static String? _fullUserId;

  static void setAccessTokenFromSdk(String? token, String? fullUserId) {
    _accessToken = token;
    _fullUserId = fullUserId;
  }

  static String normalizeUserId(String input) {
    if (input.startsWith('@')) return input;
    final host = Uri
        .parse(_homeServerUrl)
        .host;
    return '@$input:$host';
  }

  static String? _nextBatch;
  static String? _myUserId;
  static Map<String, dynamic>? _lastSyncResponse;
  static bool _syncing = false;

  static String _localPart(String userId) =>
      userId
          .split(':')
          .first
          .replaceFirst('@', '');

  static String? get accessToken => _accessToken;

  static String get homeServer => _homeServerUrl;

  static String? get userId => _fullUserId;

  static Future<bool> login({
    required String user,
    required String password,
  }) async {
    final uri = Uri.parse('$_homeServerUrl/_matrix/client/v3/login');

    final payload = jsonEncode({
      'type': 'm.login.password',
      'identifier': {'type': 'm.id.user', 'user': user},
      'password': password,
    });

    final response = await http.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: payload,
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      _accessToken = data['access_token'] as String?;
      _fullUserId = data['user_id'] as String?;

      try {
        MatrixSyncService.instance.attachClient(client);
        MatrixSyncService.instance.start();
      } catch (e) {
        print('MatrixSyncService start failed: $e');
      }

      await syncOnce();
      return true;
    } else {
      print('Login failed ${response.statusCode}: ${response.body}');
      return false;
    }
  }

  static Future<void> syncOnce() async {
    _lastSyncResponse = null;
    _nextBatch = null;
    _joinedRoomsSnapshot.clear();
    await _doSync(timeoutMs: 0);
  }

  static Future<void> forceSync({int timeout = 5000}) async {
    if (_accessToken == null) return;

    final sinceParam = _nextBatch != null
        ? '&since=${Uri.encodeComponent(_nextBatch!)}'
        : '';

    final uri = Uri.parse(
        '$_homeServerUrl/_matrix/client/v3/sync?timeout=$timeout$sinceParam');
    print('DEBUG: forceSync URI=$uri');

    final response = await http.get(
      uri,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $_accessToken',
      },
    );
    if (response.statusCode == 200) {
      final decoded = jsonDecode(response.body) as Map<String, dynamic>;
      _applySyncData(decoded);

      if (await _handleDirectInvitesAndMaybeJoin(decoded)) {
        await forceSync(timeout: 0);
      }
      print('>>> New next_batch=$_nextBatch');
    } else {
      print('forceSync failed ${response.statusCode}: ${response.body}');
    }
  }

  static Future<void> _doSync({int timeoutMs = 30000}) async {
    if (_accessToken == null) return;

    final params = _nextBatch == null
        ? '?timeout=$timeoutMs'
        : '?since=${Uri.encodeComponent(_nextBatch!)}&timeout=$timeoutMs';

    final uri = Uri.parse('$_homeServerUrl/_matrix/client/v3/sync$params');
    final response = await http.get(uri, headers: {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $_accessToken',
    });

    if (response.statusCode == 200) {
      final decoded = jsonDecode(response.body) as Map<String, dynamic>;
      _applySyncData(decoded);

      final joined = await _handleDirectInvitesAndMaybeJoin(decoded);
      if (joined) {
        await forceSync(timeout: 0);
      }
    } else {
      print('SYNC failed ${response.statusCode}: ${response.body}');
    }
  }

  static Future<void> startSyncLoop({int intervalMs = 5000}) async {
    if (_syncing) return;
    _syncing = true;
    while (_syncing) {
      await _doSync();
      await Future.delayed(Duration(milliseconds: intervalMs));
    }
  }

  static void stopSyncLoop() {
    _syncing = false;
  }

  static void _applySyncData(Map<String, dynamic> decoded) {
    _lastSyncResponse = decoded;
    _nextBatch = decoded['next_batch'] as String?;

    final rooms = decoded['rooms'] as Map<String, dynamic>?;
    if (rooms != null) {
      final join = rooms['join'] as Map<String, dynamic>?;
      if (join != null) {
        join.forEach((roomId, roomData) {
          _joinedRoomsSnapshot[roomId] = roomData;
        });
      }
      final leave = rooms['leave'] as Map<String, dynamic>?;
      if (leave != null) {
        for (final roomId in leave.keys) {
          _joinedRoomsSnapshot.remove(roomId);
        }
      }
    }

    final events = (decoded['account_data']?['events'] as List?)
        ?.cast<Map<String, dynamic>>();
    if (events != null) {
      final direct = events.firstWhere(
            (e) => e['type'] == 'm.direct',
        orElse: () => {},
      );
      if (direct.isNotEmpty) {
        _mDirectCache = direct['content'] as Map<String, dynamic>?;
      }
    }
  }

  static Future<bool> _joinRoom(String roomId) async {
    if (_accessToken == null) return false;
    final encoded = Uri.encodeComponent(roomId);
    final uri = Uri.parse(
        '$_homeServerUrl/_matrix/client/v3/rooms/$encoded/join');
    final resp = await http.post(
      uri,
      headers: {
        'Authorization': 'Bearer $_accessToken',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({}),
    );
    if (resp.statusCode == 200 || resp.statusCode == 201) return true;
    print('auto-join failed ${resp.statusCode}: ${resp.body}');
    return false;
  }

  static Future<void> _ensureDirectMapping(String otherUserId,
      String roomId) async {
    final current = <String, List<String>>{};
    final events = (_lastSyncResponse?['account_data']?['events'] as List?)
        ?.cast<Map<String, dynamic>>() ?? [];
    final directEv = events.firstWhere((e) => e['type'] == 'm.direct',
        orElse: () => {});
    final raw = directEv.isNotEmpty
        ? (directEv['content'] as Map<String, dynamic>?)
        : _mDirectCache;
    if (raw != null) {
      raw.forEach((k, v) {
        current[k] = (v as List).cast<String>().toList();
      });
    }

    final list = current[otherUserId] ?? <String>[];
    if (!list.contains(roomId)) {
      list.add(roomId);
      current[otherUserId] = list;
      final ok = await setDirectRooms(current);
      if (!ok) {
        print('setDirectRooms failed for $otherUserId -> $roomId');
      }
    }
  }

  static Future<bool> _handleDirectInvitesAndMaybeJoin(
      Map<String, dynamic> decoded) async {
    if (_accessToken == null) return false;

    final invites = decoded['rooms']?['invite'] as Map<String, dynamic>?;
    if (invites == null || invites.isEmpty) return false;

    bool anyJoined = false;
    for (final entry in invites.entries) {
      final roomId = entry.key;
      final roomData = (entry.value as Map<String, dynamic>);

      final invEvents = (roomData['invite_state']?['events'] as List?)
          ?.cast<Map<String, dynamic>>() ?? const <Map<String, dynamic>>[];

      bool isDirect = false;
      String? inviter;
      String? otherUserId;

      for (final ev in invEvents) {
        if (ev['type'] != 'm.room.member') continue;

        final content = (ev['content'] as Map?)?.cast<String, dynamic>() ??
            const {};
        if (content['is_direct'] == true) isDirect = true;

        final membership = content['membership'] as String?;
        final sender = ev['sender'] as String?;
        final stateKey = ev['state_key'] as String?;
        if (membership == 'invite') {
          inviter = sender;
          final me = _fullUserId ?? _myUserId;
          if (me != null) {
            otherUserId = (sender == me) ? stateKey : sender;
          }
        }
      }

      if (isDirect == true) {
        final ok = await _joinRoom(roomId);
        if (ok) {
          anyJoined = true;
          if (otherUserId != null && otherUserId!.isNotEmpty) {
            await _ensureDirectMapping(otherUserId!, roomId);
          }
        }
      }
    }

    return anyJoined;
  }

  static List<Room> getJoinedRooms() {
    if (_joinedRoomsSnapshot.isEmpty) return [];

    final directMap = getDirectRoomIdToUserIdMap();
    final List<Room> result = [];

    _joinedRoomsSnapshot.forEach((roomId, roomDataRaw) {
      final roomData = roomDataRaw as Map<String, dynamic>;
      String name = roomId;

      final stateEvents = roomData['state']?['events'] as List<dynamic>?;
      if (stateEvents != null) {
        final nameEvent = stateEvents.firstWhere(
              (e) => (e as Map<String, dynamic>)['type'] == 'm.room.name',
          orElse: () => null,
        ) as Map<String, dynamic>?;
        if (nameEvent != null) {
          name = nameEvent['content']?['name'] as String? ?? roomId;
        }
      }

      if (name == roomId) {
        final dmUser = directMap[roomId];
        if (dmUser != null && dmUser.isNotEmpty) {
          name = _localPart(dmUser);
        }
      }

      Map<String, dynamic>? lastMsg;
      final timelineEvents = roomData['timeline']?['events'] as List<dynamic>?;
      if (timelineEvents != null && timelineEvents.isNotEmpty) {
        lastMsg = (timelineEvents.reversed.firstWhere(
              (e) {
            final t = ((e as Map<String, dynamic>)['type'] as String?) ?? '';
            return t == 'm.room.message' || t == 'm.room.encrypted' || t.startsWith('m.call.');
          },
          orElse: () => null,
        ) as Map<String, dynamic>?);
      }

      result.add(Room(id: roomId, name: name, lastMessage: lastMsg));
    });

    return result;
  }

  static List<Message> getRoomMessages(String roomId) {
    final resp = _lastSyncResponse;
    if (resp == null) return [];

    final roomSection = resp['rooms']?['join']?[roomId] as Map<String,
        dynamic>?;
    if (roomSection == null) return [];

    final events = (roomSection['timeline']?['events'] as List?)
        ?.cast<Map<String, dynamic>>() ??
        [];

    events.sort((a, b) =>
        ((a['origin_server_ts'] as int?) ?? 0).compareTo(
            (b['origin_server_ts'] as int?) ?? 0));

    final List<Message> result = [];

    final myId = _fullUserId ?? '';
    final Map<String, Map<String, dynamic>> callInvites = {};
    final Map<String, Map<String, dynamic>> callAnswers = {};
    final Map<String, Map<String, dynamic>> callHangups = {};

    String _fmtDur(int ms) {
      if (ms <= 0) return '00:00';
      final d = Duration(milliseconds: ms);
      final mm = d.inMinutes.remainder(60).toString().padLeft(2, '0');
      final ss = d.inSeconds.remainder(60).toString().padLeft(2, '0');
      return '$mm:$ss';
    }

    for (var e in events) {
      final type = e['type'] as String? ?? '';
      final sender = e['sender'] as String? ?? '';
      final eventId = e['event_id'] as String? ?? '';
      final ts = DateTime.fromMillisecondsSinceEpoch(
        (e['origin_server_ts'] as int?) ?? 0,
        isUtc: true,
      ).toLocal();

      if (type.startsWith('m.room.message')) {
        final content = (e['content'] as Map<String, dynamic>? ?? const {});
        final msgtype = (content['msgtype'] as String?) ?? 'm.text';
        final body = (content['body'] as String?) ?? '';

        if (msgtype == 'm.text') {
          result.add(Message(
            id: eventId,
            sender: sender,
            text: body,
            type: MessageType.text,
            timestamp: ts,
          ));
          continue;
        }

        if (msgtype == 'm.image') {
          final mxcUrl = content['url'] as String?;
          final info = (content['info'] as Map?)?.cast<String, dynamic>();
          final thumbMxc = info?['thumbnail_url'] as String?;
          final mime = (info?['mimetype'] as String?) ?? 'image/*';
          final size = (info?['size'] as num?)?.toInt();
          final mediaUrl = mxcToHttp(mxcUrl);
          final thumbUrl = mxcToHttp(
              thumbMxc, width: 512, height: 512, thumbnail: true);

          result.add(Message(
            id: eventId,
            sender: sender,
            text: body,
            type: MessageType.image,
            timestamp: ts,
            mediaUrl: mediaUrl,
            thumbUrl: thumbUrl ?? mediaUrl,
            fileName: body.isNotEmpty ? body : null,
            fileSize: size,
            mimeType: mime,
          ));
          continue;
        }

        if (msgtype == 'm.file') {
          final mxcUrl = content['url'] as String?;
          final info = (content['info'] as Map?)?.cast<String, dynamic>();
          final mime = (info?['mimetype'] as String?) ??
              'application/octet-stream';
          final size = (info?['size'] as num?)?.toInt();
          final name = body.isNotEmpty
              ? body
              : (content['filename'] as String?) ?? 'file';
          final mediaUrl = mxcToHttp(mxcUrl);

          result.add(Message(
            id: eventId,
            sender: sender,
            text: name,
            type: MessageType.file,
            timestamp: ts,
            mediaUrl: mediaUrl,
            fileName: name,
            fileSize: size,
            mimeType: mime,
          ));
          continue;
        }
      }

      if (type == 'm.room.encrypted') {
        result.add(Message(
          id: eventId,
          sender: sender,
          text: 'Encrypted message',
          type: MessageType.text,
          timestamp: ts,
        ));
        continue;
      }

      if (type.startsWith('m.call.') && type != 'm.call.candidates') {
        final content = (e['content'] as Map?)?.cast<String, dynamic>() ??
            const {};
        final callId = content['call_id'] as String?;
        if (callId != null && callId.isNotEmpty) {
          if (type == 'm.call.invite') {
            callInvites[callId] = e;
          } else if (type == 'm.call.answer') {
            callAnswers[callId] = e;
          } else if (type == 'm.call.hangup') {
            callHangups[callId] = e;
          }
        }
        continue;
      }
    }

    for (final entry in callInvites.entries) {
      final callId = entry.key;
      final inv = entry.value;
      final ans = callAnswers[callId];
      final han = callHangups[callId];

      final inviter = inv['sender'] as String? ?? '';
      final incoming = inviter != myId;

      final inviteTs = (inv['origin_server_ts'] as int?) ?? 0;
      final answerTs = (ans?['origin_server_ts'] as int?);
      final hangupTs = (han?['origin_server_ts'] as int?);

      late final DateTime stamp;
      if (hangupTs != null) {
        stamp = DateTime
            .fromMillisecondsSinceEpoch(hangupTs, isUtc: true)
            .toLocal();
      } else if (answerTs != null) {
        stamp = DateTime
            .fromMillisecondsSinceEpoch(answerTs, isUtc: true)
            .toLocal();
      } else {
        stamp = DateTime
            .fromMillisecondsSinceEpoch(inviteTs, isUtc: true)
            .toLocal();
      }

      String text;
      if (answerTs != null) {
        final end = hangupTs ?? answerTs;
        final durMs = (end - answerTs).clamp(0, 1 << 30);
        final dur = _fmtDur((durMs is int) ? durMs : (durMs as num).toInt());
        text = incoming
            ? 'Incoming call, $dur'
            : 'Outgoing call, $dur';
      } else {
        text = incoming
            ? 'Missed incoming call'
            : 'Outgoing (no answer)';
      }

      result.add(Message(
        id: 'call_$callId',
        sender: inviter,
        text: text,
        type: MessageType.call,
        timestamp: stamp,
      ));
    }

    result.sort((a, b) => a.timestamp.compareTo(b.timestamp));
    return result;
  }

  static Future<String?> sendMessage(String roomId, String text,
      {String? txnId}) async {
    if (_accessToken == null) {
      print('sendMessage: no access token');
      return null;
    }

    final txn = txnId ?? DateTime
        .now()
        .millisecondsSinceEpoch
        .toString();
    final encoded = Uri.encodeComponent(roomId);
    final uri = Uri.parse(
        '$_homeServerUrl/_matrix/client/v3/rooms/$encoded/send/m.room.message/$txn');
    final payload = jsonEncode({'msgtype': 'm.text', 'body': text});

    const maxAttempts = 3;
    for (var attempt = 1; attempt <= maxAttempts; attempt++) {
      http.Response response;
      try {
        response = await http.put(
          uri,
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $_accessToken'
          },
          body: payload,
        );
      } catch (e) {
        print(
            'sendMessage transport error: $e (attempt $attempt/$maxAttempts)');
        if (attempt == maxAttempts) return null;
        await Future.delayed(const Duration(milliseconds: 800));
        continue;
      }

      if (response.statusCode == 200 || response.statusCode == 201) {
        try {
          final data = jsonDecode(response.body) as Map<String, dynamic>;
          return data['event_id'] as String?;
        } catch (_) {
          print('sendMessage: success but bad JSON: ${response.body}');
          return null;
        }
      }

      if (response.statusCode == 429) {
        int waitMs = 1000;
        try {
          final data = jsonDecode(response.body) as Map<String, dynamic>;
          waitMs = (data['retry_after_ms'] as num?)?.toInt() ?? waitMs;
        } catch (_) {
          final retryAfter = response.headers['retry-after'];
          if (retryAfter != null) {
            final sec = int.tryParse(retryAfter);
            if (sec != null) waitMs = sec * 1000;
          }
        }
        print(
            'sendMessage 429: waiting ${waitMs}ms then retry (attempt $attempt/$maxAttempts)');
        await Future.delayed(Duration(milliseconds: waitMs));
        continue;
      }

      if (response.statusCode == 401) {
        print('sendMessage unauthorized 401: ${response.body}');
        return null;
      }

      print('sendMessage failed ${response.statusCode}: ${response.body}');
      return null;
    }

    print('sendMessage aborted after $maxAttempts attempts');
    return null;
  }

  static Future<List<Message>> fetchRoomHistory(String roomId) async {
    if (_accessToken == null) return [];

    await syncOnce();

    final roomSection = _lastSyncResponse?['rooms']?['join']?[roomId]
    as Map<String, dynamic>?;
    if (roomSection == null) return [];

    final initialTimeline = (roomSection['timeline']?['events'] as List?)
        ?.cast<Map<String, dynamic>>() ??
        [];

    String? prevBatch = roomSection['timeline']?['prev_batch'] as String?;
    final olderRaw = <Map<String, dynamic>>[];

    if (prevBatch != null && prevBatch.isNotEmpty) {
      var from = prevBatch;
      const pageSize = 50;
      while (true) {
        final encoded = Uri.encodeComponent(roomId);
        final uri = Uri.parse(
          '$_homeServerUrl/_matrix/client/v3/rooms/$encoded/messages'
              '?from=${Uri.encodeComponent(from)}&dir=b&limit=$pageSize',
        );
        final resp = await http.get(uri, headers: {
          if (_accessToken != null) 'Authorization': 'Bearer $_accessToken'
        });
        if (resp.statusCode != 200) break;
        final data = jsonDecode(resp.body) as Map<String, dynamic>;
        final chunk = (data['chunk'] as List?)?.cast<Map<String, dynamic>>();
        final end = data['end'] as String?;
        if (chunk == null || chunk.isEmpty) break;
        olderRaw.addAll(chunk);
        if (end == null || end.isEmpty) break;
        from = end;
      }
    }

    final rawAll = <Map<String, dynamic>>[
      ...olderRaw,
      ...initialTimeline,
    ];
    rawAll.sort((a, b) =>
        ((a['origin_server_ts'] as int?) ?? 0).compareTo(
            (b['origin_server_ts'] as int?) ?? 0));

    final myId = _fullUserId ?? '';
    final List<Message> out = [];

    final Map<String, Map<String, dynamic>> callInvites = {};
    final Map<String, Map<String, dynamic>> callAnswers = {};
    final Map<String, Map<String, dynamic>> callHangups = {};

    String _fmtDur(int ms) {
      if (ms <= 0) return '00:00';
      final d = Duration(milliseconds: ms);
      final mm = d.inMinutes.remainder(60).toString().padLeft(2, '0');
      final ss = d.inSeconds.remainder(60).toString().padLeft(2, '0');
      return '$mm:$ss';
    }

    for (final e in rawAll) {
      final type = e['type'] as String? ?? '';
      final sender = e['sender'] as String? ?? '';
      final eventId = e['event_id'] as String? ?? '';
      final ts = DateTime.fromMillisecondsSinceEpoch(
        (e['origin_server_ts'] as int?) ?? 0,
        isUtc: true,
      ).toLocal();

      if (type.startsWith('m.call.') && type != 'm.call.candidates') {
        final content = (e['content'] as Map?)?.cast<String, dynamic>() ??
            const {};
        final callId = content['call_id'] as String?;
        if (callId != null && callId.isNotEmpty) {
          if (type == 'm.call.invite') {
            callInvites[callId] = e;
          } else if (type == 'm.call.answer') {
            callAnswers[callId] = e;
          } else if (type == 'm.call.hangup') {
            callHangups[callId] = e;
          }
        }
        continue;
      }

      if (type.startsWith('m.room.message')) {
        final content = (e['content'] as Map<String, dynamic>? ?? const {});
        final msgtype = (content['msgtype'] as String?) ?? 'm.text';
        final body = (content['body'] as String?) ?? '';

        if (msgtype == 'm.text') {
          out.add(Message(
            id: eventId,
            sender: sender,
            text: body,
            type: MessageType.text,
            timestamp: ts,
          ));
          continue;
        }

        if (msgtype == 'm.image') {
          final mxcUrl = content['url'] as String?;
          final info = (content['info'] as Map?)?.cast<String, dynamic>();
          final thumbMxc = info?['thumbnail_url'] as String?;
          final mime = (info?['mimetype'] as String?) ?? 'image/*';
          final size = (info?['size'] as num?)?.toInt();
          final mediaUrl = mxcToHttp(mxcUrl);
          final thumbUrl = mxcToHttp(
              thumbMxc, width: 512, height: 512, thumbnail: true);

          out.add(Message(
            id: eventId,
            sender: sender,
            text: body,
            type: MessageType.image,
            timestamp: ts,
            mediaUrl: mediaUrl,
            thumbUrl: thumbUrl ?? mediaUrl,
            fileName: body.isNotEmpty ? body : null,
            fileSize: size,
            mimeType: mime,
          ));
          continue;
        }

        if (msgtype == 'm.file') {
          final mxcUrl = content['url'] as String?;
          final info = (content['info'] as Map?)?.cast<String, dynamic>();
          final mime = (info?['mimetype'] as String?) ??
              'application/octet-stream';
          final size = (info?['size'] as num?)?.toInt();
          final name = body.isNotEmpty
              ? body
              : (content['filename'] as String?) ?? 'file';
          final mediaUrl = mxcToHttp(mxcUrl);

          out.add(Message(
            id: eventId,
            sender: sender,
            text: name,
            type: MessageType.file,
            timestamp: ts,
            mediaUrl: mediaUrl,
            fileName: name,
            fileSize: size,
            mimeType: mime,
          ));
          continue;
        }
      }

      if (type == 'm.room.encrypted') {
        out.add(Message(
          id: eventId,
          sender: sender,
          text: 'Encrypted message',
          type: MessageType.text,
          timestamp: ts,
        ));
        continue;
      }
    }

    for (final entry in callInvites.entries) {
      final callId = entry.key;
      final inv = entry.value;
      final ans = callAnswers[callId];
      final han = callHangups[callId];

      final inviter = inv['sender'] as String? ?? '';
      final incoming = inviter != myId;

      final inviteTs = (inv['origin_server_ts'] as int?) ?? 0;
      final answerTs = (ans?['origin_server_ts'] as int?);
      final hangupTs = (han?['origin_server_ts'] as int?);

      late final DateTime stamp;
      if (hangupTs != null) {
        stamp = DateTime
            .fromMillisecondsSinceEpoch(hangupTs, isUtc: true)
            .toLocal();
      } else if (answerTs != null) {
        stamp = DateTime
            .fromMillisecondsSinceEpoch(answerTs, isUtc: true)
            .toLocal();
      } else {
        stamp = DateTime
            .fromMillisecondsSinceEpoch(inviteTs, isUtc: true)
            .toLocal();
      }

      String text;
      if (answerTs != null) {
        final end = hangupTs ?? answerTs;
        final durMs = (end - answerTs).clamp(0, 1 << 30);
        final dur = _fmtDur((durMs is int) ? durMs : (durMs as num).toInt());
        text = incoming
            ? 'Incoming call, $dur'
            : 'Outgoing call, $dur';
      } else {
        text = incoming
            ? 'Missed incoming call'
            : 'Outgoing (no answer)';
      }

      out.add(Message(
        id: 'call_$callId',
        sender: inviter,
        text: text,
        type: MessageType.call,
        timestamp: stamp,
      ));
    }

    out.sort((a, b) => a.timestamp.compareTo(b.timestamp));
    return out;
  }

  static Future<bool> userExists(String userOrMxid) async {
    final token = _accessToken ?? AuthService.accessToken;
    if (token == null) return false;

    final target = normalizeUserId(userOrMxid);
    final encoded = Uri.encodeComponent(target);
    final uri = Uri.parse('$_homeServerUrl/_matrix/client/v3/profile/$encoded');

    final resp = await http.get(uri, headers: {
      'Authorization': 'Bearer $token',
    });

    if (resp.statusCode == 200) return true;
    if (resp.statusCode == 404) return false;
    return false;
  }

  static Future<String?> _ensureMyUserId() async {
    if (_myUserId != null) return _myUserId;
    if (_accessToken == null) return null;

    final uri = Uri.parse('$_homeServerUrl/_matrix/client/v3/account/whoami');
    final r = await http.get(
      uri,
      headers: {
        'Authorization': 'Bearer ${_accessToken ?? AuthService.accessToken}'
      },
    );

    if (r.statusCode == 200) {
      final body = jsonDecode(r.body) as Map<String, dynamic>;
      _myUserId = body['user_id'] as String?;
      if (_myUserId == null) {
        print('whoami ok, but user_id is null: ${r.body}');
      }
      return _myUserId;
    } else {
      print('whoami failed ${r.statusCode}: ${r.body}');
      return null;
    }
  }

  static Future<Room?> createDirectChat(String rawUserId) async {
    final token = _accessToken ?? AuthService.accessToken;
    if (token == null) {
      print('createDirectChat: no access token');
      return null;
    }

    final target = normalizeUserId(rawUserId);

    try {
      final exists = await userExists(target);
      if (!exists) {
        print('Warning: user may not exist or directory disabled: $target');
      }
    } catch (e) {
      print('userExists check skipped due to error: $e');
    }

    final uri = Uri.parse('$_homeServerUrl/_matrix/client/v3/createRoom');
    final payload = {
      'invite': [target],
      'is_direct': true,
      'preset': 'private_chat',
    };

    final response = await http.post(
      uri,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode(payload),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final roomId = data['room_id'] as String;

      await _ensureDirectMapping(target, roomId);
      await forceSync(timeout: 0);

      final displayName = target.split(':').first.replaceFirst('@', '');
      return Room(id: roomId, name: displayName);
    } else {
      print('Direct chat creation failed ${response.statusCode}: ${response.body}');
      return null;
    }
  }

  static Map<String, String> getDirectRoomIdToUserIdMap() {
    Map<String, dynamic>? content;

    final events = (_lastSyncResponse?['account_data']?['events'] as List?)
        ?.cast<Map<String, dynamic>>() ?? [];
    final directEvent = events.firstWhere(
          (e) => e['type'] == 'm.direct',
      orElse: () => {},
    );
    if (directEvent.isNotEmpty) {
      content = directEvent['content'] as Map<String, dynamic>?;
      _mDirectCache = content;
    } else {
      content = _mDirectCache;
    }
    if (content == null) return {};

    final map = <String, String>{};
    content.forEach((userId, rooms) {
      for (final r in (rooms as List)) {
        map[r as String] = userId as String;
      }
    });
    return map;
  }

  static List<String> getDirectRoomIds() {
    Map<String, dynamic>? content;

    final events = (_lastSyncResponse?['account_data']?['events'] as List?)
        ?.cast<Map<String, dynamic>>() ?? [];
    final directEvent = events.firstWhere(
          (e) => e['type'] == 'm.direct',
      orElse: () => {},
    );
    if (directEvent.isNotEmpty) {
      content = directEvent['content'] as Map<String, dynamic>?;
      _mDirectCache = content;
    } else {
      content = _mDirectCache;
    }
    if (content == null) return [];

    final ids = <String>[];
    for (final entry in content.values) {
      if (entry is List) ids.addAll(entry.cast<String>());
    }
    return ids;
  }

  static Future<String> getUserDisplayName(String userId) async {
    if (_accessToken == null) return _localPart(userId);
    final encoded = Uri.encodeComponent(userId);
    final uri = Uri.parse('$_homeServerUrl/_matrix/client/v3/profile/$encoded');
    final resp = await http.get(uri, headers: {
      'Authorization': 'Bearer $_accessToken',
      'Content-Type': 'application/json',
    });
    if (resp.statusCode == 200) {
      final data = jsonDecode(resp.body) as Map<String, dynamic>;
      return data['displayname'] as String? ?? _localPart(userId);
    }
    return _localPart(userId);
  }

  static Future<bool> leaveRoom(String roomId) async {
    if (_accessToken == null) return false;
    final encoded = Uri.encodeComponent(roomId);
    final uri = Uri.parse(
        '$_homeServerUrl/_matrix/client/v3/rooms/$encoded/leave');
    final resp = await http.post(
      uri,
      headers: {
        'Authorization': 'Bearer $_accessToken',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({}),
    );
    return resp.statusCode == 200 || resp.statusCode == 201;
  }

  static Future<bool> setDirectRooms(
      Map<String, List<String>> directMap) async {
    if (_accessToken == null || _fullUserId == null) return false;

    final encoded = Uri.encodeComponent(_fullUserId!);
    final uri = Uri.parse(
        '$_homeServerUrl/_matrix/client/v3/user/$encoded/account_data/m.direct');

    final resp = await http.put(
      uri,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $_accessToken',
      },
      body: jsonEncode(directMap),
    );

    final ok = resp.statusCode == 200;
    if (ok) _mDirectCache = directMap;
    return ok;
  }

  static String? mxcToHttp(String? mxc, {int? width, int? height, bool thumbnail = false}) {
    if (mxc == null || !mxc.startsWith('mxc://')) return null;

    final noScheme = mxc.substring('mxc://'.length);
    final slash = noScheme.indexOf('/');
    if (slash < 0) return null;

    final server  = noScheme.substring(0, slash);
    final mediaId = noScheme.substring(slash + 1);

    final base = _homeServerUrl.replaceFirst(RegExp(r'/$'), '');

    if (thumbnail && width != null && height != null) {
      return '$base/_matrix/media/$_mediaApiVer/thumbnail/$server/$mediaId'
          '?width=$width&height=$height&method=scale';
    }

    return '$base/_matrix/media/$_mediaApiVer/download/$server/$mediaId';
  }

  static Future<UploadResult> uploadWithProgress({
    required String name,
    required Uint8List data,
    required String mime,
    void Function(int sent, int total)? onProgress,
    void Function(UploadHandle handle)? onStart,
  }) async {
    final token = _accessToken ?? AuthService.accessToken;

    final client = http.Client();
    final handle = UploadHandle(client);
    onStart?.call(handle);

    final base = _homeServerUrl.replaceFirst(RegExp(r'/$'), '');
    final uri  = Uri.parse(
      '$base/_matrix/media/$_mediaApiVer/upload?filename=${Uri.encodeComponent(name)}',
    );

    final req = http.StreamedRequest('POST', uri);
    if (token != null) req.headers['Authorization'] = 'Bearer $token';
    req.headers['Content-Type'] = mime;
    req.headers['Accept'] = 'application/json';
    req.contentLength = data.length;

    const chunk = 64 * 1024;
    var sent = 0;

    try {
      while (sent < data.length && !handle.isCancelled) {
        final end = (sent + chunk > data.length) ? data.length : sent + chunk;
        req.sink.add(data.sublist(sent, end));
        sent = end;
        onProgress?.call(sent, data.length);
        await Future<void>.delayed(Duration.zero);
      }
      await req.sink.close();

      if (handle.isCancelled) {
        client.close();
        return UploadResult(mxc: null, handle: handle);
      }

      final resp = await client.send(req).timeout(const Duration(minutes: 2));
      final body = await resp.stream.bytesToString();
      client.close();

      if (resp.statusCode == 200 || resp.statusCode == 201) {
        final json = jsonDecode(body) as Map<String, dynamic>;
        final mxc = json['content_uri'] as String?;
        return UploadResult(mxc: mxc, handle: handle);
      }

      if (resp.statusCode == 413) {
        print('upload failed 413 (payload too large)');
        return UploadResult(mxc: null, handle: handle);
      }

      print('upload failed ${resp.statusCode}: $body');
      return UploadResult(mxc: null, handle: handle);
    } catch (e) {
      try { client.close(); } catch (_) {}
      print('upload error: $e');
      return UploadResult(mxc: null, handle: handle);
    }
  }

  static Future<String?> sendFileEvent({
    required String roomId,
    required String name,
    required String mxc,
    required String mime,
    required int size,
  }) async {
    final room = client.getRoomById(roomId);
    if (room == null) return null;
    final content = {
      'msgtype': 'm.file',
      'body': name,
      'filename': name,
      'url': mxc,
      'info': {'mimetype': mime, 'size': size},
    };
    return await room.sendEvent(content, type: 'm.room.message');
  }

  static Future<String?> sendImageEvent({
    required String roomId,
    required String name,
    required String mxc,
    required String mime,
    required int size,
    int? width,
    int? height,
    String? thumbnailMxc,
  }) async {
    final room = client.getRoomById(roomId);
    if (room == null) return null;

    final info = <String, dynamic>{'mimetype': mime, 'size': size};
    if (width != null && height != null) {
      info['w'] = width;
      info['h'] = height;
    }
    if (thumbnailMxc != null) {
      info['thumbnail_url'] = thumbnailMxc;
    }

    final content = {
      'msgtype': 'm.image',
      'body': name,
      'url': mxc,
      'info': info,
    };
    return await room.sendEvent(content, type: 'm.room.message');
  }

  static Future<String?> sendFile(String roomId, String name, List<int> bytes, String mime) async {
    final room = client.getRoomById(roomId);
    if (room == null) return null;

    try {
      final uri = await client.uploadContent(
        Uint8List.fromList(bytes),
        contentType: mime,
        filename: name,
      );

      final mxc = uri.toString();
      if (mxc.isEmpty) return null;

      final content = {
        'msgtype': 'm.file',
        'body': name,
        'filename': name,
        'url': mxc,
        'info': {'mimetype': mime, 'size': bytes.length},
      };

      return await room.sendEvent(content, type: 'm.room.message');
    } catch (e) {
      print('sendFile error: $e');
      return null;
    }
  }

  static Future<String?> sendImage(
      String roomId,
      String name,
      List<int> bytes,
      String mime, {
        int? width,
        int? height,
      }) async {
    final room = client.getRoomById(roomId);
    if (room == null) return null;

    try {
      final uri = await client.uploadContent(
        Uint8List.fromList(bytes),
        contentType: mime,
        filename: name,
      );

      final mxc = uri.toString();
      if (mxc.isEmpty) return null;

      final info = <String, dynamic>{'mimetype': mime, 'size': bytes.length};
      if (width != null && height != null) {
        info['w'] = width;
        info['h'] = height;
      }

      final content = {
        'msgtype': 'm.image',
        'body': name,
        'url': mxc,
        'info': info,
      };

      return await room.sendEvent(content, type: 'm.room.message');
    } catch (e) {
      print('sendImage error: $e');
      return null;
    }
  }
}