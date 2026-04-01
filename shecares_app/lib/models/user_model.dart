import 'package:cloud_firestore/cloud_firestore.dart';

import 'order.dart';

enum UserRole {
  customer,
  admin,
  superAdmin,
  agent;

  String get value {
    switch (this) {
      case UserRole.customer:
        return 'customer';
      case UserRole.admin:
        return 'admin';
      case UserRole.superAdmin:
        return 'super_admin';
      case UserRole.agent:
        return 'agent';
    }
  }

  bool get isAdmin => this == UserRole.admin || this == UserRole.superAdmin;
}

UserRole userRoleFromString(String? value) {
  switch (value) {
    case 'admin':
      return UserRole.admin;
    case 'super_admin':
      return UserRole.superAdmin;
    case 'agent':
      return UserRole.agent;
    case 'customer':
    default:
      return UserRole.customer;
  }
}

class UserModel {
  const UserModel({
    required this.uid,
    required this.phone,
    required this.fullName,
    required this.username,
    required this.usernameLower,
    required this.email,
    required this.languageCode,
    required this.role,
    this.careTargets = const [],
    this.defaultAddress,
    this.fcmToken,
    this.createdAt,
    this.lastLoginAt,
    this.updatedAt,
  });

  final String uid;
  final String phone;
  final String fullName;
  final String username;
  final String usernameLower;
  final String email;
  final String languageCode;
  final UserRole role;
  final List<String> careTargets;
  final DeliveryAddress? defaultAddress;
  final String? fcmToken;
  final DateTime? createdAt;
  final DateTime? lastLoginAt;
  final DateTime? updatedAt;

  String get name => fullName;
  bool get hasDefaultAddress => defaultAddress?.isComplete ?? false;
  bool get isRegistered =>
      fullName.trim().isNotEmpty &&
      username.trim().isNotEmpty &&
      email.trim().isNotEmpty;
  bool get needsProfileSetup => !isRegistered || !hasDefaultAddress;

  UserModel copyWith({
    String? uid,
    String? phone,
    String? fullName,
    String? username,
    String? usernameLower,
    String? email,
    String? languageCode,
    UserRole? role,
    List<String>? careTargets,
    Object? defaultAddress = _unset,
    String? fcmToken,
    DateTime? createdAt,
    DateTime? lastLoginAt,
    DateTime? updatedAt,
  }) {
    return UserModel(
      uid: uid ?? this.uid,
      phone: phone ?? this.phone,
      fullName: fullName ?? this.fullName,
      username: username ?? this.username,
      usernameLower: usernameLower ?? this.usernameLower,
      email: email ?? this.email,
      languageCode: languageCode ?? this.languageCode,
      role: role ?? this.role,
      careTargets: careTargets ?? this.careTargets,
      defaultAddress: identical(defaultAddress, _unset)
          ? this.defaultAddress
          : defaultAddress as DeliveryAddress?,
      fcmToken: fcmToken ?? this.fcmToken,
      createdAt: createdAt ?? this.createdAt,
      lastLoginAt: lastLoginAt ?? this.lastLoginAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  factory UserModel.fromMap(Map<String, dynamic> map, {String? uid}) {
    return UserModel(
      uid: uid ?? map['uid'] as String? ?? '',
      phone: map['phone'] as String? ?? '',
      fullName: map['fullName'] as String? ?? map['name'] as String? ?? '',
      username: map['username'] as String? ?? '',
      usernameLower: map['usernameLower'] as String? ??
          (map['username'] as String? ?? '').toLowerCase(),
      email: map['email'] as String? ?? '',
      languageCode: map['languageCode'] as String? ?? 'en',
      role: userRoleFromString(map['role'] as String?),
      careTargets: List<String>.from(map['careTargets'] as List? ?? []),
      defaultAddress: map['defaultAddress'] is Map
          ? DeliveryAddress.fromMap(
              Map<String, dynamic>.from(map['defaultAddress'] as Map),
            )
          : null,
      fcmToken: map['fcmToken'] as String?,
      createdAt: _dateFromDynamic(map['createdAt']),
      lastLoginAt: _dateFromDynamic(map['lastLoginAt']),
      updatedAt: _dateFromDynamic(map['updatedAt']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'phone': phone,
      'fullName': fullName,
      'name': fullName,
      'username': username,
      'usernameLower': usernameLower,
      'email': email,
      'languageCode': languageCode,
      'role': role.value,
      'careTargets': careTargets,
      'defaultAddress': defaultAddress?.toMap(),
      'fcmToken': fcmToken,
      'createdAt': createdAt ?? DateTime.now(),
      'lastLoginAt': lastLoginAt ?? DateTime.now(),
      'updatedAt': updatedAt ?? DateTime.now(),
    };
  }
}

const Object _unset = Object();

DateTime? _dateFromDynamic(dynamic value) {
  if (value is Timestamp) {
    return value.toDate();
  }
  if (value is DateTime) {
    return value;
  }
  return null;
}
