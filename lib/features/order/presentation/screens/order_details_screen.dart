import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../shared/models/order_model.dart';
import '../../../../shared/widgets/error_state_view.dart';
import '../providers/order_provider.dart';

class OrderDetailsScreen extends ConsumerWidget {
  const OrderDetailsScreen({super.key, required this.orderId});

  final String orderId;

  Color _statusColor(BuildContext context, String status) {
    switch (status.toLowerCase()) {
      case 'delivered':
        return Colors.green;
      case 'shipped':
        return Colors.blue;
      case 'processing':
        return Colors.orange;
      case 'cancelled':
        return Theme.of(context).colorScheme.error;
      default:
        return Colors.amber.shade700;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final orderAsync = ref.watch(orderDetailsProvider(orderId));
    final currency = NumberFormat.currency(symbol: '₹');

    return Scaffold(
      appBar: AppBar(title: const Text('Order Details')),
      body: orderAsync.when(
        data: (order) => ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _OrderSummaryCard(
              order: order,
              currency: currency,
              statusColor: _statusColor(context, order.orderStatus),
            ),
            const SizedBox(height: 12),
            ...order.items.map(
              (item) => Card(
                child: ListTile(
                  title: Text(item.title),
                  subtitle: Text(
                    'Qty: ${item.quantity}  |  ${currency.format(item.unitPrice)}',
                  ),
                  trailing: Text(currency.format(item.lineTotal)),
                ),
              ),
            ),
            if (order.shippingAddress != null) ...[
              const SizedBox(height: 12),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Shipping Address',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 8),
                      Text(order.shippingAddress!.fullName),
                      Text(order.shippingAddress!.phone),
                      Text(order.shippingAddress!.formatted),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stackTrace) => ErrorStateView(
          message: 'Could not load order details',
          onRetry: () => ref.invalidate(orderDetailsProvider(orderId)),
        ),
      ),
    );
  }
}

class _OrderSummaryCard extends StatelessWidget {
  const _OrderSummaryCard({
    required this.order,
    required this.currency,
    required this.statusColor,
  });

  final OrderModel order;
  final NumberFormat currency;
  final Color statusColor;

  String _shortOrderId(String orderId) {
    final length = orderId.length < 8 ? orderId.length : 8;
    return orderId.substring(0, length).toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    return Card(
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
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.12),
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
            const SizedBox(height: 6),
            Text(
              'Payment: ${order.paymentMethod.toUpperCase()} (${order.paymentStatus})',
            ),
            if (order.createdAt != null)
              Text(
                'Placed on: ${DateFormat('dd MMM yyyy, hh:mm a').format(order.createdAt!)}',
              ),
            const Divider(height: 20),
            _AmountRow(
              label: 'Subtotal',
              value: currency.format(order.subtotal),
            ),
            _AmountRow(
              label: 'Shipping',
              value: currency.format(order.shippingFee),
            ),
            _AmountRow(label: 'Tax', value: currency.format(order.taxFee)),
            const SizedBox(height: 4),
            _AmountRow(
              label: 'Total',
              value: currency.format(order.totalAmount),
              isEmphasis: true,
            ),
          ],
        ),
      ),
    );
  }
}

class _AmountRow extends StatelessWidget {
  const _AmountRow({
    required this.label,
    required this.value,
    this.isEmphasis = false,
  });

  final String label;
  final String value;
  final bool isEmphasis;

  @override
  Widget build(BuildContext context) {
    final textStyle = isEmphasis
        ? Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)
        : Theme.of(context).textTheme.bodyMedium;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Text(label, style: textStyle),
          const Spacer(),
          Text(value, style: textStyle),
        ],
      ),
    );
  }
}
