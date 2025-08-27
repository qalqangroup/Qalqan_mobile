import 'package:flutter/material.dart';
import '../services/auth_data.dart';
import '../services/call_store.dart';
import '../services/matrix_auth.dart';
import '../services/matrix_chat_service.dart';
import 'chat_list_page.dart';
import '../services/matrix_sync_service.dart';
import 'package:matrix/matrix.dart' as mx;
import '../services/matrix_incoming_call_service.dart';
import '../services/cred_store.dart';
import 'package:qalqan_dsm/l10n/app_localizations.dart';
import 'package:qalqan_dsm/routes/app_router.dart';
import 'package:qalqan_dsm/core/key_access.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({Key? key}) : super(key: key);

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  final TextEditingController _userController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  bool _isLoading = false;
  bool _autoLoginInProgress = false;
  String? _errorText;

  late AnimationController _animController;
  late Animation<double> _fadeAnimation;

  static const double _bottomNavHeight = 56.0;
  int _currentIndex = 2;

  bool _obscurePwd = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fadeAnimation = CurvedAnimation(parent: _animController, curve: Curves.easeIn);
    _animController.forward();

    _tryAutoLogin();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _animController.dispose();
    _userController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  void didChangeMetrics() {
    if (mounted) setState(() {});
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && !_autoLoginInProgress) {
      _tryAutoLogin();
    }
  }

  Future<void> _tryAutoLogin() async {
    if (_autoLoginInProgress) return;
    _autoLoginInProgress = true;
    setState(() => _isLoading = true);

    try {
      final creds = await CredStore.load();
      if (creds == null) {
        setState(() => _isLoading = false);
        _autoLoginInProgress = false;
        return;
      }

      final sdkOk = await AuthService.login(user: creds.user, password: creds.password);

      MatrixService.setAccessTokenFromSdk(AuthService.accessToken, AuthService.userId);
      await MatrixService.syncOnce();

      if (sdkOk) {

        AuthDataCall.instance.login = creds.user;
        AuthDataCall.instance.password = creds.password;

        final mx.Client client = MatrixService.client;
        final myUserId = MatrixService.userId ?? AuthService.userId ?? creds.user;
        await CallStore.saveMyUserId(myUserId);

        MatrixSyncService.instance.attachClient(client);
        MatrixSyncService.instance.start();

        MatrixCallService.init(client, MatrixService.userId ?? '');

        if (!mounted) return;

        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const _ChatWithBottomNav()),
        );
      } else {
        await CredStore.clear();
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorText = AppLocalizations.of(context)!.autologinFailed;
        });
      }
    } finally {
      _autoLoginInProgress = false;
    }
  }

  Future<void> _doLogin() async {
    final user = _userController.text.trim();
    final password = _passwordController.text.trim();

    if (user.isEmpty || password.isEmpty) {
      setState(() => _errorText = AppLocalizations.of(context)!.plsfill);
      return;
    }

    FocusScope.of(context).unfocus();
    setState(() {
      _isLoading = true;
      _errorText = null;
    });

    final sdkOk = await AuthService.login(user: user, password: password);

    MatrixService.setAccessTokenFromSdk(AuthService.accessToken, AuthService.userId);

    await MatrixService.syncOnce();

    if (sdkOk) {
      AuthDataCall.instance.login = user;
      AuthDataCall.instance.password = password;
      await CredStore.save(user: user, password: password);

      final mx.Client client = MatrixService.client;
      final myUserId = MatrixService.userId ?? AuthService.userId ?? user;
      await CallStore.saveMyUserId(myUserId);

      MatrixSyncService.instance.attachClient(client);
      MatrixSyncService.instance.start();

      MatrixCallService.init(client, MatrixService.userId ?? '');

      if (!mounted) return;
      // ⬇️ В оболочку с нижним меню
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const _ChatWithBottomNav()),
      );
    } else {
      setState(() => _errorText = AppLocalizations.of(context)!.loginFailed);
    }
  }

  Future<void> _onNavTap(int i) async {
    final loc = AppLocalizations.of(context)!;

    switch (i) {
      case 0:
        Navigator.of(context).pushReplacementNamed(AppRouter.start);
        break;

      case 1:
        if (!KeyAccess.isReady) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(loc.pleaseselectkeytype)),
          );
          Navigator.of(context).pushReplacementNamed(AppRouter.start);
          break;
        }
        Navigator.of(context).pushReplacementNamed(
          AppRouter.encrypt,
          arguments: KeyAccess.selected,
        );
        break;

      case 2:
      // ⬇️ Если уже логинились — сразу в оболочку с меню
        final creds = await CredStore.load();
        if (creds != null) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (_) => const _ChatWithBottomNav()),
          );
        }
        break;

      case 3:
        Navigator.of(context).pushReplacementNamed(AppRouter.decrypt);
        break;

      case 4:
        Navigator.of(context).pushReplacementNamed(AppRouter.init);
        break;
    }
    setState(() => _currentIndex = i);
  }

  Widget _buildAuthField({
    required String hint,
    required TextEditingController controller,
    bool obscure = false,
    VoidCallback? onToggleObscure,
    TextInputAction action = TextInputAction.next,
    void Function(String)? onSubmitted,
  }) {
    return SizedBox(
      width: 300,
      height: 60,
      child: TextField(
        controller: controller,
        obscureText: obscure,
        textInputAction: action,
        onSubmitted: onSubmitted,
        style: const TextStyle(color: Colors.white70, fontSize: 18),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: const TextStyle(color: Colors.white54),
          filled: true,
          fillColor: Colors.white.withOpacity(0.2),
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
          suffixIcon: onToggleObscure == null
              ? null
              : IconButton(
            icon: Icon(
              obscure ? Icons.visibility_off_outlined : Icons.visibility_outlined,
              color: Colors.white70,
            ),
            onPressed: onToggleObscure,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(26),
            borderSide: BorderSide.none,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final mq = MediaQuery.of(context);
    final insets = mq.viewInsets;

    return Scaffold(
      resizeToAvoidBottomInset: false,
      extendBody: true,
      bottomNavigationBar: SafeArea(
        top: false,
        child: ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(26)),
          child: BottomNavigationBar(
            type: BottomNavigationBarType.fixed,
            backgroundColor: Colors.white,
            currentIndex: _currentIndex,
            selectedItemColor: const Color(0xFF5869E5),
            unselectedItemColor: Colors.grey,
            showSelectedLabels: true,
            showUnselectedLabels: false,
            onTap: (i) => _onNavTap(i),
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
        child: Stack(
          children: [
            // фон
            Container(
              decoration: const BoxDecoration(
                image: DecorationImage(
                  image: AssetImage('assets/images/background.png'),
                  fit: BoxFit.cover,
                ),
              ),
            ),

            // контент
            Padding(
              padding: const EdgeInsets.only(bottom: _bottomNavHeight),
              child: GestureDetector(
                behavior: HitTestBehavior.deferToChild,
                onTap: () => FocusScope.of(context).unfocus(),
                child: FadeTransition(
                  opacity: _fadeAnimation,
                  child: AnimatedPadding(
                    duration: const Duration(milliseconds: 220),
                    curve: Curves.easeOut,
                    padding: EdgeInsets.only(bottom: insets.bottom),
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        const double fieldH = 60.0;
                        const double gapFields = 16.0;
                        const double gapBtn = 30.0;
                        const double btnH = 60.0;

                        final double fieldsBlockH = fieldH + gapFields + fieldH;
                        final double h = constraints.maxHeight;
                        final double centerY = h / 2;

                        final double fieldsTop = centerY - fieldsBlockH / 2;
                        final double userTop = fieldsTop;
                        final double passTop = userTop + fieldH + gapFields;
                        final double btnTop  = passTop + fieldH + gapBtn;

                        return Stack(
                          children: [
                            Positioned(
                              top: userTop,
                              left: 0,
                              right: 0,
                              child: Center(
                                child: _buildAuthField(
                                  hint: loc.username,
                                  controller: _userController,
                                  action: TextInputAction.next,
                                  onSubmitted: (_) => FocusScope.of(context).nextFocus(),
                                ),
                              ),
                            ),
                            Positioned(
                              top: passTop,
                              left: 0,
                              right: 0,
                              child: Center(
                                child: _buildAuthField(
                                  hint: loc.password,
                                  controller: _passwordController,
                                  obscure: _obscurePwd,
                                  onToggleObscure: () => setState(() => _obscurePwd = !_obscurePwd),
                                  action: TextInputAction.done,
                                  onSubmitted: (_) => _doLogin(),
                                ),
                              ),
                            ),
                            Positioned(
                              top: btnTop,
                              left: 0,
                              right: 0,
                              child: Center(
                                child: SizedBox(
                                  width: 300,
                                  height: btnH,
                                  child: ElevatedButton(
                                    onPressed: _isLoading ? null : _doLogin,
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
                                    child: _isLoading
                                        ? const CircularProgressIndicator(
                                      valueColor: AlwaysStoppedAnimation(Colors.white),
                                    )
                                        : Text(
                                      loc.enter,
                                      style: const TextStyle(color: Color(0xBFFFFFFF)),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            if (_errorText != null)
                              Positioned(
                                top: btnTop + btnH + 12,
                                left: 0,
                                right: 0,
                                child: Center(
                                  child: Text(
                                    _errorText!,
                                    style: const TextStyle(
                                      color: Colors.redAccent,
                                      fontWeight: FontWeight.bold,
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
              ),
            ),

            if (_isLoading)
              Container(
                color: Colors.black26,
                child: const Center(child: CircularProgressIndicator()),
              ),
          ],
        ),
      ),
    );
  }
}

/// Оболочка чата с нижним меню
class _ChatWithBottomNav extends StatefulWidget {
  const _ChatWithBottomNav({Key? key}) : super(key: key);

  @override
  State<_ChatWithBottomNav> createState() => _ChatWithBottomNavState();
}

class _ChatWithBottomNavState extends State<_ChatWithBottomNav> {
  static const double _bottomNavHeight = 56.0;
  int _currentIndex = 2;

  void _onNavTap(int i) {
    final loc = AppLocalizations.of(context)!;

    switch (i) {
      case 0: Navigator.of(context).pushReplacementNamed(AppRouter.start); break;
      case 1:
        if (!KeyAccess.isReady) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(loc.pleaseselectkeytype)));
          Navigator.of(context).pushReplacementNamed(AppRouter.start);
          break;
        }
        Navigator.of(context).pushReplacementNamed(AppRouter.encrypt, arguments: KeyAccess.selected);
        break;
      case 2: break;
      case 3: Navigator.of(context).pushReplacementNamed(AppRouter.decrypt); break;
      case 4: Navigator.of(context).pushReplacementNamed(AppRouter.init); break;
    }
    setState(() => _currentIndex = i);
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    return Scaffold(
      extendBody: true,
      bottomNavigationBar: SafeArea(
        top: false,
        child: ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(26)),
          child: BottomNavigationBar(
            type: BottomNavigationBarType.fixed,
            backgroundColor: Colors.white,
            currentIndex: _currentIndex,
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
      body: const SafeArea(
        bottom: false,
        child: Padding(
          padding: EdgeInsets.only(bottom: _bottomNavHeight),
          child: ChatListPage(),
        ),
      ),
    );
  }
}
