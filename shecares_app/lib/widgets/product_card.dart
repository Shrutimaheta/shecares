import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/pending_auth_action.dart';
import '../models/product.dart';
import '../providers/cart_provider.dart';
import '../utils/auth_gate.dart';
import '../utils/constants.dart';
import '../utils/product_experience.dart';
import 'product_media.dart';

class ProductCard extends StatelessWidget {
  const ProductCard({super.key, required this.product});

  final Product product;

  @override
  Widget build(BuildContext context) {
    return Consumer<CartProvider>(
      builder: (context, cart, child) {
        final theme = Theme.of(context);
        final quantity = cart.quantityOf(product);

        return InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () => Navigator.pushNamed(
            context,
            AppRoutes.productDetail,
            arguments: product,
          ),
          child: Card(
            clipBehavior: Clip.antiAlias,
            child: LayoutBuilder(
              builder: (context, constraints) {
                final cardHeight = constraints.maxHeight.isFinite
                    ? constraints.maxHeight
                    : 180.0;
                final compact = cardHeight < 150;

                return SizedBox.expand(
                  child: Padding(
                    padding: const EdgeInsets.all(10),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        AspectRatio(
                          aspectRatio: 1,
                          child: Stack(
                            children: [
                              Positioned.fill(
                                child: ProductMedia(
                                  imageUrl: productExperienceFor(
                                    product,
                                  ).gallery.first,
                                  borderRadius: BorderRadius.circular(14),
                                  fallbackIcon: _iconForCategory(
                                    product.category,
                                  ),
                                ),
                              ),
                              if (product.discountPercent != null)
                                Positioned(
                                  top: 6,
                                  right: 6,
                                  child: _Badge(
                                    label: '${product.discountPercent}% OFF',
                                  ),
                                ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Column(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    product.brand,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: const Color(0xFF7A676F),
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    product.name,
                                    maxLines: compact ? 1 : 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: theme.textTheme.titleSmall?.copyWith(
                                      fontWeight: FontWeight.w800,
                                      height: 1.2,
                                    ),
                                  ),
                                  if (!compact) ...[
                                    const SizedBox(height: 4),
                                    Text(
                                      product.stockCount <= 10
                                          ? 'Only ${product.stockCount} left'
                                          : 'Fast delivery',
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: theme.textTheme.bodySmall
                                          ?.copyWith(
                                            color: const Color(0xFF7A676F),
                                          ),
                                    ),
                                  ],
                                ],
                              ),
                              Column(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          'Rs ${product.finalPrice.toStringAsFixed(0)}',
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: theme.textTheme.titleSmall
                                              ?.copyWith(
                                                fontWeight: FontWeight.w800,
                                              ),
                                        ),
                                      ),
                                      if (product.salePrice != null && !compact)
                                        Text(
                                          'Rs ${product.mrp.toStringAsFixed(0)}',
                                          style: theme.textTheme.bodySmall
                                              ?.copyWith(
                                                color: const Color(0xFF8E7C84),
                                                decoration:
                                                    TextDecoration.lineThrough,
                                              ),
                                        ),
                                    ],
                                  ),
                                  const SizedBox(height: 6),
                                  if (quantity == 0)
                                    SizedBox(
                                      width: double.infinity,
                                      child: FilledButton(
                                        style: FilledButton.styleFrom(
                                          minimumSize: Size.fromHeight(
                                            compact ? 30 : 34,
                                          ),
                                          visualDensity: VisualDensity.compact,
                                          tapTargetSize:
                                              MaterialTapTargetSize.shrinkWrap,
                                        ),
                                        onPressed: product.isAvailable
                                            ? () => requireCustomerAction(
                                                context,
                                                PendingAuthAction(
                                                  type: PendingAuthActionType
                                                      .addToCart,
                                                  product: product,
                                                ),
                                              )
                                            : null,
                                        child: Text(
                                          product.isAvailable
                                              ? 'Add to cart'
                                              : 'Out of stock',
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: TextStyle(
                                            fontSize: compact ? 10 : 11,
                                          ),
                                        ),
                                      ),
                                    )
                                  else
                                    Row(
                                      children: [
                                        Expanded(
                                          child: OutlinedButton(
                                            style: OutlinedButton.styleFrom(
                                              minimumSize: Size.fromHeight(
                                                compact ? 28 : 32,
                                              ),
                                              visualDensity:
                                                  VisualDensity.compact,
                                              tapTargetSize:
                                                  MaterialTapTargetSize
                                                      .shrinkWrap,
                                              padding: EdgeInsets.zero,
                                            ),
                                            onPressed: () =>
                                                cart.updateQuantity(
                                                  product,
                                                  quantity - 1,
                                                ),
                                            child: const Icon(
                                              Icons.remove,
                                              size: 14,
                                            ),
                                          ),
                                        ),
                                        Padding(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 6,
                                          ),
                                          child: Text(
                                            '$quantity',
                                            style: theme.textTheme.titleSmall
                                                ?.copyWith(
                                                  fontWeight: FontWeight.w800,
                                                ),
                                          ),
                                        ),
                                        Expanded(
                                          child: FilledButton(
                                            style: FilledButton.styleFrom(
                                              minimumSize: Size.fromHeight(
                                                compact ? 28 : 32,
                                              ),
                                              visualDensity:
                                                  VisualDensity.compact,
                                              tapTargetSize:
                                                  MaterialTapTargetSize
                                                      .shrinkWrap,
                                              padding: EdgeInsets.zero,
                                            ),
                                            onPressed: () =>
                                                cart.updateQuantity(
                                                  product,
                                                  quantity + 1,
                                                ),
                                            child: const Icon(
                                              Icons.add,
                                              size: 14,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        );
      },
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

class _Badge extends StatelessWidget {
  const _Badge({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xFF2A1F24),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 10,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}
