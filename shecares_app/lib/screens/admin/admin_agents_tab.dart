import 'package:flutter/material.dart';

import '../../models/agent.dart';
import '../../services/firestore_service.dart';

class AdminAgentsTab extends StatelessWidget {
  const AdminAgentsTab({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Agent>>(
      stream: FirestoreService.instance.agentsStream(),
      builder: (context, snapshot) {
        final agents = snapshot.data ?? const <Agent>[];
        return ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Align(
              alignment: Alignment.centerLeft,
              child: FilledButton.icon(
                onPressed: () => _openAgentDialog(context),
                icon: const Icon(Icons.add),
                label: const Text('Add agent'),
              ),
            ),
            const SizedBox(height: 16),
            ...agents.map(
              (agent) => Card(
                child: ListTile(
                  isThreeLine: true,
                  leading: CircleAvatar(child: Text(agent.initials)),
                  title: Text(agent.name),
                  subtitle: Text(
                    '${agent.area} - ${agent.phone} - ${agent.deliveriesCompleted} deliveries',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  trailing: SizedBox(
                    width: 136,
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Switch(
                            value: agent.isActive,
                            onChanged: (value) => FirestoreService.instance
                                .setAgent(agent.copyWith(isActive: value)),
                          ),
                          IconButton(
                            visualDensity: VisualDensity.compact,
                            icon: const Icon(Icons.edit_outlined),
                            onPressed: () =>
                                _openAgentDialog(context, agent: agent),
                          ),
                          IconButton(
                            visualDensity: VisualDensity.compact,
                            icon: const Icon(Icons.delete_outline),
                            onPressed: () =>
                                FirestoreService.instance.deleteAgent(agent.id),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _openAgentDialog(BuildContext context, {Agent? agent}) async {
    final nameController = TextEditingController(text: agent?.name ?? '');
    final phoneController = TextEditingController(text: agent?.phone ?? '');
    final areaController = TextEditingController(text: agent?.area ?? '');
    final deliveriesController = TextEditingController(
      text: '${agent?.deliveriesCompleted ?? 0}',
    );
    var isActive = agent?.isActive ?? true;

    await showDialog<void>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) {
          final width = MediaQuery.of(context).size.width;
          final dialogWidth = width < 560 ? width * 0.9 : 420.0;

          return AlertDialog(
            title: Text(agent == null ? 'Add agent' : 'Edit agent'),
            content: SizedBox(
              width: dialogWidth,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: nameController,
                    decoration: const InputDecoration(labelText: 'Name'),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: phoneController,
                    decoration: const InputDecoration(labelText: 'Phone'),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: areaController,
                    decoration: const InputDecoration(labelText: 'Area'),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: deliveriesController,
                    decoration: const InputDecoration(
                      labelText: 'Completed deliveries',
                    ),
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 10),
                  SwitchListTile(
                    title: const Text('Active'),
                    value: isActive,
                    onChanged: (value) => setModalState(() => isActive = value),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: () async {
                  final built = Agent(
                    id: agent?.id ?? _slug(nameController.text),
                    name: nameController.text.trim(),
                    phone: phoneController.text.trim(),
                    area: areaController.text.trim(),
                    isActive: isActive,
                    deliveriesCompleted:
                        int.tryParse(deliveriesController.text.trim()) ?? 0,
                  );
                  await FirestoreService.instance.setAgent(built);
                  if (context.mounted) {
                    Navigator.pop(context);
                  }
                },
                child: const Text('Save'),
              ),
            ],
          );
        },
      ),
    );
  }

  String _slug(String input) {
    return input
        .trim()
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]+'), '_')
        .replaceAll(RegExp(r'^_|_$'), '');
  }
}
