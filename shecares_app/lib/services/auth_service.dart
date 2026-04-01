import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart' hide Order;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import '../models/order.dart';
import '../models/pending_auth_action.dart';
import '../models/user_model.dart';
import 'app_bootstrap.dart';
import 'firestore_service.dart';

class CustomerRegistrationData {
  const CustomerRegistrationData({
    required this.fullName,
    required this.username,
    required this.email,
    required this.password,
    required this.phone,
    required this.defaultAddress,
  });

  final String fullName;
  final String username;
  final String email;
  final String password;
  final String phone;
  final DeliveryAddress defaultAddress;
}

class RegistrationAvailability {
  const RegistrationAvailability({
    required this.usernameAvailable,
    required this.emailAvailable,
    required this.phoneAvailable,
    this.usernameMessage,
    this.emailMessage,
    this.phoneMessage,
  });

  final bool usernameAvailable;
  final bool emailAvailable;
  final bool phoneAvailable;
  final String? usernameMessage;
  final String? emailMessage;
  final String? phoneMessage;

  bool get isAvailable => usernameAvailable && emailAvailable && phoneAvailable;

  factory RegistrationAvailability.available() {
    return const RegistrationAvailability(
      usernameAvailable: true,
      emailAvailable: true,
      phoneAvailable: true,
    );
  }
}

class AuthService extends ChangeNotifier {
  AuthService();

  final FirestoreService _firestoreService = FirestoreService.instance;
  FirebaseAuth? get _firebaseAuth =>
      AppBootstrap.instance.firebaseReady ? FirebaseAuth.instance : null;
  FirebaseFirestore? get _firestore =>
      AppBootstrap.instance.firebaseReady ? FirebaseFirestore.instance : null;

  StreamSubscription<User?>? _authSubscription;
  UserModel? _currentUser;
  String _selectedLanguage = 'en';
  String? _verificationId;
  String? _pendingPhone;
  ConfirmationResult? _confirmationResult;
  int? _resendToken;
  bool _isBusy = false;
  PendingAuthAction? _pendingAction;

  UserModel? get currentUser => _currentUser;
  String get selectedLanguage => _selectedLanguage;
  bool get isSignedIn => _currentUser != null;
  bool get isBusy => _isBusy;
  bool get isFirebaseMode => AppBootstrap.instance.firebaseReady;
  bool get needsProfileSetup => _currentUser?.needsProfileSetup ?? false;
  bool get isAdmin => _currentUser?.role.isAdmin ?? false;
  PendingAuthAction? get pendingAction => _pendingAction;

  CollectionReference<Map<String, dynamic>> get _usersRef =>
      _firestore!.collection('users');

  Future<void> initialize() async {
    if (!isFirebaseMode) {
      return;
    }

    _authSubscription ??= _firebaseAuth!.authStateChanges().listen(
      _handleFirebaseUser,
    );
    await _handleFirebaseUser(_firebaseAuth!.currentUser);
  }

  void setLanguage(String code) {
    _selectedLanguage = code;
    notifyListeners();
  }

  void setPendingAction(PendingAuthAction action) {
    _pendingAction = action;
  }

  PendingAuthAction? consumePendingAction() {
    final action = _pendingAction;
    _pendingAction = null;
    return action;
  }

  /// Client-side availability check using Firestore queries.
  Future<RegistrationAvailability> checkRegistrationAvailability({
    required String username,
    required String email,
    required String phone,
  }) async {
    if (!isFirebaseMode) {
      return RegistrationAvailability.available();
    }

    final normalizedUsername = username.trim().toLowerCase();
    final normalizedEmail = email.trim().toLowerCase();
    final normalizedPhone = _normalizePhone(phone);

    bool usernameAvailable = true;
    bool emailAvailable = true;
    bool phoneAvailable = true;
    String? usernameMessage;
    String? emailMessage;
    String? phoneMessage;

    try {
      // Check username uniqueness
      if (normalizedUsername.isNotEmpty) {
        final usernameSnap = await _usersRef
            .where('usernameLower', isEqualTo: normalizedUsername)
            .limit(1)
            .get();
        if (usernameSnap.docs.isNotEmpty) {
          usernameAvailable = false;
          usernameMessage = 'This username is already taken.';
        }
      }

      // Check email uniqueness
      if (normalizedEmail.isNotEmpty) {
        final emailSnap = await _usersRef
            .where('email', isEqualTo: normalizedEmail)
            .limit(1)
            .get();
        if (emailSnap.docs.isNotEmpty) {
          emailAvailable = false;
          emailMessage = 'An account with this email already exists.';
        }
      }

      // Check phone uniqueness
      if (normalizedPhone.isNotEmpty) {
        final phoneSnap = await _usersRef
            .where('phone', isEqualTo: normalizedPhone)
            .limit(1)
            .get();
        if (phoneSnap.docs.isNotEmpty) {
          phoneAvailable = false;
          phoneMessage =
              'This phone number is already linked to another account.';
        }
      }
    } catch (e) {
      debugPrint('Availability check failed: $e');
      // If the query fails (e.g. missing index), allow registration to proceed
    }

    return RegistrationAvailability(
      usernameAvailable: usernameAvailable,
      emailAvailable: emailAvailable,
      phoneAvailable: phoneAvailable,
      usernameMessage: usernameMessage,
      emailMessage: emailMessage,
      phoneMessage: phoneMessage,
    );
  }

  Future<void> loginWithIdentifier({
    required String identifier,
    required String password,
  }) async {
    _ensureFirebaseMode(
      'Firebase is not configured yet. Add your project files before using password login.',
    );

    _setBusy(true);
    try {
      final email = await _resolveLoginEmail(identifier.trim());
      final result = await _firebaseAuth!.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      await _handleFirebaseUser(result.user);
    } on FirebaseAuthException catch (error) {
      throw Exception(_authErrorMessage(error));
    } finally {
      _setBusy(false);
    }
  }

  /// Client-side registration using Firebase Auth directly.
  Future<void> registerCustomer(CustomerRegistrationData registration) async {
    _ensureFirebaseMode(
      'Firebase is not configured yet. Add your project files before registering new customers.',
    );

    _setBusy(true);
    try {
      final normalizedEmail = registration.email.trim().toLowerCase();
      final normalizedPhone = _normalizePhone(registration.phone);
      final normalizedUsername = registration.username.trim();
      final now = DateTime.now();

      // 1. Create Firebase Auth user
      final credential = await _firebaseAuth!.createUserWithEmailAndPassword(
        email: normalizedEmail,
        password: registration.password,
      );

      final firebaseUser = credential.user;
      if (firebaseUser == null) {
        throw Exception('Account creation failed. Please try again.');
      }

      // 2. Update display name in Firebase Auth
      await firebaseUser.updateDisplayName(registration.fullName.trim());

      // 3. Send email verification
      if (!firebaseUser.emailVerified) {
        unawaited(firebaseUser.sendEmailVerification());
      }

      // 4. Save full profile to Firestore
      final profile = UserModel(
        uid: firebaseUser.uid,
        phone: normalizedPhone,
        fullName: registration.fullName.trim(),
        username: normalizedUsername,
        usernameLower: normalizedUsername.toLowerCase(),
        email: normalizedEmail,
        languageCode: _selectedLanguage,
        role: UserRole.customer,
        defaultAddress: registration.defaultAddress,
        createdAt: now,
        updatedAt: now,
        lastLoginAt: now,
      );

      await _firestoreService.saveUser(profile);
      _currentUser = profile;
      _selectedLanguage = profile.languageCode;
      notifyListeners();
    } on FirebaseAuthException catch (error) {
      throw Exception(_authErrorMessage(error));
    } finally {
      _setBusy(false);
    }
  }

  Future<void> sendPasswordReset(String identifier) async {
    _ensureFirebaseMode(
      'Firebase is not configured yet. Add your project files before using password reset.',
    );

    _setBusy(true);
    try {
      final email = await _resolveLoginEmail(identifier.trim());
      await _firebaseAuth!.sendPasswordResetEmail(email: email);
    } on FirebaseAuthException catch (error) {
      throw Exception(_authErrorMessage(error));
    } finally {
      _setBusy(false);
    }
  }

  Future<void> sendOtp(String phone) async {
    final normalizedPhone = _normalizePhone(phone);
    if (normalizedPhone.length != 10) {
      throw Exception('Phone number must be 10 digits.');
    }
    _ensureFirebaseMode(
      'Firebase is not configured yet. Add your project files before using phone login.',
    );

    _pendingPhone = normalizedPhone;
    _verificationId = null;
    _confirmationResult = null;
    _setBusy(true);

    try {
      if (kIsWeb) {
        _confirmationResult = await _firebaseAuth!.signInWithPhoneNumber(
          '+91$normalizedPhone',
        );
        return;
      }

      final completer = Completer<void>();

      await _firebaseAuth!.verifyPhoneNumber(
        phoneNumber: '+91$normalizedPhone',
        forceResendingToken: _resendToken,
        verificationCompleted: (credential) async {
          await _firebaseAuth!.signInWithCredential(credential);
          if (!completer.isCompleted) {
            completer.complete();
          }
        },
        verificationFailed: (exception) {
          if (!completer.isCompleted) {
            completer.completeError(exception);
          }
        },
        codeSent: (verificationId, resendToken) {
          _verificationId = verificationId;
          _resendToken = resendToken;
          if (!completer.isCompleted) {
            completer.complete();
          }
        },
        codeAutoRetrievalTimeout: (verificationId) {
          _verificationId = verificationId;
        },
      );

      await completer.future;
    } finally {
      _setBusy(false);
    }
  }

  Future<void> verifyOtp(String otp) async {
    if ((_pendingPhone ?? '').isEmpty) {
      throw Exception('Please request an OTP first.');
    }
    if (otp.trim().length != 6) {
      throw Exception('OTP must be 6 digits.');
    }
    _ensureFirebaseMode(
      'Firebase is not configured yet. Add your project files before using phone login.',
    );

    _setBusy(true);
    try {
      if (kIsWeb) {
        final confirmationResult = _confirmationResult;
        if (confirmationResult == null) {
          throw Exception(
            'Please request a fresh OTP for this browser session.',
          );
        }

        final result = await confirmationResult.confirm(otp.trim());
        await _handleFirebaseUser(result.user);
        return;
      }

      if ((_verificationId ?? '').isEmpty) {
        throw Exception('Please request a fresh OTP.');
      }

      final credential = PhoneAuthProvider.credential(
        verificationId: _verificationId!,
        smsCode: otp.trim(),
      );

      final result = await _firebaseAuth!.signInWithCredential(credential);
      await _handleFirebaseUser(result.user);
    } finally {
      _setBusy(false);
    }
  }

  Future<void> saveCustomerProfile({
    String? fullName,
    String? phone,
    List<String>? careTargets,
    DeliveryAddress? defaultAddress,
  }) async {
    final user = _currentUser;
    if (user == null) {
      throw Exception('No signed-in user found.');
    }

    final updated = user.copyWith(
      fullName: fullName?.trim().isNotEmpty == true
          ? fullName!.trim()
          : user.fullName,
      phone: phone?.trim().isNotEmpty == true
          ? _normalizePhone(phone!)
          : user.phone,
      careTargets: careTargets ?? user.careTargets,
      defaultAddress: defaultAddress ?? user.defaultAddress,
      updatedAt: DateTime.now(),
    );

    await _firestoreService.saveUser(updated);
    _currentUser = updated;
    notifyListeners();
  }

  Future<void> updateFcmToken(String token) async {
    final user = _currentUser;
    if (user == null || token.isEmpty) {
      return;
    }

    final updated = user.copyWith(fcmToken: token, updatedAt: DateTime.now());
    await _firestoreService.saveUser(updated);
    _currentUser = updated;
    notifyListeners();
  }

  Future<void> refreshCurrentUser() async {
    final firebaseUser = _firebaseAuth?.currentUser;
    if (firebaseUser == null) {
      return;
    }
    await _handleFirebaseUser(firebaseUser);
  }

  Future<void> signOut({bool clearPendingAction = true}) async {
    await _firebaseAuth?.signOut();
    _currentUser = null;
    _verificationId = null;
    _pendingPhone = null;
    _confirmationResult = null;
    if (clearPendingAction) {
      _pendingAction = null;
    }
    notifyListeners();
  }

  Future<void> _handleFirebaseUser(User? user) async {
    if (user == null) {
      _currentUser = null;
      notifyListeners();
      return;
    }

    final existing = await _firestoreService.getUser(user.uid);
    final normalizedPhone = _normalizePhone(
      user.phoneNumber ?? existing?.phone ?? '',
    );
    final now = DateTime.now();

    final profile =
        (existing ??
                UserModel(
                  uid: user.uid,
                  phone: normalizedPhone,
                  fullName: user.displayName ?? '',
                  username: '',
                  usernameLower: '',
                  email: user.email?.trim().toLowerCase() ?? '',
                  languageCode: _selectedLanguage,
                  role: UserRole.customer,
                  createdAt: now,
                  updatedAt: now,
                  lastLoginAt: now,
                ))
            .copyWith(
              phone: normalizedPhone.isNotEmpty
                  ? normalizedPhone
                  : existing?.phone ?? '',
              fullName: (existing?.fullName.isNotEmpty ?? false)
                  ? existing!.fullName
                  : (user.displayName ?? ''),
              email: user.email?.trim().toLowerCase() ?? existing?.email ?? '',
              languageCode: existing?.languageCode ?? _selectedLanguage,
              lastLoginAt: now,
              updatedAt: now,
            );

    await _firestoreService.saveUser(profile);
    _selectedLanguage = profile.languageCode;
    _currentUser = profile;
    notifyListeners();
  }

  /// Client-side login email resolution using Firestore queries.
  /// Supports login by email, username, or phone number.
  Future<String> _resolveLoginEmail(String identifier) async {
    final trimmed = identifier.trim();

    // If it looks like an email, return directly
    if (trimmed.contains('@')) {
      return trimmed.toLowerCase();
    }

    // Try to resolve by username
    final byUsername = await _usersRef
        .where('usernameLower', isEqualTo: trimmed.toLowerCase())
        .limit(1)
        .get();
    if (byUsername.docs.isNotEmpty) {
      final email = byUsername.docs.first.data()['email'] as String?;
      if (email != null && email.isNotEmpty) {
        return email.trim().toLowerCase();
      }
    }

    // Try to resolve by phone
    final normalizedPhone = _normalizePhone(trimmed);
    if (normalizedPhone.length == 10) {
      final byPhone = await _usersRef
          .where('phone', isEqualTo: normalizedPhone)
          .limit(1)
          .get();
      if (byPhone.docs.isNotEmpty) {
        final email = byPhone.docs.first.data()['email'] as String?;
        if (email != null && email.isNotEmpty) {
          return email.trim().toLowerCase();
        }
      }
    }

    throw Exception(
      'We could not find an account with that username or phone number.',
    );
  }

  void _ensureFirebaseMode(String message) {
    if (!isFirebaseMode) {
      throw Exception(message);
    }
  }

  String _normalizePhone(String input) {
    final digits = input.replaceAll(RegExp(r'\D'), '');
    if (digits.length > 10) {
      return digits.substring(digits.length - 10);
    }
    return digits;
  }

  String _authErrorMessage(FirebaseAuthException error) {
    switch (error.code) {
      case 'invalid-credential':
      case 'wrong-password':
      case 'user-not-found':
        return 'Incorrect login details. Please try again.';
      case 'email-already-in-use':
        return 'An account with this email already exists. Try logging in instead.';
      case 'weak-password':
        return 'Password is too weak. Use at least 8 characters.';
      case 'too-many-requests':
        return 'Too many attempts. Please wait a moment and try again.';
      default:
        return error.message ?? 'Something went wrong. Please try again.';
    }
  }

  void _setBusy(bool value) {
    _isBusy = value;
    notifyListeners();
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    super.dispose();
  }
}
