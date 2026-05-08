import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/utils/responsive_text.dart';
import '../../../../shared/models/product_model.dart';
import '../../../../shared/services/recently_viewed_store.dart';
import '../../../../shared/widgets/error_state_view.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../providers/product_provider.dart';

class StorefrontDashboardScreen extends ConsumerStatefulWidget {
  const StorefrontDashboardScreen({super.key});

  @override
  ConsumerState<StorefrontDashboardScreen> createState() =>
      _StorefrontDashboardScreenState();
}

class _StorefrontDashboardScreenState
    extends ConsumerState<StorefrontDashboardScreen> {
  final _scrollController = ScrollController();
  final _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _refreshDashboard() async {
    await ref.read(productProvider.notifier).bootstrap();
  }

  String _userKey() {
    final user = ref.read(authProvider).user;
    if (user == null) {
      return 'guest';
    }
    if (user.id.trim().isNotEmpty) {
      return user.id.trim();
    }
    return user.email.trim().isNotEmpty ? user.email.trim() : 'guest';
  }

  Future<void> _openProduct(ProductModel product) async {
    await RecentlyViewedStore.recordView(userKey: _userKey(), product: product);
    if (!mounted) {
      return;
    }
    await context.push('/home/product/${product.slug}');
    if (mounted) {
      setState(() {});
    }
  }

  Future<void> _logout() async {
    await ref.read(authProvider.notifier).logout();
    if (mounted) {
      context.go('/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(productProvider);
    final authState = ref.watch(authProvider);
    final user = authState.user;
    final userName = (user?.name.trim().isNotEmpty ?? false)
        ? user!.name.trim()
        : 'Romina';
    final avatarLabel = (user?.name.trim().isNotEmpty ?? false)
        ? user!.name.trim()
        : 'R';
    final products = state.products;
    final storyProducts = products.take(4).toList();
    final newItems = products.take(8).toList();
    final mostPopular = [...products]
      ..sort((a, b) => b.ratingCount.compareTo(a.ratingCount));
    final flashSaleItems = products.skip(1).take(8).toList();
    final topProducts = products.take(8).toList();
    final justForYou = products.skip(2).take(6).toList();
    final categoryGroups = _buildCategoryGroups(products).take(4).toList();

    if (state.errorMessage != null && state.products.isEmpty) {
      return Scaffold(
        body: SafeArea(
          child: ErrorStateView(
            message: state.errorMessage!,
            onRetry: _refreshDashboard,
          ),
        ),
      );
    }

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: const Color(0xFFF7F8FC),
      endDrawer: _UserMenuDrawer(
        userName: userName,
        email: user?.email ?? 'guest',
        onProfileTap: () => context.go('/profile'),
        onOrdersTap: () => context.go('/orders'),
        onWishlistTap: () => context.go('/wishlist'),
        onCartTap: () => context.go('/cart'),
        onLogoutTap: _logout,
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _refreshDashboard,
          child: CustomScrollView(
            controller: _scrollController,
            physics: const AlwaysScrollableScrollPhysics(
              parent: BouncingScrollPhysics(),
            ),
            slivers: [
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 10, 20, 0),
                sliver: SliverToBoxAdapter(
                  child: Align(
                    alignment: Alignment.center,
                    child: _HeaderAvatar(
                      label: avatarLabel,
                      onTap: () => _scaffoldKey.currentState?.openEndDrawer(),
                    ),
                  ),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 18, 20, 0),
                sliver: SliverToBoxAdapter(
                  child: _GreetingBlock(userName: userName),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                sliver: SliverToBoxAdapter(
                  child: _AnnouncementCard(
                    onPressed: () => context.go('/orders'),
                  ),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 26, 20, 0),
                sliver: SliverToBoxAdapter(
                  child: FutureBuilder<List<RecentlyViewedItem>>(
                    future: RecentlyViewedStore.load(_userKey()),
                    builder: (context, snapshot) {
                      final items =
                          snapshot.data ?? const <RecentlyViewedItem>[];
                      if (!snapshot.hasData || items.isEmpty) {
                        return const SizedBox.shrink();
                      }

                      return _SectionBlock(
                        title: 'Recently viewed',
                        child: SizedBox(
                          height: 92,
                          child: ListView.separated(
                            scrollDirection: Axis.horizontal,
                            itemCount: items.length,
                            separatorBuilder: (context, index) =>
                                const SizedBox(width: 14),
                            itemBuilder: (context, index) {
                              final item = items[index];
                              return _RecentlyViewedAvatar(
                                item: item,
                                onTap: () =>
                                    context.push('/home/product/${item.slug}'),
                              );
                            },
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
                sliver: SliverToBoxAdapter(
                  child: _SectionBlock(
                    title: 'My Orders',
                    child: Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      children: [
                        _OrderQuickAction(
                          label: 'To Pay',
                          onTap: () => context.go('/cart'),
                        ),
                        _OrderQuickAction(
                          label: 'To Receive',
                          onTap: () => context.go('/orders'),
                        ),
                        _OrderQuickAction(
                          label: 'To Review',
                          onTap: () => context.go('/orders'),
                          showDot: true,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
                sliver: SliverToBoxAdapter(
                  child: _SectionBlock(
                    title: 'Stories',
                    child: SizedBox(
                      height: 258,
                      child: storyProducts.isEmpty
                          ? ListView.separated(
                              scrollDirection: Axis.horizontal,
                              itemCount: 4,
                              separatorBuilder: (context, index) =>
                                  const SizedBox(width: 12),
                              itemBuilder: (context, index) {
                                return _PlaceholderStoryCard(index: index);
                              },
                            )
                          : ListView.separated(
                              scrollDirection: Axis.horizontal,
                              itemCount: storyProducts.length,
                              separatorBuilder: (context, index) =>
                                  const SizedBox(width: 12),
                              itemBuilder: (context, index) {
                                final product = storyProducts[index];
                                return _StoryCard(
                                  product: product,
                                  badgeText: index == 0 ? 'Live' : null,
                                  onTap: () => _openProduct(product),
                                );
                              },
                            ),
                    ),
                  ),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 26, 20, 0),
                sliver: SliverToBoxAdapter(
                  child: _SectionHeaderWithAction(
                    title: 'New Items',
                    onSeeAll: () => context.go('/home'),
                  ),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                sliver: SliverToBoxAdapter(
                  child: SizedBox(
                    height: 228,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: newItems.length,
                      separatorBuilder: (context, index) =>
                          const SizedBox(width: 10),
                      itemBuilder: (context, index) {
                        final product = newItems[index];
                        return _NewItemCard(
                          product: product,
                          onTap: () => _openProduct(product),
                        );
                      },
                    ),
                  ),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
                sliver: SliverToBoxAdapter(
                  child: _SectionHeaderWithAction(
                    title: 'Most Popular',
                    onSeeAll: () => context.go('/home'),
                  ),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                sliver: SliverToBoxAdapter(
                  child: SizedBox(
                    height: 172,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: mostPopular.take(8).length,
                      separatorBuilder: (context, index) =>
                          const SizedBox(width: 10),
                      itemBuilder: (context, index) {
                        final product = mostPopular[index];
                        return _PopularMiniCard(
                          product: product,
                          onTap: () => _openProduct(product),
                        );
                      },
                    ),
                  ),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
                sliver: SliverToBoxAdapter(
                  child: _SectionHeaderWithAction(
                    title: 'Categories',
                    onSeeAll: () => context.go('/home'),
                  ),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                sliver: SliverToBoxAdapter(
                  child: GridView.builder(
                    itemCount: categoryGroups.length,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          crossAxisSpacing: 10,
                          mainAxisSpacing: 10,
                          childAspectRatio: 0.95,
                        ),
                    itemBuilder: (context, index) {
                      final group = categoryGroups[index];
                      return _CategoryMosaicCard(
                        group: group,
                        onTap: () {
                          if (group.products.isNotEmpty) {
                            _openProduct(group.products.first);
                          }
                        },
                      );
                    },
                  ),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
                sliver: SliverToBoxAdapter(
                  child: _FlashSaleHeader(onSeeAll: () => context.go('/home')),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                sliver: SliverToBoxAdapter(
                  child: GridView.builder(
                    itemCount: flashSaleItems.length,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 3,
                          crossAxisSpacing: 8,
                          mainAxisSpacing: 8,
                          childAspectRatio: 0.78,
                        ),
                    itemBuilder: (context, index) {
                      final product = flashSaleItems[index];
                      return _FlashSaleCard(
                        product: product,
                        onTap: () => _openProduct(product),
                      );
                    },
                  ),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
                sliver: SliverToBoxAdapter(
                  child: _SectionBlock(
                    title: 'Top Products',
                    child: SizedBox(
                      height: 72,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: topProducts.length,
                        separatorBuilder: (context, index) =>
                            const SizedBox(width: 10),
                        itemBuilder: (context, index) {
                          final product = topProducts[index];
                          return _TopProductAvatar(
                            product: product,
                            onTap: () => _openProduct(product),
                          );
                        },
                      ),
                    ),
                  ),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
                sliver: SliverToBoxAdapter(
                  child: _SectionBlock(
                    title: 'Just For You ★',
                    child: GridView.builder(
                      itemCount: justForYou.length,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            crossAxisSpacing: 10,
                            mainAxisSpacing: 10,
                            childAspectRatio: 0.84,
                          ),
                      itemBuilder: (context, index) {
                        final product = justForYou[index];
                        return _JustForYouCard(
                          product: product,
                          onTap: () => _openProduct(product),
                        );
                      },
                    ),
                  ),
                ),
              ),
              const SliverPadding(
                padding: EdgeInsets.only(bottom: 28),
                sliver: SliverToBoxAdapter(child: SizedBox.shrink()),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HeaderAvatar extends StatelessWidget {
  const _HeaderAvatar({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final initials = label.trim().isEmpty
        ? 'R'
        : label
              .trim()
              .split(RegExp(r'\s+'))
              .where((part) => part.isNotEmpty)
              .take(2)
              .map((part) => part[0].toUpperCase())
              .join();

    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 54,
        width: 54,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: const Color(0xFFF1F4FA),
          border: Border.all(color: const Color(0xFFE3E8F1), width: 3),
        ),
        alignment: Alignment.center,
        child: Text(
          initials,
          style: const TextStyle(
            fontWeight: FontWeight.w800,
            fontSize: 18,
            color: Color(0xFF1A1A1A),
          ),
        ),
      ),
    );
  }
}

class _UserMenuDrawer extends StatelessWidget {
  const _UserMenuDrawer({
    required this.userName,
    required this.email,
    required this.onProfileTap,
    required this.onOrdersTap,
    required this.onWishlistTap,
    required this.onCartTap,
    required this.onLogoutTap,
  });

  final String userName;
  final String email;
  final VoidCallback onProfileTap;
  final VoidCallback onOrdersTap;
  final VoidCallback onWishlistTap;
  final VoidCallback onCartTap;
  final Future<void> Function() onLogoutTap;

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          children: [
            Row(
              children: [
                const CircleAvatar(
                  radius: 22,
                  backgroundColor: Color(0xFFF1F4FA),
                  child: Icon(Icons.person_rounded, color: Color(0xFF0B4DFF)),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        userName,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        email,
                        style: const TextStyle(color: Color(0xFF667085)),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            const Text(
              'Menu',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 12),
            _DrawerTile(
              icon: Icons.person_outline,
              label: 'Profile',
              onTap: () {
                Navigator.of(context).pop();
                onProfileTap();
              },
            ),
            _DrawerTile(
              icon: Icons.receipt_long_outlined,
              label: 'Orders',
              onTap: () {
                Navigator.of(context).pop();
                onOrdersTap();
              },
            ),
            _DrawerTile(
              icon: Icons.favorite_border_rounded,
              label: 'Wishlist',
              onTap: () {
                Navigator.of(context).pop();
                onWishlistTap();
              },
            ),
            _DrawerTile(
              icon: Icons.shopping_bag_outlined,
              label: 'Cart',
              onTap: () {
                Navigator.of(context).pop();
                onCartTap();
              },
            ),
            const SizedBox(height: 8),
            const Divider(),
            _DrawerTile(
              icon: Icons.logout,
              label: 'Logout',
              onTap: () async {
                Navigator.of(context).pop();
                await onLogoutTap();
              },
              danger: true,
            ),
          ],
        ),
      ),
    );
  }
}

class _DrawerTile extends StatelessWidget {
  const _DrawerTile({
    required this.icon,
    required this.label,
    required this.onTap,
    this.danger = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool danger;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(icon, color: danger ? const Color(0xFFD92D20) : null),
      title: Text(
        label,
        style: TextStyle(
          color: danger ? const Color(0xFFD92D20) : null,
          fontWeight: FontWeight.w600,
        ),
      ),
      trailing: const Icon(Icons.chevron_right_rounded),
      onTap: onTap,
    );
  }
}

class _GreetingBlock extends StatelessWidget {
  const _GreetingBlock({required this.userName});

  final String userName;

  @override
  Widget build(BuildContext context) {
    final headlineSize = adaptiveFontSize(context, base: 26, min: 20, max: 32);
    return Text(
      'Hello, $userName!',
      style: Theme.of(context).textTheme.headlineMedium?.copyWith(
        fontSize: headlineSize,
        height: 1.05,
        fontWeight: FontWeight.w700,
        color: const Color(0xFF1D1D1D),
        letterSpacing: -0.8,
      ),
    );
  }
}

class _SectionBlock extends StatelessWidget {
  const _SectionBlock({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final sectionTitle = adaptiveFontSize(context, base: 18, min: 16, max: 22);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontSize: sectionTitle,
            fontWeight: FontWeight.w800,
            color: const Color(0xFF1F1F1F),
          ),
        ),
        const SizedBox(height: 12),
        child,
      ],
    );
  }
}

class _SectionHeaderWithAction extends StatelessWidget {
  const _SectionHeaderWithAction({required this.title, required this.onSeeAll});

  final String title;
  final VoidCallback onSeeAll;

  @override
  Widget build(BuildContext context) {
    final titleSize = adaptiveFontSize(context, base: 20, min: 17, max: 24);

    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: TextStyle(
              fontSize: titleSize,
              fontWeight: FontWeight.w800,
              color: const Color(0xFF1F1F1F),
            ),
          ),
        ),
        TextButton(
          onPressed: onSeeAll,
          style: TextButton.styleFrom(
            foregroundColor: const Color(0xFF1F2937),
            padding: const EdgeInsets.symmetric(horizontal: 8),
          ),
          child: Row(
            children: [
              const Text(
                'See All',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
              const SizedBox(width: 8),
              Container(
                height: 34,
                width: 34,
                decoration: const BoxDecoration(
                  color: Color(0xFF0B4DFF),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.arrow_forward_rounded,
                  color: Colors.white,
                  size: 20,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _NewItemCard extends StatelessWidget {
  const _NewItemCard({required this.product, required this.onTap});

  final ProductModel product;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final imageUrl = product.images.isNotEmpty ? product.images.first : null;

    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: 150,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: imageUrl == null
                    ? const ColoredBox(
                        color: Color(0xFFECEFF5),
                        child: Icon(Icons.image_outlined),
                      )
                    : CachedNetworkImage(
                        imageUrl: imageUrl,
                        fit: BoxFit.cover,
                        placeholder: (context, url) =>
                            const ColoredBox(color: Color(0xFFECEFF5)),
                        errorWidget: (context, url, error) => const ColoredBox(
                          color: Color(0xFFECEFF5),
                          child: Icon(Icons.broken_image_outlined),
                        ),
                      ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              product.title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 15,
                height: 1.25,
                color: Color(0xFF2E323E),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              '\$${product.displayPrice.toStringAsFixed(2).replaceAll('.', ',')}',
              style: const TextStyle(
                fontSize: 34,
                fontWeight: FontWeight.w900,
                letterSpacing: -1,
                color: Color(0xFF1B1D21),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PopularMiniCard extends StatelessWidget {
  const _PopularMiniCard({required this.product, required this.onTap});

  final ProductModel product;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final imageUrl = product.images.isNotEmpty ? product.images.first : null;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 116,
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: const [
            BoxShadow(
              color: Color(0x11000000),
              blurRadius: 10,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: imageUrl == null
                    ? const ColoredBox(
                        color: Color(0xFFECEFF5),
                        child: Icon(Icons.image_outlined),
                      )
                    : CachedNetworkImage(
                        imageUrl: imageUrl,
                        fit: BoxFit.cover,
                        placeholder: (context, url) =>
                            const ColoredBox(color: Color(0xFFECEFF5)),
                        errorWidget: (context, url, error) => const ColoredBox(
                          color: Color(0xFFECEFF5),
                          child: Icon(Icons.broken_image_outlined),
                        ),
                      ),
              ),
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                Text(
                  product.ratingCount.toString(),
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(width: 4),
                const Icon(Icons.favorite, size: 14, color: Color(0xFF0B4DFF)),
                const Spacer(),
                Text(
                  product.category?.name ?? 'New',
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF343844),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _CategoryMosaicCard extends StatelessWidget {
  const _CategoryMosaicCard({required this.group, required this.onTap});

  final _CategoryGroup group;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: const [
            BoxShadow(
              color: Color(0x11000000),
              blurRadius: 10,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            Expanded(
              child: GridView.builder(
                itemCount: 4,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 4,
                  mainAxisSpacing: 4,
                ),
                itemBuilder: (context, index) {
                  final hasItem = index < group.products.length;
                  if (!hasItem) {
                    return const ColoredBox(color: Color(0xFFF0F2F7));
                  }
                  final product = group.products[index];
                  final imageUrl = product.images.isNotEmpty
                      ? product.images.first
                      : null;
                  return ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: imageUrl == null
                        ? const ColoredBox(
                            color: Color(0xFFECEFF5),
                            child: Icon(Icons.image_outlined, size: 16),
                          )
                        : CachedNetworkImage(
                            imageUrl: imageUrl,
                            fit: BoxFit.cover,
                            placeholder: (context, url) =>
                                const ColoredBox(color: Color(0xFFECEFF5)),
                            errorWidget: (context, url, error) =>
                                const ColoredBox(
                                  color: Color(0xFFECEFF5),
                                  child: Icon(
                                    Icons.broken_image_outlined,
                                    size: 16,
                                  ),
                                ),
                          ),
                  );
                },
              ),
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                Expanded(
                  child: Text(
                    group.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF0F1F3),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '${group.count}',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF333640),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _FlashSaleHeader extends StatelessWidget {
  const _FlashSaleHeader({required this.onSeeAll});

  final VoidCallback onSeeAll;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Expanded(
          child: Text(
            'Flash Sale',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
          ),
        ),
        const Icon(Icons.alarm_rounded, color: Color(0xFF0B4DFF), size: 22),
        const SizedBox(width: 8),
        _TimeChip(label: '00'),
        const SizedBox(width: 4),
        _TimeChip(label: '36'),
        const SizedBox(width: 4),
        _TimeChip(label: '58'),
      ],
    );
  }
}

class _TimeChip extends StatelessWidget {
  const _TimeChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: const Color(0xFFF4E9EC),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(label, style: const TextStyle(fontWeight: FontWeight.w700)),
    );
  }
}

class _FlashSaleCard extends StatelessWidget {
  const _FlashSaleCard({required this.product, required this.onTap});

  final ProductModel product;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final imageUrl = product.images.isNotEmpty ? product.images.first : null;

    return GestureDetector(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: Stack(
          fit: StackFit.expand,
          children: [
            imageUrl == null
                ? const ColoredBox(
                    color: Color(0xFFECEFF5),
                    child: Icon(Icons.image_outlined),
                  )
                : CachedNetworkImage(
                    imageUrl: imageUrl,
                    fit: BoxFit.cover,
                    placeholder: (context, url) =>
                        const ColoredBox(color: Color(0xFFECEFF5)),
                    errorWidget: (context, url, error) => const ColoredBox(
                      color: Color(0xFFECEFF5),
                      child: Icon(Icons.broken_image_outlined),
                    ),
                  ),
            Positioned(
              right: 4,
              top: 4,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFFFF2C77),
                  borderRadius: BorderRadius.circular(7),
                ),
                child: const Text(
                  '-20%',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
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

class _TopProductAvatar extends StatelessWidget {
  const _TopProductAvatar({required this.product, required this.onTap});

  final ProductModel product;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final imageUrl = product.images.isNotEmpty ? product.images.first : null;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 62,
        width: 62,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white, width: 3),
          boxShadow: const [
            BoxShadow(
              color: Color(0x19000000),
              blurRadius: 8,
              offset: Offset(0, 3),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: imageUrl == null
            ? const ColoredBox(
                color: Color(0xFFECEFF5),
                child: Icon(Icons.image_outlined),
              )
            : CachedNetworkImage(
                imageUrl: imageUrl,
                fit: BoxFit.cover,
                placeholder: (context, url) =>
                    const ColoredBox(color: Color(0xFFECEFF5)),
                errorWidget: (context, url, error) => const ColoredBox(
                  color: Color(0xFFECEFF5),
                  child: Icon(Icons.broken_image_outlined),
                ),
              ),
      ),
    );
  }
}

class _JustForYouCard extends StatelessWidget {
  const _JustForYouCard({required this.product, required this.onTap});

  final ProductModel product;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final imageUrl = product.images.isNotEmpty ? product.images.first : null;
    return GestureDetector(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: imageUrl == null
            ? const ColoredBox(
                color: Color(0xFFECEFF5),
                child: Icon(Icons.image_outlined),
              )
            : CachedNetworkImage(
                imageUrl: imageUrl,
                fit: BoxFit.cover,
                placeholder: (context, url) =>
                    const ColoredBox(color: Color(0xFFECEFF5)),
                errorWidget: (context, url, error) => const ColoredBox(
                  color: Color(0xFFECEFF5),
                  child: Icon(Icons.broken_image_outlined),
                ),
              ),
      ),
    );
  }
}

class _CategoryGroup {
  const _CategoryGroup({
    required this.name,
    required this.products,
    required this.count,
  });

  final String name;
  final List<ProductModel> products;
  final int count;
}

List<_CategoryGroup> _buildCategoryGroups(List<ProductModel> products) {
  final buckets = <String, List<ProductModel>>{};
  for (final product in products) {
    final key = (product.category?.name.trim().isNotEmpty ?? false)
        ? product.category!.name.trim()
        : 'Other';
    buckets.putIfAbsent(key, () => <ProductModel>[]).add(product);
  }

  final groups = buckets.entries
      .map(
        (entry) => _CategoryGroup(
          name: entry.key,
          products: entry.value.take(4).toList(),
          count: entry.value.length,
        ),
      )
      .toList();

  groups.sort((a, b) => b.count.compareTo(a.count));
  return groups;
}

class _AnnouncementCard extends StatelessWidget {
  const _AnnouncementCard({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final titleSize = adaptiveFontSize(context, base: 20, min: 17, max: 24);
    final bodySize = adaptiveFontSize(context, base: 16, min: 13, max: 18);

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFF0F3FA), Color(0xFFE9EEF9)],
        ),
        border: Border.all(color: const Color(0xFFDDE4F2)),
        borderRadius: BorderRadius.circular(18),
        boxShadow: const [
          BoxShadow(
            color: Color(0x12000000),
            blurRadius: 14,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Announcement',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontSize: titleSize,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF1D1D1D),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'New arrivals are live now. Check your orders and wishlist for fresh picks curated for you.',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontSize: bodySize,
                    height: 1.35,
                    color: const Color(0xFF4C5566),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          GestureDetector(
            onTap: onPressed,
            child: Container(
              height: 48,
              width: 48,
              decoration: const BoxDecoration(
                color: Color(0xFF0B4DFF),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.arrow_forward_rounded,
                color: Colors.white,
                size: 28,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RecentlyViewedAvatar extends StatelessWidget {
  const _RecentlyViewedAvatar({required this.item, required this.onTap});

  final RecentlyViewedItem item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 68,
        alignment: Alignment.center,
        child: Container(
          height: 62,
          width: 62,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white,
            border: Border.all(color: const Color(0xFFE8EDF6), width: 3),
            boxShadow: const [
              BoxShadow(
                color: Color(0x11000000),
                blurRadius: 10,
                offset: Offset(0, 5),
              ),
            ],
          ),
          clipBehavior: Clip.antiAlias,
          child: item.imageUrl.isEmpty
              ? const ColoredBox(
                  color: Color(0xFFF2F4FA),
                  child: Icon(Icons.image_outlined, color: Color(0xFF7B8597)),
                )
              : CachedNetworkImage(
                  imageUrl: item.imageUrl,
                  fit: BoxFit.cover,
                  placeholder: (context, url) =>
                      const ColoredBox(color: Color(0xFFF2F4FA)),
                  errorWidget: (context, url, error) => const ColoredBox(
                    color: Color(0xFFF2F4FA),
                    child: Icon(
                      Icons.broken_image_outlined,
                      color: Color(0xFF7B8597),
                    ),
                  ),
                ),
        ),
      ),
    );
  }
}

class _OrderQuickAction extends StatelessWidget {
  const _OrderQuickAction({
    required this.label,
    required this.onTap,
    this.showDot = false,
  });

  final String label;
  final VoidCallback onTap;
  final bool showDot;

  @override
  Widget build(BuildContext context) {
    final chipText = adaptiveFontSize(context, base: 16, min: 14, max: 19);
    return GestureDetector(
      onTap: onTap,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
            decoration: BoxDecoration(
              color: const Color(0xFFEAF1FF),
              borderRadius: BorderRadius.circular(999),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x100B4DFF),
                  blurRadius: 8,
                  offset: Offset(0, 3),
                ),
              ],
            ),
            child: Text(
              label,
              style: TextStyle(
                fontSize: chipText,
                fontWeight: FontWeight.w500,
                color: const Color(0xFF0B4DFF),
              ),
            ),
          ),
          if (showDot)
            Positioned(
              right: 16,
              top: -4,
              child: Container(
                height: 10,
                width: 10,
                decoration: const BoxDecoration(
                  color: Color(0xFF2BCB5F),
                  shape: BoxShape.circle,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _StoryCard extends StatelessWidget {
  const _StoryCard({
    required this.product,
    required this.onTap,
    this.badgeText,
  });

  final ProductModel product;
  final VoidCallback onTap;
  final String? badgeText;

  @override
  Widget build(BuildContext context) {
    final imageUrl = product.images.isNotEmpty ? product.images.first : null;
    final storyTitleSize = adaptiveFontSize(
      context,
      base: 14,
      min: 12,
      max: 16,
    );

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 138,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          boxShadow: const [
            BoxShadow(
              color: Color(0x15000000),
              blurRadius: 16,
              offset: Offset(0, 8),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (imageUrl == null)
              Container(color: const Color(0xFFF4A6B6))
            else
              CachedNetworkImage(
                imageUrl: imageUrl,
                fit: BoxFit.cover,
                placeholder: (context, url) =>
                    Container(color: const Color(0xFFF4A6B6)),
                errorWidget: (context, url, error) => Container(
                  color: const Color(0xFFF4A6B6),
                  alignment: Alignment.center,
                  child: const Icon(
                    Icons.image_not_supported_outlined,
                    color: Colors.white,
                  ),
                ),
              ),
            Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [Color(0xB3000000), Colors.transparent],
                ),
              ),
            ),
            if (badgeText != null)
              Positioned(
                left: 10,
                top: 10,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFF11C37A),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    badgeText!,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 11,
                    ),
                  ),
                ),
              ),
            Center(
              child: Container(
                height: 40,
                width: 40,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.34),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.play_arrow_rounded,
                  color: Colors.white,
                  size: 24,
                ),
              ),
            ),
            Positioned(
              left: 12,
              right: 12,
              bottom: 12,
              child: Text(
                product.title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: storyTitleSize,
                  fontWeight: FontWeight.w700,
                  height: 1.05,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PlaceholderStoryCard extends StatelessWidget {
  const _PlaceholderStoryCard({required this.index});

  final int index;

  @override
  Widget build(BuildContext context) {
    final storyTitleSize = adaptiveFontSize(
      context,
      base: 14,
      min: 12,
      max: 16,
    );
    final colors = <Color>[
      const Color(0xFF1E88E5),
      const Color(0xFFF48FB1),
      const Color(0xFF4FC3F7),
      const Color(0xFFFFB300),
    ];

    return Container(
      width: 138,
      decoration: BoxDecoration(
        color: colors[index % colors.length],
        borderRadius: BorderRadius.circular(20),
      ),
      child: Stack(
        children: [
          const Center(
            child: Icon(
              Icons.play_circle_fill_rounded,
              color: Colors.white70,
              size: 46,
            ),
          ),
          Positioned(
            left: 12,
            bottom: 12,
            child: Text(
              'Story ${index + 1}',
              style: TextStyle(
                color: Colors.white,
                fontSize: storyTitleSize,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
