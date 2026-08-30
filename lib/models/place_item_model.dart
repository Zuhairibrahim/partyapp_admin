import 'package:flutter/material.dart';

/// A reusable, bookable listing item (chalet, hall, salon, park, vendor,
/// photographer, dj, ...). One model powers every category so the whole
/// app shares a single list -> details -> booking flow.
class PlaceItem {
  final String id;
  final String name;

  /// Category title, e.g. 'الشاليهات'.
  final String category;

  /// Id of the home screen section this item belongs to (e.g. 'chalets',
  /// 'dresses'). For built-in catalog items this is filled in when the item is
  /// shown; for admin-added items it is the section the admin picked.
  final String? catalogId;

  final String? description;

  /// Full display price, e.g. '4,000 ريال'.
  final String price;

  /// Price type label, e.g. 'لكل ليلة', 'باقة كاملة', 'لكل جلسة'.
  final String? priceType;

  /// Capacity, e.g. '20 شخص'.
  final String? capacity;

  final String location;
  final double rating;
  final int reviews;

  final String mainImage;
  final List<String> images;

  /// Optional feature flags list (مسبح، مجلس، مطبخ، مواقف، جلسات خارجية...).
  final List<String> features;

  final int? rooms;
  final int? bathrooms;
  final int? majlis;
  final bool pool;
  final bool kitchen;
  final bool parking;
  final String? checkIn;
  final String? checkOut;

  /// Optional generic key-value specs shown before/after the structured ones.
  final Map<String, String> specs;

  /// Contact number for service/artist type categories.
  final String? phone;

  /// The day+date label chosen by the customer at booking time, e.g.
  /// "السبت - 5/10/2026". Only set on cart items / booked copies, never on
  /// the admin-added master item.
  final String? bookedDate;

  final bool isVendor;

  const PlaceItem({
    required this.id,
    required this.name,
    required this.category,
    this.catalogId,
    this.description,
    required this.price,
    this.priceType,
    this.capacity,
    required this.location,
    this.rating = 4.8,
    this.reviews = 0,
    required this.mainImage,
    this.images = const [],
    this.features = const [],
    this.rooms,
    this.bathrooms,
    this.majlis,
    this.pool = false,
    this.kitchen = false,
    this.parking = false,
    this.checkIn,
    this.checkOut,
    this.specs = const {},
    this.phone,
    this.bookedDate,
    this.isVendor = false,
  });

  PlaceItem copyWith({
    String? id,
    String? catalogId,
    String? bookedDate,
  }) =>
      PlaceItem(
        id: id ?? this.id,
        name: name,
        category: category,
        catalogId: catalogId ?? this.catalogId,
        description: description,
        price: price,
        priceType: priceType,
        capacity: capacity,
        location: location,
        rating: rating,
        reviews: reviews,
        mainImage: mainImage,
        images: images,
        features: features,
        rooms: rooms,
        bathrooms: bathrooms,
        majlis: majlis,
        pool: pool,
        kitchen: kitchen,
        parking: parking,
        checkIn: checkIn,
        checkOut: checkOut,
        specs: specs,
        phone: phone,
        bookedDate: bookedDate ?? this.bookedDate,
        isVendor: isVendor,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'category': category,
        'catalogId': catalogId,
        'description': description,
        'price': price,
        'priceType': priceType,
        'capacity': capacity,
        'location': location,
        'rating': rating,
        'reviews': reviews,
        'mainImage': mainImage,
        'images': images,
        'features': features,
        'rooms': rooms,
        'bathrooms': bathrooms,
        'majlis': majlis,
        'pool': pool,
        'kitchen': kitchen,
        'parking': parking,
        'checkIn': checkIn,
        'checkOut': checkOut,
        'specs': specs,
        'phone': phone,
        'bookedDate': bookedDate,
        'isVendor': isVendor,
      };

  factory PlaceItem.fromJson(Map<String, dynamic> json) => PlaceItem(
        id: (json['id'] ?? '') as String,
        name: (json['name'] ?? '') as String,
        category: (json['category'] ?? '') as String,
        catalogId: json['catalogId'] as String?,
        description: json['description'] as String?,
        price: (json['price'] ?? '') as String,
        priceType: json['priceType'] as String?,
        capacity: json['capacity'] as String?,
        location: (json['location'] ?? '') as String,
        rating: (json['rating'] as num?)?.toDouble() ?? 4.8,
        reviews: (json['reviews'] as num?)?.toInt() ?? 0,
        mainImage: (json['mainImage'] ?? '') as String,
        images: (json['images'] as List?)?.cast<String>() ?? const [],
        features: (json['features'] as List?)?.cast<String>() ?? const [],
        rooms: (json['rooms'] as num?)?.toInt(),
        bathrooms: (json['bathrooms'] as num?)?.toInt(),
        majlis: (json['majlis'] as num?)?.toInt(),
        pool: json['pool'] == true,
        kitchen: json['kitchen'] == true,
        parking: json['parking'] == true,
        checkIn: json['checkIn'] as String?,
        checkOut: json['checkOut'] as String?,
        specs: (json['specs'] as Map?)?.cast<String, String>() ?? const {},
        phone: json['phone'] as String?,
        bookedDate: json['bookedDate'] as String?,
        isVendor: json['isVendor'] == true,
      );

  List<String> get allImages =>
      images.isEmpty ? <String>[mainImage] : images;

  bool get usesLocalImages =>
      mainImage.startsWith('data:') || mainImage.startsWith('/') ||
      images.any((i) => i.startsWith('data:') || i.startsWith('/'));

  IconData get defaultIcon {
    if (category.contains('شاليه') || category.contains('منتزه')) {
      return Icons.holiday_village_outlined;
    }
    if (category.contains('قاع') || category.contains('صال')) {
      return Icons.home_work_outlined;
    }
    if (category.contains('مصور') || category.contains('تصوير')) {
      return Icons.photo_camera_outlined;
    }
    if (category.contains('دي جي') || category.contains('دجي')) {
      return Icons.music_note_outlined;
    }
    if (category.contains('فيديو')) {
      return Icons.videocam_outlined;
    }
    if (category.contains('فساتين')) {
      return Icons.checkroom_outlined;
    }
    if (category.contains('إضاء')) {
      return Icons.highlight_outlined;
    }
    if (category.contains('زين')) {
      return Icons.auto_awesome_outlined;
    }
    if (category.contains('كوش')) {
      return Icons.local_florist_outlined;
    }
    return Icons.storefront_outlined;
  }
}
