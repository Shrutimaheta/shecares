import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../models/order.dart';
import '../services/auth_service.dart';
import '../utils/app_theme.dart';
import '../utils/constants.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _fullNameController = TextEditingController();
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _phoneController = TextEditingController();
  final _houseController = TextEditingController();
  final _streetController = TextEditingController();
  final _areaController = TextEditingController();
  final _cityController = TextEditingController(text: AppConstants.defaultCity);
  final _pincodeController = TextEditingController();
  final _usernameFocus = FocusNode();
  final _emailFocus = FocusNode();
  final _phoneFocus = FocusNode();

  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _isCheckingAvailability = false;
  String? _usernameAsyncError;
  String? _emailAsyncError;
  String? _phoneAsyncError;

  @override
  void initState() {
    super.initState();
    _usernameFocus.addListener(_handleAvailabilityBlur);
    _emailFocus.addListener(_handleAvailabilityBlur);
    _phoneFocus.addListener(_handleAvailabilityBlur);
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _usernameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _phoneController.dispose();
    _houseController.dispose();
    _streetController.dispose();
    _areaController.dispose();
    _cityController.dispose();
    _pincodeController.dispose();
    _usernameFocus.removeListener(_handleAvailabilityBlur);
    _emailFocus.removeListener(_handleAvailabilityBlur);
    _phoneFocus.removeListener(_handleAvailabilityBlur);
    _usernameFocus.dispose();
    _emailFocus.dispose();
    _phoneFocus.dispose();
    super.dispose();
  }

  void _handleAvailabilityBlur() {
    if (!_usernameFocus.hasFocus &&
        !_emailFocus.hasFocus &&
        !_phoneFocus.hasFocus) {
      _checkAvailability();
    }
  }

  Future<bool> _checkAvailability() async {
    final auth = context.read<AuthService>();
    final username = _usernameController.text.trim();
    final email = _emailController.text.trim();
    final phone = _phoneController.text.trim();
    if (username.isEmpty ||
        email.isEmpty ||
        phone.isEmpty ||
        !auth.isFirebaseMode) {
      return true;
    }

    setState(() => _isCheckingAvailability = true);
    try {
      final availability = await auth.checkRegistrationAvailability(
        username: username,
        email: email,
        phone: phone,
      );
      if (!mounted) {
        return availability.isAvailable;
      }
      setState(() {
        _usernameAsyncError = availability.usernameAvailable
            ? null
            : (availability.usernameMessage ?? 'This username is taken.');
        _emailAsyncError = availability.emailAvailable
            ? null
            : (availability.emailMessage ??
                  'An account with this email already exists.');
        _phoneAsyncError = availability.phoneAvailable
            ? null
            : (availability.phoneMessage ??
                  'This phone number is already linked to another account.');
      });
      return availability.isAvailable;
    } catch (_) {
      return true;
    } finally {
      if (mounted) {
        setState(() => _isCheckingAvailability = false);
      }
    }
  }

  Future<void> _submit() async {
    final form = _formKey.currentState;
    if (form == null || !form.validate()) {
      return;
    }

    final available = await _checkAvailability();
    if (!available) {
      form.validate();
      return;
    }

    final auth = context.read<AuthService>();
    try {
      await auth.registerCustomer(
        CustomerRegistrationData(
          fullName: _fullNameController.text.trim(),
          username: _usernameController.text.trim(),
          email: _emailController.text.trim(),
          password: _passwordController.text,
          phone: _phoneController.text.trim(),
          defaultAddress: DeliveryAddress(
            fullName: _fullNameController.text.trim(),
            phone: _phoneController.text.trim(),
            houseNo: _houseController.text.trim(),
            street: _streetController.text.trim(),
            area: _areaController.text.trim(),
            city: _cityController.text.trim(),
            pincode: _pincodeController.text.trim(),
          ),
        ),
      );
      if (!mounted) {
        return;
      }

      await auth.signOut(clearPendingAction: false);
      if (!mounted) {
        return;
      }

      final shouldLoginNow = await showDialog<bool>(
        context: context,
        builder: (dialogContext) {
          return AlertDialog(
            title: const Text('Registration successful'),
            content: const Text(
              'Successful registration. Do you want to login now?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(false),
                child: const Text('Not now'),
              ),
              FilledButton(
                onPressed: () => Navigator.of(dialogContext).pop(true),
                child: const Text('Login now'),
              ),
            ],
          );
        },
      );

      if (!mounted) {
        return;
      }

      if (shouldLoginNow == true) {
        Navigator.pushNamedAndRemoveUntil(
          context,
          AppRoutes.login,
          (_) => false,
        );
      } else {
        Navigator.pushNamedAndRemoveUntil(
          context,
          AppRoutes.home,
          (_) => false,
        );
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Registration successful. Please login to continue.'),
          ),
        );
      }
    } catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error.toString().replaceFirst('Exception: ', '')),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthService>();

    return Scaffold(
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFFFFCFA), Color(0xFFFCECF0), Color(0xFFF8F2EE)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1180),
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final wide = constraints.maxWidth >= 980;
                    return Flex(
                      direction: wide ? Axis.horizontal : Axis.vertical,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Flexible(
                          flex: wide ? 5 : 0,
                          fit: wide ? FlexFit.tight : FlexFit.loose,
                          child: _RegisterHero(wide: wide),
                        ),
                        SizedBox(width: wide ? 28 : 0, height: wide ? 0 : 24),
                        Flexible(
                          flex: wide ? 6 : 0,
                          fit: wide ? FlexFit.tight : FlexFit.loose,
                          child: Card(
                            margin: EdgeInsets.zero,
                            child: Padding(
                              padding: const EdgeInsets.all(24),
                              child: Form(
                                key: _formKey,
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Create your account',
                                      style: Theme.of(context)
                                          .textTheme
                                          .headlineMedium
                                          ?.copyWith(
                                            fontWeight: FontWeight.w900,
                                            color: AppColors.ink,
                                          ),
                                    ),
                                    const SizedBox(height: 10),
                                    Text(
                                      'Register once so your address, profile, and order history are ready whenever you need a fast reorder.',
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodyLarge
                                          ?.copyWith(
                                            color: AppColors.slate,
                                            height: 1.45,
                                          ),
                                    ),
                                    const SizedBox(height: 20),
                                    TextFormField(
                                      controller: _fullNameController,
                                      textInputAction: TextInputAction.next,
                                      decoration: const InputDecoration(
                                        labelText: 'Full name',
                                        prefixIcon: Icon(Icons.badge_outlined),
                                      ),
                                      validator: (value) =>
                                          (value ?? '').trim().length < 2
                                          ? 'Full name must be at least 2 characters.'
                                          : null,
                                    ),
                                    const SizedBox(height: 12),
                                    TextFormField(
                                      controller: _usernameController,
                                      focusNode: _usernameFocus,
                                      textInputAction: TextInputAction.next,
                                      decoration: InputDecoration(
                                        labelText: 'Username',
                                        prefixIcon: const Icon(
                                          Icons.alternate_email,
                                        ),
                                        helperText:
                                            '3-20 letters, numbers, or underscores',
                                        errorText: _usernameAsyncError,
                                        suffixIcon: _isCheckingAvailability
                                            ? const Padding(
                                                padding: EdgeInsets.all(14),
                                                child: SizedBox(
                                                  width: 16,
                                                  height: 16,
                                                  child:
                                                      CircularProgressIndicator(
                                                        strokeWidth: 2,
                                                      ),
                                                ),
                                              )
                                            : null,
                                      ),
                                      onChanged: (_) {
                                        if (_usernameAsyncError != null) {
                                          setState(
                                            () => _usernameAsyncError = null,
                                          );
                                        }
                                      },
                                      validator: (value) {
                                        final username = (value ?? '').trim();
                                        if (username.length < 3 ||
                                            username.length > 20) {
                                          return 'Username must be 3-20 characters.';
                                        }
                                        if (!RegExp(
                                          r'^[A-Za-z0-9_]+$',
                                        ).hasMatch(username)) {
                                          return 'Only letters, numbers, and underscores are allowed.';
                                        }
                                        if (AppConstants.reservedUsernames
                                            .contains(username.toLowerCase())) {
                                          return 'This username is reserved.';
                                        }
                                        return _usernameAsyncError;
                                      },
                                    ),
                                    const SizedBox(height: 12),
                                    TextFormField(
                                      controller: _emailController,
                                      focusNode: _emailFocus,
                                      keyboardType: TextInputType.emailAddress,
                                      textInputAction: TextInputAction.next,
                                      decoration: InputDecoration(
                                        labelText: 'Email',
                                        prefixIcon: const Icon(
                                          Icons.mail_outline,
                                        ),
                                        errorText: _emailAsyncError,
                                      ),
                                      onChanged: (_) {
                                        if (_emailAsyncError != null) {
                                          setState(
                                            () => _emailAsyncError = null,
                                          );
                                        }
                                      },
                                      validator: (value) {
                                        final email = (value ?? '').trim();
                                        if (!RegExp(
                                          r'^[^@\s]+@[^@\s]+\.[^@\s]+$',
                                        ).hasMatch(email)) {
                                          return 'Enter a valid email address.';
                                        }
                                        return _emailAsyncError;
                                      },
                                    ),
                                    const SizedBox(height: 12),
                                    TextFormField(
                                      controller: _passwordController,
                                      obscureText: _obscurePassword,
                                      textInputAction: TextInputAction.next,
                                      decoration: InputDecoration(
                                        labelText: 'Password',
                                        prefixIcon: const Icon(
                                          Icons.lock_outline,
                                        ),
                                        suffixIcon: IconButton(
                                          onPressed: () => setState(
                                            () => _obscurePassword =
                                                !_obscurePassword,
                                          ),
                                          icon: Icon(
                                            _obscurePassword
                                                ? Icons.visibility_outlined
                                                : Icons.visibility_off_outlined,
                                          ),
                                        ),
                                      ),
                                      validator: (value) {
                                        final password = value ?? '';
                                        if (password.length < 8) {
                                          return 'Password must be at least 8 characters.';
                                        }
                                        if (!RegExp(
                                              r'[A-Za-z]',
                                            ).hasMatch(password) ||
                                            !RegExp(
                                              r'[0-9]',
                                            ).hasMatch(password)) {
                                          return 'Use at least one letter and one number.';
                                        }
                                        return null;
                                      },
                                    ),
                                    const SizedBox(height: 12),
                                    TextFormField(
                                      controller: _confirmPasswordController,
                                      obscureText: _obscureConfirmPassword,
                                      textInputAction: TextInputAction.next,
                                      decoration: InputDecoration(
                                        labelText: 'Confirm password',
                                        prefixIcon: const Icon(
                                          Icons.lock_reset_outlined,
                                        ),
                                        suffixIcon: IconButton(
                                          onPressed: () => setState(
                                            () => _obscureConfirmPassword =
                                                !_obscureConfirmPassword,
                                          ),
                                          icon: Icon(
                                            _obscureConfirmPassword
                                                ? Icons.visibility_outlined
                                                : Icons.visibility_off_outlined,
                                          ),
                                        ),
                                      ),
                                      validator: (value) =>
                                          value != _passwordController.text
                                          ? 'Passwords do not match.'
                                          : null,
                                    ),
                                    const SizedBox(height: 12),
                                    TextFormField(
                                      controller: _phoneController,
                                      focusNode: _phoneFocus,
                                      keyboardType: TextInputType.phone,
                                      textInputAction: TextInputAction.next,
                                      maxLength: 10,
                                      inputFormatters: [
                                        FilteringTextInputFormatter.digitsOnly,
                                      ],
                                      decoration: InputDecoration(
                                        labelText: 'Phone number',
                                        prefixIcon: const Icon(
                                          Icons.phone_iphone_outlined,
                                        ),
                                        counterText: '',
                                        errorText: _phoneAsyncError,
                                      ),
                                      onChanged: (_) {
                                        if (_phoneAsyncError != null) {
                                          setState(
                                            () => _phoneAsyncError = null,
                                          );
                                        }
                                      },
                                      validator: (value) {
                                        final phone = (value ?? '').trim();
                                        if (!RegExp(
                                          r'^[6-9][0-9]{9}$',
                                        ).hasMatch(phone)) {
                                          return 'Enter a valid 10-digit Indian mobile number.';
                                        }
                                        return _phoneAsyncError;
                                      },
                                    ),
                                    const SizedBox(height: 20),
                                    Text(
                                      'Default delivery address',
                                      style: Theme.of(context)
                                          .textTheme
                                          .titleMedium
                                          ?.copyWith(
                                            fontWeight: FontWeight.w800,
                                          ),
                                    ),
                                    const SizedBox(height: 12),
                                    TextFormField(
                                      controller: _houseController,
                                      decoration: const InputDecoration(
                                        labelText: 'Flat / house number',
                                      ),
                                      validator: (value) =>
                                          (value ?? '').trim().isEmpty
                                          ? 'Enter your flat or house number.'
                                          : null,
                                    ),
                                    const SizedBox(height: 12),
                                    TextFormField(
                                      controller: _streetController,
                                      decoration: const InputDecoration(
                                        labelText: 'Street / society name',
                                      ),
                                      validator: (value) =>
                                          (value ?? '').trim().isEmpty
                                          ? 'Enter your street or society.'
                                          : null,
                                    ),
                                    const SizedBox(height: 12),
                                    TextFormField(
                                      controller: _areaController,
                                      decoration: const InputDecoration(
                                        labelText: 'Area / landmark',
                                      ),
                                      validator: (value) =>
                                          (value ?? '').trim().isEmpty
                                          ? 'Enter your area or landmark.'
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
                                          ? 'Enter your city.'
                                          : null,
                                    ),
                                    const SizedBox(height: 12),
                                    TextFormField(
                                      controller: _pincodeController,
                                      keyboardType: TextInputType.number,
                                      maxLength: 6,
                                      inputFormatters: [
                                        FilteringTextInputFormatter.digitsOnly,
                                      ],
                                      decoration: const InputDecoration(
                                        labelText: 'Pincode',
                                        counterText: '',
                                      ),
                                      validator: (value) {
                                        final pincode = int.tryParse(
                                          (value ?? '').trim(),
                                        );
                                        if (pincode == null) {
                                          return 'Enter a valid 6-digit pincode.';
                                        }
                                        if (pincode <
                                                AppConstants
                                                    .minServicePincode ||
                                            pincode >
                                                AppConstants
                                                    .maxServicePincode) {
                                          return 'We currently deliver only within Ahmedabad.';
                                        }
                                        return null;
                                      },
                                    ),
                                    const SizedBox(height: 20),
                                    SizedBox(
                                      width: double.infinity,
                                      child: FilledButton.icon(
                                        onPressed:
                                            auth.isBusy || !auth.isFirebaseMode
                                            ? null
                                            : _submit,
                                        icon: const Icon(
                                          Icons.person_add_alt_1,
                                        ),
                                        label: Text(
                                          auth.isBusy
                                              ? 'Creating account...'
                                              : 'Register',
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 12),
                                    Center(
                                      child: TextButton(
                                        onPressed: auth.isBusy
                                            ? null
                                            : () => Navigator.pop(context),
                                        child: const Text(
                                          'Already have an account? Login',
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _RegisterHero extends StatelessWidget {
  const _RegisterHero({required this.wide});

  final bool wide;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(right: wide ? 12 : 0, top: wide ? 24 : 0),
      child: Column(
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
              'One registration, smoother reorders forever',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
          const SizedBox(height: 22),
          Text(
            'Save your essentials profile before the first checkout, not during a stressful moment.',
            style: Theme.of(context).textTheme.displaySmall?.copyWith(
              fontWeight: FontWeight.w900,
              height: 1.05,
              color: AppColors.ink,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'We collect the basics up front so your first manual UPI payment, delivery address, and future repeat orders feel quick and trustworthy.',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: AppColors.slate,
              height: 1.45,
            ),
          ),
        ],
      ),
    );
  }
}
