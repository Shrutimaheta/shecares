import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/checkout_settings.dart';
import '../models/order.dart';
import '../models/product.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';
import '../utils/constants.dart';
import 'admin/admin_agents_tab.dart';
import 'admin/admin_orders_tab.dart';
import 'admin/admin_products_tab.dart';

class AdminScreen extends StatefulWidget {
  const AdminScreen({super.key, this.standaloneShell = false});

  final bool standaloneShell;

  @override
  State<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen> {
  int _selectedIndex = 0;
  bool _isSeeding = false;

  Future<void> _seedPhaseOneData() async {
    final messenger = ScaffoldMessenger.of(context);
    setState(() => _isSeeding = true);
    try {
      await FirestoreService.instance.seedPhaseOneData();
      if (!mounted) {
        return;
      }
      messenger.showSnackBar(
        const SnackBar(content: Text('Phase 1 data seeded successfully.')),
      );
    } catch (error) {
      if (!mounted) {
        return;
      }
      messenger.showSnackBar(
        SnackBar(
          content: Text(error.toString().replaceFirst('Exception: ', '')),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isSeeding = false);
      }
    }
  }

  Future<void> _signOut() async {
    await context.read<AuthService>().signOut();
    if (!mounted || widget.standaloneShell) {
      return;
    }
    Navigator.pushNamedAndRemoveUntil(context, AppRoutes.login, (_) => false);
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthService>();
    final user = auth.currentUser;
    final hasAccess = user?.role.isAdmin ?? false;

    if (!hasAccess) {
      return Scaffold(
        appBar: AppBar(title: const Text('Admin panel')),
        body: Center(
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: const [
                  Icon(Icons.lock_outline, size: 40),
                  SizedBox(height: 12),
                  Text('Admin access is restricted.'),
                  SizedBox(height: 8),
                  Text(
                    'Sign in with an account that has an admin role in Firestore to continue.',
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    final tabs = [
      const _DashboardTab(),
      const AdminProductsTab(),
      const AdminOrdersTab(),
      const AdminAgentsTab(),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final wide = constraints.maxWidth >= 980;
        final rail = NavigationRail(
          selectedIndex: _selectedIndex,
          onDestinationSelected: (value) =>
              setState(() => _selectedIndex = value),
          labelType: wide
              ? NavigationRailLabelType.all
              : NavigationRailLabelType.selected,
          leading: Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 24),
            child: Text(
              'SheCares Admin',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
            ),
          ),
          destinations: const [
            NavigationRailDestination(
              icon: Icon(Icons.dashboard_outlined),
              label: Text('Dashboard'),
            ),
            NavigationRailDestination(
              icon: Icon(Icons.inventory_2_outlined),
              label: Text('Products'),
            ),
            NavigationRailDestination(
              icon: Icon(Icons.payments_outlined),
              label: Text('Orders'),
            ),
            NavigationRailDestination(
              icon: Icon(Icons.people_outlined),
              label: Text('Agents'),
            ),
          ],
        );

        final appBar = AppBar(
          title: const Text('Admin panel'),
          actionsPadding: const EdgeInsets.only(right: 4),
          actions: [
            if (constraints.maxWidth >= 760)
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: Center(
                  child: FilledButton.icon(
                    onPressed: _isSeeding ? null : _seedPhaseOneData,
                    icon: const Icon(Icons.auto_awesome_outlined),
                    label: Text(
                      _isSeeding ? 'Seeding...' : 'Seed Phase 1 data',
                    ),
                  ),
                ),
              )
            else
              IconButton(
                onPressed: _isSeeding ? null : _seedPhaseOneData,
                icon: const Icon(Icons.auto_awesome_outlined),
                tooltip: 'Seed Phase 1 data',
              ),
            IconButton(
              onPressed: _signOut,
              icon: const Icon(Icons.logout_outlined),
              tooltip: 'Sign out',
            ),
          ],
        );

        if (!wide) {
          return Scaffold(
            appBar: appBar,
            body: tabs[_selectedIndex],
            bottomNavigationBar: NavigationBar(
              selectedIndex: _selectedIndex,
              onDestinationSelected: (value) =>
                  setState(() => _selectedIndex = value),
              destinations: const [
                NavigationDestination(
                  icon: Icon(Icons.dashboard_outlined),
                  label: 'Dashboard',
                ),
                NavigationDestination(
                  icon: Icon(Icons.inventory_2_outlined),
                  label: 'Products',
                ),
                NavigationDestination(
                  icon: Icon(Icons.payments_outlined),
                  label: 'Orders',
                ),
                NavigationDestination(
                  icon: Icon(Icons.people_outlined),
                  label: 'Agents',
                ),
              ],
            ),
          );
        }

        return Scaffold(
          body: Row(
            children: [
              rail,
              const VerticalDivider(width: 1),
              Expanded(
                child: Scaffold(appBar: appBar, body: tabs[_selectedIndex]),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _DashboardTab extends StatelessWidget {
  const _DashboardTab();

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Product>>(
      stream: FirestoreService.instance.productsStream(
        includeUnavailable: true,
      ),
      builder: (context, productSnapshot) {
        final products = productSnapshot.data ?? const <Product>[];
        final lowStock = products
            .where((product) => product.stockCount < 50)
            .toList();

        return StreamBuilder<List<Order>>(
          stream: FirestoreService.instance.allOrdersStream(),
          builder: (context, orderSnapshot) {
            final orders = orderSnapshot.data ?? const <Order>[];
            final revenue = orders
                .where((order) => order.paymentStatus == PaymentStatus.verified)
                .fold<double>(0, (total, order) => total + order.totalAmount);
            final paymentReview = orders
                .where(
                  (order) => order.paymentStatus == PaymentStatus.submitted,
                )
                .length;
            final activeOrders = orders
                .where(
                  (order) =>
                      order.status == OrderStatus.confirmed ||
                      order.status == OrderStatus.preparing ||
                      order.status == OrderStatus.outForDelivery,
                )
                .length;

            return StreamBuilder<CheckoutSettings>(
              stream: FirestoreService.instance.checkoutSettingsStream(),
              builder: (context, settingsSnapshot) {
                final settings =
                    settingsSnapshot.data ?? CheckoutSettings.defaults();
                return ListView(
                  padding: const EdgeInsets.all(20),
                  children: [
                    Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      children: [
                        _MetricCard(
                          label: 'Payment review',
                          value: '$paymentReview',
                        ),
                        _MetricCard(
                          label: 'Active orders',
                          value: '$activeOrders',
                        ),
                        _MetricCard(
                          label: 'Verified revenue',
                          value: 'Rs ${revenue.toStringAsFixed(0)}',
                        ),
                        _MetricCard(
                          label: 'Products',
                          value: '${products.length}',
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Low stock alerts',
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            const SizedBox(height: 12),
                            if (lowStock.isEmpty)
                              const Text('No low-stock alerts right now.')
                            else
                              ...lowStock.map(
                                (product) => Padding(
                                  padding: const EdgeInsets.only(bottom: 8),
                                  child: Text(
                                    '${product.name} - ${product.stockCount} units left',
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Checkout setup',
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Manual UPI: ${settings.manualUpiEnabled ? 'Enabled' : 'Disabled'}',
                            ),
                            Text('UPI ID: ${settings.upiId}'),
                            Text(
                              'QR image: ${settings.hasQrImage ? 'Uploaded' : 'Missing'}',
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: const [
                            Text('Setup guide'),
                            SizedBox(height: 8),
                            Text(
                              '1. Promote the first operations account to admin or super_admin in Firestore.',
                            ),
                            Text(
                              '2. Seed Phase 1 data for products and default checkout settings.',
                            ),
                            Text(
                              '3. Upload the real UPI QR and update payee details from Settings.',
                            ),
                            Text(
                              '4. Place a test order and verify the payment from the Orders tab.',
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                );
              },
            );
          },
        );
      },
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 220,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label),
              const SizedBox(height: 8),
              Text(
                value,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
