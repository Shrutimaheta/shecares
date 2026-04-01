import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/order.dart';
import '../services/firestore_service.dart';
import '../widgets/order_status_chip.dart';

class OrderTrackingScreen extends StatelessWidget {
  const OrderTrackingScreen({super.key, required this.orderDocId});

  final String orderDocId;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Track order')),
      body: StreamBuilder<Order?>(
        stream: FirestoreService.instance.orderStream(orderDocId),
        builder: (context, snapshot) {
          final order = snapshot.data;
          if (order == null) {
            return const Center(child: CircularProgressIndicator());
          }

          final steps = const [
            OrderStatus.awaitingConfirmation,
            OrderStatus.confirmed,
            OrderStatus.preparing,
            OrderStatus.outForDelivery,
            OrderStatus.delivered,
          ];
          final currentIndex = steps.indexOf(order.status);

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(28),
                  gradient: const LinearGradient(
                    colors: [Color(0xFF3C2530), Color(0xFFC84C7A)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      order.orderId,
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                          ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        OrderStatusChip(status: order.status),
                        PaymentStatusChip(status: order.paymentStatus),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Text(
                      'Ordered on ${DateFormat('d MMM y, h:mm a').format(order.createdAt)}',
                      style: Theme.of(
                        context,
                      ).textTheme.bodyMedium?.copyWith(color: Colors.white70),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      order.etaLabel ??
                          'ETA will appear once the team confirms the order.',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                    const SizedBox(height: 14),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        if ((order.paymentUtr ?? '').isNotEmpty)
                          _HeaderPill(label: 'UTR ${order.paymentUtr}'),
                        if (order.deliverySlot != null)
                          _HeaderPill(label: order.deliverySlot!),
                        if (order.isEmergency)
                          const _HeaderPill(label: 'Emergency order'),
                        if (order.isDiscreet)
                          const _HeaderPill(label: 'Discreet packaging'),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              if (order.paymentStatus == PaymentStatus.submitted)
                Card(
                  color: const Color(0xFFFFF7E6),
                  child: ListTile(
                    leading: const Icon(Icons.pending_actions_outlined),
                    title: const Text('Payment review in progress'),
                    subtitle: Text(
                      'We have your UTR ${order.paymentUtr ?? ''}. The SheCares team will verify it before confirming the order for packing.',
                    ),
                  ),
                ),
              if (order.paymentStatus == PaymentStatus.rejected)
                Card(
                  color: const Color(0xFFFFF1F1),
                  child: ListTile(
                    leading: const Icon(Icons.cancel_outlined),
                    title: const Text('Payment rejected'),
                    subtitle: Text(
                      order.paymentRejectedReason?.isNotEmpty == true
                          ? order.paymentRejectedReason!
                          : 'The payment could not be verified for this order.',
                    ),
                  ),
                ),
              const SizedBox(height: 12),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Status timeline',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w800,
                            ),
                      ),
                      const SizedBox(height: 12),
                      ...List.generate(steps.length, (index) {
                        final step = steps[index];
                        final done = currentIndex >= index;
                        final current = order.status == step;
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                width: 28,
                                height: 28,
                                decoration: BoxDecoration(
                                  color: done
                                      ? Theme.of(context).colorScheme.primary
                                      : const Color(0xFFF1E7EA),
                                  borderRadius: BorderRadius.circular(999),
                                ),
                                child: Icon(
                                  done ? Icons.check : Icons.circle_outlined,
                                  size: 16,
                                  color: done
                                      ? Colors.white
                                      : const Color(0xFF8E7C84),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      step.label,
                                      style: Theme.of(context)
                                          .textTheme
                                          .titleSmall
                                          ?.copyWith(
                                            fontWeight: current
                                                ? FontWeight.w800
                                                : FontWeight.w600,
                                          ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      _statusMessage(step),
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodySmall
                                          ?.copyWith(
                                            color: const Color(0xFF6F5D65),
                                          ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        );
                      }),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Card(
                child: ListTile(
                  leading: const Icon(Icons.location_on_outlined),
                  title: Text(order.address.fullName),
                  subtitle: Text(order.address.formatted),
                ),
              ),
              const SizedBox(height: 12),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Delivery preferences',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w800,
                            ),
                      ),
                      const SizedBox(height: 12),
                      _PreferenceRow(
                        icon: Icons.inventory_2_outlined,
                        label: order.isDiscreet
                            ? 'Discreet packaging requested'
                            : 'Standard packaging',
                      ),
                      const SizedBox(height: 8),
                      _PreferenceRow(
                        icon: Icons.notifications_off_outlined,
                        label: order.doNotRingBell
                            ? 'Do not ring the bell'
                            : 'Normal arrival notifications',
                      ),
                      if (order.deliverySlot != null) ...[
                        const SizedBox(height: 8),
                        _PreferenceRow(
                          icon: Icons.schedule_outlined,
                          label: order.deliverySlot!,
                        ),
                      ],
                      if (order.customerNote != null &&
                          order.customerNote!.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        _PreferenceRow(
                          icon: Icons.sticky_note_2_outlined,
                          label: order.customerNote!,
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Order summary',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w800,
                            ),
                      ),
                      const SizedBox(height: 12),
                      ...order.items.map(
                        (item) => Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  '${item.product.name} x ${item.quantity}',
                                ),
                              ),
                              Text('Rs ${item.totalPrice.toStringAsFixed(0)}'),
                            ],
                          ),
                        ),
                      ),
                      const Divider(),
                      _AmountRow(label: 'Subtotal', value: order.subtotal),
                      _AmountRow(label: 'Delivery', value: order.deliveryFee),
                      if (order.emergencyFee > 0)
                        _AmountRow(
                          label: 'Emergency surcharge',
                          value: order.emergencyFee,
                        ),
                      const Divider(),
                      _AmountRow(
                        label: 'Total',
                        value: order.totalAmount,
                        bold: true,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  String _statusMessage(OrderStatus status) {
    switch (status) {
      case OrderStatus.awaitingConfirmation:
        return 'We are reviewing the submitted payment before fulfilment begins.';
      case OrderStatus.confirmed:
        return 'The payment is verified and the order is confirmed.';
      case OrderStatus.preparing:
        return 'Items are being packed and prepared for dispatch.';
      case OrderStatus.outForDelivery:
        return 'Your essentials are on the way.';
      case OrderStatus.delivered:
        return 'The order has been delivered successfully.';
      case OrderStatus.cancelled:
        return 'This order was cancelled before completion.';
    }
  }
}

class _HeaderPill extends StatelessWidget {
  const _HeaderPill({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.16),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _PreferenceRow extends StatelessWidget {
  const _PreferenceRow({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18),
        const SizedBox(width: 10),
        Expanded(child: Text(label)),
      ],
    );
  }
}

class _AmountRow extends StatelessWidget {
  const _AmountRow({
    required this.label,
    required this.value,
    this.bold = false,
  });

  final String label;
  final double value;
  final bool bold;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontWeight: bold ? FontWeight.w700 : FontWeight.w400,
            ),
          ),
          Text(
            'Rs ${value.toStringAsFixed(0)}',
            style: TextStyle(
              fontWeight: bold ? FontWeight.w700 : FontWeight.w400,
            ),
          ),
        ],
      ),
    );
  }
}
