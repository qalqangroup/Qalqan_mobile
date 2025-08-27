import 'package:flutter/material.dart';
import 'package:qalqan_dsm/features/splash/presentation/splash_screen.dart';
import 'package:qalqan_dsm/features/home/presentation/home_screen.dart';
import 'package:qalqan_dsm/features/start/presentation/start_screen.dart';
import 'package:qalqan_dsm/features/init_key/presentation/init_key_screen.dart';
import 'package:qalqan_dsm/features/chat/ui/login_page.dart';
import 'package:qalqan_dsm/features/encrypt/presentation/encrypt_screen.dart';
import 'package:qalqan_dsm/features/decrypt/presentation/decrypt_screen.dart';

typedef LocaleCallback = void Function(Locale locale);

class AppRouter {
  static const splash  = '/';
  static const home    = '/home';
  static const start   = '/start';
  static const encrypt = '/encrypt';
  static const login   = '/login';
  static const decrypt = '/decrypt';
  static const init    = '/init';

  /// Генератор маршрутов. При создании передаём callback для смены локали.
  static Route<dynamic> generate(
      RouteSettings settings, {
        required LocaleCallback onLocaleChanged,
      }) {
    switch (settings.name) {
      case splash:
        return MaterialPageRoute(
          builder: (_) => SplashScreen(onLocaleChanged: onLocaleChanged),
        );
      case home:
        return MaterialPageRoute(
          builder: (_) => HomeScreen(onLocaleChanged: onLocaleChanged),
        );
      case start:
        return MaterialPageRoute(
          builder: (_) => StartScreen(onLocaleChanged: onLocaleChanged),
        );
      case init:
        return MaterialPageRoute(
          builder: (_) => InitKeyScreen(onLocaleChanged: onLocaleChanged),
        );
      case login:
        return MaterialPageRoute(
          builder: (_) => const LoginPage(),
        );
      case encrypt:
        return MaterialPageRoute(
          builder: (_) => EncryptScreen(onLocaleChanged: onLocaleChanged),
        );
      case decrypt:
        return MaterialPageRoute(
          builder: (_) => DecryptScreen(onLocaleChanged: onLocaleChanged),
        );
      default:
        return MaterialPageRoute(
          builder: (_) => const Scaffold(
            body: Center(child: Text('Page not found')),
          ),
        );
    }
  }
}
