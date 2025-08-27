import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:qalqan_dsm/l10n/app_localizations.dart';
import 'package:qalqan_dsm/routes/app_router.dart';

class HomeScreen extends StatefulWidget {
  final ValueChanged<Locale> onLocaleChanged;
  const HomeScreen({Key? key, required this.onLocaleChanged}) : super(key: key);

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  static const _channel = MethodChannel('com.qalqan/app');

  static const double _kLangBtnWidth = 125.0;
  static const double _kCtaWidth = 300.0;

  final _passwordController = TextEditingController();
  bool _obscure = true;

  String _selectedLang = '🇺🇸 ENG';
  final _langs = ['🇺🇸 ENG', '🇷🇺 РУС', '🇰🇿 ҚАЗ'];

  @override
  void dispose() {
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context);
    final size = mq.size;
    final insets = mq.viewInsets; // высота клавиатуры
    final loc = AppLocalizations.of(context)!;

    return Scaffold(
      // Двигаем центральный блок сами (языковое меню зафиксировано)
      resizeToAvoidBottomInset: false,
      body: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => FocusScope.of(context).unfocus(),
        child: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Color(0xFF8A9AFF),
                Color(0xFF3B4DFF),
                Color(0xFF8A9AFF),
              ],
            ),
          ),
          child: SafeArea(
            child: Stack(
              children: [
                Positioned.fill(
                  child: AnimatedPadding(
                    duration: const Duration(milliseconds: 220),
                    curve: Curves.easeOut,
                    padding: EdgeInsets.only(bottom: insets.bottom),
                    child: LayoutBuilder(
                      builder: (context, cons) {
                        // Геометрия элементов
                        const tfHeight = 60.0;
                        const btnHeight = 60.0;
                        const gapTop = 50.0;     // между заголовком и полем
                        const gapBottom = 30.0;  // между полем и кнопкой

                        // Центр экрана по вертикали (поле пароля будет по центру)
                        final centerY = cons.maxHeight / 2;

                        // Позиции и размеры по ширине
                        final fieldLeft = (cons.maxWidth - _kCtaWidth) / 2;

                        // ШИРЕ заголовок (без изменения шрифта): отступы по 8dp
                        final textBoxWidth = cons.maxWidth - 16;
                        final textLeft = (cons.maxWidth - textBoxWidth) / 2;

                        final textStyle = TextStyle(
                          color: Colors.white.withOpacity(0.75),
                          fontSize: 28,
                          fontFamily: 'MontserratMedium',
                        );

                        // Считаем фактическую высоту заголовка при данной ширине,
                        // чтобы корректно выстроить отступы
                        final tp = TextPainter(
                          text: TextSpan(
                            text: loc.welcomeToQalqanDsm,
                            style: textStyle,
                          ),
                          textDirection: TextDirection.ltr,
                          maxLines: 3,
                        )..layout(maxWidth: textBoxWidth);
                        final textHeight = tp.height;

                        return Stack(
                          children: [
                            Positioned(
                              left: fieldLeft,
                              top: centerY - tfHeight / 2,
                              child: SizedBox(
                                width: _kCtaWidth,
                                height: tfHeight,
                                child: TextField(
                                  controller: _passwordController,
                                  obscureText: _obscure,
                                  style: const TextStyle(
                                    color: Colors.white70,
                                    fontSize: 20,
                                  ),
                                  decoration: InputDecoration(
                                    filled: true,
                                    fillColor: Colors.white.withOpacity(0.2),
                                    hintText: loc.enterPassword,
                                    hintStyle: const TextStyle(
                                      color: Color(0x80FFFFFF),
                                    ),
                                    contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 20,
                                      vertical: 18,
                                    ),
                                    suffixIcon: IconButton(
                                      icon: Icon(
                                        _obscure
                                            ? Icons.visibility_off_outlined
                                            : Icons.visibility_outlined,
                                        color: Colors.white70,
                                      ),
                                      onPressed: () =>
                                          setState(() => _obscure = !_obscure),
                                    ),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(26),
                                      borderSide: BorderSide.none,
                                    ),
                                  ),
                                  textInputAction: TextInputAction.done,
                                  onSubmitted: (_) =>
                                      FocusScope.of(context).unfocus(),
                                ),
                              ),
                            ),

                            Positioned(
                              left: textLeft,
                              width: textBoxWidth,
                              top: centerY - tfHeight / 2 - gapTop - textHeight,
                              child: Text(
                                loc.welcomeToQalqanDsm,
                                textAlign: TextAlign.center,
                                style: textStyle,
                              ),
                            ),

                            Positioned(
                              left: fieldLeft,
                              top: centerY + tfHeight / 2 + gapBottom,
                              child: SizedBox(
                                width: _kCtaWidth,
                                height: btnHeight,
                                child: ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF5869E5),
                                    elevation: 8,
                                    padding: const EdgeInsets.all(10),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(26),
                                    ),
                                    textStyle: const TextStyle(
                                      fontFamily: 'MontserratRegular',
                                      fontSize: 20,
                                    ),
                                  ),
                                  onPressed: _onEnterPressed,
                                  child: Text(
                                    loc.enter,
                                    style: const TextStyle(
                                      color: Color(0xBFFFFFFF),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                ),

                //
                Positioned(
                  top: size.height * 0.023,
                  right: 16,
                  child: _buildLangPicker(),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _onEnterPressed() async {
    final loc = AppLocalizations.of(context)!;
    final pwd = _passwordController.text.trim();

    if (pwd.isEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(loc.pleaseEnterPassword)));
      return;
    }

    FilePickerResult? result;
    try {
      result = await FilePicker.platform.pickFiles(
        allowMultiple: false,
        type: FileType.custom,
        allowedExtensions: ['bin'],
      );
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Ошибка выбора файла')));
      return;
    }

    if (result == null || result.files.isEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(loc.keyfilenf)));
      return;
    }

    final filePath = result.files.single.path!;
    final file = File(filePath);

    bool ok = false;
    try {
      ok = await _channel.invokeMethod<bool>(
        'decryptKey',
        {'filePath': file.path, 'password': pwd},
      ) ??
          false;
    } on PlatformException catch (e) {
      debugPrint('PlatformException: ${e.code} ${e.message}');
      ok = false;
    }

    if (!ok) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(loc.wrongPassword)));
      return;
    }

    if (!mounted) return;
    Navigator.pushReplacementNamed(context, AppRouter.start);
  }

  Widget _buildLangPicker() {
    const double itemHeight = 48.0;

    return Material(
      elevation: 8,
      borderRadius: BorderRadius.circular(26),
      color: Colors.white.withOpacity(.3),
      child: PopupMenuButton<String>(
        offset: const Offset(0, 40),
        color: Colors.white.withOpacity(.3),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(26)),
        constraints: const BoxConstraints.tightFor(width: _kLangBtnWidth),
        onSelected: (lang) {
          setState(() => _selectedLang = lang);
          if (lang.contains('ENG')) {
            widget.onLocaleChanged(const Locale('en'));
          } else if (lang.contains('РУС')) {
            widget.onLocaleChanged(const Locale('ru'));
          } else {
            widget.onLocaleChanged(const Locale('kk'));
          }
        },
        itemBuilder: (_) => _langs.map<PopupMenuEntry<String>>((lang) {
          return PopupMenuItem<String>(
            value: lang,
            height: itemHeight,
            child: SizedBox(
              width: double.infinity,
              child: Center(
                child: Text(
                  lang,
                  style: const TextStyle(
                    color: Color(0x80FFFFFF),
                    fontSize: 20,
                    fontFamily: 'MontserratRegular',
                  ),
                ),
              ),
            ),
          );
        }).toList(),
        child: SizedBox(
          width: _kLangBtnWidth,
          height: 40,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _selectedLang,
                  style: const TextStyle(
                    color: Color(0x80FFFFFF),
                    fontSize: 20,
                    fontFamily: 'MontserratRegular',
                  ),
                ),
                const Icon(Icons.arrow_drop_down, color: Color(0x80FFFFFF)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
