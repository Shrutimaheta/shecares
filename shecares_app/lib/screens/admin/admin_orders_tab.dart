import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../models/order.dart';
import '../../services/firestore_service.dart';
import '../../widgets/order_status_chip.dart';

class AdminOrdersTab extends StatefulWidget {
  const AdminOrdersTab({super.key});

  @override
  State<AdminOrdersTab> createState() => _AdminOrdersTabState();
}

class _AdminOrdersTabState extends State<AdminOrdersTab> {
  OrderStatus? _filterStatus;
  String? _selectedOrderId;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Order>>(
      stream: FirestoreService.instance.allOrdersStream(),
      builder: (context, orderSnapshot) {
        final allOrders = orderSnapshot.data ?? const <Order>[];
        final orders = _filterStatus == null
            ? allOrders
            : allOrders
                  .where((order) => order.status == _filterStatus)
                  .toList();
        final selected =
            orders
                .where((order) => order.docId == _selectedOrderId)
                .firstOrNull ??
            (orders.isNotEmpty ? orders.first : null);

        return LayoutBuilder(
          builder: (context, constraints) {
            if (orders.isEmpty) {
              return const Center(child: Text('No orders yet.'));
            }

            final wide = constraints.maxWidth >= 1180;
            final listPane = _OrderListPane(
              orders: orders,
              selectedOrderId: selected?.docId,
              filterStatus: _filterStatus,
              onFilterChanged: (status) =>
                  setState(() => _filterStatus = status),
              onSelected: (order) =>
                  setState(() => _selectedOrderId = order.docId),
            );

            if (wide) {
              return Row(
                children: [
                  SizedBox(width: 420, child: listPane),
                  const VerticalDivider(width: 1),
                  Expanded(
                    child: selected == null
                        ? const Center(
                            child: Text('Select an order to view details'),
                          )
                        : _OrderDetailPane(order: selected),
                  ),
                ],
              );
            }

            // Mobile view: Show list or detail
            if (_selectedOrderId != null && selected != null) {
              return WillPopScope(
                onWillPop: () async {
                  setState(() => _selectedOrderId = null);
                  return false;
                },
                child: Column(
                  children: [
                    AppBar(
                      leading: IconButton(
                        icon: const Icon(Icons.arrow_back),
                        onPressed: () =>
                            setState(() => _selectedOrderId = null),
                      ),
                      title: Text(selected.orderId),
                    ),
                    Expanded(child: _OrderDetailPane(order: selected)),
                  ],
                ),
              );
            }

            return listPane;
          },
        );
      },
    );
  }
}

class _OrderListPane extends StatelessWidget {
  const _OrderListPane({
    required this.orders,
    required this.selectedOrderId,
    required this.filterStatus,
    required this.onFilterChanged,
    required this.onSelected,
  });

  final List<Order> orders;
  final String? selectedOrderId;
  final OrderStatus? filterStatus;
  final ValueChanged<OrderStatus?> onFilterChanged;
  final ValueChanged<Order> onSelected;

  @override
  Widget build(BuildContext context) {
    final urgentCount = orders.where((order) => order.isEmergency).length;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Operations queue',
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _MetricPill(label: '${orders.length} visible'),
                  _MetricPill(label: '$urgentCount emergency'),
                ],
              ),
              const SizedBox(height: 12),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    ChoiceChip(
                      label: const Text('All'),
                      selected: filterStatus == null,
                      onSelected: (_) => onFilterChanged(null),
                    ),
                    const SizedBox(width: 8),
                    ...OrderStatus.values.map(
                      (status) => Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: ChoiceChip(
                          label: Text(status.label),
                          selected: filterStatus == status,
                          onSelected: (_) => onFilterChanged(status),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            itemCount: orders.length,
            separatorBuilder: (context, index) => const SizedBox(height: 10),
            itemBuilder: (context, index) {
              final order = orders[index];
              final selected = order.docId == selectedOrderId;
              return InkWell(
                borderRadius: BorderRadius.circular(24),
                onTap: () => onSelected(order),
                child: Card(
                  color: selected
                      ? Theme.of(context).colorScheme.secondaryContainer
                      : null,
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                order.orderId,
                                style: Theme.of(context).textTheme.titleMedium
                                    ?.copyWith(fontWeight: FontWeight.w800),
                              ),
                            ),
                            OrderStatusChip(status: order.status),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(order.address.fullName),
                        const SizedBox(height: 4),
                        Text(
                          DateFormat('d MMM, h:mm a').format(order.createdAt),
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(color: const Color(0xFF7A676F)),
                        ),
                        const SizedBox(height: 10),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            _InlineTag(
                              label:
                                  'Rs ${order.totalAmount.toStringAsFixed(0)}',
                            ),
                            if (order.deliverySlot != null)
                              _InlineTag(label: order.deliverySlot!),
                            if (order.isEmergency)
                              const _InlineTag(label: 'Emergency'),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _OrderDetailPane extends StatelessWidget {
  const _OrderDetailPane({required this.order});

  final Order order;

  @override
  Widget build(BuildContext context) {
    final recommendedNext = _recommendedNextStatus(order.status);

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    order.orderId,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 8),
                  OrderStatusChip(status: order.status),
                ],
              ),
            ),
            if (recommendedNext != null)
              Flexible(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Padding(
                    padding: const EdgeInsets.only(left: 8.0),
                    child: FilledButton.tonalIcon(
                      onPressed: () => FirestoreService.instance
                          .updateOrderStatus(order.docId, recommendedNext),
                      icon: const Icon(Icons.arrow_forward),
                      label: Text('Next: ${recommendedNext.label}'),
                    ),
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            _SummaryCard(
              title: 'Order total',
              value: 'Rs ${order.totalAmount.toStringAsFixed(0)}',
            ),
            _SummaryCard(title: 'Payment', value: order.paymentProvider.label),
            _SummaryCard(
              title: 'Slot',
              value: order.deliverySlot ?? 'Not selected',
            ),
          ],
        ),
        const SizedBox(height: 16),
        Card(
          color: const Color(0xFFFFF7F4),
          margin: EdgeInsets.zero,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Operational flags',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    if (order.isEmergency)
                      const _InlineTag(label: 'Emergency priority'),
                    if (order.isDiscreet)
                      const _InlineTag(label: 'Discreet packaging'),
                    if (order.doNotRingBell)
                      const _InlineTag(label: 'Do not ring bell'),
                  ],
                ),
                if (order.customerNote != null &&
                    order.customerNote!.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Text(
                    'Customer note',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(order.customerNote!),
                ],
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        Card(
          margin: EdgeInsets.zero,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Customer and delivery',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 10),
                Text(order.address.fullName),
                Text(order.address.phone),
                const SizedBox(height: 6),
                Text(order.address.formatted),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        Card(
          margin: EdgeInsets.zero,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Workflow control',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: OrderStatus.values
                      .map(
                        (status) => FilterChip(
                          label: Text(status.label),
                          selected: status == order.status,
                          onSelected: (_) => FirestoreService.instance
                              .updateOrderStatus(order.docId, status),
                        ),
                      )
                      .toList(),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        Card(
          margin: EdgeInsets.zero,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Items and billing',
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
  }

  OrderStatus? _recommendedNextStatus(OrderStatus status) {
    switch (status) {
      case OrderStatus.awaitingConfirmation:
        return OrderStatus.confirmed;
      case OrderStatus.confirmed:
        return OrderStatus.preparing;
      case OrderStatus.preparing:
        return OrderStatus.outForDelivery;
      case OrderStatus.outForDelivery:
        return OrderStatus.delivered;
      case OrderStatus.delivered:
      case OrderStatus.cancelled:
        return null;
    }
  }
}

class _MetricPill extends StatelessWidget {
  const _MetricPill({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFF8EEF1),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(label, style: const TextStyle(fontWeight: FontWeight.w700)),
    );
  }
}

class _InlineTag extends StatelessWidget {
  const _InlineTag({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: const Color(0xFFE6D7DB)),
      ),
      child: Text(label),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({required this.title, required this.value});

  final String title;
  final String value;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 180,
      child: Card(
        margin: EdgeInsets.zero,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: const Color(0xFF7A676F)),
              ),
              const SizedBox(height: 6),
              Text(
                value,
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
              ),
            ],
          ),
        ),
      ),
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
