/// Status of a booking request, managed from the admin dashboard.
enum BookingStatus {
  pending,
  processing,
  approved,
  completed,
  rejected;

  String get label => switch (this) {
        BookingStatus.pending => 'جاري الانتظار',
        BookingStatus.processing => 'جاري تلبية طلبك',
        BookingStatus.approved => 'تم قبول طلبك بنجاح',
        BookingStatus.completed => 'تم تنفيذ الطلب',
        BookingStatus.rejected => 'تم رفض الطلب',
      };
}

/// A customer booking request. Created in the customer app (after confirming
/// from the cart) then listed and managed from the admin dashboard through the
/// shared local bookings store. Each booking is tagged with its own
/// [customerId] so the customer app only shows its owner's orders while the
/// dashboard receives every customer's orders.
class Booking {
  final String id;
  final String customerId;
  final String itemId;
  final String itemName;
  final String itemCategory;
  final String itemImage;
  final String date;
  final String location;
  final List<String> services;
  final int totalPrice;
  final BookingStatus status;
  final String createdAt;

  const Booking({
    required this.id,
    required this.customerId,
    required this.itemId,
    required this.itemName,
    required this.itemCategory,
    required this.itemImage,
    required this.date,
    required this.location,
    this.services = const [],
    this.totalPrice = 0,
    this.status = BookingStatus.pending,
    required this.createdAt,
  });

  String get statusLabel => status.label;

  Booking copyWith({BookingStatus? status}) => Booking(
        id: id,
        customerId: customerId,
        itemId: itemId,
        itemName: itemName,
        itemCategory: itemCategory,
        itemImage: itemImage,
        date: date,
        location: location,
        services: services,
        totalPrice: totalPrice,
        status: status ?? this.status,
        createdAt: createdAt,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'customerId': customerId,
        'itemId': itemId,
        'itemName': itemName,
        'itemCategory': itemCategory,
        'itemImage': itemImage,
        'date': date,
        'location': location,
        'services': services,
        'totalPrice': totalPrice,
        'status': status.name,
        'createdAt': createdAt,
      };

  factory Booking.fromJson(Map<String, dynamic> json) => Booking(
        id: (json['id'] ?? '') as String,
        customerId: (json['customerId'] ?? '') as String,
        itemId: (json['itemId'] ?? '') as String,
        itemName: (json['itemName'] ?? '') as String,
        itemCategory: (json['itemCategory'] ?? '') as String,
        itemImage: (json['itemImage'] ?? '') as String,
        date: (json['date'] ?? '') as String,
        location: (json['location'] ?? '') as String,
        services: (json['services'] as List?)?.cast<String>() ?? const [],
        totalPrice: (json['totalPrice'] as num?)?.toInt() ?? 0,
        status: BookingStatus.values.asNameMap()[json['status']] ??
            BookingStatus.pending,
        createdAt: (json['createdAt'] ?? '') as String,
      );
}