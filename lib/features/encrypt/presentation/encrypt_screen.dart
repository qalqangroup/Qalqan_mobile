import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:qalqan_dsm/l10n/app_localizations.dart';
import 'package:qalqan_dsm/routes/app_router.dart';
import 'package:share_plus/share_plus.dart';
import 'package:record/record.dart';
import 'package:qalqan_dsm/core/key_access.dart';

class EncryptScreen extends StatefulWidget {
  final ValueChanged<Locale> onLocaleChanged;
  const EncryptScreen({Key? key, required this.onLocaleChanged}) : super(key: key);

  @override
  State<EncryptScreen> createState() => _EncryptScreenState();
}

class _EncryptScreenState extends State<EncryptScreen> {
  String? _keyType = 'all';

  static const _channel = MethodChannel('com.qalqan/app');

  final _recorder = AudioRecorder();
  bool _isRecording = false;
  String? _recordedPath;

  bool _loading = false;
  String? _selectedNav;
  final _textController = TextEditingController();
  static const _bottomNavHeight = 56.0;

  bool _allowOpen = false;
  bool _guardChecked = false;

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_guardChecked) return;
    _guardChecked = true;

    final args = ModalRoute.of(context)?.settings.arguments;
    final fromArgs = (args is String && args.trim().isNotEmpty) ? args.trim() : null;

    final selected = fromArgs ?? KeyAccess.selected;

    if (selected != null && selected.trim().isNotEmpty) {
      _keyType = selected.toLowerCase();
      _allowOpen = true;
    } else {
      // Нет выбранного ключа — не пускаем, отправляем на Start
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final loc = AppLocalizations.of(context)!;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(loc.pleaseselectkeytype)),
        );
        Navigator.of(context).pushReplacementNamed(AppRouter.start);
      });
    }
  }

  Future<String?> _getOutputDir() async {
    return await _channel.invokeMethod<String>('getOutputDir');
  }

  Future<void> _encryptAndShare(String method, Map<String, dynamic> args) async {
    setState(() => _loading = true);
    try {
      final outName = await _channel.invokeMethod<String>(method, args);
      if (outName == null) throw PlatformException(code: 'NULL', message: 'No output');
      final dir = await _getOutputDir();
      if (dir == null) throw PlatformException(code: 'NOPATH', message: 'No dir');
      final filePath = '$dir/$outName';
      if (!File(filePath).existsSync()) throw PlatformException(code: 'NOFILE', message: 'File not found');

      await SharePlus.instance.share(ShareParams(text: outName, files: [XFile(filePath)]));
    } on PlatformException catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message ?? 'Error')));
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _pickFile() async {
    final res = await FilePicker.platform.pickFiles(type: FileType.any);
    if (res?.files.single.path != null) {
      await _encryptAndShare('encryptFile', {'path': res!.files.single.path!, 'keyType': _keyType});
      setState(() => _selectedNav = AppRouter.encrypt);
    }
  }

  Future<void> _takePhoto() async {
    final picker = ImagePicker();
    final photo = await picker.pickImage(source: ImageSource.camera);
    if (photo?.path != null) {
      await _encryptAndShare('encryptPhoto', {'path': photo!.path, 'keyType': _keyType});
      setState(() => _selectedNav = AppRouter.encrypt);
    }
  }

  Future<void> _takeVideo() async {
    final picker = ImagePicker();
    final vid = await picker.pickVideo(source: ImageSource.camera, maxDuration: const Duration(seconds: 15));
    if (vid?.path != null) {
      await _encryptAndShare('encryptVideo', {'path': vid!.path, 'keyType': _keyType});
      setState(() => _selectedNav = AppRouter.encrypt);
    }
  }

  Future<void> _recordAudio() async {
    final loc = AppLocalizations.of(context)!;
    if (!await _recorder.hasPermission()) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(loc.error)));
      return;
    }

    if (!_isRecording) {
      final dir = await _getOutputDir() ?? '/tmp';
      final path = '$dir/audio_${DateTime.now().millisecondsSinceEpoch}.3gp';
      await _recorder.start(
        const RecordConfig(
          encoder: AudioEncoder.amrNb,
          bitRate: 128000,
          sampleRate: 8000,
          numChannels: 1,
        ),
        path: path,
      );
      setState(() {
        _isRecording = true;
        _recordedPath = path;
      });
    } else {
      final recordedPath = await _recorder.stop();
      setState(() => _isRecording = false);

      if (recordedPath != null) {
        await _encryptAndShare('encryptAudio', {'path': recordedPath, 'keyType': _keyType});
        try {
          final orig = File(recordedPath);
          if (await orig.exists()) {
            await orig.delete();
          }
        } catch (e) {
          debugPrint('Failed to delete original audio file: $e');
        }
        setState(() => _selectedNav = AppRouter.encrypt);
      }
    }
  }

  Future<void> _encryptText() async {
    final txt = _textController.text.trim();
    if (txt.isEmpty) return;
    await _encryptAndShare('encryptText', {'text': txt, 'keyType': _keyType});
    _textController.clear();
    setState(() => _selectedNav = AppRouter.encrypt);
  }

  void _encrypt() {
    if (_textController.text.trim().isNotEmpty) {
      _encryptText();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context)!.typeMsg)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_allowOpen) {
      // Экран не доступен без выбора типа ключа на StartScreen
      return const Scaffold(body: SizedBox.shrink());
    }

    final loc = AppLocalizations.of(context)!;
    final size = MediaQuery.of(context).size;
    final insets = MediaQuery.of(context).viewInsets; // высота клавиатуры

    return Scaffold(
      resizeToAvoidBottomInset: false,
      extendBody: true,
      bottomNavigationBar: ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(26)),
        child: BottomNavigationBar(
          backgroundColor: const Color(0xFFFFFFFF),
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
      body: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.only(bottom: _bottomNavHeight),
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => FocusScope.of(context).unfocus(),
            child: Container(
              width: double.infinity,
              height: double.infinity,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0xFF8A9AFF), Color(0xFF3B4DFF), Color(0xFF8A9AFF)],
                ),
              ),
              child: Stack(
                children: [
                  if (_loading)
                    Align(
                      alignment: const Alignment(0, 0.75),
                      child: SizedBox(
                        width: size.width * 0.8,
                        height: 46,
                        child: LinearProgressIndicator(
                          color: Colors.white.withOpacity(0.8),
                          backgroundColor: Colors.white.withOpacity(0.2),
                        ),
                      ),
                    ),

                  // Центрированный стек; поднимаем весь блок ровно на высоту клавиатуры
                  Center(
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 220),
                      curve: Curves.easeOut,

                      transform: Matrix4.translationValues(0, -insets.bottom, 0),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _buildButton(
                            iconPath: 'assets/images/selectfile.png',
                            label: loc.selectFile,
                            onPressed: _pickFile,
                          ),
                          const SizedBox(height: 20),

                          _buildButton(
                            iconPath: 'assets/images/takephoto.png',
                            label: loc.takePhoto,
                            onPressed: _takePhoto,
                          ),
                          const SizedBox(height: 20),

                          _buildButton(
                            iconPath: 'assets/images/takevideo.png',
                            label: loc.takeVideo,
                            onPressed: _takeVideo,
                          ),
                          const SizedBox(height: 20),

                          _buildButton(
                            iconPath: 'assets/images/microphone.png',
                            label: _isRecording ? loc.stopRecord : loc.recordAudio,
                            onPressed: _recordAudio,
                          ),
                          const SizedBox(height: 20),

                          // Поле ввода
                          SizedBox(
                            width: 300,
                            height: 100,
                            child: TextField(
                              controller: _textController,
                              maxLines: null,
                              style: const TextStyle(color: Colors.white70, fontSize: 20),
                              decoration: InputDecoration(
                                hintText: loc.typeMsg,
                                hintStyle: const TextStyle(color: Colors.white54),
                                filled: true,
                                fillColor: Colors.white.withOpacity(0.2),
                                prefixIcon: Image.asset(
                                  'assets/images/textmsg.png',
                                  width: 24,
                                  height: 24,
                                  color: Colors.white70,
                                ),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(26),
                                  borderSide: BorderSide.none,
                                ),
                                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                              ),
                              textInputAction: TextInputAction.newline,
                            ),
                          ),

                          const SizedBox(height: 20),

                          _buildButton(
                            label: loc.encrypt,
                            onPressed: _encrypt,
                            width: 300,
                            backgroundColor: const Color(0xFF5869E5),
                            labelColor: Colors.white,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
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
      case AppRouter.start:    return 0;
      case AppRouter.encrypt:  return 1;
      case AppRouter.login:    return 2;
      case AppRouter.decrypt:  return 3;
      case AppRouter.init:     return 4;
      default:                 return 1;
    }
  }

  void _onNavTap(int index) {
    switch (index) {
      case 0: Navigator.of(context).pushReplacementNamed(AppRouter.start);   break;
      case 1: /* stay */                                                      break;
      case 2: Navigator.of(context).pushReplacementNamed(AppRouter.login);   break;
      case 3: Navigator.of(context).pushReplacementNamed(AppRouter.decrypt); break;
      case 4: Navigator.of(context).pushReplacementNamed(AppRouter.init);    break;
    }
    setState(() => _selectedNav = _navKeyByIndex(index));
  }

  String _navKeyByIndex(int i) {
    switch (i) {
      case 0: return AppRouter.start;
      case 1: return AppRouter.encrypt;
      case 2: return AppRouter.login;
      case 3: return AppRouter.decrypt;
      default: return AppRouter.init;
    }
  }
}
