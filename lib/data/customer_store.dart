import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/services.dart';

import '../models/customer_profile.dart';
import 'booking_store.dart';

/// Cloud Firestore-backed store for customer registration profiles, keyed by
/// the customer's phone number (`u<phone>`), so the same number always restores
/// the same account (profile, bookings and cart) on any device. The services
/// catalogue on the home screen is shared and identical for every customer;
/// only each user's own data (profile, cart, orders) is isolated.
class CustomerStore {
  CustomerStore._();

  static final CustomerStore instance = CustomerStore._();

  static const String _collection = 'profiles';

  static const MethodChannel _channel = MethodChannel('partyapp/customerstore');

  FirebaseFirestore get _db => FirebaseFirestore.instance;

  CustomerProfile? _cache;

  /// Loads THIS device's own profile (null until the user logs in).
  Future<CustomerProfile?> load() async {
    if (_cache != null) return _cache;
    return reload();
  }

  Future<CustomerProfile?> reload() async {
    final customerId = await BookingStore.instance.getOrCreateCustomerId();
    try {
      final doc = await _db.collection(_collection).doc(customerId).get();
      if (!doc.exists) {
        _cache = null;
        return null;
      }
      _cache = CustomerProfile.fromJson(doc.data()!);
    } catch (_) {
      _cache = null;
    }
    return _cache;
  }

  /// Loads every registered customer profile (used by the dashboard's orders
  /// section to group orders per customer).
  Future<List<CustomerProfile>> loadAll() async {
    try {
      final snapshot = await _db.collection(_collection).get();
      final profiles = <CustomerProfile>[];
      for (final doc in snapshot.docs) {
        try {
          profiles.add(CustomerProfile.fromJson(doc.data()));
        } catch (_) {
          // Skip any malformed document; keep the rest.
        }
      }
      return profiles;
    } catch (_) {
      return const [];
    }
  }

  /// Deterministic account id for a phone number: the same number always maps
  /// to the same account on any device.
  static String accountIdForPhone(String phone) =>
      'u${phone.replaceAll(RegExp(r'\D'), '')}';

  Future<CustomerProfile?> findByPhone(String phone) async {
    final digits = phone.replaceAll(RegExp(r'\D'), '');
    if (digits.isEmpty) return null;
    try {
      final snapshot = await _db
          .collection(_collection)
          .where('phone', isEqualTo: digits)
          .limit(1)
          .get();
      if (snapshot.docs.isEmpty) return null;
      return CustomerProfile.fromJson(snapshot.docs.first.data());
    } catch (_) {
      // Offline or malformed result: treat as a brand new account.
      return null;
    }
  }

  /// Logs in with [name] and [phone]. If an account already exists for this
  /// phone number it is restored (together with its bookings and cart);
  /// otherwise a fresh account is created.
  Future<CustomerProfile> ensureProfile({
    required String name,
    required String phone,
  }) async {
    final digits = phone.replaceAll(RegExp(r'\D'), '');
    final existing = await findByPhone(digits);
    final profile = existing ??
        CustomerProfile(
          customerId: accountIdForPhone(digits),
          name: name.trim(),
          phone: digits,
          createdAt: DateTime.now().toIso8601String(),
        );
    await save(profile);
    return profile;
  }

  /// Saves the profile in Firestore. The account id is also written to the
  /// native id file so bookings and the cart get the same id, and the profile
  /// json file mirrors it for compatibility.
  Future<bool> save(CustomerProfile profile) async {
    try {
      await _db
          .collection(_collection)
          .doc(profile.customerId)
          .set(profile.toJson());
    } catch (_) {
      return false;
    }
    try {
      await _channel.invokeMethod<String>('writeId', profile.customerId);
      await _channel.invokeMethod<String>('write', jsonEncode(profile.toJson()));
    } catch (_) {
      // Best-effort; the profile still lives in Firestore.
    }
    _cache = profile;
    return true;
  }

  /// Logs out on this device: clears the in-memory profile and deletes the
  /// locally stored profile + customer id files, so the splash goes back to
  /// the mandatory login screen on next launch. Past bookings stay in
  /// Firestore under the phone account and reappear when the user logs back in
  /// with the same number.
  Future<void> clearLocal() async {
    _cache = null;
    try {
      await _channel.invokeMethod<String>('clear');
    } catch (_) {
      // Best-effort; in-memory state is already gone.
    }
  }
}