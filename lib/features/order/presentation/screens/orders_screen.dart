import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/utils/responsive_text.dart';
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

  String _statusLabel(String backendStatus) {
    switch (backendStatus.toLowerCase()) {
      case 'delivered':
        return 'Delivered';
      case 'shipped':
        return 'Shipped';
      case 'processing':
      case 'placed':
      default:
        return 'Packed';
    }
  }

  bool _isDelivered(String backendStatus) {
    return backendStatus.toLowerCase() == 'delivered';
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

    return Scaffold(
      backgroundColor: const Color(0xFFF6F7FA),
      body: SafeArea(
        child: Builder(
          builder: (context) {
            if (state.isInitialLoading && state.orders.isEmpty) {
              return ListView.separated(
                padding: const EdgeInsets.fromLTRB(18, 12, 18, 16),
                itemBuilder: (context, index) =>
                    const LoadingSkeleton(height: 112),
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
              child: ListView.builder(
                controller: _scrollController,
                cacheExtent: 900,
                padding: const EdgeInsets.fromLTRB(18, 12, 18, 20),
                itemCount:
                    state.orders.length + 1 + (state.isLoadingMore ? 1 : 0),
                itemBuilder: (context, index) {
                  if (index == 0) {
                    return const Padding(
                      padding: EdgeInsets.only(bottom: 16),
                      child: _OrdersHeader(),
                    );
                  }

                  final dataIndex = index - 1;
                  if (dataIndex >= state.orders.length) {
                    return const Center(
                      child: Padding(
                        padding: EdgeInsets.all(12),
                        child: CircularProgressIndicator(),
                      ),
                    );
                  }

                  final order = state.orders[dataIndex];
                  final statusLabel = _statusLabel(order.orderStatus);
                  final isDelivered = _isDelivered(order.orderStatus);

                  return Hero(
                    tag: 'order-${order.id}',
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 14),
                      child: _OrderRowCard(
                        orderId: _shortOrderId(order.id),
                        itemCount: order.items.length,
                        statusLabel: statusLabel,
                        delivered: isDelivered,
                        imageUrls: order.items
                            .map((item) => item.image ?? '')
                            .where((url) => url.isNotEmpty)
                            .take(4)
                            .toList(),
                        onTap: () =>
                            context.push('/orders/details/${order.id}'),
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

class _OrdersHeader extends StatelessWidget {
  const _OrdersHeader();

  @override
  Widget build(BuildContext context) {
    final titleSize = adaptiveFontSize(context, base: 26, min: 22, max: 34);
    final subtitleSize = adaptiveFontSize(context, base: 14, min: 12, max: 16);

    return Row(
      children: [
        Container(
          height: 50,
          width: 50,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            image: const DecorationImage(
              image: NetworkImage(
                'https://images.unsplash.com/photo-1524504388940-b1c1722653e1?auto=format&fit=crop&w=200&q=80',
              ),
              fit: BoxFit.cover,
            ),
            boxShadow: const [
              BoxShadow(
                color: Color(0x14000000),
                blurRadius: 10,
                offset: Offset(0, 4),
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'To Receive',
                style: TextStyle(
                  fontSize: titleSize,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.8,
                  color: const Color(0xFF1D1F24),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                'My Orders',
                style: TextStyle(
                  fontSize: subtitleSize,
                  color: Color(0xFF4A4E59),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        const _TopIcon(icon: Icons.inventory_2_outlined),
        const SizedBox(width: 8),
        const _TopIcon(icon: Icons.tune_rounded, dot: true),
        const SizedBox(width: 8),
        const _TopIcon(icon: Icons.settings_outlined),
      ],
    );
  }
}

class _TopIcon extends StatelessWidget {
  const _TopIcon({required this.icon, this.dot = false});

  final IconData icon;
  final bool dot;

  @override
  Widget build(BuildContext context) {
    final boxSize = adaptiveFontSize(context, base: 38, min: 34, max: 42);
    final iconSize = adaptiveFontSize(context, base: 19, min: 16, max: 22);

    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          height: boxSize,
          width: boxSize,
          decoration: const BoxDecoration(
            color: Color(0xFFE3E8F7),
            shape: BoxShape.circle,
          ),
          alignment: Alignment.center,
          child: Icon(icon, color: const Color(0xFF0B4DFF), size: iconSize),
        ),
        if (dot)
          Positioned(
            right: 0,
            top: -2,
            child: Container(
              height: 9,
              width: 9,
              decoration: const BoxDecoration(
                color: Color(0xFF0B4DFF),
                shape: BoxShape.circle,
              ),
            ),
          ),
      ],
    );
  }
}

class _OrderRowCard extends StatelessWidget {
  const _OrderRowCard({
    required this.orderId,
    required this.itemCount,
    required this.statusLabel,
    required this.delivered,
    required this.imageUrls,
    required this.onTap,
  });

  final String orderId;
  final int itemCount;
  final String statusLabel;
  final bool delivered;
  final List<String> imageUrls;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final statusSize = adaptiveFontSize(context, base: 18, min: 16, max: 22);
    final orderIdSize = adaptiveFontSize(context, base: 18, min: 15, max: 20);
    final metaSize = adaptiveFontSize(context, base: 14, min: 12, max: 16);
    final badgeSize = adaptiveFontSize(context, base: 14, min: 12, max: 15);
    final actionSize = adaptiveFontSize(context, base: 16, min: 14, max: 18);

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(10, 10, 10, 10),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _OrderImageCollage(imageUrls: imageUrls),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Order #$orderId',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontWeight: FontWeight.w800,
                                  fontSize: orderIdSize,
                                  color: const Color(0xFF1E2025),
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Standard Delivery',
                                style: TextStyle(
                                  fontSize: metaSize,
                                  color: Color(0xFF3D4048),
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF1F2F4),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            itemCount == 1 ? '1 item' : '$itemCount items',
                            style: TextStyle(
                              fontSize: badgeSize,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF2A2D35),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: Row(
                            children: [
                              Flexible(
                                child: Text(
                                  statusLabel,
                                  style: TextStyle(
                                    fontSize: statusSize,
                                    fontWeight: FontWeight.w800,
                                    color: const Color(0xFF1B1D21),
                                  ),
                                ),
                              ),
                              if (delivered) ...[
                                const SizedBox(width: 6),
                                const Icon(
                                  Icons.check_circle_rounded,
                                  color: Color(0xFF0B4DFF),
                                  size: 22,
                                ),
                              ],
                            ],
                          ),
                        ),
                        const SizedBox(width: 10),
                        SizedBox(
                          width: 94,
                          height: 40,
                          child: delivered
                              ? OutlinedButton(
                                  onPressed: onTap,
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: const Color(0xFF0B4DFF),
                                    side: const BorderSide(
                                      color: Color(0xFF0B4DFF),
                                      width: 2,
                                    ),
                                    padding: EdgeInsets.zero,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                  child: Text(
                                    'Review',
                                    style: TextStyle(
                                      fontSize: actionSize,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                )
                              : FilledButton(
                                  onPressed: onTap,
                                  style: FilledButton.styleFrom(
                                    backgroundColor: const Color(0xFF0B4DFF),
                                    foregroundColor: Colors.white,
                                    padding: EdgeInsets.zero,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                  child: Text(
                                    'Track',
                                    style: TextStyle(
                                      fontSize: actionSize,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _OrderImageCollage extends StatelessWidget {
  const _OrderImageCollage({required this.imageUrls});

  final List<String> imageUrls;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 94,
      width: 94,
      decoration: BoxDecoration(
        color: const Color(0xFFF0F2F7),
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [
          BoxShadow(
            color: Color(0x12000000),
            blurRadius: 8,
            offset: Offset(0, 4),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: GridView.builder(
        itemCount: 4,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 2,
          mainAxisSpacing: 2,
        ),
        itemBuilder: (context, index) {
          final hasImage = index < imageUrls.length;
          if (!hasImage) {
            return const ColoredBox(
              color: Color(0xFFE4E8F2),
              child: Icon(
                Icons.image_outlined,
                size: 16,
                color: Color(0xFF8A92A6),
              ),
            );
          }

          return CachedNetworkImage(
            imageUrl: imageUrls[index],
            fit: BoxFit.cover,
            placeholder: (context, url) =>
                const ColoredBox(color: Color(0xFFE4E8F2)),
            errorWidget: (context, url, error) => const ColoredBox(
              color: Color(0xFFE4E8F2),
              child: Icon(
                Icons.broken_image_outlined,
                size: 16,
                color: Color(0xFF8A92A6),
              ),
            ),
          );
        },
      ),
    );
  }
}
