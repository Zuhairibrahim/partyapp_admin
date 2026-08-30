import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/services.dart';

import '../models/booking_model.dart';

/// Cloud Firestore-backed booking store shared between the customer app and
/// the admin dashboard. The customer app creates requests (each tagged with
/// its own [customerId]); the dashboard lists ALL customers' orders and
/// updates their status; the customer's "طلباتي" inbox filters them back to
/// its own orders.
class BookingStore {
  BookingStore._();

  static final BookingStore instance = BookingStore._();

  static const String _collection = 'bookings';

  FirebaseFirestore get _db => FirebaseFirestore.instance;

  static const MethodChannel _channel = MethodChannel('partyapp/bookingstore');

  List<Booking> _cache = const [];

  Future<List<Booking>> load() async {
    if (_cache.isNotEmpty) return _cache;
    return reload();
  }

  Future<List<Booking>> reload() async {
    try {
      final snapshot = await _db.collection(_collection).get();
      final bookings = <Booking>[];
      for (final doc in snapshot.docs) {
        try {
          bookings.add(Booking.fromJson(doc.data()));
        } catch (_) {
          // Skip any malformed document; keep the rest.
        }
      }
      _cache = bookings;
    } catch (_) {
      _cache = const [];
    }
    return _cache;
  }

  Future<bool> add(Booking booking) async {
    try {
      await _db
          .collection(_collection)
          .doc(booking.id)
          .set(booking.toJson());
      _cache = [..._cache, booking];
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> updateStatus(String id, BookingStatus status) async {
    try {
      await _db.collection(_collection).doc(id).update({
        'status': status.name,
      });
      final list = [
        for (final b in _cache)
          b.id == id ? b.copyWith(status: status) : b,
      ];
      _cache = list;
      return true;
    } catch (_) {
      return false;
    }
  }

  /// Returns the persistent unique id of the account on THIS device. After the
  /// name+phone login the id file holds the phone-derived account id, so the
  /// same number always maps to the same account on any device and every
  /// customer sees only their own bookings. Before a login it falls back to a
  /// per-installation id kept in the native id file.
  Future<String> getOrCreateCustomerId() async {
    try {
      final existing = await _channel.invokeMethod<String>('readId');
      if (existing != null && existing.isNotEmpty) return existing;
    } catch (_) {
      // No native side (tests/web): fall through and generate in-process.
    }
    final random = Random();
    final id = 'c${DateTime.now().millisecondsSinceEpoch}_'
        '${random.nextInt(0xFFFFFF).toRadixString(16)}';
    try {
      await _channel.invokeMethod<String>('writeId', id);
    } catch (_) {
      // Best-effort; the id still works for this session.
    }
    return id;
  }
}