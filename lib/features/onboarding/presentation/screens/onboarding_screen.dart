import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../shared/widgets/custom_button.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<_OnboardingData> _pages = const [
    _OnboardingData(
      title: 'Discover premium products',
      description:
          'Browse curated collections, trending picks, and exclusive offers designed for fast shopping.',
      icon: Icons.storefront_outlined,
      gradients: [Color(0xFF2563EB), Color(0xFF60A5FA)],
    ),
    _OnboardingData(
      title: 'Fast checkout with trusted payments',
      description:
          'Add items to cart, pay securely, and track orders from one polished shopping experience.',
      icon: Icons.lock_outline,
      gradients: [Color(0xFF0EA5E9), Color(0xFF22C55E)],
    ),
    _OnboardingData(
      title: 'Stay updated on every order',
      description:
          'See delivery progress, wishlist products, and personalized shopping details in one place.',
      icon: Icons.local_shipping_outlined,
      gradients: [Color(0xFFF97316), Color(0xFFFACC15)],
    ),
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _completeOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isFirstTime', false);

    if (!mounted) {
      return;
    }

    context.go('/login');
  }

  void _goNext() {
    if (_currentPage == _pages.length - 1) {
      _completeOnboarding();
      return;
    }
    _pageController.nextPage(
      duration: const Duration(milliseconds: 320),
      curve: Curves.easeOutCubic,
    );
  }

  void _skip() => _completeOnboarding();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
          child: Column(
            children: [
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(onPressed: _skip, child: const Text('Skip')),
              ),
              Expanded(
                child: PageView.builder(
                  controller: _pageController,
                  itemCount: _pages.length,
                  onPageChanged: (value) =>
                      setState(() => _currentPage = value),
                  itemBuilder: (context, index) {
                    final page = _pages[index];
                    return AnimatedPadding(
                      duration: const Duration(milliseconds: 250),
                      padding: const EdgeInsets.only(top: 12),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _OnboardingIllustration(page: page),
                          const SizedBox(height: 36),
                          Text(
                            page.title,
                            textAlign: TextAlign.center,
                            style: theme.textTheme.headlineMedium?.copyWith(
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            page.description,
                            textAlign: TextAlign.center,
                            style: theme.textTheme.bodyLarge?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                              height: 1.5,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 18),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  _pages.length,
                  (index) => AnimatedContainer(
                    duration: const Duration(milliseconds: 260),
                    curve: Curves.easeOutCubic,
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    height: 10,
                    width: _currentPage == index ? 28 : 10,
                    decoration: BoxDecoration(
                      color: _currentPage == index
                          ? theme.colorScheme.primary
                          : theme.colorScheme.primary.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 22),
              Row(
                children: [
                  if (_currentPage != _pages.length - 1)
                    Expanded(
                      child: CustomButton(
                        label: 'Next',
                        icon: Icons.arrow_forward_rounded,
                        onPressed: _goNext,
                      ),
                    )
                  else
                    Expanded(
                      child: CustomButton(
                        label: 'Get Started',
                        icon: Icons.shopping_bag_outlined,
                        onPressed: _completeOnboarding,
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _OnboardingData {
  const _OnboardingData({
    required this.title,
    required this.description,
    required this.icon,
    required this.gradients,
  });

  final String title;
  final String description;
  final IconData icon;
  final List<Color> gradients;
}

class _OnboardingIllustration extends StatelessWidget {
  const _OnboardingIllustration({required this.page});

  final _OnboardingData page;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AspectRatio(
      aspectRatio: 1,
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: page.gradients,
          ),
          borderRadius: BorderRadius.circular(32),
          boxShadow: const [
            BoxShadow(
              color: Color(0x26000000),
              blurRadius: 32,
              offset: Offset(0, 18),
            ),
          ],
        ),
        child: Stack(
          children: [
            Positioned(
              top: -24,
              right: -24,
              child: _CircleDecoration(
                size: 120,
                color: Colors.white.withValues(alpha: 0.14),
              ),
            ),
            Positioned(
              bottom: -28,
              left: -28,
              child: _CircleDecoration(
                size: 140,
                color: Colors.white.withValues(alpha: 0.1),
              ),
            ),
            Center(
              child: Container(
                height: 144,
                width: 144,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(36),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.25),
                  ),
                ),
                child: Icon(page.icon, size: 68, color: Colors.white),
              ),
            ),
            Positioned(
              bottom: 22,
              left: 22,
              child: _MiniBadge(
                title: 'Bazario',
                subtitle: 'Premium shopping',
                background: theme.colorScheme.surface,
                foreground: theme.colorScheme.onSurface,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CircleDecoration extends StatelessWidget {
  const _CircleDecoration({required this.size, required this.color});

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

class _MiniBadge extends StatelessWidget {
  const _MiniBadge({
    required this.title,
    required this.subtitle,
    required this.background,
    required this.foreground,
  });

  final String title;
  final String subtitle;
  final Color background;
  final Color foreground;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(color: foreground, fontWeight: FontWeight.w700),
          ),
          Text(
            subtitle,
            style: TextStyle(color: foreground.withValues(alpha: 0.7)),
          ),
        ],
      ),
    );
  }
}
