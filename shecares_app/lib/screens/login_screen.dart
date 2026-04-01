import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../services/auth_service.dart';
import '../utils/app_theme.dart';
import '../utils/auth_gate.dart';
import '../utils/constants.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _identifierController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _identifierController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final identifier = _identifierController.text.trim();
    final password = _passwordController.text;
    if (identifier.isEmpty || password.isEmpty) {
      _showMessage('Enter your email address and password.');
      return;
    }

    final auth = context.read<AuthService>();
    try {
      await auth.loginWithIdentifier(
        identifier: identifier,
        password: password,
      );
      if (!mounted) {
        return;
      }
      await completePendingAuthFlow(context);
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
    if (auth.isSignedIn) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          completePendingAuthFlow(context);
        }
      });
    }

    return Scaffold(
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFFFFCFA), Color(0xFFFDEAF0), Color(0xFFF8F1ED)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final wide = constraints.maxWidth >= 920;
              return Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1120),
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(24),
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        minHeight: constraints.maxHeight - 48,
                      ),
                      child: wide
                          ? Row(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Expanded(flex: 6, child: _LoginHero(wide: wide)),
                                const SizedBox(width: 40),
                                Expanded(
                                  flex: 5,
                                  child: _LoginForm(
                                    identifierController: _identifierController,
                                    passwordController: _passwordController,
                                    obscurePassword: _obscurePassword,
                                    onTogglePassword: () => setState(() => _obscurePassword = !_obscurePassword),
                                    isBusy: auth.isBusy,
                                    isFirebaseMode: auth.isFirebaseMode,
                                    onSubmit: _submit,
                                  ),
                                ),
                              ],
                            )
                          : Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                _LoginHero(wide: wide),
                                const SizedBox(height: 32),
                                _LoginForm(
                                  identifierController: _identifierController,
                                  passwordController: _passwordController,
                                  obscurePassword: _obscurePassword,
                                  onTogglePassword: () => setState(() => _obscurePassword = !_obscurePassword),
                                  isBusy: auth.isBusy,
                                  isFirebaseMode: auth.isFirebaseMode,
                                  onSubmit: _submit,
                                ),
                              ],
                            ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

class _LoginForm extends StatelessWidget {
  const _LoginForm({
    required this.identifierController,
    required this.passwordController,
    required this.obscurePassword,
    required this.onTogglePassword,
    required this.isBusy,
    required this.isFirebaseMode,
    required this.onSubmit,
  });

  final TextEditingController identifierController;
  final TextEditingController passwordController;
  final bool obscurePassword;
  final VoidCallback onTogglePassword;
  final bool isBusy;
  final bool isFirebaseMode;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      elevation: 2,
      shadowColor: Colors.black12,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Welcome back',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.w900,
                    color: AppColors.ink,
                  ),
            ),
            const SizedBox(height: 10),
            Text(
              'Sign in only when you want to add items to cart, check out, or track your orders.',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: AppColors.slate,
                    height: 1.5,
                  ),
            ),
            const SizedBox(height: 32),
            TextField(
              controller: identifierController,
              textInputAction: TextInputAction.next,
              keyboardType: TextInputType.emailAddress,
              autofillHints: const [AutofillHints.email],
              inputFormatters: [FilteringTextInputFormatter.singleLineFormatter],
              decoration: const InputDecoration(
                labelText: 'Email address',
                prefixIcon: Icon(Icons.mail_outline),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: passwordController,
              obscureText: obscurePassword,
              textInputAction: TextInputAction.done,
              autofillHints: const [AutofillHints.password],
              decoration: InputDecoration(
                labelText: 'Password',
                prefixIcon: const Icon(Icons.lock_outline),
                suffixIcon: IconButton(
                  onPressed: onTogglePassword,
                  icon: Icon(
                    obscurePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                  ),
                ),
              ),
              onSubmitted: (_) {
                if (!isBusy) onSubmit();
              },
            ),
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: isBusy ? null : () => Navigator.pushNamed(context, AppRoutes.forgotPassword),
                child: const Text('Forgot password?'),
              ),
            ),
            const SizedBox(height: 16),
            if (!isFirebaseMode) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.secondaryContainer,
                  borderRadius: BorderRadius.circular(18),
                ),
                child: const Text('Firebase is not configured yet. Add your project files before testing live auth.'),
              ),
              const SizedBox(height: 16),
            ],
            SizedBox(
              width: double.infinity,
              height: 54,
              child: FilledButton.icon(
                onPressed: isBusy || !isFirebaseMode ? null : onSubmit,
                icon: isBusy ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Icon(Icons.login_rounded),
                label: Text(isBusy ? 'Signing in...' : 'Login'),
              ),
            ),
            const SizedBox(height: 24),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF7F4),
                borderRadius: BorderRadius.circular(22),
                border: Border.all(color: const Color(0xFFF0D9DF)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('New to SheCares?', style: TextStyle(fontWeight: FontWeight.w800)),
                  const SizedBox(height: 8),
                  const Text('Create your account once to save your delivery address and track orders.'),
                  const SizedBox(height: 16),
                  OutlinedButton.icon(
                    onPressed: isBusy ? null : () => Navigator.pushNamed(context, AppRoutes.register),
                    icon: const Icon(Icons.person_add_alt_1),
                    label: const Text('Create account'),
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

class _LoginHero extends StatelessWidget {
  const _LoginHero({required this.wide});

  final bool wide;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.82),
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: const Color(0xFFF0D4DE)),
          ),
          child: const Text(
            'Browse first. Login only when you are ready to act.',
            style: TextStyle(fontWeight: FontWeight.w700),
          ),
        ),
        const SizedBox(height: 24),
        Text(
          'A calmer storefront for private essentials.',
          style: Theme.of(context).textTheme.displaySmall?.copyWith(
                fontWeight: FontWeight.w900,
                height: 1.1,
                color: AppColors.ink,
              ),
        ),
        const SizedBox(height: 20),
        Text(
          'SheCares lets families browse sanitary pads, baby diapers, and adult care without friction. Sign in only when you want to pay or track an order.',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: AppColors.slate,
                height: 1.5,
              ),
        ),
        const SizedBox(height: 32),
        const Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            _LoginHeroChip(icon: Icons.lock_person_outlined, label: 'Secure login'),
            _LoginHeroChip(icon: Icons.qr_code_2_outlined, label: 'UPI payment'),
            _LoginHeroChip(icon: Icons.local_shipping_outlined, label: 'Live tracking'),
          ],
        ),
      ],
    );
  }
}

class _LoginHeroChip extends StatelessWidget {
  const _LoginHeroChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.9),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: const Color(0xFFEAD6DD)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18, color: AppColors.roseDeep),
          const SizedBox(width: 8),
          Text(label, style: const TextStyle(fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}
