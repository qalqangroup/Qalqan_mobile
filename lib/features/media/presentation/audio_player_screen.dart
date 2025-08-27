import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';

class AudioPlayerScreen extends StatefulWidget {
  final String path;
  const AudioPlayerScreen(this.path, {Key? key}) : super(key: key);
  @override
  _AudioPlayerScreenState createState() => _AudioPlayerScreenState();
}

class _AudioPlayerScreenState extends State<AudioPlayerScreen> {
  late AudioPlayer _player;
  @override
  void initState() {
    super.initState();
    _player = AudioPlayer()..setFilePath(widget.path).then((_) {
      _player.play();
    });
  }
  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body: StreamBuilder<Duration?>(
        stream: _player.positionStream,
        builder: (context, snapshot) {
          final pos = snapshot.data ?? Duration.zero;
          return Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(widget.path.split('/').last),
              Slider(
                min: 0,
                max: _player.duration?.inMilliseconds.toDouble() ?? 1,
                value: pos.inMilliseconds.toDouble().clamp(0, _player.duration?.inMilliseconds.toDouble() ?? 1),
                onChanged: (v) => _player.seek(Duration(milliseconds: v.toInt())),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(
                    icon: Icon(Icons.replay_10),
                    onPressed: () => _player.seek(pos - Duration(seconds: 10)),
                  ),
                  StreamBuilder<bool>(
                    stream: _player.playerStateStream.map((s) => s.playing),
                    builder: (_, snap) {
                      final playing = snap.data ?? false;
                      return IconButton(
                        icon: Icon(playing ? Icons.pause : Icons.play_arrow),
                        onPressed: () => playing ? _player.pause() : _player.play(),
                      );
                    },
                  ),
                  IconButton(
                    icon: Icon(Icons.forward_10),
                    onPressed: () => _player.seek(pos + Duration(seconds: 10)),
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }
}
