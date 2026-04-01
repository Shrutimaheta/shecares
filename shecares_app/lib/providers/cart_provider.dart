import 'dart:async';

import 'package:flutter/foundation.dart';

import '../models/cart_item.dart';
import '../models/product.dart';
import '../models/user_model.dart';
import '../services/firestore_service.dart';
import '../utils/constants.dart';

class CartProvider extends ChangeNotifier {
  final FirestoreService _firestoreService = FirestoreService.instance;

  List<CartItem> _items = [];
  bool _isDiscreet = true;
  bool _isEmergency = false;
  String? _userId;
  bool _isLoading = false;
  StreamSubscription<SavedCart?>? _cartSubscription;

  List<CartItem> get items => _items;
  bool get isDiscreet => _isDiscreet;
  bool get isEmergency => _isEmergency;
  bool get isLoading => _isLoading;

  int get itemCount => _items.fold(0, (sum, item) => sum + item.quantity);
  double get subtotal => _items.fold(0, (sum, item) => sum + item.totalPrice);
  double get deliveryFee =>
      subtotal >= AppConstants.freeDeliveryThreshold || subtotal == 0
      ? 0
      : AppConstants.deliveryFee;
  double get emergencyFee => _isEmergency ? AppConstants.emergencyFee : 0;
  double get total => subtotal + deliveryFee + emergencyFee;
  bool get canUseEmergency =>
      _items.isEmpty ||
      _items.every(
        (item) => item.product.category == ProductCategory.sanitaryPads,
      );

  CartProvider attachUser(UserModel? user) {
    final nextUserId = user?.uid;
    if (_userId == nextUserId) {
      return this;
    }

    _cartSubscription?.cancel();
    _userId = nextUserId;

    if (_userId == null || _userId!.isEmpty) {
      _applyCart(null, loading: false);
      return this;
    }

    _isLoading = true;
    notifyListeners();
    _cartSubscription = _firestoreService.cartStream(_userId!).listen((saved) {
      _applyCart(saved, loading: false);
    });
    return this;
  }

  int quantityOf(Product product) {
    final match = _items.where((item) => item.product.id == product.id);
    if (match.isEmpty) {
      return 0;
    }
    return match.first.quantity;
  }

  Future<void> addItem(Product product) async {
    _ensureCanAdd(product);

    final index = _items.indexWhere((item) => item.product.id == product.id);
    if (index == -1) {
      _items = [..._items, CartItem(product: product)];
    } else {
      final existing = _items[index];
      _items[index] = existing.copyWith(quantity: existing.quantity + 1);
    }
    await _sync();
  }

  Future<void> updateQuantity(Product product, int quantity) async {
    final index = _items.indexWhere((item) => item.product.id == product.id);
    if (index == -1) {
      return;
    }

    if (quantity <= 0) {
      _items.removeAt(index);
    } else {
      final safeQuantity = quantity.clamp(1, AppConstants.maxQuantityPerSku);
      final maxAllowed = product.stockCount.clamp(0, AppConstants.maxQuantityPerSku);
      if (safeQuantity > maxAllowed) {
        return;
      }
      _items[index] = _items[index].copyWith(quantity: safeQuantity);
    }

    if (!canUseEmergency) {
      _isEmergency = false;
    }

    await _sync();
  }

  Future<void> removeItem(Product product) async {
    _items = _items.where((item) => item.product.id != product.id).toList();
    if (!canUseEmergency) {
      _isEmergency = false;
    }
    await _sync();
  }

  Future<void> setDiscreet(bool value) async {
    _isDiscreet = value;
    await _sync();
  }

  Future<void> setEmergency(bool value) async {
    if (value && !canUseEmergency) {
      return;
    }
    _isEmergency = value;
    await _sync();
  }

  Future<void> clearCart({bool persist = true}) async {
    _items = [];
    _isDiscreet = true;
    _isEmergency = false;
    if (persist) {
      await _sync();
      return;
    }
    notifyListeners();
  }

  void _applyCart(SavedCart? saved, {required bool loading}) {
    _items = saved?.items ?? [];
    _isDiscreet = saved?.isDiscreet ?? true;
    _isEmergency = saved?.isEmergency ?? false;
    if (!canUseEmergency) {
      _isEmergency = false;
    }
    _isLoading = loading;
    notifyListeners();
  }

  void _ensureCanAdd(Product product) {
    if (!product.isAvailable || product.stockCount <= 0) {
      throw Exception('This product is currently out of stock.');
    }

    final currentQuantity = quantityOf(product);
    if (currentQuantity == 0 && _items.length >= AppConstants.maxCartSkus) {
      throw Exception(
        'You can add up to ${AppConstants.maxCartSkus} different products in one order.',
      );
    }
    if (currentQuantity >= AppConstants.maxQuantityPerSku) {
      throw Exception(
        'You can add up to ${AppConstants.maxQuantityPerSku} units of one product.',
      );
    }
    if (currentQuantity >= product.stockCount) {
      throw Exception('Only ${product.stockCount} units are available right now.');
    }
  }

  Future<void> _sync() async {
    notifyListeners();
    if (_userId == null || _userId!.isEmpty) {
      return;
    }
    await _firestoreService.saveCart(
      _userId!,
      _items,
      isDiscreet: _isDiscreet,
      isEmergency: _isEmergency,
    );
  }

  @override
  void dispose() {
    _cartSubscription?.cancel();
    super.dispose();
  }
}
