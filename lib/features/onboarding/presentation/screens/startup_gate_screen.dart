import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../features/auth/presentation/providers/auth_provider.dart';

class StartupGateScreen extends ConsumerStatefulWidget {
  const StartupGateScreen({super.key});

  @override
  ConsumerState<StartupGateScreen> createState() => _StartupGateScreenState();
}

class _StartupGateScreenState extends ConsumerState<StartupGateScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animationController;
  late final Animation<double> _fadeAnimation;
  late final Animation<double> _scaleAnimation;

  static const _splashDelay = Duration(milliseconds: 2300);

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    );
    _scaleAnimation = Tween<double>(begin: 0.94, end: 1).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeOutBack,
      ),
    );

    _animationController.forward();
    _resolveStartDestination();
  }

  Future<void> _resolveStartDestination() async {
    final prefs = await SharedPreferences.getInstance();
    final skipSplashDelay = prefs.getBool('skipSplashDelay') ?? false;
    final isFirstTime = prefs.getBool('isFirstTime') ?? true;
    final authState = ref.read(authProvider);
    final isLoggedIn = authState.isLoggedIn;
    final isAdmin = (authState.user?.role.toLowerCase() ?? '') == 'admin';

    if (!skipSplashDelay) {
      await Future<void>.delayed(_splashDelay);
    }

    if (!mounted) {
      return;
    }

    if (isFirstTime) {
      context.go('/onboarding');
    } else {
      context.go(isLoggedIn ? (isAdmin ? '/admin' : '/home') : '/login');
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF050E2A), Color(0xFF0B1A4A)],
          ),
        ),
        child: Stack(
          children: [
            Positioned(
              top: -90,
              right: -50,
              child: _GlowCircle(
                size: 220,
                color: const Color(0xFF9A63FF).withValues(alpha: 0.2),
              ),
            ),
            Positioned(
              bottom: -100,
              left: -40,
              child: _GlowCircle(
                size: 210,
                color: const Color(0xFFFF8A3D).withValues(alpha: 0.2),
              ),
            ),
            Center(
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: ScaleTransition(
                  scale: _scaleAnimation,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Image.asset(
                        'assets/images/DarkLogo.png',
                        width: 260,
                        fit: BoxFit.contain,
                        errorBuilder: (context, error, stackTrace) {
                          return const _FallbackLogo();
                        },
                      ),
                      const SizedBox(height: 18),
                      const Text(
                        'Shop smarter, faster, better.',
                        style: TextStyle(
                          color: Color(0xFFD3DAF0),
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 28),
                      const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Color(0xFFFF8A3D),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _GlowCircle extends StatelessWidget {
  const _GlowCircle({required this.size, required this.color});

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: size,
      width: size,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
  }
}

class _FallbackLogo extends StatelessWidget {
  const _FallbackLogo();

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: const [
        Icon(
          Icons.shopping_cart_checkout_rounded,
          size: 46,
          color: Color(0xFF9A63FF),
        ),
        SizedBox(width: 10),
        Text(
          'BAZARIO',
          style: TextStyle(
            color: Colors.white,
            fontSize: 36,
            letterSpacing: 1.5,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }
}
