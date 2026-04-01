import 'package:flutter/material.dart';

import '../models/order.dart';

class OrderStatusChip extends StatelessWidget {
  const OrderStatusChip({super.key, required this.status});

  final OrderStatus status;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: _color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: _color.withOpacity(0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(_icon, size: 14, color: _color),
          const SizedBox(width: 6),
          Text(
            status.label,
            style: TextStyle(color: _color, fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }

  Color get _color {
    switch (status) {
      case OrderStatus.awaitingConfirmation:
        return Colors.deepOrange.shade700;
      case OrderStatus.confirmed:
        return Colors.blue.shade700;
      case OrderStatus.preparing:
        return Colors.amber.shade800;
      case OrderStatus.outForDelivery:
        return Colors.teal.shade700;
      case OrderStatus.delivered:
        return Colors.green.shade700;
      case OrderStatus.cancelled:
        return Colors.red.shade700;
    }
  }

  IconData get _icon {
    switch (status) {
      case OrderStatus.awaitingConfirmation:
        return Icons.pending_actions_outlined;
      case OrderStatus.confirmed:
        return Icons.verified_outlined;
      case OrderStatus.preparing:
        return Icons.inventory_2_outlined;
      case OrderStatus.outForDelivery:
        return Icons.local_shipping_outlined;
      case OrderStatus.delivered:
        return Icons.check_circle_outline;
      case OrderStatus.cancelled:
        return Icons.cancel_outlined;
    }
  }
}

class PaymentStatusChip extends StatelessWidget {
  const PaymentStatusChip({super.key, required this.status});

  final PaymentStatus status;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: _color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: _color.withOpacity(0.2)),
      ),
      child: Text(
        status.label,
        style: TextStyle(color: _color, fontWeight: FontWeight.w700),
      ),
    );
  }

  Color get _color {
    switch (status) {
      case PaymentStatus.submitted:
        return Colors.deepOrange.shade700;
      case PaymentStatus.verified:
        return Colors.green.shade700;
      case PaymentStatus.rejected:
        return Colors.red.shade700;
    }
  }
}
