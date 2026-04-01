import '../utils/constants.dart';

class CheckoutSettings {
  const CheckoutSettings({
    required this.manualUpiEnabled,
    required this.upiId,
    required this.payeeName,
    required this.paymentInstructions,
    required this.minimumUtrLength,
    this.qrImagePath,
    this.updatedAt,
    this.updatedBy,
  });

  static const Object _unset = Object();

  final bool manualUpiEnabled;
  final String upiId;
  final String payeeName;
  final String paymentInstructions;
  final int minimumUtrLength;
  final String? qrImagePath;
  final DateTime? updatedAt;
  final String? updatedBy;

  bool get hasQrImage => (qrImagePath ?? '').trim().isNotEmpty;

  factory CheckoutSettings.defaults() {
    return const CheckoutSettings(
      manualUpiEnabled: true,
      upiId: AppConstants.defaultUpiId,
      payeeName: AppConstants.defaultPayeeName,
      paymentInstructions: AppConstants.defaultPaymentInstructions,
      minimumUtrLength: AppConstants.defaultMinimumUtrLength,
      qrImagePath: null,
    );
  }

  CheckoutSettings copyWith({
    bool? manualUpiEnabled,
    String? upiId,
    String? payeeName,
    String? paymentInstructions,
    int? minimumUtrLength,
    Object? qrImagePath = _unset,
    DateTime? updatedAt,
    String? updatedBy,
  }) {
    return CheckoutSettings(
      manualUpiEnabled: manualUpiEnabled ?? this.manualUpiEnabled,
      upiId: upiId ?? this.upiId,
      payeeName: payeeName ?? this.payeeName,
      paymentInstructions: paymentInstructions ?? this.paymentInstructions,
      minimumUtrLength: minimumUtrLength ?? this.minimumUtrLength,
      qrImagePath: identical(qrImagePath, _unset)
          ? this.qrImagePath
          : qrImagePath as String?,
      updatedAt: updatedAt ?? this.updatedAt,
      updatedBy: updatedBy ?? this.updatedBy,
    );
  }

  factory CheckoutSettings.fromMap(Map<String, dynamic> map) {
    final defaults = CheckoutSettings.defaults();
    return CheckoutSettings(
      manualUpiEnabled:
          map['manualUpiEnabled'] as bool? ?? defaults.manualUpiEnabled,
      upiId: map['upiId'] as String? ?? defaults.upiId,
      payeeName: map['payeeName'] as String? ?? defaults.payeeName,
      paymentInstructions:
          map['paymentInstructions'] as String? ?? defaults.paymentInstructions,
      minimumUtrLength:
          map['minimumUtrLength'] as int? ?? defaults.minimumUtrLength,
      qrImagePath: map['qrImagePath'] as String?,
      updatedAt: _dateFromDynamic(map['updatedAt']),
      updatedBy: map['updatedBy'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'manualUpiEnabled': manualUpiEnabled,
      'upiId': upiId,
      'payeeName': payeeName,
      'paymentInstructions': paymentInstructions,
      'minimumUtrLength': minimumUtrLength,
      'qrImagePath': qrImagePath,
      'updatedAt': updatedAt ?? DateTime.now(),
      'updatedBy': updatedBy,
    };
  }
}

DateTime? _dateFromDynamic(dynamic value) {
  if (value is DateTime) {
    return value;
  }

  try {
    return value?.toDate() as DateTime?;
  } catch (_) {
    return null;
  }
}
