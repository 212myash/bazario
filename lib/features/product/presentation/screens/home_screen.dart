import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../shared/widgets/error_state_view.dart';
import '../../../../shared/widgets/loading_skeleton.dart';
import '../../../../shared/widgets/product_card.dart';
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

    return Scaffold(
      appBar: AppBar(
        title: const Text('Bazario'),
        actions: [
          IconButton(
            onPressed: () => context.go('/cart'),
            icon: const Icon(Icons.shopping_cart_outlined),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
            child: TextField(
              controller: _searchController,
              decoration: const InputDecoration(
                hintText: 'Search products...',
                prefixIcon: Icon(Icons.search),
              ),
              onChanged: (value) {
                _debounce?.cancel();
                _debounce = Timer(const Duration(milliseconds: 450), () {
                  ref.read(productProvider.notifier).updateSearch(value.trim());
                });
              },
            ),
          ),
          if (state.categories.isNotEmpty)
            SizedBox(
              height: 44,
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                scrollDirection: Axis.horizontal,
                itemBuilder: (_, index) {
                  if (index == 0) {
                    final selected = state.selectedCategory.isEmpty;
                    return ChoiceChip(
                      label: const Text('All'),
                      selected: selected,
                      onSelected: (_) {
                        ref.read(productProvider.notifier).updateCategory('');
                      },
                    );
                  }

                  final category = state.categories[index - 1];
                  final selected = state.selectedCategory == category.id;
                  return ChoiceChip(
                    label: Text(category.name),
                    selected: selected,
                    onSelected: (_) {
                      ref
                          .read(productProvider.notifier)
                          .updateCategory(category.id);
                    },
                  );
                },
                separatorBuilder: (context, index) => const SizedBox(width: 8),
                itemCount: state.categories.length + 1,
              ),
            ),
          const SizedBox(height: 12),
          Expanded(
            child: Builder(
              builder: (context) {
                if (state.isLoading && state.products.isEmpty) {
                  return GridView.builder(
                    padding: const EdgeInsets.all(16),
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
                  );
                }

                if (state.errorMessage != null) {
                  return ErrorStateView(
                    message: state.errorMessage!,
                    onRetry: () =>
                        ref.read(productProvider.notifier).fetchProducts(),
                  );
                }

                if (state.products.isEmpty) {
                  return const Center(child: Text('No products found'));
                }

                return RefreshIndicator(
                  onRefresh: () => ref
                      .read(productProvider.notifier)
                      .fetchProducts(refresh: true),
                  child: GridView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(16),
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
                          ref.read(cartProvider.notifier).addItem(product.id);
                        },
                      );
                    },
                    itemCount:
                        state.products.length + (state.isLoadingMore ? 2 : 0),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
