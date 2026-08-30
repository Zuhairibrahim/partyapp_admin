import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img;
import 'package:partyapp_admin/models/featured_provider.dart';
import 'package:partyapp_admin/models/place_item_model.dart';

/// Dashboard store backed by Cloud Firestore (the `places` collection) plus
/// Firebase Storage. The item texts and prices are written to the `places`
/// document; photos picked in the form are uploaded to Firebase Storage
/// automatically and the resulting download URLs are stored in
/// `mainImage`/`images`, so the customer app shows them directly over the
/// network. The customer app reads the SAME collection, so a newly saved item
/// appears in it immediately.
class DashboardStore {
  DashboardStore._();

  static final DashboardStore instance = DashboardStore._();

  static const String _collection = 'places';

  static const String _featuredCollection = 'featured';

  FirebaseFirestore get _db => FirebaseFirestore.instance;

  List<PlaceItem> _cache = const [];

  Future<List<PlaceItem>> load() async {
    if (_cache.isNotEmpty) return _cache;
    return reload();
  }

  /// Reads the whole `places` collection from Firestore.
  Future<List<PlaceItem>> reload() async {
    try {
      final snapshot = await _db.collection(_collection).get();
      final items = <PlaceItem>[];
      for (final doc in snapshot.docs) {
        try {
          items.add(PlaceItem.fromJson(doc.data()));
        } catch (_) {
          // Skip any malformed document; keep the rest.
        }
      }
      _cache = items;
    } catch (_) {
      _cache = const [];
    }
    return _cache;
  }

  Future<bool> add(PlaceItem item) async {
    final stored = await _withStoredImages(item);
    final items = List<PlaceItem>.from(_cache)..add(stored);
    _cache = items;
    try {
      await _db.collection(_collection).doc(stored.id).set(stored.toJson());
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> update(PlaceItem item) async {
    final stored = await _withStoredImages(item);
    final items = List<PlaceItem>.from(_cache);
    final index = items.indexWhere((e) => e.id == stored.id);
    if (index == -1) {
      items.add(stored);
    } else {
      items[index] = stored;
    }
    _cache = items;
    try {
      await _db.collection(_collection).doc(stored.id).set(stored.toJson());
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> remove(String id) async {
    final items = List<PlaceItem>.from(_cache)
      ..removeWhere((e) => e.id == id);
    _cache = items;
    try {
      await _db.collection(_collection).doc(id).delete();
      return true;
    } catch (_) {
      return false;
    }
  }

  /// Reads the whole `featured` collection from Firestore, in dashboard order.
  Future<List<FeaturedProvider>> loadFeatured() async {
    try {
      final snapshot = await _db.collection(_featuredCollection).get();
      final items = <FeaturedProvider>[];
      for (final doc in snapshot.docs) {
        try {
          items.add(FeaturedProvider.fromJson(doc.data()));
        } catch (_) {
          // Skip any malformed document; keep the rest.
        }
      }
      items.sort((a, b) => a.createdAt.compareTo(b.createdAt));
      return items;
    } catch (_) {
      return const [];
    }
  }

  /// Adds a new featured provider to the `featured` collection, uploading any
  /// base64 photo to Firebase Storage first.
  Future<bool> addFeatured(FeaturedProvider item) async {
    final stored = await _withFeaturedImages(item);
    try {
      await _db
          .collection(_featuredCollection)
          .doc(stored.id)
          .set(stored.toJson());
      return true;
    } catch (_) {
      return false;
    }
  }

  /// Replaces a featured provider with the same id.
  Future<bool> updateFeatured(FeaturedProvider item) async {
    final stored = await _withFeaturedImages(item);
    try {
      await _db
          .collection(_featuredCollection)
          .doc(stored.id)
          .set(stored.toJson());
      return true;
    } catch (_) {
      return false;
    }
  }

  /// Removes a featured provider by id.
  Future<bool> removeFeatured(String id) async {
    try {
      await _db.collection(_featuredCollection).doc(id).delete();
      return true;
    } catch (_) {
      return false;
    }
  }

  /// Uploads the featured provider's base64/data-URI photo to Firebase
  /// Storage and swaps it for its download URL. Network URLs are kept as-is.
  Future<FeaturedProvider> _withFeaturedImages(
    FeaturedProvider item,
  ) async {
    if (!item.image.startsWith('data:')) return item;
    final url = await _uploadImage(
      item.image,
      'featured/${item.id}/photo_${DateTime.now().millisecondsSinceEpoch}_0.jpg',
    );
    final json = item.toJson();
    json['image'] = url;
    return FeaturedProvider.fromJson(json);
  }

  /// Uploads one image: data-URI photos go to [path] in Firebase Storage and
  /// the download URL is returned; network/local sources are kept as-is.
  Future<String> _uploadImage(String source, String path) async {
    if (!source.startsWith('data:')) return source;
    try {
      final bytes = memoryBytes(source);
      final ref = FirebaseStorage.instance.ref(path);
      await ref.putData(bytes, SettableMetadata(contentType: 'image/jpeg'));
      return await ref.getDownloadURL();
    } catch (_) {
      // Keep the data URI so the item still appears (even without storage).
      return source;
    }
  }

  /// Uploads any base64/data-URI photos to Firebase Storage and swaps them for
  /// their download URLs, so the customer app can fetch them over the network.
  /// Existing network URLs (e.g. from a previous save) are kept as-is. All
  /// images are uploaded in parallel so saving a multi-photo item is fast.
  Future<PlaceItem> _withStoredImages(PlaceItem item) async {
    final sources = item.images.isEmpty
        ? <String>[item.mainImage]
        : List<String>.from(item.images);
    final stamp = DateTime.now().millisecondsSinceEpoch;
    final urls = await Future.wait<String>([
      for (var i = 0; i < sources.length; i++)
        _uploadImage(sources[i], 'places/${item.id}/photo_${stamp}_$i.jpg'),
    ]);
    if (urls.isEmpty) return item;
    final json = item.toJson();
    json['mainImage'] = urls.first;
    json['images'] = urls;
    return PlaceItem.fromJson(json);
  }

  /// Converts picked image bytes into a base64 data URI that the shared
  /// AppImage widget can render in both apps.
  static String toDataUri(Uint8List bytes) =>
      'data:image/jpeg;base64,${base64Encode(bytes)}';

  /// Shrinks and re-compresses raw image bytes (on a background isolate) so a
  /// whole photo gallery stays small before uploading to Firebase Storage.
  /// Returns the original bytes if it cannot be decoded.
  static Future<Uint8List> compressAsync(Uint8List bytes) =>
      compute(_compressIsolate, bytes);

  static Uint8List _compressIsolate(Uint8List bytes) =>
      compressImage(bytes);

  /// Shrinks and re-compresses raw image bytes so a whole photo gallery stays
  /// small enough before uploading to Firebase Storage. Returns the original
  /// bytes if it cannot be decoded.
  static Uint8List compressImage(
    Uint8List bytes, {
    int maxWidth = 760,
    int quality = 52,
  }) {
    try {
      final decoded = img.decodeImage(bytes);
      if (decoded == null) return bytes;
      final resized = decoded.width > maxWidth
          ? img.copyResize(decoded, width: maxWidth)
          : decoded;
      return Uint8List.fromList(img.encodeJpg(resized, quality: quality));
    } catch (_) {
      return bytes;
    }
  }

  /// Decodes a base64 data URI back to bytes (for inline previews/uploads).
  static Uint8List memoryBytes(String dataUri) =>
      base64Decode(dataUri.split(',').last);
}