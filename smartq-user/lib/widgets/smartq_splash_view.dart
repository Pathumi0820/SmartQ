import 'package:flutter/material.dart';
import '../utils/brand_colors.dart';

class SmartQSplashView extends StatelessWidget {
  final bool showLoading;

  const SmartQSplashView({
    super.key,
    this.showLoading = true,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: BrandColors.primary,
      body: SafeArea(
        child: Stack(
          children: [
            const Positioned(
              top: -80,
              right: -60,
              child: _BackgroundCircle(
                size: 220,
                opacity: 0.07,
              ),
            ),
            const Positioned(
              bottom: -100,
              left: -80,
              child: _BackgroundCircle(
                size: 240,
                opacity: 0.06,
              ),
            ),
            const Positioned(
              top: 120,
              left: -45,
              child: _BackgroundCircle(
                size: 110,
                opacity: 0.04,
              ),
            ),
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const _SplashLogo(),
                    const SizedBox(height: 22),
                    const Text(
                      'SmartQ',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.2,
                      ),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Queue Management System',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 22,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                    const SizedBox(height: 82),
                    const Text(
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

class _BackgroundCircle extends StatelessWidget {
  final double size;
  final double opacity;

  const _BackgroundCircle({
    required this.size,
    required this.opacity,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: opacity),
        shape: BoxShape.circle,
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
        color: Colors.white.withValues(alpha: 0.14),
        shape: BoxShape.circle,
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.22),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.12),
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