import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:qalqan_dsm/l10n/app_localizations.dart';
import 'package:qalqan_dsm/routes/app_router.dart';
import 'package:qalqan_dsm/core/key_access.dart';

class InitKeyScreen extends StatefulWidget {
  final ValueChanged<Locale>? onLocaleChanged;

  const InitKeyScreen({Key? key, this.onLocaleChanged}) : super(key: key);

  @override
  State<InitKeyScreen> createState() => _InitKeyScreenState();
}

class _InitKeyScreenState extends State<InitKeyScreen>
    with WidgetsBindingObserver {
  static const _channel = MethodChannel('com.qalqan/app');

  late final AppLocalizations loc;

  final _newPwdController = TextEditingController();
  final _confirmController = TextEditingController();

  // Focus
  final _focusNew = FocusNode();
  final _focusConfirm = FocusNode();
  bool get _anyFieldFocused => _focusNew.hasFocus || _focusConfirm.hasFocus;

  bool _obscureNew = true;
  bool _obscureConfirm = true;
  int _currentNavIndex = 4;

  static const _bottomNavHeight = 56.0;

  // интервалы
  static const double _gapFields = 20.0; // между полями
  static const double _gapButton = 30.0; // между подтверждением и кнопкой

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _focusNew.addListener(() => setState(() {}));
    _focusConfirm.addListener(() => setState(() {}));
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    loc = AppLocalizations.of(context)!;
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _newPwdController.dispose();
    _confirmController.dispose();
    _focusNew.dispose();
    _focusConfirm.dispose();
    super.dispose();
  }

  @override
  void didChangeMetrics() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context);
    final insets = mq.viewInsets; // высота клавиатуры

    final bool keyboardVisible = insets.bottom > 0.0;
    final double belowCenterShift = keyboardVisible ? 0.0 : mq.size.height * 0.05;

    return Scaffold(
      resizeToAvoidBottomInset: false,
      extendBody: true,
      bottomNavigationBar: SafeArea(
        top: false,
        child: ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(26)),
          child: BottomNavigationBar(
            backgroundColor: Colors.white,
            elevation: 8,
            currentIndex: _currentNavIndex,
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
                  colors: [ Color(0xFF8A9AFF), Color(0xFF3B4DFF), Color(0xFF8A9AFF) ],
                ),
              ),
              child: Stack(
                children: [
                  Positioned.fill(
                    child: AnimatedPadding(
                      duration: const Duration(milliseconds: 220),
                      curve: Curves.easeOut,
                      padding: EdgeInsets.only(bottom: insets.bottom),
                      child: Center(
                        child: AnimatedSlide(
                          duration: const Duration(milliseconds: 260),
                          curve: Curves.easeOutCubic,

                          offset: _anyFieldFocused ? const Offset(0, -0.22) : Offset.zero,
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 220),
                            transform: Matrix4.translationValues(0, belowCenterShift, 0),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                _passwordField(
                                  controller: _newPwdController,
                                  obscure: _obscureNew,
                                  hint: loc.newPassword,
                                  onToggle: () => setState(() => _obscureNew = !_obscureNew),
                                  textInputAction: TextInputAction.next,
                                  focusNode: _focusNew,
                                ),
                                const SizedBox(height: _gapFields),
                                _passwordField(
                                  controller: _confirmController,
                                  obscure: _obscureConfirm,
                                  hint: loc.confirmPassword,
                                  onToggle: () => setState(() => _obscureConfirm = !_obscureConfirm),
                                  textInputAction: TextInputAction.done,
                                  onSubmitted: (_) => _onSave(),
                                  focusNode: _focusConfirm,
                                ),
                                const SizedBox(height: _gapButton),
                                SizedBox(
                                  width: 300,
                                  height: 60,
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
                                    onPressed: _onSave,
                                    child: Text(
                                      loc.save,
                                      style: const TextStyle(color: Color(0xBFFFFFFF)),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
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

  Widget _passwordField({
    required TextEditingController controller,
    required bool obscure,
    required String hint,
    required VoidCallback onToggle,
    TextInputAction textInputAction = TextInputAction.done,
    ValueChanged<String>? onSubmitted,
    FocusNode? focusNode,
  }) {
    return SizedBox(
      width: 300,
      height: 60,
      child: TextField(
        focusNode: focusNode,
        controller: controller,
        obscureText: obscure,
        textInputAction: textInputAction,
        onSubmitted: onSubmitted,
        style: const TextStyle(color: Colors.white70, fontSize: 18),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: const TextStyle(color: Colors.white54),
          filled: true,
          fillColor: Colors.white.withOpacity(0.2),
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
          suffixIcon: IconButton(
            icon: Icon(
              obscure ? Icons.visibility_off_outlined : Icons.visibility_outlined,
              color: Colors.white70,
            ),
            onPressed: onToggle,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(26),
            borderSide: BorderSide.none,
          ),
        ),
      ),
    );
  }

  Future<void> _onSave() async {
    final newPwd = _newPwdController.text.trim();
    final confirm = _confirmController.text.trim();

    if (newPwd.isEmpty || confirm.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(loc.fillAllFields)));
      return;
    }
    if (newPwd != confirm) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(loc.passwordsDoNotMatch)));
      return;
    }

    bool ok = false;
    try {
      ok = await _channel.invokeMethod<bool>('encryptKeys', {'password': newPwd}) ?? false;
    } on PlatformException catch (e) {
      debugPrint('encryptKeys error: ${e.code} ${e.message}');
    }

    if (!ok) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(loc.error)));
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(loc.success)));
    if (!mounted) return;
    Navigator.pushReplacementNamed(context, AppRouter.start);
  }

  void _onNavTap(int index) {
    switch (index) {
      case 0:
        setState(() => _currentNavIndex = 0);
        Navigator.of(context).pushReplacementNamed(AppRouter.start);
        break;

      case 1:
        if (!KeyAccess.isReady) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(loc.pleaseselectkeytype)),
          );
          setState(() => _currentNavIndex = 0);
          Navigator.of(context).pushReplacementNamed(AppRouter.start);
          return;
        }
        setState(() => _currentNavIndex = 1);
        Navigator.of(context).pushReplacementNamed(
          AppRouter.encrypt,
          arguments: KeyAccess.selected,
        );
        break;

      case 2:
        setState(() => _currentNavIndex = 2);
        Navigator.of(context).pushReplacementNamed(AppRouter.login);
        break;

      case 3:
        setState(() => _currentNavIndex = 3);
        Navigator.of(context).pushReplacementNamed(AppRouter.decrypt);
        break;

      case 4:
      default:
        setState(() => _currentNavIndex = 4);
        break;
    }
  }
}
