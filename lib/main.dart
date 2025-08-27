import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_callkit_incoming/flutter_callkit_incoming.dart';
import 'package:flutter_callkit_incoming/entities/call_kit_params.dart';
import 'package:flutter_callkit_incoming/entities/call_event.dart';
import 'package:uuid/uuid.dart';
import 'no_transitions.dart';
import 'features/chat/services/call_store.dart';
import 'features/chat/services/matrix_incoming_call_service.dart';
import 'l10n/app_localizations.dart';
import 'routes/app_router.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

String _extractLocalpart(String mxid) {
  if (mxid.startsWith('@') && mxid.contains(':')) {
    return mxid.substring(1, mxid.indexOf(':'));
  }
  return mxid;
}

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  try {
    await Firebase.initializeApp();

    final data = message.data;
    final eventType = data['type'] ?? data['event_type'];

    if (eventType == 'm.call.invite') {
      final String? callId = (data['call_id'] ?? data['callId'])?.toString();
      final String? roomId = (data['room_id'] ?? data['roomId'])?.toString();
      final String sender = (data['sender'] ?? 'unknown').toString();
      final String name = _extractLocalpart(sender);

      if (callId != null && callId.isNotEmpty) {
        final uuid = const Uuid().v4();
        await CallStore.mapCallIdToUuid(callId, uuid);

        final active = await FlutterCallkitIncoming.activeCalls();
        if (active.any((c) => c['id'] == uuid)) return;

        await FlutterCallkitIncoming.showCallkitIncoming(
          CallKitParams(
            id: uuid,
            nameCaller: name,
            appName: 'Qalqan',
            type: 0,
            textAccept: 'Accept',
            textDecline: 'Decline',
            handle: data['handle']?.toString() ?? sender,
            duration: 30000,
            extra: {'call_id': callId, 'room_id': roomId, 'sender': sender},
          ),
        );
      }
      return;
    } else if (eventType == 'm.call.hangup') {
      final String? callId = (data['call_id'] ?? data['callId'])?.toString();
      if (callId != null && callId.isNotEmpty) {
        final uuid = await CallStore.uuidForCallId(callId) ?? callId;
        await FlutterCallkitIncoming.endCall(uuid);
        await CallStore.unmapCallId(callId);
      }
      return;
    }

    final params = CallKitParams(
      id: data['call_id']?.toString() ?? DateTime.now().millisecondsSinceEpoch.toString(),
      nameCaller: data['caller_name']?.toString() ?? 'Incoming call',
      appName: 'Qalqan',
      handle: data['handle']?.toString() ?? 'unknown',
      type: 0,
      duration: 30000,
    );
    await FlutterCallkitIncoming.showCallkitIncoming(params);
  } catch (e, st) {
    debugPrint('BG push handler error: $e\n$st');
  }
}

Future<void> _requestRuntimePerms() async {
  await FirebaseMessaging.instance.requestPermission();
}

Future<void> _initFirebaseAndPush() async {
  await Firebase.initializeApp();
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  await _requestRuntimePerms();

  FirebaseMessaging.onMessage.listen((msg) {
    debugPrint('FCM foreground: ${msg.data}');
  });
}

Future<void> _postBootInit() async {
  final fcm = FirebaseMessaging.instance;
  await fcm.requestPermission();
  FirebaseMessaging.onMessage.listen((msg) {
    debugPrint('FCM foreground (postBoot): ${msg.data}');
  });
}

Future<void> _initCallkitEventStream() async {
  FlutterCallkitIncoming.onEvent.listen((e) async {
    if (e == null) return;

    final ev = e.event;
    final uuid = e.body?['id'] as String?;
    final extra = (e.body?['extra'] as Map?)?.cast<String, dynamic>();
    final callId = extra?['call_id'] as String?;

    switch (ev) {
      case Event.actionCallAccept:
        if (callId != null && uuid != null) {
          final mapped = await CallStore.uuidForCallId(callId);
          if (mapped == null) {
            await CallStore.mapCallIdToUuid(callId, uuid);
          }
          try {
            MatrixCallService.I.handleCallkitAccept(callId);
          } catch (_) {}
        }
        break;

      case Event.actionCallDecline:
      case Event.actionCallEnded:
      case Event.actionCallTimeout:
        if (uuid != null) {
          await FlutterCallkitIncoming.endCall(uuid);
        }
        if (callId != null) {
          await CallStore.unmapCallId(callId);
        }
        break;

      default:
        break;
    }
  });
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await _initFirebaseAndPush();
  runApp(const MyApp());
  unawaited(_postBootInit());
  unawaited(_initCallkitEventStream());
}

class MyApp extends StatefulWidget {
  const MyApp({Key? key}) : super(key: key);
  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  Locale _locale = const Locale('en');

  void _setLocale(Locale locale) {
    setState(() => _locale = locale);
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(
        pageTransitionsTheme: const PageTransitionsTheme(
          builders: {
            TargetPlatform.android:  NoTransitionsBuilder(),
            TargetPlatform.iOS:      NoTransitionsBuilder(),
            TargetPlatform.linux:    NoTransitionsBuilder(),
            TargetPlatform.macOS:    NoTransitionsBuilder(),
            TargetPlatform.windows:  NoTransitionsBuilder(),
          },
        ),
      ),
      title: 'Qalqan',
      navigatorKey: navigatorKey,
      locale: _locale,
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      initialRoute: AppRouter.splash,
      onGenerateRoute: (settings) =>
          AppRouter.generate(settings, onLocaleChanged: _setLocale),
      debugShowCheckedModeBanner: false,
    );
  }
}
