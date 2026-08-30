import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/place_item_model.dart';
import 'booking_store.dart';

/// Customer-side cart backed by Firestore under the customer's own id, so the
/// same saved items ("سلاتك") follow the account. Items are added via
/// "احجز الآن" then confirmed into booking requests.
class CartStore {
  CartStore._();

  static final CartStore instance = CartStore._();

  static const String _collection = 'carts';

  FirebaseFirestore get _db => FirebaseFirestore.instance;

  List<PlaceItem> _cache = const [];

  Future<String> _myCartId() => BookingStore.instance.getOrCreateCustomerId();

  Future<List<PlaceItem>> load() async {
    if (_cache.isNotEmpty) return _cache;
    return reload();
  }

  Future<List<PlaceItem>> reload() async {
    try {
      final userId = await _myCartId();
      final doc = await _db.collection(_collection).doc(userId).get();
      final raw = doc.data()?['items'] as List?;
      final items = <PlaceItem>[];
      if (raw != null) {
        for (final e in raw) {
          try {
            items.add(
              PlaceItem.fromJson((e as Map).cast<String, dynamic>()),
            );
          } catch (_) {
            // Skip any malformed entry; keep the rest.
          }
        }
      }
      _cache = items;
    } catch (_) {
      _cache = const [];
    }
    return _cache;
  }

  Future<bool> add(PlaceItem item) async {
    final current = await reload();
    if (current.any((e) => e.id == item.id)) return true;
    return _persist([...current, item]);
  }

  Future<bool> remove(String id) async {
    final current = await reload();
    return _persist([for (final e in current) if (e.id != id) e]);
  }

  Future<bool> clear() => _persist(const []);

  Future<bool> _persist(List<PlaceItem> items) async {
    _cache = items;
    try {
      final userId = await _myCartId();
      await _db.collection(_collection).doc(userId).set({
        'customerId': userId,
        'updatedAt': DateTime.now().toIso8601String(),
        'items': items.map((e) => e.toJson()).toList(),
      });
      return true;
    } catch (_) {
      return false;
    }
  }
}