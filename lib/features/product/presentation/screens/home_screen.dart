import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/brand_colors.dart';
import '../../../../shared/widgets/category_chip.dart';
import '../../../../shared/widgets/brand_logo.dart';
import '../../../../shared/widgets/custom_search_bar.dart';
import '../../../../shared/widgets/error_state_view.dart';
import '../../../../shared/widgets/loading_skeleton.dart';
import '../../../../shared/widgets/product_card.dart';
import '../../../../shared/widgets/section_title.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../cart/presentation/providers/cart_provider.dart';
import '../providers/product_provider.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  final _searchController = TextEditingController();
  Timer? _debounce;
  late final ScrollController _scrollController;
  String _fallbackCategory = 'All';

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController()..addListener(_onScroll);
  }

  void _onScroll() {
    if (!_scrollController.hasClients) {
      return;
    }

    final threshold = _scrollController.position.maxScrollExtent - 280;
    if (_scrollController.position.pixels >= threshold) {
      ref.read(productProvider.notifier).loadMore();
    }
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    _scrollController
      ..removeListener(_onScroll)
      ..dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(productProvider);
    final authState = ref.watch(authProvider);
    final rawName = authState.user?.name.trim() ?? '';
    final userName = rawName.isEmpty ? 'there' : rawName;
    final chips = _buildCategories(state);

    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 74,
        titleSpacing: 16,
        title: const BrandLogo(width: 160),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: _IconCircleButton(
              icon: Icons.shopping_bag_outlined,
              onTap: () => context.go('/cart'),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Builder(
          builder: (context) {
            if (state.errorMessage != null && state.products.isEmpty) {
              return ErrorStateView(
                message: state.errorMessage!,
                onRetry: () =>
                    ref.read(productProvider.notifier).fetchProducts(),
              );
            }

            return RefreshIndicator(
              onRefresh: () => ref
                  .read(productProvider.notifier)
                  .fetchProducts(refresh: true),
              child: CustomScrollView(
                controller: _scrollController,
                physics: const BouncingScrollPhysics(),
                slivers: [
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
                    sliver: SliverToBoxAdapter(
                      child: _TopHeader(
                        userName: userName,
                        greetingText: _greetingByTime(),
                        onNotificationTap: () {},
                      ),
                    ),
                  ),
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
                    sliver: SliverToBoxAdapter(
                      child: CustomSearchBar(
                        controller: _searchController,
                        hintText: 'Search',
                        onChanged: (value) {
                          _debounce?.cancel();
                          _debounce = Timer(
                            const Duration(milliseconds: 450),
                            () {
                              ref
                                  .read(productProvider.notifier)
                                  .updateSearch(value.trim());
                            },
                          );
                        },
                        onFilterTap: () {},
                      ),
                    ),
                  ),
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
                    sliver: SliverToBoxAdapter(
                      child: SectionTitle(title: 'Categories', onSeeAll: () {}),
                    ),
                  ),
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                    sliver: SliverToBoxAdapter(
                      child: SizedBox(
                        height: 42,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          itemCount: chips.length,
                          separatorBuilder: (context, index) =>
                              const SizedBox(width: 10),
                          itemBuilder: (context, index) {
                            final chip = chips[index];
                            return CategoryChip(
                              label: chip.label,
                              selected: chip.selected,
                              onTap: chip.onTap,
                            );
                          },
                        ),
                      ),
                    ),
                  ),
                  const SliverPadding(
                    padding: EdgeInsets.fromLTRB(16, 16, 16, 0),
                    sliver: SliverToBoxAdapter(child: _PromoBanner()),
                  ),
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(16, 22, 16, 0),
                    sliver: SliverToBoxAdapter(
                      child: SectionTitle(
                        title: 'Popular Product',
                        onSeeAll: () {},
                      ),
                    ),
                  ),
                  if (state.isLoading && state.products.isEmpty)
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(16, 14, 16, 24),
                      sliver: SliverGrid.builder(
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              childAspectRatio: 0.66,
                              crossAxisSpacing: 12,
                              mainAxisSpacing: 12,
                            ),
                        itemBuilder: (context, index) =>
                            const LoadingSkeleton(height: 220),
                        itemCount: 6,
                      ),
                    )
                  else if (state.products.isEmpty)
                    const SliverFillRemaining(
                      hasScrollBody: false,
                      child: Center(child: Text('No products found')),
                    )
                  else
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(16, 14, 16, 24),
                      sliver: SliverGrid.builder(
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              childAspectRatio: 0.66,
                              crossAxisSpacing: 12,
                              mainAxisSpacing: 12,
                            ),
                        itemBuilder: (context, index) {
                          if (index >= state.products.length) {
                            return const LoadingSkeleton(height: 220);
                          }
                          final product = state.products[index];
                          return ProductCard(
                            product: product,
                            onTap: () =>
                                context.push('/home/product/${product.slug}'),
                            onAddToCart: () {
                              ref
                                  .read(cartProvider.notifier)
                                  .addItem(product.id);
                            },
                          );
                        },
                        itemCount:
                            state.products.length +
                            (state.isLoadingMore ? 2 : 0),
                      ),
                    ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  List<_ChipVm> _buildCategories(ProductState state) {
    if (state.categories.isEmpty) {
      const fallback = ['All', 'Men', 'Women', 'Kids'];
      return fallback
          .map(
            (label) => _ChipVm(
              label: label,
              selected: _fallbackCategory == label,
              onTap: () {
                setState(() {
                  _fallbackCategory = label;
                });
                if (label == 'All') {
                  ref.read(productProvider.notifier).updateCategory('');
                }
              },
            ),
          )
          .toList();
    }

    return [
      _ChipVm(
        label: 'All',
        selected: state.selectedCategory.isEmpty,
        onTap: () => ref.read(productProvider.notifier).updateCategory(''),
      ),
      ...state.categories.map(
        (category) => _ChipVm(
          label: category.name,
          selected: state.selectedCategory == category.id,
          onTap: () =>
              ref.read(productProvider.notifier).updateCategory(category.id),
        ),
      ),
    ];
  }

  String _greetingByTime() {
    final hour = DateTime.now().hour;
    if (hour < 12) {
      return 'Good Morning';
    }
    if (hour < 17) {
      return 'Good Afternoon';
    }
    if (hour < 21) {
      return 'Good Evening';
    }
    return 'Good Night';
  }
}

class _TopHeader extends StatelessWidget {
  const _TopHeader({
    required this.userName,
    required this.greetingText,
    required this.onNotificationTap,
  });

  final String userName;
  final String greetingText;
  final VoidCallback onNotificationTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      children: [
        const CircleAvatar(
          radius: 22,
          backgroundColor: Color(0xFFDDE5FF),
          child: Icon(Icons.person, color: BrandColors.logoNavy),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Hello, $userName',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              Text(
                greetingText,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
        _IconCircleButton(
          icon: Icons.notifications_none_rounded,
          onTap: onNotificationTap,
        ),
      ],
    );
  }
}

class _IconCircleButton extends StatelessWidget {
  const _IconCircleButton({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: onTap,
      child: Ink(
        height: 42,
        width: 42,
        decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius: BorderRadius.circular(12),
          boxShadow: const [
            BoxShadow(
              color: Color(0x12000000),
              blurRadius: 14,
              offset: Offset(0, 6),
            ),
          ],
        ),
        child: Icon(icon, size: 22),
      ),
    );
  }
}

class _PromoBanner extends StatelessWidget {
  const _PromoBanner();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 142,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [BrandColors.logoNavy, BrandColors.logoViolet],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
        boxShadow: const [
          BoxShadow(
            color: Color(0x330C1B4D),
            blurRadius: 22,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    'Bazario Picks\nSpecial Sale Up To 40%',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      height: 1.2,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 10),
                  FilledButton.tonal(
                    onPressed: () {},
                    style: FilledButton.styleFrom(
                      backgroundColor: BrandColors.logoGold,
                      foregroundColor: const Color(0xFF2D1600),
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      minimumSize: const Size(0, 34),
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: const Text('Shop Now'),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            const BrandLogo(width: 92, showWordmark: false),
          ],
        ),
      ),
    );
  }
}

class _ChipVm {
  const _ChipVm({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;
}
