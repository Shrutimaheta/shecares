import 'dart:typed_data';

import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';

import '../utils/constants.dart';
import 'app_bootstrap.dart';

class SelectedProductImage {
  const SelectedProductImage({required this.bytes, required this.fileName});

  final Uint8List bytes;
  final String fileName;
}

class UploadedProductImage {
  const UploadedProductImage({required this.url, required this.storagePath});

  final String url;
  final String storagePath;
}

class StorageService {
  StorageService._();

  static final StorageService instance = StorageService._();

  final ImagePicker _picker = ImagePicker();

  bool get isReady => AppBootstrap.instance.firebaseReady;

  Future<SelectedProductImage?> pickProductImage() async {
    final file = await _picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1600,
      imageQuality: 88,
    );
    if (file == null) {
      return null;
    }

    final bytes = await file.readAsBytes();
    final fileName = file.name.trim().isEmpty ? 'image.jpg' : file.name;
    return SelectedProductImage(bytes: bytes, fileName: fileName);
  }

  Future<UploadedProductImage> uploadProductImage({
    required String productId,
    required SelectedProductImage image,
    String? replacePath,
  }) async {
    final safeProductId = _safeSegment(
      productId.isEmpty ? 'product' : productId,
    );
    return _uploadImage(
      storagePath:
          'products/$safeProductId/${DateTime.now().millisecondsSinceEpoch}.${_extensionFromName(image.fileName)}',
      image: image,
      replacePath: replacePath,
      customMetadata: {'productId': safeProductId},
    );
  }

  Future<UploadedProductImage> uploadCheckoutQrImage({
    required SelectedProductImage image,
    String? replacePath,
  }) async {
    return _uploadImage(
      storagePath: AppConstants.defaultCheckoutQrPath,
      image: image,
      replacePath: replacePath,
      customMetadata: const {'type': 'checkout_qr'},
    );
  }

  Future<String?> resolveDownloadUrl(String? path) async {
    if (!isReady || path == null || path.trim().isEmpty) {
      return null;
    }

    try {
      return await FirebaseStorage.instance.ref(path).getDownloadURL();
    } on FirebaseException catch (error) {
      if (error.code == 'object-not-found') {
        return null;
      }
      rethrow;
    }
  }

  Future<void> deleteByPath(String? path) async {
    if (!isReady || path == null || path.trim().isEmpty) {
      return;
    }

    try {
      await FirebaseStorage.instance.ref(path).delete();
    } on FirebaseException catch (error) {
      if (error.code != 'object-not-found') {
        rethrow;
      }
    }
  }

  Future<UploadedProductImage> _uploadImage({
    required String storagePath,
    required SelectedProductImage image,
    String? replacePath,
    Map<String, String>? customMetadata,
  }) async {
    if (!isReady) {
      throw StateError(
        'Firebase Storage is not configured yet. Enable Storage in Firebase before uploading images.',
      );
    }

    final extension = _extensionFromName(image.fileName);
    final reference = FirebaseStorage.instance.ref(storagePath);
    final metadata = SettableMetadata(
      contentType: _mimeTypeForExtension(extension),
      customMetadata: customMetadata,
    );

    await reference.putData(image.bytes, metadata);
    final downloadUrl = await reference.getDownloadURL();

    if (replacePath != null &&
        replacePath.trim().isNotEmpty &&
        replacePath != storagePath) {
      await deleteByPath(replacePath);
    }

    return UploadedProductImage(url: downloadUrl, storagePath: storagePath);
  }

  String _extensionFromName(String fileName) {
    final dotIndex = fileName.lastIndexOf('.');
    if (dotIndex == -1 || dotIndex == fileName.length - 1) {
      return 'jpg';
    }

    return fileName.substring(dotIndex + 1).toLowerCase();
  }

  String _mimeTypeForExtension(String extension) {
    switch (extension) {
      case 'png':
        return 'image/png';
      case 'webp':
        return 'image/webp';
      case 'gif':
        return 'image/gif';
      case 'heic':
      case 'heif':
        return 'image/heic';
      case 'jpeg':
      case 'jpg':
      default:
        return 'image/jpeg';
    }
  }

  String _safeSegment(String value) {
    return value
        .trim()
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9_-]+'), '_')
        .replaceAll(RegExp(r'_+'), '_')
        .replaceAll(RegExp(r'^_|_$'), '');
  }
}
