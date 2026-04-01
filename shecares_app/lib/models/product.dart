import 'package:cloud_firestore/cloud_firestore.dart';

enum ProductCategory { sanitaryPads, babyDiapers, adultDiapers }

extension ProductCategoryX on ProductCategory {
  String get value {
    switch (this) {
      case ProductCategory.sanitaryPads: return 'sanitary_pads';
      case ProductCategory.babyDiapers: return 'baby_diapers';
      case ProductCategory.adultDiapers: return 'adult_diapers';
    }
  }
  String get title {
    switch (this) {
      case ProductCategory.sanitaryPads: return 'Sanitary Pads';
      case ProductCategory.babyDiapers: return 'Baby Diapers';
      case ProductCategory.adultDiapers: return 'Adult Diapers';
    }
  }
  String get shortTitle {
    switch (this) {
      case ProductCategory.sanitaryPads: return 'Sanitary';
      case ProductCategory.babyDiapers: return 'Baby';
      case ProductCategory.adultDiapers: return 'Adult';
    }
  }
}

ProductCategory productCategoryFromString(String? value) {
  switch (value) {
    case 'baby_diapers': return ProductCategory.babyDiapers;
    case 'adult_diapers': return ProductCategory.adultDiapers;
    default: return ProductCategory.sanitaryPads;
  }
}

class Product {
  const Product({
    required this.id,
    required this.name,
    required this.brand,
    required this.category,
    required this.description,
    required this.highlights,
    required this.attributes,
    required this.mrp,
    this.salePrice,
    required this.stockCount,
    required this.rating,
    required this.reviewCount,
    required this.isAvailable,
    this.isBestSeller = false,
    this.isNew = false,
    required this.tileColor,
    this.imageUrl,
    this.imageStoragePath,
  });

  final String id;
  final String name;
  final String brand;
  final ProductCategory category;
  final String description;
  final List<String> highlights;
  final List<String> attributes;
  final double mrp;
  final double? salePrice;
  final int stockCount;
  final double rating;
  final int reviewCount;
  final bool isAvailable;
  final bool isBestSeller;
  final bool isNew;
  final int tileColor;
  final String? imageUrl;
  final String? imageStoragePath;

  double get finalPrice => salePrice ?? mrp;
  bool get hasImage => imageUrl != null && imageUrl!.trim().length > 10;

  int? get discountPercent {
    if (salePrice == null || mrp <= 0) return null;
    return (((mrp - salePrice!) / mrp) * 100).round();
  }

  Product copyWith({
    String? id,
    String? name,
    String? brand,
    ProductCategory? category,
    String? description,
    List<String>? highlights,
    List<String>? attributes,
    double? mrp,
    double? salePrice,
    int? stockCount,
    double? rating,
    int? reviewCount,
    bool? isAvailable,
    bool? isBestSeller,
    bool? isNew,
    int? tileColor,
    String? imageUrl,
    String? imageStoragePath,
  }) {
    return Product(
      id: id ?? this.id,
      name: name ?? this.name,
      brand: brand ?? this.brand,
      category: category ?? this.category,
      description: description ?? this.description,
      highlights: highlights ?? this.highlights,
      attributes: attributes ?? this.attributes,
      mrp: mrp ?? this.mrp,
      salePrice: salePrice ?? this.salePrice,
      stockCount: stockCount ?? this.stockCount,
      rating: rating ?? this.rating,
      reviewCount: reviewCount ?? this.reviewCount,
      isAvailable: isAvailable ?? this.isAvailable,
      isBestSeller: isBestSeller ?? this.isBestSeller,
      isNew: isNew ?? this.isNew,
      tileColor: tileColor ?? this.tileColor,
      imageUrl: imageUrl ?? this.imageUrl,
      imageStoragePath: imageStoragePath ?? this.imageStoragePath,
    );
  }

  factory Product.fromMap(Map<String, dynamic> map, {String? id}) {
    return Product(
      id: id ?? map['id']?.toString() ?? '',
      name: map['name']?.toString() ?? '',
      brand: map['brand']?.toString() ?? '',
      category: productCategoryFromString(map['category']?.toString()),
      description: map['description']?.toString() ?? '',
      highlights: List<String>.from(map['highlights'] as List? ?? const []),
      attributes: List<String>.from(map['attributes'] as List? ?? const []),
      mrp: (map['mrp'] as num?)?.toDouble() ?? 0,
      salePrice: (map['salePrice'] as num?)?.toDouble(),
      stockCount: (map['stockCount'] as num?)?.toInt() ?? 0,
      rating: (map['rating'] as num?)?.toDouble() ?? 4.5,
      reviewCount: (map['reviewCount'] as num?)?.toInt() ?? 0,
      isAvailable: map['isAvailable'] as bool? ?? true,
      isBestSeller: map['isBestSeller'] as bool? ?? false,
      isNew: map['isNew'] as bool? ?? false,
      tileColor: (map['tileColor'] as num?)?.toInt() ?? 0xFFF6D5E1,
      imageUrl: map['imageUrl']?.toString(),
      imageStoragePath: map['imageStoragePath']?.toString(),
    );
  }

  factory Product.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    return Product.fromMap(doc.data() ?? const {}, id: doc.id);
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'brand': brand,
      'category': category.value,
      'description': description,
      'highlights': highlights,
      'attributes': attributes,
      'mrp': mrp,
      'salePrice': salePrice,
      'stockCount': stockCount,
      'rating': rating,
      'reviewCount': reviewCount,
      'isAvailable': isAvailable,
      'isBestSeller': isBestSeller,
      'isNew': isNew,
      'tileColor': tileColor,
      'imageUrl': imageUrl,
      'imageStoragePath': imageStoragePath,
    };
  }
}
