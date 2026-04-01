import 'dart:async';
import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart' hide Order;

import '../models/agent.dart';
import '../models/cart_item.dart';
import '../models/checkout_settings.dart';
import '../models/order.dart';
import '../models/product.dart';
import '../models/user_model.dart';
import '../utils/constants.dart';
import '../utils/dummy_data.dart';
import 'app_bootstrap.dart';

typedef SavedCart =
    ({List<CartItem> items, bool isDiscreet, bool isEmergency});

typedef DashboardStats =
    ({int totalOrders, double revenue, int productCount, int activeAgents});

class OrderPlacementResult {
  const OrderPlacementResult({required this.docId, required this.orderId});

  final String docId;
  final String orderId;
}

class OrderPlacementException implements Exception {
  const OrderPlacementException(this.message);

  final String message;

  @override
  String toString() => 'Exception: $message';
}

class FirestoreService {
  FirestoreService._() {
    _products.addAll(SeedData.products.map(_normalizeProduct));
    _agents.addAll(SeedData.agents);
    _ngoPartners.addAll(SeedData.ngoPartners);
    _checkoutSettings = CheckoutSettings.defaults();
  }

  static final FirestoreService instance = FirestoreService._();

  final List<Product> _products = [];
  final List<Order> _orders = [];
  final List<Agent> _agents = [];
  final List<Map<String, String>> _ngoPartners = [];
  final Map<String, UserModel> _users = {};
  final Map<String, SavedCart> _carts = {};

  CheckoutSettings _checkoutSettings = CheckoutSettings.defaults();

  final StreamController<List<Product>> _productsController =
      StreamController<List<Product>>.broadcast();
  final StreamController<List<Order>> _ordersController =
      StreamController<List<Order>>.broadcast();
  final StreamController<List<Agent>> _agentsController =
      StreamController<List<Agent>>.broadcast();
  final StreamController<List<Map<String, String>>> _ngoPartnersController =
      StreamController<List<Map<String, String>>>.broadcast();
  final StreamController<String> _cartEventsController =
      StreamController<String>.broadcast();
  final StreamController<CheckoutSettings> _checkoutSettingsController =
      StreamController<CheckoutSettings>.broadcast();

  FirebaseFirestore? get _firestore =>
      AppBootstrap.instance.firebaseReady ? FirebaseFirestore.instance : null;

  bool get isBackendReady => _firestore != null;

  CollectionReference<Map<String, dynamic>> get _productsRef =>
      _firestore!.collection('products');
  CollectionReference<Map<String, dynamic>> get _ordersRef =>
      _firestore!.collection('orders');
  CollectionReference<Map<String, dynamic>> get _usersRef =>
      _firestore!.collection('users');
  CollectionReference<Map<String, dynamic>> get _cartsRef =>
      _firestore!.collection('carts');
  CollectionReference<Map<String, dynamic>> get _agentsRef =>
      _firestore!.collection('agents');
  CollectionReference<Map<String, dynamic>> get _ngoPartnersRef =>
      _firestore!.collection('ngo_partners');
  CollectionReference<Map<String, dynamic>> get _siteSettingsRef =>
      _firestore!.collection('site_settings');
  DocumentReference<Map<String, dynamic>> get _checkoutSettingsRef =>
      _siteSettingsRef.doc(AppConstants.defaultCheckoutSettingsDocId);

  Stream<List<Product>> productsStream({bool includeUnavailable = false}) {
    if (isBackendReady) {
      return _productsRef.snapshots().map((snapshot) {
        final products = snapshot.docs
            .map(Product.fromFirestore)
            .map(_normalizeProduct)
            .toList()
          ..sort((a, b) => a.name.compareTo(b.name));
        return includeUnavailable
            ? products
            : products.where((product) => product.isAvailable).toList();
      });
    }

    return (() async* {
      yield _filterProducts(_products, includeUnavailable);
      yield* _productsController.stream.map(
        (products) => _filterProducts(products, includeUnavailable),
      );
    })();
  }

  Future<List<Product>> getProducts({bool includeUnavailable = false}) async {
    if (isBackendReady) {
      final snapshot = await _productsRef.get();
      final products = snapshot.docs
          .map(Product.fromFirestore)
          .map(_normalizeProduct)
          .toList();
      return _filterProducts(products, includeUnavailable);
    }
    return _filterProducts(_products, includeUnavailable);
  }

  Future<bool> isSeeded() async {
    if (isBackendReady) {
      final snapshot = await _productsRef.limit(1).get();
      return snapshot.docs.isNotEmpty;
    }
    return _products.isNotEmpty;
  }

  Future<void> seedAllProducts() async {
    if (isBackendReady) {
      final batch = _firestore!.batch();
      for (final product in SeedData.products.map(_normalizeProduct)) {
        batch.set(_productsRef.doc(product.id), product.toMap(), SetOptions(merge: true));
      }
      await batch.commit();
      return;
    }

    _products
      ..clear()
      ..addAll(SeedData.products.map(_normalizeProduct));
    _productsController.add(List<Product>.unmodifiable(_products));
  }

  Future<void> setProduct(Product product) async {
    final normalized = _normalizeProduct(product);

    if (isBackendReady) {
      await _productsRef.doc(normalized.id).set(normalized.toMap());
      return;
    }

    final index = _products.indexWhere((item) => item.id == normalized.id);
    if (index == -1) {
      _products.add(normalized);
    } else {
      _products[index] = normalized;
    }
    _productsController.add(List<Product>.unmodifiable(_products));
  }

  Future<void> deleteProduct(String id) async {
    if (isBackendReady) {
      await _productsRef.doc(id).delete();
      return;
    }

    _products.removeWhere((product) => product.id == id);
    _productsController.add(List<Product>.unmodifiable(_products));
  }

  Future<void> saveUser(UserModel user) async {
    if (isBackendReady) {
      await _usersRef.doc(user.uid).set(user.toMap(), SetOptions(merge: true));
      return;
    }
    _users[user.uid] = user;
  }

  Future<UserModel?> getUser(String uid) async {
    if (isBackendReady) {
      final doc = await _usersRef.doc(uid).get();
      if (!doc.exists) {
        return null;
      }
      return UserModel.fromMap(doc.data() ?? const {}, uid: doc.id);
    }
    return _users[uid];
  }

  Future<void> saveUserDefaultAddress(String uid, DeliveryAddress address) async {
    final existing = await getUser(uid);
    if (existing == null) {
      return;
    }
    await saveUser(
      existing.copyWith(defaultAddress: address, updatedAt: DateTime.now()),
    );
  }

  Stream<SavedCart?> cartStream(String userId) {
    if (isBackendReady) {
      return _cartsRef.doc(userId).snapshots().map((doc) {
        if (!doc.exists) {
          return null;
        }
        return _cartStateFromMap(doc.data() ?? const {});
      });
    }

    return (() async* {
      yield _carts[userId];
      yield* _cartEventsController.stream
          .where((eventUserId) => eventUserId == userId)
          .map((_) => _carts[userId]);
    })();
  }

  Future<void> saveCart(
    String userId,
    List<CartItem> items, {
    required bool isDiscreet,
    required bool isEmergency,
  }) async {
    final normalizedItems = _normalizeCartItems(items);
    final normalizedEmergency = normalizedItems.isEmpty
        ? false
        : (isEmergency && _canUseEmergency(normalizedItems));
    _validateCartInput(normalizedItems, isEmergency: normalizedEmergency);

    final cartMap = _cartStateToMap(
      normalizedItems,
      isDiscreet: isDiscreet,
      isEmergency: normalizedEmergency,
    );

    if (isBackendReady) {
      await _cartsRef.doc(userId).set(cartMap);
      return;
    }

    _carts[userId] = (
      items: normalizedItems,
      isDiscreet: isDiscreet,
      isEmergency: normalizedEmergency,
    );
    _cartEventsController.add(userId);
  }

  Future<SavedCart?> getCart(String userId) async {
    if (isBackendReady) {
      final doc = await _cartsRef.doc(userId).get();
      if (!doc.exists) {
        return null;
      }
      return _cartStateFromMap(doc.data() ?? const {});
    }

    return _carts[userId];
  }

  Stream<CheckoutSettings> checkoutSettingsStream() {
    if (isBackendReady) {
      return _checkoutSettingsRef.snapshots().map((snapshot) {
        if (!snapshot.exists) {
          return CheckoutSettings.defaults();
        }
        return CheckoutSettings.fromMap(snapshot.data() ?? const {});
      });
    }

    return (() async* {
      yield _checkoutSettings;
      yield* _checkoutSettingsController.stream;
    })();
  }

  Future<CheckoutSettings> getCheckoutSettings() async {
    if (isBackendReady) {
      final doc = await _checkoutSettingsRef.get();
      if (!doc.exists) {
        return CheckoutSettings.defaults();
      }
      return CheckoutSettings.fromMap(doc.data() ?? const {});
    }

    return _checkoutSettings;
  }

  Future<void> saveCheckoutSettings(CheckoutSettings settings) async {
    final normalized = settings.copyWith(updatedAt: DateTime.now());
    if (isBackendReady) {
      await _checkoutSettingsRef.set(
        normalized.toMap(),
        SetOptions(merge: true),
      );
      return;
    }

    _checkoutSettings = normalized;
    _checkoutSettingsController.add(_checkoutSettings);
  }

  Future<void> seedCheckoutSettings({bool overwrite = false}) async {
    final defaults = CheckoutSettings.defaults();
    if (isBackendReady) {
      final existing = await _checkoutSettingsRef.get();
      if (existing.exists && !overwrite) {
        return;
      }
      await _checkoutSettingsRef.set(defaults.toMap(), SetOptions(merge: true));
      return;
    }

    _checkoutSettings = defaults;
    _checkoutSettingsController.add(_checkoutSettings);
  }

  Future<bool> isPaymentUtrTaken(
    String utr, {
    String? excludeOrderDocId,
  }) async {
    final normalizedUtr = _normalizedUtr(utr);
    if (normalizedUtr.isEmpty) {
      return false;
    }

    if (isBackendReady) {
      final snapshot = await _ordersRef
          .where('paymentUtr', isEqualTo: normalizedUtr)
          .limit(5)
          .get();
      return snapshot.docs.any((doc) => doc.id != excludeOrderDocId);
    }

    return _orders.any(
      (order) =>
          order.paymentUtr == normalizedUtr && order.docId != excludeOrderDocId,
    );
  }

  Future<OrderPlacementResult> placeOrder(Order order) async {
    _validateDeliveryAddress(order.address);
    _validateCartInput(order.items, isEmergency: order.isEmergency);

    final settings = await getCheckoutSettings();
    if (order.paymentProvider == PaymentProvider.manualUpi) {
      if (!settings.manualUpiEnabled) {
        throw const OrderPlacementException(
          'Manual UPI checkout is currently disabled. Please contact support.',
        );
      }

      _validateManualUpi(
        order.paymentUtr,
        minimumUtrLength: settings.minimumUtrLength,
      );

      if (await isPaymentUtrTaken(order.paymentUtr ?? '')) {
        throw const OrderPlacementException(
          'This transaction reference has already been used on another order. Please check the UTR and try again.',
        );
      }
    }

    if (isBackendReady) {
      return _placeOrderInFirestore(order, settings);
    }

    return _placeOrderLocally(order, settings);
  }

  Stream<List<Order>> userOrdersStream(String uid) {
    if (isBackendReady) {
      return _ordersRef.where('userId', isEqualTo: uid).snapshots().map(
        (snapshot) =>
            snapshot.docs.map(Order.fromFirestore).toList()
              ..sort((a, b) => b.createdAt.compareTo(a.createdAt)),
      );
    }

    return (() async* {
      yield _orders.where((order) => order.userId == uid).toList();
      yield* _ordersController.stream.map(
        (orders) => orders.where((order) => order.userId == uid).toList(),
      );
    })();
  }

  Stream<List<Order>> allOrdersStream() {
    if (isBackendReady) {
      return _ordersRef.snapshots().map(
        (snapshot) =>
            snapshot.docs.map(Order.fromFirestore).toList()
              ..sort((a, b) => b.createdAt.compareTo(a.createdAt)),
      );
    }

    return (() async* {
      yield List<Order>.from(_orders);
      yield* _ordersController.stream;
    })();
  }

  Stream<Order?> orderStream(String docId) {
    if (isBackendReady) {
      return _ordersRef.doc(docId).snapshots().map((snapshot) {
        if (!snapshot.exists) {
          return null;
        }
        return Order.fromFirestore(snapshot);
      });
    }

    return (() async* {
      yield _orders.cast<Order?>().firstWhere(
        (order) => order?.docId == docId,
        orElse: () => null,
      );
      yield* _ordersController.stream.map(
        (orders) => orders.cast<Order?>().firstWhere(
          (order) => order?.docId == docId,
          orElse: () => null,
        ),
      );
    })();
  }

  Future<void> verifyPayment(String docId, {required String adminUid}) async {
    if (isBackendReady) {
      final firestore = _firestore!;
      await firestore.runTransaction((transaction) async {
        final orderSnapshot = await transaction.get(_ordersRef.doc(docId));
        if (!orderSnapshot.exists) {
          throw const OrderPlacementException('This order no longer exists.');
        }

        final order = Order.fromFirestore(orderSnapshot);
        if (order.paymentStatus != PaymentStatus.submitted) {
          throw const OrderPlacementException(
            'This payment has already been reviewed.',
          );
        }

        final refreshedItems = <CartItem>[];
        for (final item in order.items) {
          final productRef = _productsRef.doc(item.product.id);
          final productSnapshot = await transaction.get(productRef);
          if (!productSnapshot.exists) {
            throw OrderPlacementException(
              '${item.product.name} is no longer available.',
            );
          }

          final liveProduct = _normalizeProduct(
            Product.fromFirestore(productSnapshot),
          );
          if (item.quantity > liveProduct.stockCount) {
            throw OrderPlacementException(
              'Cannot confirm ${order.orderId}. ${liveProduct.name} only has ${liveProduct.stockCount} units left in stock.',
            );
          }

          refreshedItems.add(CartItem(product: liveProduct, quantity: item.quantity));
          final remaining = liveProduct.stockCount - item.quantity;
          transaction.set(
            productRef,
            {
              'stockCount': remaining,
              'isAvailable': remaining > 0,
            },
            SetOptions(merge: true),
          );
        }

        final now = DateTime.now();
        final verifiedOrder = order.copyWith(
          items: refreshedItems,
          status: OrderStatus.confirmed,
          paymentStatus: PaymentStatus.verified,
          paymentVerifiedAt: now,
          paymentVerifiedBy: adminUid,
          updatedAt: now,
          etaLabel: _etaLabelForStatus(OrderStatus.confirmed),
        );
        transaction.set(orderSnapshot.reference, verifiedOrder.toMap());
      });
      return;
    }

    final index = _orders.indexWhere((order) => order.docId == docId);
    if (index == -1) {
      return;
    }

    final order = _orders[index];
    if (order.paymentStatus != PaymentStatus.submitted) {
      throw const OrderPlacementException(
        'This payment has already been reviewed.',
      );
    }

    final refreshedItems = <CartItem>[];
    for (final item in order.items) {
      final productIndex = _products.indexWhere(
        (product) => product.id == item.product.id,
      );
      if (productIndex == -1) {
        throw OrderPlacementException(
          '${item.product.name} is no longer available.',
        );
      }

      final liveProduct = _normalizeProduct(_products[productIndex]);
      if (item.quantity > liveProduct.stockCount) {
        throw OrderPlacementException(
          'Cannot confirm ${order.orderId}. ${liveProduct.name} only has ${liveProduct.stockCount} units left in stock.',
        );
      }

      refreshedItems.add(CartItem(product: liveProduct, quantity: item.quantity));
      final remaining = liveProduct.stockCount - item.quantity;
      _products[productIndex] = liveProduct.copyWith(
        stockCount: remaining,
        isAvailable: remaining > 0,
      );
    }

    _orders[index] = order.copyWith(
      items: refreshedItems,
      status: OrderStatus.confirmed,
      paymentStatus: PaymentStatus.verified,
      paymentVerifiedAt: DateTime.now(),
      paymentVerifiedBy: adminUid,
      updatedAt: DateTime.now(),
      etaLabel: _etaLabelForStatus(OrderStatus.confirmed),
    );

    _productsController.add(List<Product>.unmodifiable(_products));
    _ordersController.add(List<Order>.unmodifiable(_orders));
  }

  Future<void> rejectPayment(
    String docId, {
    required String adminUid,
    required String reason,
  }) async {
    final trimmedReason = reason.trim();
    if (trimmedReason.isEmpty) {
      throw const OrderPlacementException('Please provide a rejection reason.');
    }

    if (isBackendReady) {
      final now = DateTime.now();
      await _ordersRef.doc(docId).set({
        'orderStatus': OrderStatus.cancelled.value,
        'paymentStatus': PaymentStatus.rejected.value,
        'paymentRejectedReason': trimmedReason,
        'updatedAt': now,
        'etaLabel': _etaLabelForStatus(OrderStatus.cancelled),
        'paymentVerifiedBy': adminUid,
      }, SetOptions(merge: true));
      return;
    }

    final index = _orders.indexWhere((order) => order.docId == docId);
    if (index == -1) {
      return;
    }

    _orders[index] = _orders[index].copyWith(
      status: OrderStatus.cancelled,
      paymentStatus: PaymentStatus.rejected,
      paymentRejectedReason: trimmedReason,
      updatedAt: DateTime.now(),
      etaLabel: _etaLabelForStatus(OrderStatus.cancelled),
      paymentVerifiedBy: adminUid,
    );
    _ordersController.add(List<Order>.unmodifiable(_orders));
  }

  Future<void> updateOrderStatus(
    String docId,
    OrderStatus status, {
    String? cancellationReason,
  }) async {
    if (isBackendReady) {
      await _updateOrderStatusInFirestore(
        docId,
        status,
        cancellationReason: cancellationReason,
      );
      return;
    }

    final index = _orders.indexWhere((order) => order.docId == docId);
    if (index == -1) {
      return;
    }

    final existing = _orders[index];
    if (existing.paymentStatus != PaymentStatus.verified &&
        status != OrderStatus.cancelled) {
      throw const OrderPlacementException(
        'Verify payment before moving this order into fulfilment.',
      );
    }

    if (status == OrderStatus.cancelled && _shouldRestock(existing)) {
      _restockItems(existing.items);
      _productsController.add(List<Product>.unmodifiable(_products));
    }

    _orders[index] = existing.copyWith(
      status: status,
      updatedAt: DateTime.now(),
      etaLabel: _etaLabelForStatus(status),
      cancellationReason: cancellationReason,
    );
    _ordersController.add(List<Order>.unmodifiable(_orders));
  }

  Stream<List<Agent>> agentsStream() {
    if (isBackendReady) {
      return _agentsRef.snapshots().map(
        (snapshot) =>
            snapshot.docs.map(Agent.fromFirestore).toList()
              ..sort((a, b) => a.name.compareTo(b.name)),
      );
    }

    return (() async* {
      yield List<Agent>.from(_agents);
      yield* _agentsController.stream;
    })();
  }

  Future<void> seedAgents() async {
    if (isBackendReady) {
      final batch = _firestore!.batch();
      for (final agent in SeedData.agents) {
        batch.set(_agentsRef.doc(agent.id), agent.toMap());
      }
      await batch.commit();
      return;
    }

    _agents
      ..clear()
      ..addAll(SeedData.agents);
    _agentsController.add(List<Agent>.unmodifiable(_agents));
  }

  Future<void> setAgent(Agent agent) async {
    if (isBackendReady) {
      await _agentsRef.doc(agent.id).set(agent.toMap());
      return;
    }

    final index = _agents.indexWhere((item) => item.id == agent.id);
    if (index == -1) {
      _agents.add(agent);
    } else {
      _agents[index] = agent;
    }
    _agentsController.add(List<Agent>.unmodifiable(_agents));
  }

  Future<void> setAgentForOrder(String orderDocId, String? agentId) async {
    if (isBackendReady) {
      await _ordersRef.doc(orderDocId).set({
        'assignedAgentId': agentId,
        'updatedAt': DateTime.now(),
      }, SetOptions(merge: true));
      return;
    }

    final index = _orders.indexWhere((o) => o.docId == orderDocId);
    if (index != -1) {
      _orders[index] = _orders[index].copyWith(assignedAgentId: agentId);
      _ordersController.add(List<Order>.unmodifiable(_orders));
    }
  }

  Future<void> deleteAgent(String id) async {
    if (isBackendReady) {
      await _agentsRef.doc(id).delete();
      return;
    }

    _agents.removeWhere((agent) => agent.id == id);
    _agentsController.add(List<Agent>.unmodifiable(_agents));
  }

  Future<void> seedNgoPartners() async {
    if (isBackendReady) {
      final batch = _firestore!.batch();
      for (var i = 0; i < SeedData.ngoPartners.length; i++) {
        batch.set(
          _ngoPartnersRef.doc('ngo_${i + 1}'),
          SeedData.ngoPartners[i],
        );
      }
      await batch.commit();
      return;
    }

    _ngoPartners
      ..clear()
      ..addAll(SeedData.ngoPartners);
    _ngoPartnersController.add(
      List<Map<String, String>>.unmodifiable(_ngoPartners),
    );
  }

  Stream<List<Map<String, String>>> ngoPartnersStream() {
    if (isBackendReady) {
      return _ngoPartnersRef.snapshots().map((snapshot) {
        final partners = snapshot.docs
            .map((doc) => {
                  'name': doc.data()['name']?.toString() ?? '',
                  'type': doc.data()['type']?.toString() ?? '',
                  'area': doc.data()['area']?.toString() ?? '',
                })
            .toList()
          ..sort(
            (a, b) => (a['name'] ?? '')
                .toLowerCase()
                .compareTo((b['name'] ?? '').toLowerCase()),
          );
        return partners;
      });
    }

    return (() async* {
      yield List<Map<String, String>>.from(_ngoPartners);
      yield* _ngoPartnersController.stream;
    })();
  }

  Future<DashboardStats> getDashboardStats() async {
    final products = await getProducts(includeUnavailable: true);
    final orders = isBackendReady
        ? (await _ordersRef.get()).docs.map(Order.fromFirestore).toList()
        : _orders;
    final agents = isBackendReady
        ? (await _agentsRef.get()).docs.map(Agent.fromFirestore).toList()
        : _agents;

    return (
      totalOrders: orders.length,
      revenue: orders.fold<double>(
        0,
        (total, order) => total + order.totalAmount,
      ),
      productCount: products.length,
      activeAgents: agents.where((agent) => agent.isActive).length,
    );
  }

  Future<void> seedPhaseOneData() async {
    await seedAllProducts();
    await seedCheckoutSettings();
    await seedNgoPartners();
    if (!isBackendReady) {
      _orders.clear();
      _carts.clear();
      _ordersController.add(List<Order>.unmodifiable(_orders));
    }
  }

  Future<OrderPlacementResult> _placeOrderInFirestore(
    Order order,
    CheckoutSettings initialSettings,
  ) async {
    final firestore = _firestore!;
    final orderDoc = _ordersRef.doc();
    Order? savedOrder;

    await firestore.runTransaction((transaction) async {
      final refreshedItems = <CartItem>[];

      for (final item in order.items) {
        final productRef = _productsRef.doc(item.product.id);
        final productSnapshot = await transaction.get(productRef);
        if (!productSnapshot.exists) {
          throw OrderPlacementException(
            '${item.product.name} is no longer available.',
          );
        }

        final liveProduct = _normalizeProduct(
          Product.fromFirestore(productSnapshot),
        );
        if (!liveProduct.isAvailable) {
          throw OrderPlacementException(
            '${liveProduct.name} is currently unavailable.',
          );
        }
        if (item.quantity > liveProduct.stockCount) {
          throw OrderPlacementException(
            'Only ${liveProduct.stockCount} units of ${liveProduct.name} are available right now.',
          );
        }

        refreshedItems.add(CartItem(product: liveProduct, quantity: item.quantity));
      }

      final settingsSnapshot = await transaction.get(_checkoutSettingsRef);
      final checkoutSettings = settingsSnapshot.exists
          ? CheckoutSettings.fromMap(settingsSnapshot.data() ?? const {})
          : initialSettings;

      final now = DateTime.now();
      final orderId = order.orderId.isEmpty ? _generateOrderId() : order.orderId;
      final pricedOrder = _pricedOrder(
        order,
        items: refreshedItems,
        docId: orderDoc.id,
        orderId: orderId,
        createdAt: now,
        checkoutSettings: checkoutSettings,
      );

      transaction.set(orderDoc, pricedOrder.toMap());
      transaction.set(
        _cartsRef.doc(order.userId),
        _cartStateToMap(const [], isDiscreet: true, isEmergency: false),
      );
      savedOrder = pricedOrder;
    });

    final placedOrder = savedOrder;
    if (placedOrder == null) {
      throw const OrderPlacementException('Unable to place the order right now.');
    }

    return OrderPlacementResult(
      docId: placedOrder.docId,
      orderId: placedOrder.orderId,
    );
  }

  Future<OrderPlacementResult> _placeOrderLocally(
    Order order,
    CheckoutSettings checkoutSettings,
  ) async {
    final refreshedItems = <CartItem>[];

    for (final item in order.items) {
      final index = _products.indexWhere((product) => product.id == item.product.id);
      if (index == -1) {
        throw OrderPlacementException(
          '${item.product.name} is no longer available.',
        );
      }

      final liveProduct = _normalizeProduct(_products[index]);
      if (!liveProduct.isAvailable) {
        throw OrderPlacementException(
          '${liveProduct.name} is currently unavailable.',
        );
      }
      if (item.quantity > liveProduct.stockCount) {
        throw OrderPlacementException(
          'Only ${liveProduct.stockCount} units of ${liveProduct.name} are available right now.',
        );
      }

      refreshedItems.add(CartItem(product: liveProduct, quantity: item.quantity));
    }

    final docId = 'local-${Random().nextInt(999999)}';
    final now = DateTime.now();
    final orderId = order.orderId.isEmpty ? _generateOrderId() : order.orderId;
    final pricedOrder = _pricedOrder(
      order,
      items: refreshedItems,
      docId: docId,
      orderId: orderId,
      createdAt: now,
      checkoutSettings: checkoutSettings,
    );

    _orders.insert(0, pricedOrder);
    _carts[order.userId] = (
      items: const <CartItem>[],
      isDiscreet: true,
      isEmergency: false,
    );

    _ordersController.add(List<Order>.unmodifiable(_orders));
    _cartEventsController.add(order.userId);

    return OrderPlacementResult(docId: docId, orderId: orderId);
  }

  Future<void> _updateOrderStatusInFirestore(
    String docId,
    OrderStatus status, {
    String? cancellationReason,
  }) async {
    final firestore = _firestore!;
    await firestore.runTransaction((transaction) async {
      final orderSnapshot = await transaction.get(_ordersRef.doc(docId));
      if (!orderSnapshot.exists) {
        throw const OrderPlacementException('This order no longer exists.');
      }

      final order = Order.fromFirestore(orderSnapshot);
      if (order.paymentStatus != PaymentStatus.verified &&
          status != OrderStatus.cancelled) {
        throw const OrderPlacementException(
          'Verify payment before moving this order into fulfilment.',
        );
      }

      if (status == OrderStatus.cancelled && _shouldRestock(order)) {
        for (final item in order.items) {
          final productRef = _productsRef.doc(item.product.id);
          final productSnapshot = await transaction.get(productRef);
          if (!productSnapshot.exists) {
            continue;
          }
          final liveProduct = _normalizeProduct(
            Product.fromFirestore(productSnapshot),
          );
          final restored = liveProduct.stockCount + item.quantity;
          transaction.set(
            productRef,
            {
              'stockCount': restored,
              'isAvailable': restored > 0,
            },
            SetOptions(merge: true),
          );
        }
      }

      transaction.set(orderSnapshot.reference, {
        'orderStatus': status.value,
        'updatedAt': DateTime.now(),
        'etaLabel': _etaLabelForStatus(status),
        'cancellationReason': status == OrderStatus.cancelled
            ? cancellationReason
            : order.cancellationReason,
      }, SetOptions(merge: true));
    });
  }

  Order _pricedOrder(
    Order order, {
    required List<CartItem> items,
    required String docId,
    required String orderId,
    required DateTime createdAt,
    required CheckoutSettings checkoutSettings,
  }) {
    final subtotal = items.fold<double>(
      0,
      (total, item) => total + item.totalPrice,
    );
    final deliveryFee = subtotal >= AppConstants.freeDeliveryThreshold
        ? 0
        : AppConstants.deliveryFee;
    final emergencyFee = order.isEmergency ? AppConstants.emergencyFee : 0;

    return order.copyWith(
      docId: docId,
      orderId: orderId,
      items: items,
      status: OrderStatus.awaitingConfirmation,
      paymentStatus: order.paymentProvider == PaymentProvider.cod
          ? PaymentStatus.verified
          : PaymentStatus.submitted,
      paymentProvider: order.paymentProvider,
      subtotal: subtotal.toDouble(),
      deliveryFee: deliveryFee.toDouble(),
      emergencyFee: emergencyFee.toDouble(),
      totalAmount: (subtotal + deliveryFee + emergencyFee).toDouble(),
      etaLabel: _etaLabelForStatus(OrderStatus.awaitingConfirmation),
      createdAt: createdAt,
      updatedAt: createdAt,
      paymentUtr: order.paymentProvider == PaymentProvider.cod
          ? null
          : _normalizedUtr(order.paymentUtr),
      paymentSubmittedAt: createdAt,
      paymentSnapshot: order.paymentProvider == PaymentProvider.cod
          ? null
          : PaymentSnapshot(
              upiId: checkoutSettings.upiId,
              payeeName: checkoutSettings.payeeName,
              qrImagePath: checkoutSettings.qrImagePath,
              instructions: checkoutSettings.paymentInstructions,
            ),
      paymentVerifiedAt: null,
      paymentVerifiedBy: null,
      paymentRejectedReason: null,
      cancellationReason: null,
      isEmergency: order.isEmergency && _canUseEmergency(items),
    );
  }

  SavedCart _cartStateFromMap(Map<String, dynamic> data) {
    return (
      items: (data['items'] as List? ?? const [])
          .map(
            (item) => CartItem.fromMap(
              Map<String, dynamic>.from(item as Map),
            ),
          )
          .toList(),
      isDiscreet: data['isDiscreet'] as bool? ?? true,
      isEmergency: data['isEmergency'] as bool? ?? false,
    );
  }

  Map<String, dynamic> _cartStateToMap(
    List<CartItem> items, {
    required bool isDiscreet,
    required bool isEmergency,
  }) {
    return {
      'items': items.map((item) => item.toMap()).toList(),
      'isDiscreet': isDiscreet,
      'isEmergency': isEmergency,
      'updatedAt': DateTime.now(),
    };
  }

  void _validateDeliveryAddress(DeliveryAddress address) {
    if (address.fullName.trim().isEmpty ||
        address.houseNo.trim().isEmpty ||
        address.street.trim().isEmpty ||
        address.area.trim().isEmpty ||
        address.city.trim().isEmpty) {
      throw const OrderPlacementException('Please complete the delivery address.');
    }

    final phone = address.phone.trim();
    if (!RegExp(r'^[6-9][0-9]{9}$').hasMatch(phone)) {
      throw const OrderPlacementException(
        'Phone number must be a valid 10-digit Indian mobile number.',
      );
    }

    final pincode = int.tryParse(address.pincode.trim());
    if (pincode == null) {
      throw const OrderPlacementException('Pincode must be 6 digits.');
    }
    if (pincode < AppConstants.minServicePincode ||
        pincode > AppConstants.maxServicePincode) {
      throw const OrderPlacementException(
        'SheCares currently delivers only within Ahmedabad service pincodes.',
      );
    }
  }

  void _validateCartInput(
    List<CartItem> items, {
    required bool isEmergency,
  }) {
    if (items.isEmpty) {
      throw const OrderPlacementException('Your cart is empty.');
    }
    if (items.length > AppConstants.maxCartSkus) {
      throw OrderPlacementException(
        'You can order up to ${AppConstants.maxCartSkus} different products at once.',
      );
    }
    if (isEmergency && !_canUseEmergency(items)) {
      throw const OrderPlacementException(
        'Emergency delivery is available only for sanitary-pad-only carts.',
      );
    }

    for (final item in items) {
      if (item.quantity <= 0) {
        throw OrderPlacementException(
          'Invalid quantity selected for ${item.product.name}.',
        );
      }
      if (item.quantity > AppConstants.maxQuantityPerSku) {
        throw OrderPlacementException(
          'You can add up to ${AppConstants.maxQuantityPerSku} units per product.',
        );
      }
    }
  }

  void _validateManualUpi(
    String? utr, {
    required int minimumUtrLength,
  }) {
    final normalizedUtr = _normalizedUtr(utr);
    if (normalizedUtr.isEmpty) {
      throw const OrderPlacementException(
        'Please enter the UTR or transaction reference number from your UPI app.',
      );
    }
    if (normalizedUtr.length < minimumUtrLength) {
      throw OrderPlacementException(
        'UTR should be at least $minimumUtrLength characters long.',
      );
    }
    if (!RegExp(r'^[A-Z0-9]+$').hasMatch(normalizedUtr)) {
      throw const OrderPlacementException(
        'UTR can contain only letters and numbers without spaces or symbols.',
      );
    }
  }

  List<CartItem> _normalizeCartItems(List<CartItem> items) {
    return items
        .map(
          (item) => CartItem(
            product: _normalizeProduct(item.product),
            quantity: item.quantity,
          ),
        )
        .toList();
  }

  bool _canUseEmergency(List<CartItem> items) {
    if (items.isEmpty) {
      return false;
    }
    return items.every(
      (item) => item.product.category == ProductCategory.sanitaryPads,
    );
  }

  bool _shouldRestock(Order order) {
    return order.paymentStatus == PaymentStatus.verified &&
        order.status != OrderStatus.cancelled &&
        order.status != OrderStatus.delivered;
  }

  void _restockItems(List<CartItem> items) {
    for (final item in items) {
      final index = _products.indexWhere((product) => product.id == item.product.id);
      if (index == -1) {
        continue;
      }
      final product = _normalizeProduct(_products[index]);
      final restored = product.stockCount + item.quantity;
      _products[index] = product.copyWith(
        stockCount: restored,
        isAvailable: restored > 0,
      );
    }
  }

  Product _normalizeProduct(Product product) {
    final available = product.isAvailable && product.stockCount > 0;
    return product.copyWith(isAvailable: available);
  }

  List<Product> _filterProducts(
    List<Product> products,
    bool includeUnavailable,
  ) {
    final filtered = includeUnavailable
        ? List<Product>.from(products.map(_normalizeProduct))
        : products
              .map(_normalizeProduct)
              .where((product) => product.isAvailable)
              .toList();
    filtered.sort((a, b) => a.name.compareTo(b.name));
    return filtered;
  }

  String generateOrderId() => _generateOrderId();
  String etaLabelForStatus(OrderStatus status) => _etaLabelForStatus(status);

  String _generateOrderId() {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final random = Random();
    final suffix = List.generate(
      8,
      (_) => chars[random.nextInt(chars.length)],
    ).join();
    return 'SC$suffix';
  }

  String _normalizedUtr(String? value) {
    return (value ?? '').trim().toUpperCase();
  }

  String _etaLabelForStatus(OrderStatus status) {
    switch (status) {
      case OrderStatus.awaitingConfirmation:
        return 'Awaiting payment confirmation';
      case OrderStatus.confirmed:
        return 'Confirmed and queued for packing';
      case OrderStatus.preparing:
        return 'Packing your essentials now';
      case OrderStatus.outForDelivery:
        return 'Out for delivery today';
      case OrderStatus.delivered:
        return 'Delivered';
      case OrderStatus.cancelled:
        return 'Cancelled';
    }
  }
}
