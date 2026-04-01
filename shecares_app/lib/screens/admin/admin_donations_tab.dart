import 'package:flutter/material.dart';

import '../../services/firestore_service.dart';

class AdminDonationsTab extends StatelessWidget {
  const AdminDonationsTab({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Map<String, String>>>(
      stream: FirestoreService.instance.ngoPartnersStream(),
      builder: (context, snapshot) {
        final ngoPartners = snapshot.data ?? const <Map<String, String>>[];
        return ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text('Donations and NGO partners'),
                    SizedBox(height: 8),
                    Text(
                      'The donation workflow itself is intentionally out of scope for Phase 1, but the admin surface keeps a simple NGO partner list ready for the next phase.',
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            ...ngoPartners.map(
              (partner) => Card(
                child: ListTile(
                  leading: const Icon(Icons.group_outlined),
                  title: Text(partner['name'] ?? 'Partner NGO'),
                  subtitle: Text(
                    '${partner['type'] ?? 'NGO'} - ${partner['area'] ?? 'Ahmedabad'}',
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
