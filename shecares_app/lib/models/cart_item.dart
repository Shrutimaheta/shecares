import 'product.dart';

class CartItem {
  const CartItem({required this.product, this.quantity = 1});

  final Product product;
  final int quantity;

  double get totalPrice => product.finalPrice * quantity;

  CartItem copyWith({Product? product, int? quantity}) {
    return CartItem(
      product: product ?? this.product,
      quantity: quantity ?? this.quantity,
    );
  }

  factory CartItem.fromMap(Map<String, dynamic> map) {
    return CartItem(
      product: Product.fromMap(
        Map<String, dynamic>.from(map['product'] as Map? ?? const {}),
      ),
      quantity: map['quantity'] as int? ?? 1,
    );
  }

  Map<String, dynamic> toMap() {
    return {'product': product.toMap(), 'quantity': quantity};
  }
}
