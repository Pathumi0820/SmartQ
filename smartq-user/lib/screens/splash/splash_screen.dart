import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../auth/login_screen.dart';
import '../home/home_screen.dart';

const Color smartQBrandBlue = Color(0xFF1E6DFB);

class SplashScreen extends StatefulWidget {
  const SplashScreen({
    super.key,
  });

  @override
  State<SplashScreen> createState() =>
      _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  StreamSubscription<User?>? _authSubscription;
  Timer? _fallbackTimer;

  bool _navigationCompleted = false;

  @override
  void initState() {
    super.initState();
    _restoreAuthenticationSession();
  }

  Future<void> _restoreAuthenticationSession() async {
    try {
      // Keeps the branded splash visible briefly.
      await Future<void>.delayed(
        const Duration(seconds: 1),
      );

      if (!mounted || _navigationCompleted) {
        return;
      }

      final User? currentUser =
          FirebaseAuth.instance.currentUser;

      if (currentUser != null) {
        _openHomeScreen();
        return;
      }

      _authSubscription = FirebaseAuth.instance
          .authStateChanges()
          .listen(
            (User? user) {
          if (!mounted || _navigationCompleted) {
            return;
          }

          if (user != null) {
            _openHomeScreen();
          } else {
            _openLoginScreen();
          }
        },
        onError: (Object error) {
          debugPrint(
            'Authentication restoration error: $error',
          );

          _openLoginScreen();
        },
      );

      _fallbackTimer = Timer(
        const Duration(seconds: 2),
            () {
          if (!mounted || _navigationCompleted) {
            return;
          }

          final User? user =
              FirebaseAuth.instance.currentUser;

          if (user != null) {
            _openHomeScreen();
          } else {
            _openLoginScreen();
          }
        },
      );
    } catch (error) {
      debugPrint(
        'Splash authentication check error: $error',
      );

      _openLoginScreen();
    }
  }

  void _openHomeScreen() {
    if (!mounted || _navigationCompleted) {
      return;
    }

    _navigationCompleted = true;
    _cancelListeners();

    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute<void>(
        settings: const RouteSettings(
          name: '/home',
        ),
        builder: (_) => const HomeScreen(),
      ),
          (Route<dynamic> route) => false,
    );
  }

  void _openLoginScreen() {
    if (!mounted || _navigationCompleted) {
      return;
    }

    _navigationCompleted = true;
    _cancelListeners();

    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute<void>(
        settings: const RouteSettings(
          name: '/login',
        ),
        builder: (_) => const LoginScreen(),
      ),
          (Route<dynamic> route) => false,
    );
  }

  void _cancelListeners() {
    _fallbackTimer?.cancel();
    _fallbackTimer = null;

    unawaited(
      _authSubscription?.cancel(),
    );

    _authSubscription = null;
  }

  @override
  void dispose() {
    _cancelListeners();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: smartQBrandBlue,
      body: SafeArea(
        child: Stack(
          children: [
            Positioned(
              top: -80,
              right: -60,
              child: Container(
                width: 220,
                height: 220,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.07),
                  shape: BoxShape.circle,
                ),
              ),
            ),
            Positioned(
              bottom: -100,
              left: -80,
              child: Container(
                width: 240,
                height: 240,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.06),
                  shape: BoxShape.circle,
                ),
              ),
            ),
            Positioned(
              top: 120,
              left: -45,
              child: Container(
                width: 110,
                height: 110,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.04),
                  shape: BoxShape.circle,
                ),
              ),
            ),
            const Center(
              child: Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: 24,
                ),
                child: Column(
                  mainAxisAlignment:
                  MainAxisAlignment.center,
                  children: [
                    _SplashLogo(),
                    SizedBox(height: 22),
                    Text(
                      'SmartQ',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.2,
                      ),
                    ),
                    SizedBox(height: 6),
                    Text(
                      'Queue Management System',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 22,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                    SizedBox(height: 82),
                    Text(
                      'Smart Queue. Better Care.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        letterSpacing: 0.3,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SplashLogo extends StatelessWidget {
  const _SplashLogo();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 120,
      height: 120,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.14),
        shape: BoxShape.circle,
        border: Border.all(
          color: Colors.white.withOpacity(0.22),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.12),
            blurRadius: 22,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: const Icon(
        Icons.local_hospital_rounded,
        color: Colors.white,
        size: 72,
      ),
    );
  }
}