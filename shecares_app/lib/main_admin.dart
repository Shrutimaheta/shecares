import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'screens/admin_screen.dart';
import 'services/app_bootstrap.dart';
import 'services/auth_service.dart';
import 'utils/app_theme.dart';
import 'utils/constants.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AppBootstrap.instance.initialize();
  final authService = AuthService();
  await authService.initialize();
  runApp(SheCaresAdminWebApp(authService: authService));
}

class SheCaresAdminWebApp extends StatelessWidget {
  const SheCaresAdminWebApp({super.key, required this.authService});

  final AuthService authService;

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<AuthService>.value(
      value: authService,
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: AppConstants.adminAppName,
        theme: AppTheme.light(),
        home: const _AdminAuthGate(),
      ),
    );
  }
}

class _AdminAuthGate extends StatelessWidget {
  const _AdminAuthGate();

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthService>();
    final user = auth.currentUser;

    if (!auth.isFirebaseMode) {
      return const _AdminSetupRequiredScreen();
    }
    if (user == null) {
      return const _AdminLoginScreen();
    }
    if (!auth.isAdmin) {
      return const _AdminAccessPendingScreen();
    }
    return const AdminScreen();
  }
}

class _AdminLoginScreen extends StatefulWidget {
  const _AdminLoginScreen();

  @override
  State<_AdminLoginScreen> createState() => _AdminLoginScreenState();
}

class _AdminLoginScreenState extends State<_AdminLoginScreen> {
  final _phoneController = TextEditingController();
  final _otpController = TextEditingController();
  bool _otpSent = false;

  @override
  void dispose() {
    _phoneController.dispose();
    _otpController.dispose();
    super.dispose();
  }

  Future<void> _sendOtp() async {
    final phone = _phoneController.text.trim();
    final auth = context.read<AuthService>();
    try {
      await auth.sendOtp(phone);
      if (!mounted) {
        return;
      }
      setState(() => _otpSent = true);
      _showMessage('OTP sent to +91 $phone.');
    } catch (error) {
      _showMessage(error.toString().replaceFirst('Exception: ', ''));
    }
  }

  Future<void> _verifyOtp() async {
    final auth = context.read<AuthService>();
    try {
      await auth.verifyOtp(_otpController.text.trim());
      if (!mounted) {
        return;
      }
      if (!auth.isAdmin) {
        _showMessage(
          'This phone number is signed in, but it does not have admin access yet.',
        );
      }
    } catch (error) {
      _showMessage(error.toString().replaceFirst('Exception: ', ''));
    }
  }

  void _showMessage(String message) {
    if (!mounted) {
      return;
    }
    final messenger = ScaffoldMessenger.maybeOf(context);
    messenger?.showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthService>();
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Scaffold(
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(16, 24, 16, 24 + bottomInset),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: constraints.maxHeight - 48,
                ),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 460),
                    child: Card(
                      margin: const EdgeInsets.all(8),
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              AppConstants.adminAppName,
                              style: Theme.of(context).textTheme.headlineSmall
                                  ?.copyWith(fontWeight: FontWeight.w800),
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              'Sign in with your admin phone number. Access is granted only to Firebase users whose role is marked as admin or super_admin.',
                            ),
                            const SizedBox(height: 20),
                            TextField(
                              controller: _phoneController,
                              keyboardType: TextInputType.phone,
                              maxLength: 10,
                              decoration: const InputDecoration(
                                labelText: 'Phone number',
                                prefixText: '+91 ',
                                counterText: '',
                              ),
                            ),
                            const SizedBox(height: 12),
                            if (_otpSent) ...[
                              TextField(
                                controller: _otpController,
                                keyboardType: TextInputType.number,
                                maxLength: 6,
                                decoration: const InputDecoration(
                                  labelText: 'OTP',
                                  counterText: '',
                                ),
                              ),
                              const SizedBox(height: 12),
                            ],
                            SizedBox(
                              width: double.infinity,
                              child: FilledButton(
                                onPressed: auth.isBusy
                                    ? null
                                    : (_otpSent ? _verifyOtp : _sendOtp),
                                child: Text(
                                  auth.isBusy
                                      ? 'Please wait...'
                                      : (_otpSent ? 'Verify OTP' : 'Send OTP'),
                                ),
                              ),
                            ),
                            if (_otpSent)
                              Align(
                                alignment: Alignment.centerLeft,
                                child: TextButton(
                                  onPressed: auth.isBusy
                                      ? null
                                      : () => setState(() => _otpSent = false),
                                  child: const Text('Change number'),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _AdminAccessPendingScreen extends StatelessWidget {
  const _AdminAccessPendingScreen();

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthService>();
    final user = auth.currentUser;
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Scaffold(
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(16, 24, 16, 24 + bottomInset),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: constraints.maxHeight - 48,
                ),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 520),
                    child: Card(
                      margin: const EdgeInsets.all(8),
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Access pending',
                              style: Theme.of(context).textTheme.headlineSmall
                                  ?.copyWith(fontWeight: FontWeight.w800),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Signed in as +91 ${user?.phone ?? ''}, but this account is not marked as admin yet. Update the user role in Firestore to continue.',
                            ),
                            const SizedBox(height: 20),
                            Wrap(
                              spacing: 12,
                              runSpacing: 12,
                              children: [
                                FilledButton.tonal(
                                  onPressed: auth.isBusy
                                      ? null
                                      : () => context
                                            .read<AuthService>()
                                            .refreshCurrentUser(),
                                  child: const Text('Refresh access'),
                                ),
                                OutlinedButton(
                                  onPressed: auth.isBusy
                                      ? null
                                      : () => context
                                            .read<AuthService>()
                                            .signOut(),
                                  child: const Text('Sign out'),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _AdminSetupRequiredScreen extends StatelessWidget {
  const _AdminSetupRequiredScreen();

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Scaffold(
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(16, 24, 16, 24 + bottomInset),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: constraints.maxHeight - 48,
                ),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 560),
                    child: Card(
                      margin: const EdgeInsets.all(8),
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Firebase setup required',
                              style: Theme.of(context).textTheme.headlineSmall
                                  ?.copyWith(fontWeight: FontWeight.w800),
                            ),
                            const SizedBox(height: 10),
                            const Text(
                              'Add the generated FlutterFire options and platform config files first. Once those files are in place, this admin panel will use live Firebase Auth and Firestore automatically.',
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
