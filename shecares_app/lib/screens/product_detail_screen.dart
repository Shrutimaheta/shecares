import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:video_player/video_player.dart';

import '../models/product.dart';
import '../models/pending_auth_action.dart';
import '../providers/cart_provider.dart';
import '../utils/auth_gate.dart';
import '../utils/constants.dart';
import '../utils/product_experience.dart';
import '../widgets/product_media.dart';

class ProductDetailScreen extends StatefulWidget {
  const ProductDetailScreen({super.key, required this.product});

  final Product product;

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  late final ProductExperience _experience;
  late final PageController _pageController;

  int _currentIndex = 0;
  VideoPlayerController? _videoController;
  bool _videoReady = false;
  bool _videoError = false;

  @override
  void initState() {
    super.initState();
    _experience = productExperienceFor(widget.product);
    _pageController = PageController();
    unawaited(_initializeVideo());
  }

  Future<void> _initializeVideo() async {
    if (_experience.videoUrl == null) {
      return;
    }

    final controller = VideoPlayerController.networkUrl(
      Uri.parse(_experience.videoUrl!),
    );
    _videoController = controller;

    try {
      await controller.initialize();
      await controller.setLooping(true);
      if (!mounted) {
        return;
      }
      setState(() => _videoReady = true);
    } catch (_) {
      if (!mounted) {
        return;
      }
      setState(() => _videoError = true);
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    _videoController?.dispose();
    super.dispose();
  }

  Future<void> _handleBuyNow() async {
    await requireCustomerAction(
      context,
      PendingAuthAction(
        type: PendingAuthActionType.buyNow,
        product: widget.product,
      ),
    );
  }

  Future<void> _runCartAction() async {
    await requireCustomerAction(
      context,
      PendingAuthAction(
        type: PendingAuthActionType.addToCart,
        product: widget.product,
      ),
    );
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _toggleVideo() async {
    final controller = _videoController;
    if (controller == null || !_videoReady) {
      return;
    }

    if (controller.value.isPlaying) {
      await controller.pause();
    } else {
      await controller.play();
    }
    if (mounted) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CartProvider>();
    final product = widget.product;
    final quantity = cart.quantityOf(product);

    return Scaffold(
      appBar: AppBar(title: Text(product.brand)),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          child: Row(
            children: [
              Expanded(
                child: quantity == 0
                    ? OutlinedButton.icon(
                        onPressed: _runCartAction,
                        icon: const Icon(Icons.add_shopping_cart_outlined),
                        label: const Text('Add'),
                      )
                    : _QuantityControl(
                        quantity: quantity,
                        onDecrement: () =>
                            cart.updateQuantity(product, quantity - 1),
                        onIncrement: () =>
                            cart.updateQuantity(product, quantity + 1),
                      ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: FilledButton(
                  onPressed: _handleBuyNow,
                  child: Text(quantity == 0 ? 'Buy now' : 'Go to cart'),
                ),
              ),
            ],
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(18, 8, 18, 24),
        children: [
          SizedBox(
            height: 320,
            child: Stack(
              children: [
                PageView.builder(
                  controller: _pageController,
                  itemCount: _experience.gallery.length,
                  onPageChanged: (index) =>
                      setState(() => _currentIndex = index),
                  itemBuilder: (context, index) {
                    return ProductMedia(
                      imageUrl: _experience.gallery[index],
                      borderRadius: BorderRadius.circular(32),
                      fallbackIcon: _iconForCategory(product.category),
                      overlay: const DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [Colors.transparent, Color(0x22000000)],
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                          ),
                        ),
                      ),
                    );
                  },
                ),
                Positioned(
                  top: 14,
                  left: 14,
                  child: _TopTag(label: product.category.title),
                ),
                if (product.discountPercent != null)
                  Positioned(
                    top: 14,
                    right: 14,
                    child: _TopTag(
                      label: '${product.discountPercent}% OFF',
                      dark: true,
                    ),
                  ),
                Positioned(
                  left: 14,
                  right: 14,
                  bottom: 14,
                  child: Row(
                    children: [
                      Expanded(
                        child: Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: _experience.trustTags
                              .take(2)
                              .map((tag) => _TopTag(label: tag))
                              .toList(),
                        ),
                      ),
                      if (_experience.videoUrl != null)
                        const _TopTag(
                          label: 'Video',
                          dark: true,
                          icon: Icons.play_circle_fill,
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          SizedBox(
            height: 70,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: _experience.gallery.length,
              separatorBuilder: (context, index) => const SizedBox(width: 10),
              itemBuilder: (context, index) {
                final selected = index == _currentIndex;
                return InkWell(
                  borderRadius: BorderRadius.circular(18),
                  onTap: () {
                    _pageController.animateToPage(
                      index,
                      duration: const Duration(milliseconds: 240),
                      curve: Curves.easeOut,
                    );
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 220),
                    width: 72,
                    padding: const EdgeInsets.all(3),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                        color: selected
                            ? Theme.of(context).colorScheme.primary
                            : const Color(0xFFE6D7DB),
                        width: selected ? 2 : 1,
                      ),
                    ),
                    child: ProductMedia(
                      imageUrl: _experience.gallery[index],
                      borderRadius: BorderRadius.circular(14),
                      fallbackIcon: _iconForCategory(product.category),
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 18),
          Text(
            product.brand,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: const Color(0xFF7A676F),
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            product.name,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w800,
              height: 1.15,
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              _DetailPill(
                icon: Icons.star_rounded,
                label:
                    '${product.rating.toStringAsFixed(1)} (${product.reviewCount} reviews)',
              ),
              _DetailPill(
                icon: Icons.local_fire_department_outlined,
                label: _experience.soldLabel,
              ),
              if (product.stockCount <= 10)
                _DetailPill(
                  icon: Icons.warning_amber_rounded,
                  label: 'Only ${product.stockCount} left',
                ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                'Rs ${product.finalPrice.toStringAsFixed(0)}',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              if (product.salePrice != null) ...[
                const SizedBox(width: 10),
                Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Text(
                    'MRP Rs ${product.mrp.toStringAsFixed(0)}',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: const Color(0xFF8E7C84),
                      decoration: TextDecoration.lineThrough,
                    ),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 8),
          Text(
            _experience.deliveryLabel,
            style: Theme.of(
              context,
            ).textTheme.bodyLarge?.copyWith(color: const Color(0xFF7A676F)),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: product.attributes
                .map((attribute) => _DetailChip(label: attribute))
                .toList(),
          ),
          const SizedBox(height: 18),
          Card(
            margin: EdgeInsets.zero,
            color: const Color(0xFFFFF7F4),
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Why this works in real life',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _experience.story,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: const Color(0xFF6F5D65),
                      height: 1.45,
                    ),
                  ),
                  const SizedBox(height: 14),
                  ...product.highlights.map(
                    (highlight) => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Padding(
                            padding: EdgeInsets.only(top: 2),
                            child: Icon(
                              Icons.check_circle_outline,
                              size: 18,
                              color: Color(0xFF4C9B7A),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(child: Text(highlight)),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          if (_experience.videoUrl != null)
            Card(
              margin: EdgeInsets.zero,
              clipBehavior: Clip.antiAlias,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'See the product closer',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'A short media preview helps customers judge fit, packaging, and texture before reordering.',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: const Color(0xFF6F5D65),
                      ),
                    ),
                    const SizedBox(height: 14),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(24),
                      child: AspectRatio(
                        aspectRatio: _videoReady
                            ? _videoController!.value.aspectRatio
                            : 16 / 9,
                        child: _videoError
                            ? const ColoredBox(
                                color: Color(0xFFF8EEF1),
                                child: Center(
                                  child: Text(
                                    'Video preview is unavailable right now.',
                                  ),
                                ),
                              )
                            : !_videoReady
                            ? const ColoredBox(
                                color: Color(0xFFF8EEF1),
                                child: Center(
                                  child: CircularProgressIndicator(),
                                ),
                              )
                            : Stack(
                                fit: StackFit.expand,
                                children: [
                                  VideoPlayer(_videoController!),
                                  DecoratedBox(
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        colors: [
                                          Colors.transparent,
                                          Colors.black.withOpacity(0.35),
                                        ],
                                        begin: Alignment.topCenter,
                                        end: Alignment.bottomCenter,
                                      ),
                                    ),
                                  ),
                                  Center(
                                    child: IconButton.filledTonal(
                                      onPressed: _toggleVideo,
                                      iconSize: 34,
                                      icon: Icon(
                                        _videoController!.value.isPlaying
                                            ? Icons.pause_rounded
                                            : Icons.play_arrow_rounded,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          if (_experience.videoUrl != null) const SizedBox(height: 16),
          Card(
            margin: EdgeInsets.zero,
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Product details',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    product.description,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: const Color(0xFF6F5D65),
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Card(
            margin: EdgeInsets.zero,
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _InfoRow(
                    icon: Icons.inventory_2_outlined,
                    title: 'Discreet packaging',
                    message:
                        'Your parcel uses plain outer packaging and does not display product type.',
                  ),
                  const SizedBox(height: 14),
                  _InfoRow(
                    icon: Icons.schedule_outlined,
                    title: 'Delivery workflow',
                    message:
                        'Choose a preferred slot at checkout, add doorbell instructions, and track assignment live.',
                  ),
                  const SizedBox(height: 14),
                  _InfoRow(
                    icon: Icons.autorenew_rounded,
                    title: 'Easy restocking',
                    message:
                        'Popular products surface ratings, monthly demand, and availability so repeat orders feel faster.',
                  ),
                ],
              ),
            ),
          ),
        ],
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

class _QuantityControl extends StatelessWidget {
  const _QuantityControl({
    required this.quantity,
    required this.onDecrement,
    required this.onIncrement,
  });

  final int quantity;
  final VoidCallback onDecrement;
  final VoidCallback onIncrement;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 56,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE2CDD4)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          IconButton(onPressed: onDecrement, icon: const Icon(Icons.remove)),
          Text(
            '$quantity',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
          ),
          IconButton(onPressed: onIncrement, icon: const Icon(Icons.add)),
        ],
      ),
    );
  }
}

class _TopTag extends StatelessWidget {
  const _TopTag({required this.label, this.dark = false, this.icon});

  final String label;
  final bool dark;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final color = dark ? const Color(0xFF2A1F24) : Colors.white;
    final foreground = dark ? Colors.white : const Color(0xFF2A1F24);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(dark ? 0.92 : 0.88),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 14, color: foreground),
            const SizedBox(width: 6),
          ],
          Text(
            label,
            style: TextStyle(
              color: foreground,
              fontWeight: FontWeight.w700,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

class _DetailPill extends StatelessWidget {
  const _DetailPill({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: const Color(0xFFE6D7DB)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [Icon(icon, size: 16), const SizedBox(width: 8), Text(label)],
      ),
    );
  }
}

class _DetailChip extends StatelessWidget {
  const _DetailChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFF8EEF1),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontWeight: FontWeight.w600,
          color: Color(0xFF6E5962),
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.icon,
    required this.title,
    required this.message,
  });

  final IconData icon;
  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: const Color(0xFFF8E9EC),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Icon(icon),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: Theme.of(
                  context,
                ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 4),
              Text(
                message,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: const Color(0xFF6F5D65),
                  height: 1.45,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
