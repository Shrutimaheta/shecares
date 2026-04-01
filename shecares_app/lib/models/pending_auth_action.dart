import 'product.dart';

enum PendingAuthActionType {
  addToCart,
  buyNow,
  openCart,
  openOrders,
  openProfile,
}

class PendingAuthAction {
  const PendingAuthAction({
    required this.type,
    this.product,
    this.quantity = 1,
    this.sourceRoute,
  });

  final PendingAuthActionType type;
  final Product? product;
  final int quantity;
  final String? sourceRoute;
}
