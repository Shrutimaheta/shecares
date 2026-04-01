import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/auth_service.dart';
import '../utils/constants.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  bool _isReady = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _boot());
  }

  Future<void> _boot() async {
    final auth = context.read<AuthService>();
    await auth.initialize();
    await Future<void>.delayed(const Duration(milliseconds: 700));
    if (!mounted) {
      return;
    }

    if (auth.isSignedIn) {
      if (auth.isAdmin) {
        Navigator.pushReplacementNamed(context, AppRoutes.admin);
      } else {
        Navigator.pushReplacementNamed(context, AppRoutes.home);
      }
      return;
    }

    setState(() => _isReady = true);
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthService>();
    return Scaffold(
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFFFF8F4), Color(0xFFFDECEF), Color(0xFFF7F1EA)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Stack(
          children: [
            Positioned(
              top: -90,
              right: -40,
              child: Container(
                width: 260,
                height: 260,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Color(0x33E26D8E),
                ),
              ),
            ),
            Positioned(
              bottom: -130,
              left: -60,
              child: Container(
                width: 320,
                height: 320,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Color(0x228B5CF6),
                ),
              ),
            ),
            SafeArea(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  return SingleChildScrollView(
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        minHeight: constraints.maxHeight,
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Center(
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 960),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 8,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.78),
                                    borderRadius: BorderRadius.circular(999),
                                    border: Border.all(
                                      color: const Color(0xFFEACFD7),
                                    ),
                                  ),
                                  child: const Text(
                                    'Private care. Smoother reorders. Trusted delivery.',
                                    style: TextStyle(fontWeight: FontWeight.w700),
                                  ),
                                ),
                                const SizedBox(height: 20),
                                Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.all(20),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.86),
                                    borderRadius: BorderRadius.circular(28),
                                    border: Border.all(
                                      color: const Color(0xFFE9D5DC),
                                    ),
                                    boxShadow: const [
                                      BoxShadow(
                                        color: Color(0x1E000000),
                                        blurRadius: 20,
                                        offset: Offset(0, 8),
                                      ),
                                    ],
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'SheCares',
                                        style: Theme.of(context)
                                            .textTheme
                                            .displaySmall
                                            ?.copyWith(
                                              fontWeight: FontWeight.w900,
                                              color: const Color(0xFF2F1A24),
                                            ),
                                      ),
                                      const SizedBox(height: 10),
                                      Text(
                                        'A calmer storefront for sanitary pads, baby diapers, and adult care essentials.',
                                        style: Theme.of(context)
                                            .textTheme
                                            .titleMedium
                                            ?.copyWith(
                                              color: const Color(0xFF5F4B54),
                                              height: 1.4,
                                            ),
                                      ),
                                      const SizedBox(height: 14),
                                      const Wrap(
                                        spacing: 8,
                                        runSpacing: 8,
                                        children: [
                                          _SplashPill(
                                            icon: Icons.lock_outline,
                                            label: 'Discreet packaging',
                                          ),
                                          _SplashPill(
                                            icon: Icons.event_available_outlined,
                                            label: 'Slot-based delivery',
                                          ),
                                          _SplashPill(
                                            icon: Icons.track_changes_outlined,
                                            label: 'Live order tracking',
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 22),
                                Text(
                                  'Choose app language',
                                  style: Theme.of(context).textTheme.titleMedium
                                      ?.copyWith(fontWeight: FontWeight.w700),
                                ),
                                const SizedBox(height: 10),
                                Wrap(
                                  spacing: 10,
                                  runSpacing: 10,
                                  children: AppConstants.languages.map((
                                    language,
                                  ) {
                                    final selected =
                                        auth.selectedLanguage == language['code'];
                                    return ChoiceChip(
                                      label: Text(language['label'] ?? ''),
                                      selected: selected,
                                      onSelected: (_) => auth.setLanguage(
                                        language['code'] ?? 'en',
                                      ),
                                    );
                                  }).toList(),
                                ),
                                const SizedBox(height: 14),
                                Text(
                                  'Gujarati and Hindi preference is saved now for phased rollout.',
                                  style: Theme.of(context).textTheme.bodySmall
                                      ?.copyWith(color: const Color(0xFF6E5A62)),
                                ),
                                const SizedBox(height: 48),
                                if (!_isReady)
                                  const Center(child: CircularProgressIndicator())
                                else
                                  SizedBox(
                                    width: double.infinity,
                                    child: FilledButton.icon(
                                      onPressed: () async {
                                        final auth = context.read<AuthService>();
                                        if (auth.isSignedIn) {
                                          if (auth.isAdmin) {
                                            Navigator.pushReplacementNamed(context, AppRoutes.admin);
                                          } else {
                                            Navigator.pushReplacementNamed(context, AppRoutes.home);
                                          }
                                        } else {
                                          Navigator.pushReplacementNamed(context, AppRoutes.login);
                                        }
                                      },
                                      icon: const Icon(Icons.storefront_outlined),
                                      label: const Text('Enter storefront'),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SplashPill extends StatelessWidget {
  const _SplashPill({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFFDF2F5),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: const Color(0xFFEBCDD8)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: const Color(0xFFB44775)),
          const SizedBox(width: 6),
          Text(label, style: const TextStyle(fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}
