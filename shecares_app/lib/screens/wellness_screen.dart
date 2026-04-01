import 'package:flutter/material.dart';

import '../utils/constants.dart';
import '../widgets/app_bottom_nav.dart';
import '../widgets/app_main_menu.dart';

class WellnessScreen extends StatelessWidget {
  const WellnessScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Wellness'),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Period care'),
              Tab(text: 'Baby care'),
              Tab(text: 'Elder care'),
            ],
          ),
        ),
        drawer: const AppMainMenu(currentRoute: AppRoutes.wellness),
        bottomNavigationBar: const AppBottomNav(selectedIndex: 2),
        body: const TabBarView(
          children: [
            _ComingSoonCard(title: 'Period tracker and care guidance'),
            _ComingSoonCard(title: 'Baby diapering and skin care tips'),
            _ComingSoonCard(title: 'Adult care and comfort guidance'),
          ],
        ),
      ),
    );
  }
}

class _ComingSoonCard extends StatelessWidget {
  const _ComingSoonCard({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Card(
        margin: const EdgeInsets.all(24),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.auto_awesome_outlined, size: 40),
              const SizedBox(height: 12),
              Text(title, style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 8),
              const Text(
                'This section is planned for a future update and is intentionally out of scope for the Phase 1 MVP.',
              ),
            ],
          ),
        ),
      ),
    );
  }
}
