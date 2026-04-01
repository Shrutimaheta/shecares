import 'package:flutter/material.dart';

import '../models/cart_item.dart';
import '../models/product.dart';
import '../utils/product_experience.dart';
import 'product_media.dart';

class CartItemWidget extends StatelessWidget {
  const CartItemWidget({
    super.key,
    required this.item,
    required this.onUpdateQuantity,
  });

  final CartItem item;
  final Future<void> Function(Product product, int quantity) onUpdateQuantity;

  @override
  Widget build(BuildContext context) {
    final experience = productExperienceFor(item.product);
    final isCompact = MediaQuery.of(context).size.width < 420;

    final quantityControl = Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: const Color(0xFFF8EEF1),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            visualDensity: VisualDensity.compact,
            constraints: const BoxConstraints.tightFor(width: 32, height: 32),
            onPressed: () => onUpdateQuantity(item.product, item.quantity - 1),
            icon: const Icon(Icons.remove_circle_outline),
          ),
          Text(
            '${item.quantity}',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
          ),
          IconButton(
            visualDensity: VisualDensity.compact,
            constraints: const BoxConstraints.tightFor(width: 32, height: 32),
            onPressed: () => onUpdateQuantity(item.product, item.quantity + 1),
            icon: const Icon(Icons.add_circle_outline),
          ),
        ],
      ),
    );

    Widget productInfo() {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            item.product.brand,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: const Color(0xFF7A676F),
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            item.product.name,
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 6),
          Text(
            experience.deliveryLabel,
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: const Color(0xFF7A676F)),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Text(
                'Rs ${item.product.finalPrice.toStringAsFixed(0)}',
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
              ),
              const SizedBox(width: 8),
              if (item.product.salePrice != null)
                Expanded(
                  child: Text(
                    'Rs ${item.product.mrp.toStringAsFixed(0)}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: const Color(0xFF8E7C84),
                      decoration: TextDecoration.lineThrough,
                    ),
                  ),
                ),
            ],
          ),
        ],
      );
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: isCompact
            ? Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ProductMedia(
                        imageUrl: experience.gallery.first,
                        height: 92,
                        width: 84,
                        borderRadius: BorderRadius.circular(20),
                        fallbackIcon: _iconForCategory(item.product.category),
                      ),
                      const SizedBox(width: 14),
                      Expanded(child: productInfo()),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      quantityControl,
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Rs ${item.totalPrice.toStringAsFixed(0)}',
                          textAlign: TextAlign.end,
                          style: Theme.of(context).textTheme.titleSmall
                              ?.copyWith(fontWeight: FontWeight.w800),
                        ),
                      ),
                    ],
                  ),
                ],
              )
            : Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ProductMedia(
                    imageUrl: experience.gallery.first,
                    height: 92,
                    width: 84,
                    borderRadius: BorderRadius.circular(20),
                    fallbackIcon: _iconForCategory(item.product.category),
                  ),
                  const SizedBox(width: 14),
                  Expanded(child: productInfo()),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      quantityControl,
                      const SizedBox(height: 10),
                      Text(
                        'Rs ${item.totalPrice.toStringAsFixed(0)}',
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
      ),
    );
  }

  IconData _iconForCategory(ProductCategory category) {
    switch (category) {
      case ProductCategory.sanitaryPads:
        return Icons.favorite;
      case ProductCategory.babyDiapers:
        return Icons.child_friendly;
      case ProductCategory.adultDiapers:
        return Icons.accessibility_new;
    }
  }
}
