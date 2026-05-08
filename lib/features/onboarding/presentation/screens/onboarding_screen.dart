import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentIndex = 0;
  bool _isCompleting = false;

  static const _items = [
    _OnboardData(
      title: 'Hello',
      description:
        'Discover curated picks, trending deals, and a smoother way to shop in just a few taps.',
      imageUrl:
          'https://images.unsplash.com/photo-1607082348824-0a96f2a4b9da?auto=format&fit=crop&w=1200&q=80',
      buttonLabel: null,
    ),
    _OnboardData(
      title: 'Ready?',
      description:
        'Save favorites, track orders, and checkout faster whenever you are ready.',
      imageUrl:
          'https://images.unsplash.com/photo-1524504388940-b1c1722653e1?auto=format&fit=crop&w=1200&q=80',
      buttonLabel: "Let's Start",
    ),
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _completeOnboarding() async {
    if (_isCompleting) {
      return;
    }

    setState(() => _isCompleting = true);

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isFirstTime', false);

    if (!mounted) {
      return;
    }

    context.go('/login');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F4F6),
      body: SafeArea(
        child: Stack(
          children: [
            const Positioned.fill(child: _BackdropDecor()),
            Column(
              children: [
                const SizedBox(height: 28),
                Expanded(
                  child: PageView.builder(
                    controller: _pageController,
                    itemCount: _items.length,
                    onPageChanged: (value) {
                      setState(() => _currentIndex = value);
                    },
                    itemBuilder: (context, index) {
                      final item = _items[index];
                      final isLast = index == _items.length - 1;

                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 18),
                        child: _OnboardCard(
                          item: item,
                          isCompleting: _isCompleting,
                          onPrimaryAction: isLast ? _completeOnboarding : null,
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(
                    _items.length,
                    (index) => AnimatedContainer(
                      duration: const Duration(milliseconds: 240),
                      margin: const EdgeInsets.symmetric(horizontal: 10),
                      height: 16,
                      width: 16,
                      decoration: BoxDecoration(
                        color: _currentIndex == index
                            ? const Color(0xFF0B4DFF)
                            : const Color(0xFFC9DBFF),
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 26),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _BackdropDecor extends StatelessWidget {
  const _BackdropDecor();

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned(
          left: -190,
          top: -170,
          child: Container(
            height: 520,
            width: 520,
            decoration: const BoxDecoration(
              color: Color(0xFF0B4DFF),
              shape: BoxShape.circle,
            ),
          ),
        ),
        Positioned(
          left: -150,
          bottom: -210,
          child: Container(
            height: 430,
            width: 430,
            decoration: const BoxDecoration(
              color: Color(0xFFDCE8FF),
              shape: BoxShape.circle,
            ),
          ),
        ),
      ],
    );
  }
}

class _OnboardCard extends StatelessWidget {
  const _OnboardCard({
    required this.item,
    required this.isCompleting,
    this.onPrimaryAction,
  });

  final _OnboardData item;
  final bool isCompleting;
  final Future<void> Function()? onPrimaryAction;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(40),
        boxShadow: const [
          BoxShadow(
            color: Color(0x18000000),
            blurRadius: 22,
            offset: Offset(0, 12),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          Expanded(
            flex: 6,
            child: Image.network(
              item.imageUrl,
              fit: BoxFit.cover,
              width: double.infinity,
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  color: const Color(0xFFF1C7D8),
                  alignment: Alignment.center,
                  child: const Icon(
                    Icons.image_not_supported_outlined,
                    size: 56,
                    color: Color(0xFF7A7A7A),
                  ),
                );
              },
            ),
          ),
          Expanded(
            flex: 5,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 22, 24, 18),
              child: Column(
                children: [
                  Text(
                    item.title,
                    style: theme.textTheme.displaySmall?.copyWith(
                      fontSize: 62,
                      fontWeight: FontWeight.w800,
                      color: const Color(0xFF1A1A1A),
                      height: 0.92,
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    item.description,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontSize: 21,
                      color: const Color(0xFF272727),
                      height: 1.45,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                  const Spacer(),
                  if (item.buttonLabel != null)
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        onPressed: (isCompleting || onPrimaryAction == null)
                            ? null
                            : onPrimaryAction,
                        style: FilledButton.styleFrom(
                          minimumSize: const Size.fromHeight(74),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(22),
                          ),
                          backgroundColor: const Color(0xFF0B4DFF),
                          foregroundColor: Colors.white,
                          textStyle: theme.textTheme.titleMedium?.copyWith(
                            fontSize: 22,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                        child: isCompleting
                            ? const SizedBox(
                                height: 24,
                                width: 24,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.4,
                                  color: Colors.white,
                                ),
                              )
                            : Text(item.buttonLabel!),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _OnboardData {
  const _OnboardData({
    required this.title,
    required this.description,
    required this.imageUrl,
    required this.buttonLabel,
  });

  final String title;
  final String description;
  final String imageUrl;
  final String? buttonLabel;
}
