import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../shared/widgets/empty_state_view.dart';
import '../../../../shared/widgets/error_state_view.dart';
import '../../../../shared/widgets/loading_skeleton.dart';
import '../providers/order_provider.dart';

class OrdersScreen extends ConsumerStatefulWidget {
  const OrdersScreen({super.key});

  @override
  ConsumerState<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends ConsumerState<OrdersScreen> {
  late final ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController()..addListener(_onScroll);
    Future.microtask(
      () => ref.read(orderProvider.notifier).fetchOrders(refresh: true),
    );
  }

  void _onScroll() {
    if (!_scrollController.hasClients) {
      return;
    }

    final threshold = _scrollController.position.maxScrollExtent - 220;
    if (_scrollController.position.pixels >= threshold) {
      ref.read(orderProvider.notifier).loadMore();
    }
  }

  String _shortOrderId(String orderId) {
    final length = orderId.length < 8 ? orderId.length : 8;
    return orderId.substring(0, length).toUpperCase();
  }

  @override
  void dispose() {
    _scrollController
      ..removeListener(_onScroll)
      ..dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(orderProvider);
    final currency = NumberFormat.currency(symbol: '₹');

    return Scaffold(
      appBar: AppBar(title: const Text('My Orders')),
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 250),
        child: Builder(
          key: ValueKey(
            '${state.isInitialLoading}_${state.orders.length}_${state.errorMessage}',
          ),
          builder: (context) {
            if (state.isInitialLoading && state.orders.isEmpty) {
              return ListView.separated(
                padding: const EdgeInsets.all(16),
                itemBuilder: (context, index) =>
                    const LoadingSkeleton(height: 120),
                separatorBuilder: (context, index) =>
                    const SizedBox(height: 10),
                itemCount: 6,
              );
            }

            if (state.errorMessage != null && state.orders.isEmpty) {
              return ErrorStateView(
                message: state.errorMessage!,
                onRetry: () =>
                    ref.read(orderProvider.notifier).fetchOrders(refresh: true),
              );
            }

            if (state.orders.isEmpty) {
              return const EmptyStateView(
                icon: Icons.receipt_long_outlined,
                title: 'No Orders Yet',
                subtitle: 'Once you place an order, it will show up here.',
              );
            }

            return RefreshIndicator(
              onRefresh: () =>
                  ref.read(orderProvider.notifier).fetchOrders(refresh: true),
              child: ListView.separated(
                controller: _scrollController,
                padding: const EdgeInsets.all(16),
                itemCount: state.orders.length + (state.isLoadingMore ? 1 : 0),
                separatorBuilder: (context, index) =>
                    const SizedBox(height: 10),
                itemBuilder: (context, index) {
                  if (index >= state.orders.length) {
                    return const Center(
                      child: Padding(
                        padding: EdgeInsets.all(12),
                        child: CircularProgressIndicator(),
                      ),
                    );
                  }

                  final order = state.orders[index];
                  final status = order.orderStatus.toLowerCase();

                  final statusColor = switch (status) {
                    'delivered' => Colors.green,
                    'shipped' => Colors.blue,
                    'processing' => Colors.orange,
                    'cancelled' => Theme.of(context).colorScheme.error,
                    _ => Colors.amber.shade700,
                  };

                  return Hero(
                    tag: 'order-${order.id}',
                    child: Card(
                      child: InkWell(
                        borderRadius: BorderRadius.circular(18),
                        onTap: () =>
                            context.push('/orders/details/${order.id}'),
                        child: Padding(
                          padding: const EdgeInsets.all(14),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      'Order #${_shortOrderId(order.id)}',
                                      style: Theme.of(context)
                                          .textTheme
                                          .titleMedium
                                          ?.copyWith(
                                            fontWeight: FontWeight.w700,
                                          ),
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 5,
                                    ),
                                    decoration: BoxDecoration(
                                      color: statusColor.withValues(
                                        alpha: 0.12,
                                      ),
                                      borderRadius: BorderRadius.circular(999),
                                    ),
                                    child: Text(
                                      order.orderStatus.toUpperCase(),
                                      style: TextStyle(
                                        color: statusColor,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text(
                                '${order.items.length} items • ${currency.format(order.totalAmount)}',
                              ),
                              if (order.createdAt != null) ...[
                                const SizedBox(height: 4),
                                Text(
                                  DateFormat(
                                    'dd MMM yyyy, hh:mm a',
                                  ).format(order.createdAt!),
                                  style: Theme.of(context).textTheme.bodySmall,
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            );
          },
        ),
      ),
    );
  }
}
