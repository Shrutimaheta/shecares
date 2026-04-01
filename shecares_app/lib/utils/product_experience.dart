import '../models/product.dart';

class ProductExperience {
  const ProductExperience({
    required this.gallery,
    required this.deliveryLabel,
    required this.soldLabel,
    required this.trustTags,
    required this.story,
    this.videoUrl,
  });

  final List<String> gallery;
  final String deliveryLabel;
  final String soldLabel;
  final List<String> trustTags;
  final String story;
  final String? videoUrl;
}

ProductExperience productExperienceFor(Product product) {
  switch (product.category) {
    case ProductCategory.sanitaryPads:
      return ProductExperience(
        gallery: _galleryFor(product, _padGallery),
        deliveryLabel: product.isBestSeller
            ? 'Fast-moving essential, ships today'
            : 'Discreet delivery across Ahmedabad',
        soldLabel: product.isBestSeller
            ? '1.2k bought this month'
            : 'Popular monthly essential',
        trustTags: const [
          'Discreet packing',
          'Comfort-first',
          'Monthly restock',
        ],
        story:
            'Built for reliable repeat ordering with dignity-first delivery and privacy-safe packaging.',
        videoUrl: _padVideoProducts.contains(product.id) ? _sampleVideo : null,
      );
    case ProductCategory.babyDiapers:
      return ProductExperience(
        gallery: _galleryFor(product, _babyGallery),
        deliveryLabel: 'Same-day dispatch on stocked sizes',
        soldLabel: product.isBestSeller
            ? '850 family reorders this month'
            : 'Trusted by busy caregivers',
        trustTags: const [
          'Leak protection',
          'Family reorder friendly',
          'Doorstep restock',
        ],
        story:
            'Sized for repeat purchasing, quick reorder flows, and dependable family restocking.',
        videoUrl: _babyVideoProducts.contains(product.id) ? _sampleVideo : null,
      );
    case ProductCategory.adultDiapers:
      return ProductExperience(
        gallery: _galleryFor(product, _adultGallery),
        deliveryLabel: 'Home-care ready with plain packaging',
        soldLabel: product.isBestSeller
            ? '620 caregiver reorders this month'
            : 'Caregiver-approved comfort',
        trustTags: const [
          'Private delivery',
          'Caregiver support',
          'Home-care staple',
        ],
        story:
            'Designed for caregiver confidence, privacy-sensitive fulfillment, and easy repeat supply.',
        videoUrl: _adultVideoProducts.contains(product.id)
            ? _sampleVideo
            : null,
      );
  }
}

List<String> _galleryFor(Product product, List<String> fallback) {
  final image = product.imageUrl;
  if (image == null || image.trim().isEmpty) {
    return fallback;
  }
  return [image, ...fallback.where((item) => item != image)];
}

String categoryHeroImage(ProductCategory category) {
  switch (category) {
    case ProductCategory.sanitaryPads:
      return _padGallery.first;
    case ProductCategory.babyDiapers:
      return _babyGallery.first;
    case ProductCategory.adultDiapers:
      return _adultGallery.first;
  }
}

const _sampleVideo = 'https://samplelib.com/lib/preview/mp4/sample-5s.mp4';

const _padVideoProducts = {
  'pads_whisper_ultra_clean_xl_plus',
  'pads_sofy_antibacterial',
};

const _babyVideoProducts = {
  'baby_pampers_active_nb',
  'baby_mamypoko_extra_absorb_m',
};

const _adultVideoProducts = {'adult_friends_premium_m'};

const _padGallery = [
  'https://images.pexels.com/photos/3735657/pexels-photo-3735657.jpeg?auto=compress&cs=tinysrgb&w=1200',
  'https://images.pexels.com/photos/6621143/pexels-photo-6621143.jpeg?auto=compress&cs=tinysrgb&w=1200',
  'https://images.pexels.com/photos/4041392/pexels-photo-4041392.jpeg?auto=compress&cs=tinysrgb&w=1200',
];

const _babyGallery = [
  'https://images.pexels.com/photos/3662667/pexels-photo-3662667.jpeg?auto=compress&cs=tinysrgb&w=1200',
  'https://images.pexels.com/photos/1257110/pexels-photo-1257110.jpeg?auto=compress&cs=tinysrgb&w=1200',
  'https://images.pexels.com/photos/5793459/pexels-photo-5793459.jpeg?auto=compress&cs=tinysrgb&w=1200',
];

const _adultGallery = [
  'https://images.pexels.com/photos/7551670/pexels-photo-7551670.jpeg?auto=compress&cs=tinysrgb&w=1200',
  'https://images.pexels.com/photos/7551682/pexels-photo-7551682.jpeg?auto=compress&cs=tinysrgb&w=1200',
  'https://images.pexels.com/photos/3768131/pexels-photo-3768131.jpeg?auto=compress&cs=tinysrgb&w=1200',
];
