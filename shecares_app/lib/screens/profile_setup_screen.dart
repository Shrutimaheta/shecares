import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/auth_service.dart';
import '../utils/constants.dart';

class ProfileSetupScreen extends StatefulWidget {
  const ProfileSetupScreen({super.key});

  @override
  State<ProfileSetupScreen> createState() => _ProfileSetupScreenState();
}

class _ProfileSetupScreenState extends State<ProfileSetupScreen> {
  final _nameController = TextEditingController();
  final Set<String> _careTargets = <String>{};

  @override
  void initState() {
    super.initState();
    final user = context.read<AuthService>().currentUser;
    _nameController.text = user?.name ?? '';
    _careTargets.addAll(user?.careTargets ?? const []);
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _continue() async {
    if (_nameController.text.trim().isEmpty) {
      _showMessage('Please enter your full name.');
      return;
    }
    if (_careTargets.isEmpty) {
      _showMessage('Please select who you are shopping for.');
      return;
    }

    final auth = context.read<AuthService>();
    try {
      await auth.saveCustomerProfile(
        fullName: _nameController.text,
        careTargets: _careTargets.toList(),
      );
      if (!mounted) {
        return;
      }
      Navigator.pushNamedAndRemoveUntil(context, AppRoutes.home, (_) => false);
    } catch (error) {
      _showMessage(error.toString().replaceFirst('Exception: ', ''));
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthService>();
    return Scaffold(
      appBar: AppBar(title: const Text('Set up profile')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Tell us how to personalize delivery',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'We use this only to tailor the catalog, delivery reminders, and order experience.',
              ),
              const SizedBox(height: 24),
              TextField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Full name'),
              ),
              const SizedBox(height: 20),
              Text(
                'Who are you shopping for?',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: AppConstants.careTargets.map((target) {
                  final isSelected = _careTargets.contains(target);
                  return FilterChip(
                    selected: isSelected,
                    label: Text(target),
                    onSelected: (selected) {
                      setState(() {
                        if (selected) {
                          _careTargets.add(target);
                        } else {
                          _careTargets.remove(target);
                        }
                      });
                    },
                  );
                }).toList(),
              ),
              const SizedBox(height: 40),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: auth.isBusy ? null : _continue,
                  child: const Text('Continue'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
