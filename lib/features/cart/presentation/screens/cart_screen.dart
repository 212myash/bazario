import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../shared/widgets/app_button.dart';
import '../../../../shared/widgets/empty_state_view.dart';
import '../../../../shared/widgets/error_state_view.dart';
import '../../../../shared/widgets/loading_skeleton.dart';
import '../providers/cart_provider.dart';

class CartScreen extends ConsumerStatefulWidget {
  const CartScreen({super.key});

  @override
  ConsumerState<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends ConsumerState<CartScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() => ref.read(cartProvider.notifier).fetchCart());
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(cartProvider);
    final currency = NumberFormat.currency(symbol: '₹');

    return Scaffold(
      appBar: AppBar(title: const Text('My Cart')),
      body: Builder(
        builder: (context) {
          if (state.isLoading && state.cart == null) {
            return ListView.separated(
              padding: const EdgeInsets.all(16),
              itemBuilder: (context, index) =>
                  const LoadingSkeleton(height: 96),
              separatorBuilder: (context, index) => const SizedBox(height: 10),
              itemCount: 5,
            );
          }

          if (state.errorMessage != null && state.cart == null) {
            return ErrorStateView(
              message: state.errorMessage!,
              onRetry: () => ref.read(cartProvider.notifier).fetchCart(),
            );
          }

          final items = state.cart?.items ?? [];
          if (items.isEmpty) {
            return const EmptyStateView(
              icon: Icons.shopping_cart_outlined,
              title: 'Your cart is empty',
              subtitle: 'Browse products and add your favorites to cart.',
            );
          }

          return Column(
            children: [
              Expanded(
                child: ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemBuilder: (_, index) {
                    final item = items[index];
                    final productId = item.product?.id ?? '';

                    return Card(
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    item.product?.title ?? 'Unknown Product',
                                  ),
                                  const SizedBox(height: 6),
                                  Text(currency.format(item.priceSnapshot)),
                                ],
                              ),
                            ),
                            IconButton(
                              onPressed: item.quantity > 1
                                  ? () => ref
                                        .read(cartProvider.notifier)
                                        .updateItem(
                                          productId,
                                          item.quantity - 1,
                                        )
                                  : null,
                              icon: const Icon(Icons.remove_circle_outline),
                            ),
                            Text('${item.quantity}'),
                            IconButton(
                              onPressed: () => ref
                                  .read(cartProvider.notifier)
                                  .updateItem(productId, item.quantity + 1),
                              icon: const Icon(Icons.add_circle_outline),
                            ),
                            IconButton(
                              onPressed: () => ref
                                  .read(cartProvider.notifier)
                                  .removeItem(productId),
                              icon: const Icon(Icons.delete_outline),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                  separatorBuilder: (context, index) =>
                      const SizedBox(height: 10),
                  itemCount: items.length,
                ),
              ),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  border: Border(
                    top: BorderSide(color: Theme.of(context).dividerColor),
                  ),
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        const Text('Total'),
                        const Spacer(),
                        Text(
                          currency.format(state.cart?.total ?? 0),
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.w700),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    AppButton(
                      label: 'Proceed to Checkout',
                      onPressed: () => context.push('/checkout'),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
