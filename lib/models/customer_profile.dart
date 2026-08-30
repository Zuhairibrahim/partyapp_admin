import 'dart:math';

/// The customer's mandatory registration profile: just the [name] and the
/// required [phone]. The [customerId] ties every booking this customer creates
/// to this profile, so the dashboard can show each customer's name and open
/// their own inbox.
class CustomerProfile {
  final String customerId;
  final String name;
  final String phone;
  final String createdAt;

  const CustomerProfile({
    required this.customerId,
    required this.name,
    required this.phone,
    required this.createdAt,
  });

  String get fullName => name.trim();

  /// One-time persistent id for this app installation (same scheme used by
  /// the bookings, so bookings and the profile always line up).
  static String generateId() {
    final random = Random();
    return 'c${DateTime.now().millisecondsSinceEpoch}_'
        '${random.nextInt(0xFFFFFF).toRadixString(16)}';
  }

  CustomerProfile copyWith({String? customerId}) => CustomerProfile(
        customerId: customerId ?? this.customerId,
        name: name,
        phone: phone,
        createdAt: createdAt,
      );

  Map<String, dynamic> toJson() => {
        'customerId': customerId,
        'name': name,
        'phone': phone,
        'createdAt': createdAt,
      };

  factory CustomerProfile.fromJson(Map<String, dynamic> json) =>
      CustomerProfile(
        customerId: (json['customerId'] ?? '') as String,
        name: (json['name'] ?? '') as String,
        phone: (json['phone'] ?? '') as String,
        createdAt: (json['createdAt'] ?? '') as String,
      );
}