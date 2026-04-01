import 'package:flutter/material.dart';

class ProductMedia extends StatelessWidget {
  const ProductMedia({
    super.key,
    required this.imageUrl,
    this.height,
    this.width,
    this.borderRadius = const BorderRadius.all(Radius.circular(24)),
    this.fit = BoxFit.cover,
    this.overlay,
    this.fallbackIcon = Icons.shopping_bag_outlined,
  });

  final String imageUrl;
  final double? height;
  final double? width;
  final BorderRadius borderRadius;
  final BoxFit fit;
  final Widget? overlay;
  final IconData fallbackIcon;

  @override
  Widget build(BuildContext context) {
    Widget child = ClipRRect(
      borderRadius: borderRadius,
      child: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFF8E9EC), Color(0xFFF4F0EA)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Stack(
          fit: StackFit.expand,
          children: [
            Image.network(
              imageUrl,
              fit: fit,
              loadingBuilder: (context, child, progress) {
                if (progress == null) {
                  return child;
                }
                return _placeholder();
              },
              errorBuilder: (context, error, stackTrace) {
                return _placeholder();
              },
            ),
            ...[overlay].whereType<Widget>(),
          ],
        ),
      ),
    );

    if (height != null || width != null) {
      child = SizedBox(height: height, width: width, child: child);
    }

    return child;
  }

  Widget _placeholder() {
    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFFF8E9EC), Color(0xFFF4F0EA)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Center(
        child: Icon(fallbackIcon, size: 42, color: const Color(0xFF9E6C7E)),
      ),
    );
  }
}
