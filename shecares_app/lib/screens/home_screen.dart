import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/pending_auth_action.dart';
import '../models/product.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';
import '../utils/auth_gate.dart';
import '../utils/constants.dart';
import '../utils/product_experience.dart';
import '../widgets/app_bottom_nav.dart';
import '../widgets/app_main_menu.dart';
import '../widgets/cart_badge_button.dart';
import '../widgets/empty_state_card.dart';
import '../widgets/product_card.dart';
import '../widgets/product_media.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthService>();
    final viewportWidth = MediaQuery.of(context).size.width;
    final productRailCardWidth = ((viewportWidth - 52).clamp(
      220.0,
      340.0,
    )).toDouble();
    final productRailHeight = viewportWidth < 430 ? 176.0 : 188.0;
    final userName = auth.currentUser?.name.trim().isEmpty ?? true
        ? 'friend'
        : auth.currentUser!.name.split(' ').first;

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Hello, $userName',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            Text(
              'Thoughtful essentials, delivered discreetly in Ahmedabad',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
        actions: const [CartBadgeButton()],
      ),
      drawer: const AppMainMenu(currentRoute: AppRoutes.home),
      bottomNavigationBar: const AppBottomNav(selectedIndex: 0),
      body: StreamBuilder<List<Product>>(
        stream: FirestoreService.instance.productsStream(),
        builder: (context, snapshot) {
          if (!snapshot.hasData &&
              snapshot.connectionState != ConnectionState.active) {
            return const Center(child: CircularProgressIndicator());
          }

          final products = snapshot.data ?? const <Product>[];
          if (products.isEmpty) {
            final actionLabel = auth.isAdmin
                ? 'Open admin dashboard'
                : 'Explore wellness';
            final actionHandler = auth.isAdmin
                ? () => Navigator.pushNamed(context, AppRoutes.admin)
                : () => Navigator.pushNamed(context, AppRoutes.wellness);

            return ListView(
              padding: const EdgeInsets.all(24),
              children: [
                EmptyStateCard(
                  icon: Icons.inventory_2_outlined,
                  title: 'Products are being prepared',
                  message:
                      'We are updating the storefront right now. Please check back shortly to browse the latest essentials.',
                  actionLabel: actionLabel,
                  onAction: actionHandler,
                ),
              ],
            );
          }

          final bestSellers = products
              .where((product) => product.isBestSeller)
              .toList();
          final newArrivals = products
              .where((product) => product.isNew)
              .toList();
          final spotlightProducts = bestSellers.isEmpty
              ? products.take(6).toList()
              : bestSellers;
          final freshProducts = newArrivals.isEmpty
              ? products.reversed.take(6).toList()
              : newArrivals;

          return ListView(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
            children: [
              _HeroBanner(userName: userName),
              const SizedBox(height: 16),
              InkWell(
                borderRadius: BorderRadius.circular(22),
                onTap: () => Navigator.pushNamed(context, AppRoutes.products),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 15,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(22),
                    border: Border.all(color: const Color(0xFFE8DADF)),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.search),
                      SizedBox(width: 12),
                      Expanded(
                        child: Text('Search pads, diapers, sizes, or brands'),
                      ),
                      Icon(Icons.tune_rounded),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 14),
              SizedBox(
                height: 42,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: const [
                    _TrustPill(
                      icon: Icons.shield_outlined,
                      label: 'Privacy-first delivery',
                    ),
                    _TrustPill(
                      icon: Icons.local_shipping_outlined,
                      label: 'Live order tracking',
                    ),
                    _TrustPill(
                      icon: Icons.currency_rupee_rounded,
                      label: 'Free above Rs 499',
                    ),
                    _TrustPill(
                      icon: Icons.schedule_outlined,
                      label: 'Slot-based checkout',
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 28),
              _SectionHeader(
                title: 'Shop by care need',
                actionLabel: 'View all',
                onAction: () =>
                    Navigator.pushNamed(context, AppRoutes.products),
              ),
              const SizedBox(height: 14),
              SizedBox(
                height: 188,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: ProductCategory.values.length,
                  separatorBuilder: (context, index) =>
                      const SizedBox(width: 12),
                  itemBuilder: (context, index) {
                    final category = ProductCategory.values[index];
                    final count = products
                        .where((product) => product.category == category)
                        .length;
                    return SizedBox(
                      width: 252,
                      child: _CategorySpotlightCard(
                        category: category,
                        productCount: count,
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 28),
              _SectionHeader(
                title: 'Top picks this week',
                actionLabel: 'Browse catalog',
                onAction: () =>
                    Navigator.pushNamed(context, AppRoutes.products),
              ),
              const SizedBox(height: 12),
              SizedBox(
                height: productRailHeight,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: spotlightProducts.length,
                  separatorBuilder: (context, index) =>
                      const SizedBox(width: 12),
                  itemBuilder: (context, index) => SizedBox(
                    width: productRailCardWidth,
                    child: ProductCard(product: spotlightProducts[index]),
                  ),
                ),
              ),
              const SizedBox(height: 28),
              _SectionHeader(
                title: 'Fresh arrivals and restocks',
                actionLabel: 'See what is new',
                onAction: () =>
                    Navigator.pushNamed(context, AppRoutes.products),
              ),
              const SizedBox(height: 12),
              SizedBox(
                height: productRailHeight,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: freshProducts.length,
                  separatorBuilder: (context, index) =>
                      const SizedBox(width: 12),
                  itemBuilder: (context, index) => SizedBox(
                    width: productRailCardWidth,
                    child: ProductCard(product: freshProducts[index]),
                  ),
                ),
              ),
              const SizedBox(height: 28),
              Text(
                'How SheCares handles delivery',
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 12),
              const Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  _WorkflowCard(
                    icon: Icons.shopping_bag_outlined,
                    title: 'Browse with context',
                    message:
                        'Each product shows stock, ratings, delivery promise, and privacy-friendly details.',
                  ),
                  _WorkflowCard(
                    icon: Icons.event_available_outlined,
                    title: 'Choose your slot',
                    message:
                        'Pick a delivery window, add doorstep notes, and request plain packaging in checkout.',
                  ),
                  _WorkflowCard(
                    icon: Icons.route_outlined,
                    title: 'Track the handoff',
                    message:
                        'Admin confirms, assigns an agent, and updates progress live while you track ETA.',
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }
}

class _HeroBanner extends StatelessWidget {
  const _HeroBanner({required this.userName});

  final String userName;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(32),
        gradient: const LinearGradient(
          colors: [Color(0xFF3C2530), Color(0xFFC84C7A)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x22000000),
            blurRadius: 24,
            offset: Offset(0, 14),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(32),
        child: Stack(
          children: [
            Positioned(
              right: 0,
              top: 0,
              bottom: 0,
              width: 180,
              child: ProductMedia(
                imageUrl: categoryHeroImage(ProductCategory.sanitaryPads),
                borderRadius: BorderRadius.zero,
                fallbackIcon: Icons.favorite,
                overlay: const DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.transparent, Color(0x22000000)],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(22),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.16),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: const Text(
                      'Real-time care commerce',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 12,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Reliable monthly essentials for you, $userName.',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      height: 1.15,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Shop pads, baby diapers, and adult diapers with discreet packing, slot-based checkout, and live delivery tracking.',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.white.withOpacity(0.86),
                      height: 1.45,
                    ),
                  ),
                  const SizedBox(height: 18),
                  Row(
                    children: [
                      Expanded(
                        child: FilledButton(
                          style: FilledButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: const Color(0xFF3C2530),
                          ),
                          onPressed: () =>
                              Navigator.pushNamed(context, AppRoutes.products),
                          child: const Text('Shop now'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: OutlinedButton(
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.white,
                            side: BorderSide(
                              color: Colors.white.withOpacity(0.35),
                            ),
                          ),
                          onPressed: () => requireCustomerAction(
                            context,
                            const PendingAuthAction(
                              type: PendingAuthActionType.openOrders,
                            ),
                          ),
                          child: const Text('Track orders'),
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
    );
  }
}

class _CategorySpotlightCard extends StatelessWidget {
  const _CategorySpotlightCard({
    required this.category,
    required this.productCount,
  });

  final ProductCategory category;
  final int productCount;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(28),
      onTap: () =>
          Navigator.pushNamed(context, AppRoutes.products, arguments: category),
      child: Card(
        clipBehavior: Clip.antiAlias,
        child: Stack(
          children: [
            Positioned.fill(
              child: ProductMedia(
                imageUrl: categoryHeroImage(category),
                borderRadius: BorderRadius.zero,
                fallbackIcon: _iconForCategory(category),
                overlay: const DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.transparent, Color(0xE622171B)],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Icon(
                      _iconForCategory(category),
                      color: Colors.white,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    category.title,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '$productCount curated SKUs for fast, practical reordering',
                    style: Theme.of(
                      context,
                    ).textTheme.bodySmall?.copyWith(color: Colors.white70),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _iconForCategory(ProductCategory category) {
    switch (category) {
      case ProductCategory.sanitaryPads:
        return Icons.favorite;
      case ProductCategory.babyDiapers:
        return Icons.child_friendly;
      case ProductCategory.adultDiapers:
        return Icons.accessibility_new;
    }
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({
    required this.title,
    required this.actionLabel,
    required this.onAction,
  });

  final String title;
  final String actionLabel;
  final VoidCallback onAction;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
          ),
        ),
        TextButton(onPressed: onAction, child: Text(actionLabel)),
      ],
    );
  }
}

class _TrustPill extends StatelessWidget {
  const _TrustPill({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(right: 10),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: const Color(0xFFE6D7DB)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [Icon(icon, size: 18), const SizedBox(width: 8), Text(label)],
      ),
    );
  }
}

class _WorkflowCard extends StatelessWidget {
  const _WorkflowCard({
    required this.icon,
    required this.title,
    required this.message,
  });

  final IconData icon;
  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 280,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: const Color(0xFFF8E9EC),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon),
              ),
              const SizedBox(height: 14),
              Text(
                title,
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 8),
              Text(
                message,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: const Color(0xFF6F5D65),
                  height: 1.45,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
