import 'dart:async';
import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart' show FirebaseException;
import 'package:flutter/material.dart';

import '../../models/product.dart';
import '../../services/app_bootstrap.dart';
import '../../services/firestore_service.dart';
import '../../services/storage_service.dart';
import '../../widgets/product_media.dart';

class AdminProductsTab extends StatefulWidget {
  const AdminProductsTab({super.key});

  @override
  State<AdminProductsTab> createState() => _AdminProductsTabState();
}

class _AdminProductsTabState extends State<AdminProductsTab> {
  String _search = '';
  ProductCategory? _selectedCategory;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Product>>(
      stream: FirestoreService.instance.productsStream(
        includeUnavailable: true,
      ),
      builder: (context, snapshot) {
        final products = (snapshot.data ?? const <Product>[]).where((product) {
          final matchesCategory =
              _selectedCategory == null ||
              product.category == _selectedCategory;
          final needle = _search.toLowerCase();
          final matchesSearch =
              needle.isEmpty ||
              product.name.toLowerCase().contains(needle) ||
              product.brand.toLowerCase().contains(needle);
          return matchesCategory && matchesSearch;
        }).toList();

        final isWide = MediaQuery.of(context).size.width > 700;
        return ListView(
          padding: const EdgeInsets.all(12),
          children: [
            _BackendStatusCard(
              firestoreReady: FirestoreService.instance.isBackendReady,
              firebaseConfigured: AppBootstrap.instance.isConfigured,
              storageReady: StorageService.instance.isReady,
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                SizedBox(
                  width: isWide ? 280 : double.infinity,
                  child: TextField(
                    decoration: const InputDecoration(
                      prefixIcon: Icon(Icons.search),
                      labelText: 'Search products',
                    ),
                    onChanged: (value) => setState(() => _search = value),
                  ),
                ),
                SizedBox(
                  width: isWide ? 220 : double.infinity,
                  child: DropdownButtonFormField<ProductCategory?>(
                    value: _selectedCategory,
                    decoration: const InputDecoration(labelText: 'Category'),
                    items: [
                      const DropdownMenuItem<ProductCategory?>(
                        value: null,
                        child: Text('All categories'),
                      ),
                      ...ProductCategory.values.map(
                        (category) => DropdownMenuItem<ProductCategory?>(
                          value: category,
                          child: Text(category.title),
                        ),
                      ),
                    ],
                    onChanged: (value) =>
                        setState(() => _selectedCategory = value),
                  ),
                ),
                FilledButton.icon(
                  onPressed: () => _openProductDialog(context),
                  icon: const Icon(Icons.add),
                  label: const Text('Add product'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (products.isEmpty)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'No products yet',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Use the Seed Phase 1 data button in the top bar once, then edit products here and upload real product photos from your device.',
                      ),
                      const SizedBox(height: 16),
                      OutlinedButton.icon(
                        onPressed: () => _openProductDialog(context),
                        icon: const Icon(Icons.add_photo_alternate_outlined),
                        label: const Text('Add first product manually'),
                      ),
                    ],
                  ),
                ),
              )
            else
              LayoutBuilder(
                builder: (context, constraints) {
                  final isWide = constraints.maxWidth > 700;
                  return Column(
                    children: products.map((product) {
                      return Card(
                        margin: const EdgeInsets.symmetric(vertical: 8),
                        child: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: isWide
                              ? Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    _buildLeading(product),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(product.name, style: Theme.of(context).textTheme.titleMedium),
                                          const SizedBox(height: 4),
                                          Text(
                                            '${product.brand} - ${product.category.title}',
                                            style: Theme.of(context).textTheme.bodySmall,
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            'Rs ${product.finalPrice.toStringAsFixed(0)}  |  Stock: ${product.stockCount}',
                                            style: Theme.of(context).textTheme.bodySmall,
                                          ),
                                        ],
                                      ),
                                    ),
                                    Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Switch(
                                          value: product.isAvailable,
                                          onChanged: (value) =>
                                              FirestoreService.instance.setProduct(
                                                product.copyWith(isAvailable: value),
                                              ),
                                        ),
                                        Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            IconButton(
                                              visualDensity: VisualDensity.compact,
                                              icon: const Icon(Icons.edit_outlined),
                                              onPressed: () => _openProductDialog(context, product: product),
                                            ),
                                            IconButton(
                                              visualDensity: VisualDensity.compact,
                                              icon: const Icon(Icons.delete_outline),
                                              onPressed: () => _confirmDelete(context, product),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ],
                                )
                              : Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        _buildLeading(product),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(product.name, style: Theme.of(context).textTheme.titleMedium),
                                              const SizedBox(height: 4),
                                              Text(
                                                '${product.brand} - ${product.category.title}',
                                                style: Theme.of(context).textTheme.bodySmall,
                                              ),
                                              const SizedBox(height: 4),
                                              Text(
                                                'Rs ${product.finalPrice.toStringAsFixed(0)}  |  Stock: ${product.stockCount}',
                                                style: Theme.of(context).textTheme.bodySmall,
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Switch(
                                          value: product.isAvailable,
                                          onChanged: (value) =>
                                              FirestoreService.instance.setProduct(
                                                product.copyWith(isAvailable: value),
                                              ),
                                        ),
                                        Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            IconButton(
                                              visualDensity: VisualDensity.compact,
                                              icon: const Icon(Icons.edit_outlined),
                                              onPressed: () => _openProductDialog(context, product: product),
                                            ),
                                            IconButton(
                                              visualDensity: VisualDensity.compact,
                                              icon: const Icon(Icons.delete_outline),
                                              onPressed: () => _confirmDelete(context, product),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                        ),
                      );
                    }).toList(),
                  );
                },
              ),
          ],
        );
      },
    );
  }

  Widget _buildLeading(Product product) {
    if (product.hasImage) {
      return ProductMedia(
        imageUrl: product.imageUrl!,
        width: 52,
        height: 52,
        borderRadius: BorderRadius.circular(12),
        fallbackIcon: _iconForCategory(product.category),
      );
    }
    return Container(
      width: 52,
      height: 52,
      decoration: BoxDecoration(
        color: const Color(0xFFF7F1F3),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(
        _iconForCategory(product.category),
        size: 28,
        color: const Color(0xFF9E6C7E),
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext context, Product product) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete product'),
        content: const Text(
          'Are you sure you want to delete this product? This cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    if ((product.imageStoragePath ?? '').isNotEmpty) {
      await StorageService.instance.deleteByPath(product.imageStoragePath);
    }
    await FirestoreService.instance.deleteProduct(product.id);
  }

  Future<void> _openProductDialog(
    BuildContext context, {
    Product? product,
  }) async {
    final formKey = GlobalKey<FormState>();
    final nameController = TextEditingController(text: product?.name ?? '');
    final brandController = TextEditingController(text: product?.brand ?? '');
    final externalImageController = TextEditingController(
      text: product?.imageStoragePath == null ? (product?.imageUrl ?? '') : '',
    );
    final descriptionController = TextEditingController(
      text: product?.description ?? '',
    );
    final highlightsController = TextEditingController(
      text: product?.highlights.join(', ') ?? '',
    );
    final attributesController = TextEditingController(
      text: product?.attributes.join(', ') ?? '',
    );
    final mrpController = TextEditingController(
      text: product?.mrp.toStringAsFixed(0) ?? '',
    );
    final saleController = TextEditingController(
      text: product?.salePrice?.toStringAsFixed(0) ?? '',
    );
    final stockController = TextEditingController(
      text: product?.stockCount.toString() ?? '100',
    );

    var category = product?.category ?? ProductCategory.sanitaryPads;
    var isAvailable = product?.isAvailable ?? true;
    var isBestSeller = product?.isBestSeller ?? false;
    var isNew = product?.isNew ?? false;
    var persistedImageUrl = product?.imageUrl;
    var persistedStoragePath = product?.imageStoragePath;
    SelectedProductImage? selectedImage;
    var removeImage = false;
    var isSaving = false;
    String? errorMessage;

    try {
      await showDialog<void>(
        context: context,
        builder: (context) {
          return StatefulBuilder(
            builder: (context, setModalState) {
              final width = MediaQuery.of(context).size.width;
              final dialogWidth = width < 760 ? width * 0.9 : 560.0;
              final remotePreview = !removeImage
                  ? _previewImageUrl(
                      persistedImageUrl: persistedImageUrl,
                      persistedStoragePath: persistedStoragePath,
                      externalImageUrl: externalImageController.text.trim(),
                    )
                  : null;

              return AlertDialog(
                title: Text(product == null ? 'Add product' : 'Edit product'),
                content: SizedBox(
                  width: dialogWidth,
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      maxHeight: MediaQuery.of(context).size.height * 0.85,
                    ),
                    child: SingleChildScrollView(
                      child: Form(
                        key: formKey,
                        autovalidateMode: AutovalidateMode.onUserInteraction,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const _DialogSectionTitle('Product image'),
                            _buildDialogImagePreview(
                              previewBytes: selectedImage?.bytes,
                              previewUrl: remotePreview,
                              category: category,
                            ),
                            const SizedBox(height: 12),
                            Wrap(
                              spacing: 12,
                              runSpacing: 12,
                              children: [
                                OutlinedButton.icon(
                                  onPressed: isSaving
                                      ? null
                                      : () async {
                                          try {
                                            final picked = await StorageService
                                                .instance
                                                .pickProductImage();
                                            if (picked == null) {
                                              return;
                                            }
                                            setModalState(() {
                                              selectedImage = picked;
                                              removeImage = false;
                                              errorMessage = null;
                                            });
                                          } catch (error) {
                                            setModalState(() {
                                              errorMessage = error
                                                .toString()
                                                .replaceFirst(
                                                  'Exception: ',
                                                  '',
                                                );
                                          });
                                        }
                                      },
                                  icon: const Icon(Icons.upload_file_outlined),
                                  label: const Text('Upload from device'),
                                ),
                                if (selectedImage != null ||
                                    remotePreview != null)
                                  TextButton.icon(
                                    onPressed: isSaving
                                        ? null
                                        : () {
                                            setModalState(() {
                                              selectedImage = null;
                                              externalImageController.clear();
                                              removeImage = true;
                                              errorMessage = null;
                                            });
                                          },
                                    icon: const Icon(Icons.delete_outline),
                                    label: const Text('Remove image'),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              StorageService.instance.isReady
                                  ? 'Uploads are sent to Firebase Storage and linked in Firestore.'
                                  : 'Storage is not ready. You can still save products without uploading an image.',
                            ),
                            const SizedBox(height: 12),
                            TextFormField(
                              controller: externalImageController,
                              decoration: const InputDecoration(
                                labelText: 'External image URL (optional)',
                                hintText:
                                    'Use only if image is already hosted online',
                              ),
                              keyboardType: TextInputType.url,
                              onChanged: (_) => setModalState(() {
                                removeImage = false;
                                errorMessage = null;
                              }),
                            ),
                            const SizedBox(height: 14),
                            const Divider(),
                            const SizedBox(height: 6),
                            const _DialogSectionTitle('Basic details'),
                            TextFormField(
                              controller: nameController,
                              decoration: const InputDecoration(
                                labelText: 'Product name',
                              ),
                              validator: (value) => (value ?? '').trim().isEmpty
                                  ? 'Product name is required.'
                                  : null,
                            ),
                            const SizedBox(height: 10),
                            TextFormField(
                              controller: brandController,
                              decoration: const InputDecoration(
                                labelText: 'Brand',
                              ),
                              validator: (value) => (value ?? '').trim().isEmpty
                                  ? 'Brand is required.'
                                  : null,
                            ),
                            const SizedBox(height: 10),
                            DropdownButtonFormField<ProductCategory>(
                              value: category,
                              decoration: const InputDecoration(
                                labelText: 'Category',
                              ),
                              items: ProductCategory.values
                                  .map(
                                    (item) => DropdownMenuItem(
                                      value: item,
                                      child: Text(item.title),
                                    ),
                                  )
                                  .toList(),
                              onChanged: (value) => setModalState(
                                () => category =
                                    value ?? ProductCategory.sanitaryPads,
                              ),
                            ),
                            const SizedBox(height: 10),
                            TextFormField(
                              controller: descriptionController,
                              decoration: const InputDecoration(
                                labelText: 'Description',
                              ),
                              maxLines: 3,
                              validator: (value) => (value ?? '').trim().isEmpty
                                  ? 'Description is required.'
                                  : null,
                            ),
                            const SizedBox(height: 10),
                            TextFormField(
                              controller: highlightsController,
                              decoration: const InputDecoration(
                                labelText: 'Highlights (comma separated)',
                              ),
                            ),
                            const SizedBox(height: 10),
                            TextFormField(
                              controller: attributesController,
                              decoration: const InputDecoration(
                                labelText: 'Attributes (comma separated)',
                              ),
                            ),
                            const SizedBox(height: 14),
                            const Divider(),
                            const SizedBox(height: 6),
                            const _DialogSectionTitle('Pricing and inventory'),
                            TextFormField(
                              controller: mrpController,
                              decoration: const InputDecoration(labelText: 'MRP'),
                              keyboardType: TextInputType.number,
                              validator: (value) {
                                final mrp = double.tryParse((value ?? '').trim());
                                if (mrp == null || mrp <= 0) {
                                  return 'MRP must be greater than 0.';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 10),
                            TextFormField(
                              controller: saleController,
                              decoration: const InputDecoration(
                                labelText: 'Sale price (optional)',
                              ),
                              keyboardType: TextInputType.number,
                              validator: (value) {
                                final trimmed = (value ?? '').trim();
                                if (trimmed.isEmpty) {
                                  return null;
                                }
                                final sale = double.tryParse(trimmed);
                                if (sale == null || sale <= 0) {
                                  return 'Sale price must be a valid number.';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 10),
                            TextFormField(
                              controller: stockController,
                              decoration: const InputDecoration(
                                labelText: 'Stock count',
                              ),
                              keyboardType: TextInputType.number,
                              validator: (value) {
                                final stock = int.tryParse((value ?? '').trim());
                                if (stock == null || stock < 0) {
                                  return 'Stock count must be 0 or more.';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 10),
                            SwitchListTile(
                              title: const Text('Available'),
                              value: isAvailable,
                              onChanged: (value) =>
                                  setModalState(() => isAvailable = value),
                            ),
                            SwitchListTile(
                              title: const Text('Bestseller'),
                              value: isBestSeller,
                              onChanged: (value) =>
                                  setModalState(() => isBestSeller = value),
                            ),
                            SwitchListTile(
                              title: const Text('New arrival'),
                              value: isNew,
                              onChanged: (value) =>
                                  setModalState(() => isNew = value),
                            ),
                            if (isSaving) ...[
                              const SizedBox(height: 12),
                              const LinearProgressIndicator(),
                              const SizedBox(height: 8),
                              const Text('Saving product...'),
                            ],
                            if ((errorMessage ?? '').isNotEmpty) ...[
                              const SizedBox(height: 12),
                              Text(
                                errorMessage!,
                                style: TextStyle(
                                  color: Theme.of(context).colorScheme.error,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                actions: [
                  TextButton(
                    onPressed: isSaving ? null : () => Navigator.pop(context),
                    child: const Text('Cancel'),
                  ),
                  FilledButton(
                    onPressed: isSaving
                        ? null
                        : () async {
                            final form = formKey.currentState;
                            if (form == null || !form.validate()) {
                              return;
                            }

                            final name = nameController.text.trim();
                            final brand = brandController.text.trim();
                            final description = descriptionController.text.trim();
                            final mrp = double.tryParse(mrpController.text.trim()) ?? 0;
                            final productId = product?.id ?? _slug(name);
                            final externalImageUrl = externalImageController.text.trim();

                            if (productId.isEmpty) {
                              setModalState(
                                () => errorMessage = 'Please enter a valid product name.',
                              );
                              return;
                            }

                            setModalState(() {
                              isSaving = true;
                              errorMessage = null;
                            });

                            try {
                              String? imageUrl;
                              String? imageStoragePath;

                              if (selectedImage != null) {
                                final uploaded = await StorageService.instance.uploadProductImage(
                                  productId: productId,
                                  image: selectedImage!,
                                  replacePath: persistedStoragePath,
                                );
                                imageUrl = uploaded.url;
                                imageStoragePath = uploaded.storagePath;
                              } else if (!removeImage && externalImageUrl.isNotEmpty) {
                                if ((persistedStoragePath ?? '').isNotEmpty) {
                                  await StorageService.instance.deleteByPath(
                                    persistedStoragePath,
                                  );
                                }
                                imageUrl = externalImageUrl;
                                imageStoragePath = null;
                              } else if (!removeImage && (persistedStoragePath ?? '').isNotEmpty) {
                                imageUrl = persistedImageUrl;
                                imageStoragePath = persistedStoragePath;
                              } else {
                                if ((persistedStoragePath ?? '').isNotEmpty) {
                                  await StorageService.instance.deleteByPath(
                                    persistedStoragePath,
                                  );
                                }
                                imageUrl = null;
                                imageStoragePath = null;
                              }

                              final built = Product(
                                id: productId,
                                name: name,
                                brand: brand,
                                category: category,
                                description: description,
                                highlights: _splitCsv(highlightsController.text),
                                attributes: _splitCsv(attributesController.text),
                                mrp: mrp,
                                salePrice: saleController.text.trim().isEmpty
                                    ? null
                                    : double.tryParse(saleController.text.trim()),
                                stockCount: int.tryParse(stockController.text.trim()) ?? 0,
                                rating: product?.rating ?? 4.6,
                                reviewCount: product?.reviewCount ?? 0,
                                isAvailable: isAvailable,
                                isBestSeller: isBestSeller,
                                isNew: isNew,
                                tileColor: product?.tileColor ?? _defaultColor(category),
                                imageUrl: imageUrl,
                                imageStoragePath: imageStoragePath,
                              );

                              await _saveProductWithRetry(built);
                              if (context.mounted) {
                                Navigator.pop(context);
                              }
                            } on FirebaseException catch (error) {
                              setModalState(() {
                                isSaving = false;
                                errorMessage = _firebaseSaveError(error);
                              });
                            } on TimeoutException {
                              setModalState(() {
                                isSaving = false;
                                errorMessage =
                                    'Timed out while contacting Firestore. Please check internet and Firebase project access.';
                              });
                            } catch (error) {
                              setModalState(() {
                                isSaving = false;
                                errorMessage = error
                                    .toString()
                                    .replaceFirst('Exception: ', '')
                                    .replaceFirst('StateError: ', '');
                              });
                            }
                          },
                    child: Text(isSaving ? 'Saving...' : 'Save'),
                  ),
                ],
              );
            },
          );
        },
      );
    } finally {
      nameController.dispose();
      brandController.dispose();
      externalImageController.dispose();
      descriptionController.dispose();
      highlightsController.dispose();
      attributesController.dispose();
      mrpController.dispose();
      saleController.dispose();
      stockController.dispose();
    }
  }

  Widget _buildDialogImagePreview({
    required Uint8List? previewBytes,
    required String? previewUrl,
    required ProductCategory category,
  }) {
    if (previewBytes != null) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Image.memory(
          previewBytes,
          width: 148,
          height: 148,
          fit: BoxFit.cover,
        ),
      );
    }

    if ((previewUrl ?? '').trim().isNotEmpty) {
      return ProductMedia(
        imageUrl: previewUrl!,
        width: 148,
        height: 148,
        borderRadius: BorderRadius.circular(20),
        fallbackIcon: _iconForCategory(category),
      );
    }

    return Container(
      width: 148,
      height: 148,
      decoration: BoxDecoration(
        color: const Color(0xFFF7F1F3),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Icon(
        _iconForCategory(category),
        size: 40,
        color: const Color(0xFF9E6C7E),
      ),
    );
  }

  String? _previewImageUrl({
    required String? persistedImageUrl,
    required String? persistedStoragePath,
    required String externalImageUrl,
  }) {
    if (externalImageUrl.isNotEmpty) {
      return externalImageUrl;
    }
    if ((persistedStoragePath ?? '').isNotEmpty) {
      return persistedImageUrl;
    }
    return null;
  }

  List<String> _splitCsv(String value) {
    return value
        .split(',')
        .map((item) => item.trim())
        .where((item) => item.isNotEmpty)
        .toList();
  }

  String _slug(String input) {
    return input
        .trim()
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]+'), '_')
        .replaceAll(RegExp(r'^_|_$'), '');
  }

  int _defaultColor(ProductCategory category) {
    switch (category) {
      case ProductCategory.sanitaryPads:
        return 0xFFF7D9E3;
      case ProductCategory.babyDiapers:
        return 0xFFDFF1F7;
      case ProductCategory.adultDiapers:
        return 0xFFF0EDF3;
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

  String _firebaseSaveError(FirebaseException error) {
    switch (error.code) {
      case 'permission-denied':
        return 'Permission denied. This account is not allowed to write products.';
      case 'unauthenticated':
        return 'You are not authenticated with Firebase.';
      case 'unavailable':
        return 'Firestore is currently unavailable.';
      case 'deadline-exceeded':
        return 'Firestore request timed out.';
      default:
        final message = (error.message ?? '').trim();
        if (message.isNotEmpty) {
          return 'Firebase error (${error.code}): $message';
        }
        return 'Firebase error: ${error.code}';
    }
  }

  Future<void> _saveProductWithRetry(Product product) async {
    const maxAttempts = 2;
    var attempt = 0;

    while (true) {
      attempt += 1;
      try {
        await FirestoreService.instance
            .setProduct(product)
            .timeout(const Duration(seconds: 20));
        return;
      } on TimeoutException {
        if (attempt >= maxAttempts) {
          rethrow;
        }
        await Future<void>.delayed(Duration(milliseconds: 500 * attempt));
      } on FirebaseException catch (error) {
        final retryable =
            error.code == 'unavailable' ||
            error.code == 'deadline-exceeded' ||
            error.code == 'aborted';

        if (!retryable || attempt >= maxAttempts) {
          rethrow;
        }

        await Future<void>.delayed(Duration(milliseconds: 500 * attempt));
      }
    }
  }
}

class _DialogSectionTitle extends StatelessWidget {
  const _DialogSectionTitle(this.title);

  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        title,
        style: Theme.of(
          context,
        ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800),
      ),
    );
  }
}

class _BackendStatusCard extends StatelessWidget {
  const _BackendStatusCard({
    required this.firestoreReady,
    required this.firebaseConfigured,
    required this.storageReady,
  });

  final bool firestoreReady;
  final bool firebaseConfigured;
  final bool storageReady;

  @override
  Widget build(BuildContext context) {
    final backendLabel = firestoreReady
        ? 'Connected to Firestore'
        : 'Running in local fallback mode';
    final backendColor = firestoreReady
        ? Colors.green.shade700
        : Colors.orange.shade700;

    return Card(
      color: const Color(0xFFFFF8F4),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Backend status',
              style: Theme.of(
                context,
              ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.cloud_done_outlined, size: 18, color: backendColor),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    backendLabel,
                    style: TextStyle(
                      color: backendColor,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              'Firebase config: ${firebaseConfigured ? 'Configured' : 'Missing'}  |  Storage: ${storageReady ? 'Ready' : 'Not ready'}',
            ),
            if (!firestoreReady)
              const Padding(
                padding: EdgeInsets.only(top: 6),
                child: Text(
                  'Changes here will not persist to Firebase until backend connection succeeds.',
                ),
              ),
          ],
        ),
      ),
    );
  }
}
