import 'package:flutter/material.dart';

import '../models/product.dart';
import '../services/firestore_service.dart';
import '../utils/constants.dart';
import '../utils/product_experience.dart';
import '../widgets/cart_badge_button.dart';
import '../widgets/empty_state_card.dart';
import '../widgets/app_main_menu.dart';
import '../widgets/product_card.dart';
import '../widgets/product_media.dart';

enum ProductSortOption { popular, topRated, bestDeals, lowToHigh, highToLow }

class ProductListScreen extends StatefulWidget {
  const ProductListScreen({super.key, this.initialCategory});

  final ProductCategory? initialCategory;

  @override
  State<ProductListScreen> createState() => _ProductListScreenState();
}

class _ProductListScreenState extends State<ProductListScreen> {
  ProductCategory? _selectedCategory;
  ProductSortOption _sortOption = ProductSortOption.popular;
  String _searchQuery = '';
  bool _bestSellerOnly = false;
  bool _dealOnly = false;
  bool _newOnly = false;

  @override
  void initState() {
    super.initState();
    _selectedCategory = widget.initialCategory;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_selectedCategory?.title ?? 'Care essentials'),
        actions: const [CartBadgeButton()],
      ),
      drawer: const AppMainMenu(currentRoute: AppRoutes.products),
      body: StreamBuilder<List<Product>>(
        stream: FirestoreService.instance.productsStream(),
        builder: (context, snapshot) {
          final allProducts = snapshot.data ?? const <Product>[];
          final products = _sort(_filter(allProducts));
          final heroCategory =
              _selectedCategory ?? ProductCategory.sanitaryPads;

          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
            children: [
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(28),
                  gradient: const LinearGradient(
                    colors: [Color(0xFFFCF4F1), Color(0xFFF8E7EC)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(28),
                  child: Stack(
                    children: [
                      Positioned(
                        right: 0,
                        top: 0,
                        bottom: 0,
                        width: 130,
                        child: ProductMedia(
                          imageUrl: categoryHeroImage(heroCategory),
                          borderRadius: BorderRadius.zero,
                          fallbackIcon: _iconForCategory(heroCategory),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(18),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _selectedCategory?.title ?? 'All care essentials',
                              style: Theme.of(context).textTheme.titleLarge
                                  ?.copyWith(fontWeight: FontWeight.w800),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Use search, smart filters, and sorting to find the right fit faster.',
                              style: Theme.of(context).textTheme.bodyMedium
                                  ?.copyWith(color: const Color(0xFF6F5D65)),
                            ),
                            const SizedBox(height: 14),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Text(
                                '${products.length} products matched',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                onChanged: (value) => setState(() => _searchQuery = value),
                decoration: const InputDecoration(
                  prefixIcon: Icon(Icons.search),
                  suffixIcon: Icon(Icons.tune_rounded),
                  hintText: 'Search by brand, size, fit, or feature',
                ),
              ),
              const SizedBox(height: 14),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    ChoiceChip(
                      label: const Text('All'),
                      selected: _selectedCategory == null,
                      onSelected: (_) =>
                          setState(() => _selectedCategory = null),
                    ),
                    const SizedBox(width: 8),
                    ...ProductCategory.values.map(
                      (category) => Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: ChoiceChip(
                          label: Text(category.shortTitle),
                          selected: _selectedCategory == category,
                          onSelected: (_) =>
                              setState(() => _selectedCategory = category),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    FilterChip(
                      label: const Text('Bestsellers'),
                      selected: _bestSellerOnly,
                      onSelected: (value) =>
                          setState(() => _bestSellerOnly = value),
                    ),
                    const SizedBox(width: 8),
                    FilterChip(
                      label: const Text('Deals 15%+'),
                      selected: _dealOnly,
                      onSelected: (value) => setState(() => _dealOnly = value),
                    ),
                    const SizedBox(width: 8),
                    FilterChip(
                      label: const Text('New arrivals'),
                      selected: _newOnly,
                      onSelected: (value) => setState(() => _newOnly = value),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              DropdownButtonFormField<ProductSortOption>(
                value: _sortOption,
                decoration: const InputDecoration(labelText: 'Sort by'),
                items: ProductSortOption.values
                    .map(
                      (option) => DropdownMenuItem<ProductSortOption>(
                        value: option,
                        child: Text(_labelForSort(option)),
                      ),
                    )
                    .toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() => _sortOption = value);
                  }
                },
              ),
              const SizedBox(height: 18),
              if (products.isEmpty)
                EmptyStateCard(
                  icon: Icons.search_off_outlined,
                  title: 'No products matched',
                  message:
                      'Try clearing a filter or searching with a broader term like pad, diaper, or cotton.',
                  actionLabel: 'Clear filters',
                  onAction: () => setState(() {
                    _searchQuery = '';
                    _bestSellerOnly = false;
                    _dealOnly = false;
                    _newOnly = false;
                    _selectedCategory = widget.initialCategory;
                  }),
                )
              else
                LayoutBuilder(
                  builder: (context, constraints) {
                    final width = constraints.maxWidth;
                    final crossAxisCount = width >= 1280
                        ? 3
                        : width >= 900
                        ? 2
                        : 1;
                    final itemWidth =
                        (width - ((crossAxisCount - 1) * 12)) / crossAxisCount;
                    final aspectRatio = crossAxisCount == 1
                        ? (itemWidth >= 560 ? 3.0 : 2.6)
                        : 2.15;

                    return GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: crossAxisCount,
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                        childAspectRatio: aspectRatio,
                      ),
                      itemCount: products.length,
                      itemBuilder: (context, index) =>
                          ProductCard(product: products[index]),
                    );
                  },
                ),
            ],
          );
        },
      ),
    );
  }

  List<Product> _filter(List<Product> products) {
    final query = _searchQuery.trim().toLowerCase();

    return products.where((product) {
      final matchesCategory =
          _selectedCategory == null || product.category == _selectedCategory;
      final matchesQuery =
          query.isEmpty ||
          product.name.toLowerCase().contains(query) ||
          product.brand.toLowerCase().contains(query) ||
          product.description.toLowerCase().contains(query) ||
          product.attributes.any(
            (attribute) => attribute.toLowerCase().contains(query),
          );
      final matchesBestSeller = !_bestSellerOnly || product.isBestSeller;
      final matchesDeal = !_dealOnly || (product.discountPercent ?? 0) >= 15;
      final matchesNew = !_newOnly || product.isNew;

      return matchesCategory &&
          matchesQuery &&
          matchesBestSeller &&
          matchesDeal &&
          matchesNew;
    }).toList();
  }

  List<Product> _sort(List<Product> products) {
    final sorted = [...products];
    switch (_sortOption) {
      case ProductSortOption.popular:
        sorted.sort((a, b) {
          final popularityA = (a.isBestSeller ? 1000 : 0) + a.reviewCount;
          final popularityB = (b.isBestSeller ? 1000 : 0) + b.reviewCount;
          return popularityB.compareTo(popularityA);
        });
        break;
      case ProductSortOption.topRated:
        sorted.sort((a, b) => b.rating.compareTo(a.rating));
        break;
      case ProductSortOption.bestDeals:
        sorted.sort(
          (a, b) => (b.discountPercent ?? 0).compareTo(a.discountPercent ?? 0),
        );
        break;
      case ProductSortOption.lowToHigh:
        sorted.sort((a, b) => a.finalPrice.compareTo(b.finalPrice));
        break;
      case ProductSortOption.highToLow:
        sorted.sort((a, b) => b.finalPrice.compareTo(a.finalPrice));
        break;
    }
    return sorted;
  }

  String _labelForSort(ProductSortOption option) {
    switch (option) {
      case ProductSortOption.popular:
        return 'Popular first';
      case ProductSortOption.topRated:
        return 'Top rated';
      case ProductSortOption.bestDeals:
        return 'Best deals';
      case ProductSortOption.lowToHigh:
        return 'Price: low to high';
      case ProductSortOption.highToLow:
        return 'Price: high to low';
    }
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
