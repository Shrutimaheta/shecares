import 'package:cloud_firestore/cloud_firestore.dart';

import 'cart_item.dart';

enum OrderStatus {
  awaitingConfirmation,
  confirmed,
  preparing,
  outForDelivery,
  delivered,
  cancelled,
}

extension OrderStatusX on OrderStatus {
  String get value {
    switch (this) {
      case OrderStatus.awaitingConfirmation:
        return 'awaiting_confirmation';
      case OrderStatus.confirmed:
        return 'confirmed';
      case OrderStatus.preparing:
        return 'preparing';
      case OrderStatus.outForDelivery:
        return 'out_for_delivery';
      case OrderStatus.delivered:
        return 'delivered';
      case OrderStatus.cancelled:
        return 'cancelled';
    }
  }

  String get label {
    switch (this) {
      case OrderStatus.awaitingConfirmation:
        return 'Awaiting Confirmation';
      case OrderStatus.confirmed:
        return 'Confirmed';
      case OrderStatus.preparing:
        return 'Preparing';
      case OrderStatus.outForDelivery:
        return 'Out for Delivery';
      case OrderStatus.delivered:
        return 'Delivered';
      case OrderStatus.cancelled:
        return 'Cancelled';
    }
  }
}

OrderStatus orderStatusFromString(String? value) {
  switch (value) {
    case 'confirmed':
      return OrderStatus.confirmed;
    case 'preparing':
      return OrderStatus.preparing;
    case 'out_for_delivery':
      return OrderStatus.outForDelivery;
    case 'delivered':
      return OrderStatus.delivered;
    case 'cancelled':
      return OrderStatus.cancelled;
    case 'placed':
    case 'awaiting_confirmation':
    default:
      return OrderStatus.awaitingConfirmation;
  }
}

enum PaymentStatus { submitted, verified, rejected }

extension PaymentStatusX on PaymentStatus {
  String get value {
    switch (this) {
      case PaymentStatus.submitted:
        return 'submitted';
      case PaymentStatus.verified:
        return 'verified';
      case PaymentStatus.rejected:
        return 'rejected';
    }
  }

  String get label {
    switch (this) {
      case PaymentStatus.submitted:
        return 'Payment Review Pending';
      case PaymentStatus.verified:
        return 'Payment Verified';
      case PaymentStatus.rejected:
        return 'Payment Rejected';
    }
  }
}

PaymentStatus paymentStatusFromString(String? value) {
  switch (value) {
    case 'verified':
      return PaymentStatus.verified;
    case 'rejected':
      return PaymentStatus.rejected;
    case 'submitted':
    default:
      return PaymentStatus.submitted;
  }
}

enum PaymentProvider { manualUpi, cod }

extension PaymentProviderX on PaymentProvider {
  String get value {
    switch (this) {
      case PaymentProvider.manualUpi:
        return 'manual_upi';
      case PaymentProvider.cod:
        return 'cod';
    }
  }

  String get label {
    switch (this) {
      case PaymentProvider.manualUpi:
        return 'Manual UPI';
      case PaymentProvider.cod:
        return 'Cash on Delivery';
    }
  }
}

PaymentProvider paymentProviderFromString(String? value) {
  switch (value) {
    case 'cod':
      return PaymentProvider.cod;
    case 'card':
    case 'upi':
    case 'manual_upi':
    default:
      return PaymentProvider.manualUpi;
  }
}

class DeliveryAddress {
  const DeliveryAddress({
    required this.fullName,
    required this.phone,
    required this.houseNo,
    required this.street,
    required this.area,
    required this.city,
    required this.pincode,
  });

  final String fullName;
  final String phone;
  final String houseNo;
  final String street;
  final String area;
  final String city;
  final String pincode;

  bool get isComplete =>
      fullName.trim().isNotEmpty &&
      phone.trim().isNotEmpty &&
      houseNo.trim().isNotEmpty &&
      street.trim().isNotEmpty &&
      area.trim().isNotEmpty &&
      city.trim().isNotEmpty &&
      pincode.trim().isNotEmpty;

  String get formatted => '$houseNo, $street, $area, $city - $pincode';

  DeliveryAddress copyWith({
    String? fullName,
    String? phone,
    String? houseNo,
    String? street,
    String? area,
    String? city,
    String? pincode,
  }) {
    return DeliveryAddress(
      fullName: fullName ?? this.fullName,
      phone: phone ?? this.phone,
      houseNo: houseNo ?? this.houseNo,
      street: street ?? this.street,
      area: area ?? this.area,
      city: city ?? this.city,
      pincode: pincode ?? this.pincode,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'fullName': fullName,
      'phone': phone,
      'houseNo': houseNo,
      'street': street,
      'area': area,
      'city': city,
      'pincode': pincode,
    };
  }

  factory DeliveryAddress.fromMap(Map<String, dynamic> map) {
    return DeliveryAddress(
      fullName: map['fullName'] as String? ?? map['name'] as String? ?? '',
      phone: map['phone'] as String? ?? '',
      houseNo: map['houseNo'] as String? ?? map['flatNo'] as String? ?? '',
      street: map['street'] as String? ?? '',
      area: map['area'] as String? ?? '',
      city: map['city'] as String? ?? '',
      pincode: map['pincode'] as String? ?? '',
    );
  }
}

class PaymentSnapshot {
  const PaymentSnapshot({
    required this.upiId,
    required this.payeeName,
    required this.qrImagePath,
    required this.instructions,
  });

  static const Object _unset = Object();

  final String upiId;
  final String payeeName;
  final String? qrImagePath;
  final String instructions;

  PaymentSnapshot copyWith({
    String? upiId,
    String? payeeName,
    Object? qrImagePath = _unset,
    String? instructions,
  }) {
    return PaymentSnapshot(
      upiId: upiId ?? this.upiId,
      payeeName: payeeName ?? this.payeeName,
      qrImagePath: identical(qrImagePath, _unset)
          ? this.qrImagePath
          : qrImagePath as String?,
      instructions: instructions ?? this.instructions,
    );
  }

  factory PaymentSnapshot.fromMap(Map<String, dynamic> map) {
    return PaymentSnapshot(
      upiId: map['upiId'] as String? ?? '',
      payeeName: map['payeeName'] as String? ?? '',
      qrImagePath: map['qrImagePath'] as String?,
      instructions: map['instructions'] as String? ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'upiId': upiId,
      'payeeName': payeeName,
      'qrImagePath': qrImagePath,
      'instructions': instructions,
    };
  }
}

class Order {
  const Order({
    required this.docId,
    required this.orderId,
    required this.userId,
    required this.items,
    required this.address,
    required this.status,
    required this.paymentStatus,
    required this.paymentProvider,
    required this.subtotal,
    required this.deliveryFee,
    required this.emergencyFee,
    required this.totalAmount,
    required this.isDiscreet,
    required this.doNotRingBell,
    required this.isEmergency,
    required this.createdAt,
    required this.updatedAt,
    this.etaLabel,
    this.deliverySlot,
    this.customerNote,
    this.paymentUtr,
    this.paymentSubmittedAt,
    this.paymentSnapshot,
    this.paymentVerifiedAt,
    this.paymentVerifiedBy,
    this.paymentRejectedReason,
    this.cancellationReason,
    this.assignedAgentId,
  });

  static const Object _unset = Object();

  final String docId;
  final String orderId;
  final String userId;
  final List<CartItem> items;
  final DeliveryAddress address;
  final OrderStatus status;
  final PaymentStatus paymentStatus;
  final PaymentProvider paymentProvider;
  final double subtotal;
  final double deliveryFee;
  final double emergencyFee;
  final double totalAmount;
  final bool isDiscreet;
  final bool doNotRingBell;
  final bool isEmergency;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? etaLabel;
  final String? deliverySlot;
  final String? customerNote;
  final String? paymentUtr;
  final DateTime? paymentSubmittedAt;
  final PaymentSnapshot? paymentSnapshot;
  final DateTime? paymentVerifiedAt;
  final String? paymentVerifiedBy;
  final String? paymentRejectedReason;
  final String? cancellationReason;
  final String? assignedAgentId;

  bool get isPendingPaymentReview =>
      status == OrderStatus.awaitingConfirmation &&
      paymentStatus == PaymentStatus.submitted;

  Order copyWith({
    String? docId,
    String? orderId,
    String? userId,
    List<CartItem>? items,
    DeliveryAddress? address,
    OrderStatus? status,
    PaymentStatus? paymentStatus,
    PaymentProvider? paymentProvider,
    double? subtotal,
    double? deliveryFee,
    double? emergencyFee,
    double? totalAmount,
    bool? isDiscreet,
    bool? doNotRingBell,
    bool? isEmergency,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? etaLabel,
    String? deliverySlot,
    String? customerNote,
    Object? paymentUtr = _unset,
    Object? paymentSubmittedAt = _unset,
    Object? paymentSnapshot = _unset,
    Object? paymentVerifiedAt = _unset,
    Object? paymentVerifiedBy = _unset,
    Object? paymentRejectedReason = _unset,
    Object? cancellationReason = _unset,
    Object? assignedAgentId = _unset,
  }) {
    return Order(
      docId: docId ?? this.docId,
      orderId: orderId ?? this.orderId,
      userId: userId ?? this.userId,
      items: items ?? this.items,
      address: address ?? this.address,
      status: status ?? this.status,
      paymentStatus: paymentStatus ?? this.paymentStatus,
      paymentProvider: paymentProvider ?? this.paymentProvider,
      subtotal: subtotal ?? this.subtotal,
      deliveryFee: deliveryFee ?? this.deliveryFee,
      emergencyFee: emergencyFee ?? this.emergencyFee,
      totalAmount: totalAmount ?? this.totalAmount,
      isDiscreet: isDiscreet ?? this.isDiscreet,
      doNotRingBell: doNotRingBell ?? this.doNotRingBell,
      isEmergency: isEmergency ?? this.isEmergency,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      etaLabel: etaLabel ?? this.etaLabel,
      deliverySlot: deliverySlot ?? this.deliverySlot,
      customerNote: customerNote ?? this.customerNote,
      paymentUtr: identical(paymentUtr, _unset)
          ? this.paymentUtr
          : paymentUtr as String?,
      paymentSubmittedAt: identical(paymentSubmittedAt, _unset)
          ? this.paymentSubmittedAt
          : paymentSubmittedAt as DateTime?,
      paymentSnapshot: identical(paymentSnapshot, _unset)
          ? this.paymentSnapshot
          : paymentSnapshot as PaymentSnapshot?,
      paymentVerifiedAt: identical(paymentVerifiedAt, _unset)
          ? this.paymentVerifiedAt
          : paymentVerifiedAt as DateTime?,
      paymentVerifiedBy: identical(paymentVerifiedBy, _unset)
          ? this.paymentVerifiedBy
          : paymentVerifiedBy as String?,
      paymentRejectedReason: identical(paymentRejectedReason, _unset)
          ? this.paymentRejectedReason
          : paymentRejectedReason as String?,
      cancellationReason: identical(cancellationReason, _unset)
          ? this.cancellationReason
          : cancellationReason as String?,
      assignedAgentId: identical(assignedAgentId, _unset)
          ? this.assignedAgentId
          : assignedAgentId as String?,
    );
  }

  factory Order.fromMap(Map<String, dynamic> map, {String? docId}) {
    return Order(
      docId: docId ?? map['docId'] as String? ?? '',
      orderId: map['orderId'] as String? ?? '',
      userId: map['userId'] as String? ?? '',
      items: (map['items'] as List? ?? const [])
          .map(
            (item) => CartItem.fromMap(Map<String, dynamic>.from(item as Map)),
          )
          .toList(),
      address: DeliveryAddress.fromMap(
        Map<String, dynamic>.from(map['address'] as Map? ?? const {}),
      ),
      status: orderStatusFromString(
        map['orderStatus'] as String? ?? map['status'] as String?,
      ),
      paymentStatus: paymentStatusFromString(
        map['paymentStatus'] as String?,
      ),
      paymentProvider: paymentProviderFromString(
        map['paymentProvider'] as String? ?? map['paymentMethod'] as String?,
      ),
      subtotal: (map['subtotal'] as num?)?.toDouble() ?? 0,
      deliveryFee: (map['deliveryFee'] as num?)?.toDouble() ?? 0,
      emergencyFee: (map['emergencyFee'] as num?)?.toDouble() ?? 0,
      totalAmount: (map['totalAmount'] as num?)?.toDouble() ?? 0,
      isDiscreet: map['isDiscreet'] as bool? ?? true,
      doNotRingBell: map['doNotRingBell'] as bool? ?? false,
      isEmergency: map['isEmergency'] as bool? ?? false,
      createdAt: _dateFromDynamic(map['createdAt']) ?? DateTime.now(),
      updatedAt: _dateFromDynamic(map['updatedAt']) ?? DateTime.now(),
      etaLabel: map['etaLabel'] as String?,
      deliverySlot: map['deliverySlot'] as String?,
      customerNote: map['customerNote'] as String?,
      paymentUtr: map['paymentUtr'] as String?,
      paymentSubmittedAt: _dateFromDynamic(map['paymentSubmittedAt']),
      paymentSnapshot: map['paymentSnapshot'] is Map
          ? PaymentSnapshot.fromMap(
              Map<String, dynamic>.from(map['paymentSnapshot'] as Map),
            )
          : null,
      paymentVerifiedAt: _dateFromDynamic(map['paymentVerifiedAt']),
      paymentVerifiedBy: map['paymentVerifiedBy'] as String?,
      paymentRejectedReason: map['paymentRejectedReason'] as String?,
      cancellationReason: map['cancellationReason'] as String?,
      assignedAgentId: map['assignedAgentId'] as String?,
    );
  }

  factory Order.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    return Order.fromMap(doc.data() ?? const {}, docId: doc.id);
  }

  Map<String, dynamic> toMap() {
    return {
      'docId': docId,
      'orderId': orderId,
      'userId': userId,
      'items': items.map((item) => item.toMap()).toList(),
      'address': address.toMap(),
      'orderStatus': status.value,
      'paymentStatus': paymentStatus.value,
      'paymentProvider': paymentProvider.value,
      'subtotal': subtotal,
      'deliveryFee': deliveryFee,
      'emergencyFee': emergencyFee,
      'totalAmount': totalAmount,
      'isDiscreet': isDiscreet,
      'doNotRingBell': doNotRingBell,
      'isEmergency': isEmergency,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
      'etaLabel': etaLabel,
      'deliverySlot': deliverySlot,
      'customerNote': customerNote,
      'paymentUtr': paymentUtr,
      'paymentSubmittedAt': paymentSubmittedAt,
      'paymentSnapshot': paymentSnapshot?.toMap(),
      'paymentVerifiedAt': paymentVerifiedAt,
      'paymentVerifiedBy': paymentVerifiedBy,
      'paymentRejectedReason': paymentRejectedReason,
      'cancellationReason': cancellationReason,
      'assignedAgentId': assignedAgentId,
    };
  }
}

DateTime? _dateFromDynamic(dynamic value) {
  if (value is Timestamp) {
    return value.toDate();
  }
  if (value is DateTime) {
    return value;
  }
  return null;
}
