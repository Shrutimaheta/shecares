import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/order.dart';
import '../services/auth_service.dart';
import '../utils/constants.dart';
import '../widgets/app_bottom_nav.dart';
import '../widgets/app_main_menu.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _fullNameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _houseController = TextEditingController();
  final _streetController = TextEditingController();
  final _areaController = TextEditingController();
  final _cityController = TextEditingController(text: AppConstants.defaultCity);
  final _pincodeController = TextEditingController();

  bool _isEditing = false;
  bool _isSaving = false;

  @override
  void dispose() {
    _fullNameController.dispose();
    _phoneController.dispose();
    _houseController.dispose();
    _streetController.dispose();
    _areaController.dispose();
    _cityController.dispose();
    _pincodeController.dispose();
    super.dispose();
  }

  void _syncControllersFromUser(AuthService auth) {
    final user = auth.currentUser;
    if (user == null) {
      return;
    }
    final address = user.defaultAddress;
    _fullNameController.text = user.fullName;
    _phoneController.text = user.phone;
    _houseController.text = address?.houseNo ?? '';
    _streetController.text = address?.street ?? '';
    _areaController.text = address?.area ?? '';
    _cityController.text = address?.city ?? AppConstants.defaultCity;
    _pincodeController.text = address?.pincode ?? '';
  }

  Future<void> _saveProfile() async {
    final form = _formKey.currentState;
    if (form == null || !form.validate()) {
      return;
    }

    final auth = context.read<AuthService>();
    final updatedAddress = DeliveryAddress(
      fullName: _fullNameController.text.trim(),
      phone: _phoneController.text.trim(),
      houseNo: _houseController.text.trim(),
      street: _streetController.text.trim(),
      area: _areaController.text.trim(),
      city: _cityController.text.trim(),
      pincode: _pincodeController.text.trim(),
    );

    setState(() => _isSaving = true);
    try {
      await auth.saveCustomerProfile(
        fullName: _fullNameController.text.trim(),
        phone: _phoneController.text.trim(),
        defaultAddress: updatedAddress,
      );
      if (!mounted) {
        return;
      }
      setState(() => _isEditing = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile updated successfully.')),
      );
    } catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error.toString().replaceFirst('Exception: ', '')),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  Future<void> _signOut() async {
    final confirmed =
        await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Sign out'),
            content: const Text('Do you want to sign out from SheCares?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Sign out'),
              ),
            ],
          ),
        ) ??
        false;

    if (!confirmed || !mounted) {
      return;
    }

    await context.read<AuthService>().signOut();
    if (!mounted) {
      return;
    }
    Navigator.pushNamedAndRemoveUntil(context, AppRoutes.login, (_) => false);
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthService>();
    final user = auth.currentUser;
    if (user != null && !_isEditing) {
      _syncControllersFromUser(auth);
    }

    final initials = (user?.fullName.isNotEmpty ?? false)
        ? user!.fullName
              .split(' ')
              .map((part) => part[0])
              .take(2)
              .join()
              .toUpperCase()
        : 'SC';

    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      drawer: const AppMainMenu(currentRoute: AppRoutes.profile),
      bottomNavigationBar: const AppBottomNav(selectedIndex: 3),
      body: user == null
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            CircleAvatar(radius: 28, child: Text(initials)),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Text(
                                _isEditing
                                    ? 'Edit profile details'
                                    : (user.fullName.isNotEmpty
                                          ? user.fullName
                                          : 'SheCares customer'),
                                style: Theme.of(context).textTheme.titleLarge,
                              ),
                            ),
                            if (!_isEditing)
                              TextButton.icon(
                                onPressed: () {
                                  _syncControllersFromUser(auth);
                                  setState(() => _isEditing = true);
                                },
                                icon: const Icon(Icons.edit_outlined),
                                label: const Text('Edit'),
                              ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        if (!_isEditing) ...[
                          _InfoLine(
                            label: 'Email',
                            value: user.email.isNotEmpty
                                ? user.email
                                : 'Not set',
                          ),
                          _InfoLine(
                            label: 'Username',
                            value: user.username.isNotEmpty
                                ? '@${user.username}'
                                : 'Not set',
                          ),
                          _InfoLine(
                            label: 'Full name',
                            value: user.fullName.isNotEmpty
                                ? user.fullName
                                : 'Not set',
                          ),
                          _InfoLine(
                            label: 'Phone',
                            value: user.phone.isNotEmpty
                                ? '+91 ${user.phone}'
                                : 'Not set',
                          ),
                          _InfoLine(
                            label: 'Default address',
                            value: user.defaultAddress?.formatted ?? 'Not set',
                          ),
                        ] else
                          Form(
                            key: _formKey,
                            child: Column(
                              children: [
                                TextFormField(
                                  controller: _fullNameController,
                                  decoration: const InputDecoration(
                                    labelText: 'Full name',
                                  ),
                                  validator: (value) =>
                                      (value ?? '').trim().length < 2
                                      ? 'Please enter your full name.'
                                      : null,
                                ),
                                const SizedBox(height: 12),
                                TextFormField(
                                  initialValue: user.email,
                                  enabled: false,
                                  decoration: const InputDecoration(
                                    labelText: 'Email (cannot be changed here)',
                                  ),
                                ),
                                const SizedBox(height: 12),
                                TextFormField(
                                  initialValue: user.username,
                                  enabled: false,
                                  decoration: const InputDecoration(
                                    labelText:
                                        'Username (cannot be changed here)',
                                  ),
                                ),
                                const SizedBox(height: 12),
                                TextFormField(
                                  controller: _phoneController,
                                  keyboardType: TextInputType.phone,
                                  maxLength: 10,
                                  decoration: const InputDecoration(
                                    labelText: 'Phone number',
                                    counterText: '',
                                  ),
                                  validator: (value) {
                                    final phone = (value ?? '').trim();
                                    if (!RegExp(
                                      r'^[6-9][0-9]{9}$',
                                    ).hasMatch(phone)) {
                                      return 'Enter a valid 10-digit Indian mobile number.';
                                    }
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 12),
                                TextFormField(
                                  controller: _houseController,
                                  decoration: const InputDecoration(
                                    labelText: 'Flat or house number',
                                  ),
                                  validator: (value) =>
                                      (value ?? '').trim().isEmpty
                                      ? 'Please enter your house or flat number.'
                                      : null,
                                ),
                                const SizedBox(height: 12),
                                TextFormField(
                                  controller: _streetController,
                                  decoration: const InputDecoration(
                                    labelText: 'Street or society',
                                  ),
                                  validator: (value) =>
                                      (value ?? '').trim().isEmpty
                                      ? 'Please enter your street or society.'
                                      : null,
                                ),
                                const SizedBox(height: 12),
                                TextFormField(
                                  controller: _areaController,
                                  decoration: const InputDecoration(
                                    labelText: 'Area or landmark',
                                  ),
                                  validator: (value) =>
                                      (value ?? '').trim().isEmpty
                                      ? 'Please enter your area or landmark.'
                                      : null,
                                ),
                                const SizedBox(height: 12),
                                TextFormField(
                                  controller: _cityController,
                                  decoration: const InputDecoration(
                                    labelText: 'City',
                                  ),
                                  validator: (value) =>
                                      (value ?? '').trim().isEmpty
                                      ? 'Please enter your city.'
                                      : null,
                                ),
                                const SizedBox(height: 12),
                                TextFormField(
                                  controller: _pincodeController,
                                  keyboardType: TextInputType.number,
                                  maxLength: 6,
                                  decoration: const InputDecoration(
                                    labelText: 'Pincode',
                                    counterText: '',
                                  ),
                                  validator: (value) {
                                    final pincode = int.tryParse(
                                      (value ?? '').trim(),
                                    );
                                    if (pincode == null) {
                                      return 'Pincode must be 6 digits.';
                                    }
                                    if (pincode <
                                            AppConstants.minServicePincode ||
                                        pincode >
                                            AppConstants.maxServicePincode) {
                                      return 'Sorry, we currently deliver only within Ahmedabad.';
                                    }
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    Expanded(
                                      child: OutlinedButton(
                                        onPressed: _isSaving
                                            ? null
                                            : () {
                                                _syncControllersFromUser(auth);
                                                setState(
                                                  () => _isEditing = false,
                                                );
                                              },
                                        child: const Text('Cancel'),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: FilledButton(
                                        onPressed: _isSaving
                                            ? null
                                            : _saveProfile,
                                        child: Text(
                                          _isSaving
                                              ? 'Saving...'
                                              : 'Save changes',
                                        ),
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
                ),
                const SizedBox(height: 12),
                ListTile(
                  leading: const Icon(Icons.receipt_long_outlined),
                  title: const Text('My orders'),
                  subtitle: const Text('Track current and past deliveries'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () =>
                      Navigator.pushReplacementNamed(context, AppRoutes.orders),
                ),
                if (user.role.isAdmin)
                  ListTile(
                    leading: const Icon(Icons.admin_panel_settings_outlined),
                    title: const Text('Admin panel'),
                    subtitle: const Text('Open operations dashboard'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => Navigator.pushNamed(context, AppRoutes.admin),
                  ),
                ListTile(
                  leading: const Icon(Icons.language_outlined),
                  title: const Text('Language preference'),
                  subtitle: Text(
                    'Saved as ${auth.selectedLanguage.toUpperCase()}',
                  ),
                ),
                const SizedBox(height: 16),
                FilledButton.tonal(
                  onPressed: _signOut,
                  child: const Text('Sign out'),
                ),
              ],
            ),
    );
  }
}

class _InfoLine extends StatelessWidget {
  const _InfoLine({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: const Color(0xFF7A676F),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}
