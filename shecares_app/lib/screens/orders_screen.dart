import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../models/order.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';
import '../utils/constants.dart';
import '../widgets/app_bottom_nav.dart';
import '../widgets/app_main_menu.dart';
import '../widgets/empty_state_card.dart';
import '../widgets/order_status_chip.dart';

class OrdersScreen extends StatelessWidget {
  const OrdersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthService>();
    final user = auth.currentUser;

    return Scaffold(
      appBar: AppBar(title: const Text('Orders')),
      drawer: const AppMainMenu(currentRoute: AppRoutes.orders),
      bottomNavigationBar: const AppBottomNav(selectedIndex: 1),
      body: user == null
          ? Center(
              child: EmptyStateCard(
                icon: Icons.lock_outline,
                title: 'Login required',
                message: 'Please login to view your SheCares orders.',
                actionLabel: 'Login',
                onAction: () => Navigator.pushNamed(context, AppRoutes.login),
              ),
            )
          : StreamBuilder<List<Order>>(
              stream: FirestoreService.instance.userOrdersStream(user.uid),
              builder: (context, snapshot) {
                final orders = snapshot.data ?? const <Order>[];
                if (orders.isEmpty) {
                  return Center(
                    child: EmptyStateCard(
                      icon: Icons.receipt_long_outlined,
                      title: 'No orders yet',
                      message:
                          'Once you submit your first manual UPI order, it will show up here instantly for payment review and fulfilment tracking.',
                      actionLabel: 'Browse products',
                      onAction: () =>
                          Navigator.pushNamed(context, AppRoutes.home),
                    ),
                  );
                }

                final pendingReview = orders
                    .where(
                      (order) => order.paymentStatus == PaymentStatus.submitted,
                    )
                    .length;
                final activeOrders = orders
                    .where(
                      (order) =>
                          order.status != OrderStatus.delivered &&
                          order.status != OrderStatus.cancelled,
                    )
                    .length;

                return ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    Card(
                      color: const Color(0xFFFFF7F4),
                      child: Padding(
                        padding: const EdgeInsets.all(18),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Your SheCares order desk',
                              style: Theme.of(context).textTheme.titleLarge
                                  ?.copyWith(fontWeight: FontWeight.w800),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Track payment review, preparation, dispatch, and delivery from one place.',
                              style: Theme.of(context).textTheme.bodyMedium
                                  ?.copyWith(color: const Color(0xFF6F5D65)),
                            ),
                            const SizedBox(height: 14),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: [
                                _CountPill(
                                  label: '$pendingReview awaiting review',
                                ),
                                _CountPill(label: '$activeOrders active'),
                                _CountPill(
                                  label: '${orders.length} total orders',
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    ...orders.map((order) => _OrderCard(order: order)),
                  ],
                );
              },
            ),
    );
  }
}

class _OrderCard extends StatelessWidget {
  const _OrderCard({required this.order});

  final Order order;

  @override
  Widget build(BuildContext context) {
    final itemPreview = order.items
        .take(2)
        .map((item) => item.product.name)
        .join(', ');
    final extraCount = order.items.length - 2;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    order.orderId,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                OrderStatusChip(status: order.status),
              ],
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                PaymentStatusChip(status: order.paymentStatus),
                if ((order.paymentUtr ?? '').isNotEmpty)
                  _InfoPill(
                    icon: Icons.qr_code_2_outlined,
                    label: 'UTR ${order.paymentUtr}',
                  ),
                if (order.deliverySlot != null)
                  _InfoPill(
                    icon: Icons.schedule_outlined,
                    label: order.deliverySlot!,
                  ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              extraCount > 0
                  ? '$itemPreview and $extraCount more'
                  : itemPreview,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 8),
            Text(
              DateFormat('d MMM y, h:mm a').format(order.createdAt),
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: const Color(0xFF7A676F)),
            ),
            const SizedBox(height: 10),
            Text(
              _statusMessage(order),
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: const Color(0xFF6F5D65),
                height: 1.45,
              ),
            ),
            if ((order.paymentRejectedReason ?? '').isNotEmpty) ...[
              const SizedBox(height: 10),
              Text(
                'Payment rejected: ${order.paymentRejectedReason}',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.red.shade700,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
            const SizedBox(height: 14),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Text(
                  'Rs ${order.totalAmount.toStringAsFixed(0)}',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                FilledButton.tonal(
                  onPressed: () => Navigator.pushNamed(
                    context,
                    AppRoutes.tracking,
                    arguments: order.docId,
                  ),
                  child: const Text('Track order'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _statusMessage(Order order) {
    if (order.paymentStatus == PaymentStatus.submitted) {
      return 'Your payment reference is submitted. The SheCares team will verify it before confirming and packing the order.';
    }
    if (order.paymentStatus == PaymentStatus.rejected) {
      return 'This order was cancelled after payment review. You can place a fresh order with the correct UTR if you still need these items.';
    }

    switch (order.status) {
      case OrderStatus.awaitingConfirmation:
        return 'We are waiting to confirm the payment before fulfilment starts.';
      case OrderStatus.confirmed:
        return 'Payment is verified and the order is confirmed for fulfilment.';
      case OrderStatus.preparing:
        return 'Your essentials are being packed for dispatch.';
      case OrderStatus.outForDelivery:
        return 'Your order is on the way to your address.';
      case OrderStatus.delivered:
        return 'The order has been delivered successfully.';
      case OrderStatus.cancelled:
        return 'This order was cancelled.';
    }
  }
}

class _CountPill extends StatelessWidget {
  const _CountPill({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(label, style: const TextStyle(fontWeight: FontWeight.w700)),
    );
  }
}

class _InfoPill extends StatelessWidget {
  const _InfoPill({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final maxWidth = MediaQuery.of(context).size.width * 0.58;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFF8EEF1),
        borderRadius: BorderRadius.circular(999),
      ),
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16),
            const SizedBox(width: 6),
            Flexible(
              child: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis),
            ),
          ],
        ),
      ),
    );
  }
}
