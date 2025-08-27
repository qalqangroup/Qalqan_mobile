import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:qalqan_dsm/l10n/app_localizations.dart';
import 'package:qalqan_dsm/routes/app_router.dart';
import 'package:qalqan_dsm/features/media/presentation/video_player_screen.dart';
import 'package:qalqan_dsm/features/media/presentation/audio_player_screen.dart';
import 'package:qalqan_dsm/core/key_access.dart';

class DecryptScreen extends StatefulWidget {
  final ValueChanged<Locale> onLocaleChanged;
  const DecryptScreen({Key? key, required this.onLocaleChanged}) : super(key: key);

  @override
  State<DecryptScreen> createState() => _DecryptScreenState();
}

class _DecryptScreenState extends State<DecryptScreen> {
  static const _channel = MethodChannel('com.qalqan/app');
  Future<String?> _getCacheDir() async => await _channel.invokeMethod<String>('getCacheDir');
  late AppLocalizations loc;

  bool _loading = false;
  String? _pickedPath;
  String? _decryptedText;
  String? _selectedNav;
  static const _bottomNavHeight = 56.0;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    loc = AppLocalizations.of(context)!;
  }

  Future<String> _getDownloadsDir() async {
    return (await _channel.invokeMethod<String>('getOutputDir'))!;
  }

  Future<void> _pickFile() async {
    final res = await FilePicker.platform.pickFiles(type: FileType.any);
    if (res?.files.single.path != null) {
      setState(() {
        _pickedPath = res!.files.single.path;
        _decryptedText = null;
      });
    }
  }

  Future<void> _onDecrypt() async {
    if (_pickedPath == null) {
      _showToast(loc.selectFile);
      return;
    }
    setState(() {
      _loading = true;
      _decryptedText = null;
    });

    try {
      final payload = await _channel.invokeMapMethod<String, dynamic>(
        'decryptFile',
        {'filePath': _pickedPath},
      );
      if (payload == null || !payload.containsKey('code')) {
        throw PlatformException(code: 'NULL', message: 'No response');
      }
      final code = payload['code'] as int;

      switch (code) {
        case 1:
        case 2:
          _showToast(loc.error);
          break;
        case 3: // image
        case 4: // video
        case 7: // audio
          final fname = payload['fileName'] as String;
          final cacheDir = await _getCacheDir();
          final path = '$cacheDir/$fname';
          if (code == 3) {
            _viewImage(path);
          } else if (code == 4) {
            _viewVideo(path);
          } else {
            _viewAudio(path);
          }
          break;
        case 5: // text
          setState(() {
            _decryptedText = payload['text'] as String;
          });
          break;
        case 6: // generic file in cache
          _showToast(loc.success);
          break;
        default:
          _showToast(loc.error);
      }
    } on PlatformException catch (e) {
      _showToast(e.message ?? loc.error);
    } finally {
      setState(() => _loading = false);
    }
  }

  void _showToast(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  Future<bool> _askSaveOrDelete(String srcPath) async {
    final answer = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(loc.saveFileQuestion),
        content: Text(loc.saveFileExplanation),
        actions: [
          TextButton(
            child: Text(loc.no),
            onPressed: () => Navigator.of(context).pop(false),
          ),
          TextButton(
            child: Text(loc.yes),
            onPressed: () => Navigator.of(context).pop(true),
          ),
        ],
      ),
    );
    final save = answer == true;
    if (save) {
      final downloads = await _getDownloadsDir();
      final name = srcPath.split('/').last;
      final dst = '$downloads/$name';
      try {
        await File(srcPath).copy(dst);
        _showToast(loc.fileSaved(dst));
      } catch (_) {
        _showToast(loc.errorSavingFile);
      }
    } else {
      try {
        await File(srcPath).delete();
      } catch (_) {}
    }
    return true;
  }

  void _viewImage(String path) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => WillPopScope(
          onWillPop: () => _askSaveOrDelete(path),
          child: Scaffold(
            appBar: AppBar(),
            body: Center(child: Image.file(File(path))),
          ),
        ),
      ),
    );
  }

  void _viewVideo(String path) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => WillPopScope(
          onWillPop: () => _askSaveOrDelete(path),
          child: VideoPlayerScreen(path),
        ),
      ),
    );
  }

  void _viewAudio(String path) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => WillPopScope(
          onWillPop: () => _askSaveOrDelete(path),
          child: AudioPlayerScreen(path),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      bottomNavigationBar: SafeArea(
        top: false,
        child: ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(26)),
          child: BottomNavigationBar(
            type: BottomNavigationBarType.fixed,
            backgroundColor: Colors.white,
            currentIndex: _selectedNavIndex(),
            selectedItemColor: const Color(0xFF5869E5),
            unselectedItemColor: Colors.grey,
            showSelectedLabels: true,
            showUnselectedLabels: false,
            onTap: _onNavTap,
            items: [
              BottomNavigationBarItem(icon: const Icon(Icons.home),        label: loc.main),
              BottomNavigationBarItem(icon: const Icon(Icons.lock),        label: loc.encrypt),
              BottomNavigationBarItem(icon: const Icon(Icons.chat_bubble), label: loc.chat),
              BottomNavigationBarItem(icon: const Icon(Icons.lock_open),   label: loc.decrypt),
              BottomNavigationBarItem(icon: const Icon(Icons.person),      label: loc.profile),
            ],
          ),
        ),
      ),
      body: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.only(bottom: _bottomNavHeight),
          child: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [ Color(0xFF8A9AFF), Color(0xFF3B4DFF), Color(0xFF8A9AFF) ],
              ),
            ),
            child: LayoutBuilder(
              builder: (context, constraints) {
                const double btnH = 60.0;
                const double gap = 30.0;

                final double h = constraints.maxHeight;
                final double centerY = h / 2;

                final double selectTop = centerY - btnH / 2;
                final double decryptTop = centerY + btnH / 2 + gap;
                final double textTop   = decryptTop + btnH + gap;

                return Stack(
                  children: [
                    Positioned(
                      top: selectTop,
                      left: 0,
                      right: 0,
                      child: Center(
                        child: _buildButton(
                          iconPath: 'assets/images/selectfile.png',
                          label: loc.selectFile,
                          onPressed: _pickFile,
                        ),
                      ),
                    ),
                    Positioned(
                      top: decryptTop,
                      left: 0,
                      right: 0,
                      child: Center(
                        child: _buildButton(
                          label: loc.decrypt,
                          onPressed: _onDecrypt,
                          width: 300,
                          backgroundColor: const Color(0xFF5869E5),
                          labelColor: Colors.white,
                        ),
                      ),
                    ),
                    if (_decryptedText != null)
                      Positioned(
                        top: textTop,
                        left: 0,
                        right: 0,
                        child: Center(
                          child: Container(
                            width: 300,
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.white24,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              _decryptedText!,
                              style: const TextStyle(color: Colors.white70),
                            ),
                          ),
                        ),
                      ),
                    if (_loading)
                      const Align(
                        alignment: Alignment(0, 0.8),
                        child: SizedBox(
                          width: 46,
                          height: 46,
                          child: CircularProgressIndicator(
                            color: Colors.white70,
                            strokeWidth: 4,
                          ),
                        ),
                      ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildButton({
    String? iconPath,
    required String label,
    required VoidCallback onPressed,
    double width = 300,
    Color backgroundColor = const Color(0x40FFFFFF),
    Color labelColor = const Color(0xBFFFFFFF),
  }) {
    return SizedBox(
      width: width,
      height: 60,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: backgroundColor,
          elevation: 8,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(26)),
          textStyle: const TextStyle(fontFamily: 'MontserratRegular', fontSize: 20),
        ),
        onPressed: onPressed,
        child: iconPath != null
            ? Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset(iconPath, width: 24, height: 24, color: labelColor),
            const SizedBox(width: 8),
            Text(label, style: TextStyle(color: labelColor, fontSize: 20)),
          ],
        )
            : Text(label, style: TextStyle(color: labelColor, fontSize: 20)),
      ),
    );
  }

  int _selectedNavIndex() {
    switch (_selectedNav) {
      case AppRouter.start:   return 0;
      case AppRouter.encrypt: return 1;
      case AppRouter.login:   return 2;
      case AppRouter.decrypt: return 3;
      case AppRouter.init:    return 4;
      default:                return 3;
    }
  }

  void _onNavTap(int i) {
    switch (i) {
      case 0:
        setState(() => _selectedNav = AppRouter.start);
        Navigator.of(context).pushReplacementNamed(AppRouter.start);
        break;

      case 1: // Encrypt — только после выбора типа ключа и нажатия Start
        if (!KeyAccess.isReady) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(loc.pleaseselectkeytype)),
          );
          setState(() => _selectedNav = AppRouter.decrypt);
          Navigator.of(context).pushReplacementNamed(AppRouter.start);
          return;
        }
        setState(() => _selectedNav = AppRouter.encrypt);
        Navigator.of(context).pushReplacementNamed(
          AppRouter.encrypt,
          arguments: KeyAccess.selected,
        );
        break;

      case 2:
        setState(() => _selectedNav = AppRouter.login);
        Navigator.of(context).pushReplacementNamed(AppRouter.login);
        break;

      case 4:
        setState(() => _selectedNav = AppRouter.init);
        Navigator.of(context).pushReplacementNamed(AppRouter.init);
        break;

      case 3:
      default:
        setState(() => _selectedNav = AppRouter.decrypt);
        break;
    }
  }

  String _navKeyByIndex(int i) {
    switch (i) {
      case 0: return AppRouter.start;
      case 1: return AppRouter.encrypt;
      case 2: return AppRouter.login;
      case 3: return AppRouter.decrypt;
      case 4:
      default: return AppRouter.init;
    }
  }
}
