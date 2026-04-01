import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/pending_auth_action.dart';
import '../services/auth_service.dart';
import '../utils/auth_gate.dart';
import '../utils/constants.dart';

class AppMainMenu extends StatelessWidget {
  const AppMainMenu({super.key, required this.currentRoute});

  final String currentRoute;

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthService>();
    final user = auth.currentUser;
    final userLabel = user?.fullName.trim().isNotEmpty == true
        ? user!.fullName
        : 'Guest user';
    final subtitle = user?.email.trim().isNotEmpty == true
        ? user!.email
        : 'Browse freely, login for orders';

    return Drawer(
      child: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: EdgeInsets.zero,
                children: [
                  UserAccountsDrawerHeader(
                    margin: const EdgeInsets.only(bottom: 6),
                    accountName: Text(
                      userLabel,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    accountEmail: Text(
                      subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    currentAccountPicture: CircleAvatar(
                      child: Text(
                        (userLabel.isNotEmpty ? userLabel[0] : 'S')
                            .toUpperCase(),
                      ),
                    ),
                  ),
                  _MenuItem(
                    icon: Icons.home_outlined,
                    label: 'Home',
                    selected: currentRoute == AppRoutes.home,
                    onTap: () => _navigateTo(context, AppRoutes.home),
                  ),
                  _MenuItem(
                    icon: Icons.shopping_bag_outlined,
                    label: 'Products',
                    selected: currentRoute == AppRoutes.products,
                    onTap: () => _navigateTo(context, AppRoutes.products),
                  ),
                  _MenuItem(
                    icon: Icons.shopping_cart_outlined,
                    label: 'Cart',
                    selected: currentRoute == AppRoutes.cart,
                    onTap: () => _navigateProtected(
                      context,
                      AppRoutes.cart,
                      const PendingAuthAction(
                        type: PendingAuthActionType.openCart,
                      ),
                    ),
                  ),
                  _MenuItem(
                    icon: Icons.receipt_long_outlined,
                    label: 'Orders',
                    selected: currentRoute == AppRoutes.orders,
                    onTap: () => _navigateProtected(
                      context,
                      AppRoutes.orders,
                      const PendingAuthAction(
                        type: PendingAuthActionType.openOrders,
                      ),
                    ),
                  ),
                  _MenuItem(
                    icon: Icons.favorite_outline,
                    label: 'Wellness',
                    selected: currentRoute == AppRoutes.wellness,
                    onTap: () => _navigateTo(context, AppRoutes.wellness),
                  ),
                  _MenuItem(
                    icon: Icons.person_outline,
                    label: 'Profile',
                    selected: currentRoute == AppRoutes.profile,
                    onTap: () => _navigateProtected(
                      context,
                      AppRoutes.profile,
                      const PendingAuthAction(
                        type: PendingAuthActionType.openProfile,
                      ),
                    ),
                  ),
                  if (auth.isAdmin)
                    _MenuItem(
                      icon: Icons.admin_panel_settings_outlined,
                      label: 'Admin',
                      selected: currentRoute == AppRoutes.admin,
                      onTap: () => _navigateTo(context, AppRoutes.admin),
                    ),
                ],
              ),
            ),
            const Divider(height: 1),
            _MenuItem(
              icon: user == null ? Icons.login_rounded : Icons.logout_rounded,
              label: user == null ? 'Login' : 'Sign out',
              onTap: () => user == null
                  ? _navigateTo(context, AppRoutes.login)
                  : _signOut(context),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _navigateTo(BuildContext context, String routeName) async {
    Navigator.pop(context);
    if (currentRoute == routeName) {
      return;
    }
    await Navigator.pushReplacementNamed(context, routeName);
  }

  Future<void> _navigateProtected(
    BuildContext context,
    String routeName,
    PendingAuthAction action,
  ) async {
    Navigator.pop(context);
    if (currentRoute == routeName) {
      return;
    }
    await requireCustomerAction(context, action);
  }

  Future<void> _signOut(BuildContext context) async {
    Navigator.pop(context);
    await context.read<AuthService>().signOut();
    if (!context.mounted) {
      return;
    }
    Navigator.pushNamedAndRemoveUntil(context, AppRoutes.login, (_) => false);
  }
}

class _MenuItem extends StatelessWidget {
  const _MenuItem({
    required this.icon,
    required this.label,
    required this.onTap,
    this.selected = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon),
      title: Text(label),
      selected: selected,
      onTap: onTap,
    );
  }
}
