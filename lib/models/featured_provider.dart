/// A provider shown in the customer app's featured (مقدمون مميزون) strip.
/// Managed entirely from the dashboard: the admin adds/edits/deletes these
/// entries in Firestore and they appear instantly in the customer app.
///
/// Besides the strip itself the provider has a full details page, so it also
/// carries optional descriptive fields (specialty, capacity, location, ...).
class FeaturedProvider {
  final String id;
  final String name;

  /// Display rating, e.g. 4.9.
  final double rating;

  /// Full display price, e.g. 'ريال 120,000'.
  final String price;

  /// Cover image: a Firebase Storage download URL (after an upload) or a
  /// base64 data URI (dashboard preview before saving).
  final String image;

  /// Insertion order (epoch millis); used so the list keeps dashboard order.
  final int createdAt;

  /// Optional specialty / service type, e.g. 'قاعة أفراح', 'منظم حفلات'.
  final String? category;

  /// Optional price type label, e.g. 'لكل ليلة', 'باقة كاملة'.
  final String? priceType;

  /// Optional capacity, e.g. '300 شخص'.
  final String? capacity;

  /// Optional governorate / location, e.g. 'أمانة العاصمة صنعاء'.
  final String? location;

  /// Optional short description shown on the details page.
  final String? description;

  /// Optional contact number (opened via WhatsApp / phone call).
  final String? phone;

  const FeaturedProvider({
    required this.id,
    required this.name,
    this.rating = 4.8,
    required this.price,
    required this.image,
    this.createdAt = 0,
    this.category,
    this.priceType,
    this.capacity,
    this.location,
    this.description,
    this.phone,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'rating': rating,
        'price': price,
        'image': image,
        'createdAt': createdAt,
        'category': category,
        'priceType': priceType,
        'capacity': capacity,
        'location': location,
        'description': description,
        'phone': phone,
      };

  factory FeaturedProvider.fromJson(Map<String, dynamic> json) =>
      FeaturedProvider(
        id: (json['id'] ?? '') as String,
        name: (json['name'] ?? '') as String,
        rating: (json['rating'] as num?)?.toDouble() ?? 4.8,
        price: (json['price'] ?? '') as String,
        image: (json['image'] ?? '') as String,
        createdAt: (json['createdAt'] as num?)?.toInt() ?? 0,
        category: json['category'] as String?,
        priceType: json['priceType'] as String?,
        capacity: json['capacity'] as String?,
        location: json['location'] as String?,
        description: json['description'] as String?,
        phone: json['phone'] as String?,
      );
}