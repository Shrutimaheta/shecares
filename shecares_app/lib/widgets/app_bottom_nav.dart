import 'package:flutter/material.dart';

import '../models/pending_auth_action.dart';
import '../utils/auth_gate.dart';

class AppBottomNav extends StatelessWidget {
  const AppBottomNav({super.key, required this.selectedIndex});

  final int selectedIndex;

  @override
  Widget build(BuildContext context) {
    return NavigationBar(
      selectedIndex: selectedIndex,
      onDestinationSelected: (index) {
        if (index == selectedIndex) {
          return;
        }

        switch (index) {
          case 0:
            Navigator.pushReplacementNamed(context, '/home');
            return;
          case 1:
            requireCustomerAction(
              context,
              const PendingAuthAction(type: PendingAuthActionType.openOrders),
            );
            return;
          case 2:
            Navigator.pushReplacementNamed(context, '/wellness');
            return;
          case 3:
            requireCustomerAction(
              context,
              const PendingAuthAction(type: PendingAuthActionType.openProfile),
            );
            return;
        }
      },
      destinations: const [
        NavigationDestination(
          icon: Icon(Icons.home_outlined),
          selectedIcon: Icon(Icons.home),
          label: 'Home',
        ),
        NavigationDestination(
          icon: Icon(Icons.receipt_long_outlined),
          selectedIcon: Icon(Icons.receipt_long),
          label: 'Orders',
        ),
        NavigationDestination(
          icon: Icon(Icons.favorite_outline),
          selectedIcon: Icon(Icons.favorite),
          label: 'Wellness',
        ),
        NavigationDestination(
          icon: Icon(Icons.person_outline),
          selectedIcon: Icon(Icons.person),
          label: 'Profile',
        ),
      ],
    );
  }
}
