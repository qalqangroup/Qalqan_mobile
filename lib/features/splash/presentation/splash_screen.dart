import 'dart:math';
import 'package:flutter/material.dart';
import 'package:qalqan_dsm/core/theme.dart';
import 'package:qalqan_dsm/routes/app_router.dart';

class SplashScreen extends StatefulWidget {
  final ValueChanged<Locale> onLocaleChanged;
  const SplashScreen({Key? key, required this.onLocaleChanged}) : super(key: key);

  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _rotation;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 6000),
    );

    _rotation = Tween<double>(begin: 0, end: 2 * pi).animate(
      CurvedAnimation(parent: _controller, curve: Curves.linear),
    );

    _controller.forward();
    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        Navigator.of(context).pushReplacementNamed(AppRouter.home);
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: AppTheme.splashGradient,
        ),
        child: Center(
          child: Stack(
            alignment: Alignment.center,
            children: [
              Image.asset(
                'assets/images/lock.png',
                width: 200,
                height: 200,
              ),
              AnimatedBuilder(
                animation: _rotation,
                builder: (_, child) => Transform.rotate(
                  angle: _rotation.value,
                  child: child,
                ),
                child: Image.asset(
                  'assets/images/ring.png',
                  width: 200,
                  height: 200,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}