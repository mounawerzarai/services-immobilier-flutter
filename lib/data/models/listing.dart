import 'package:cloud_firestore/cloud_firestore.dart';

/// Annonce complète (collection Firestore : listings).
class Listing {
  const Listing({
    required this.id,
    required this.title,
    required this.price,
    required this.transactionType,
    required this.sellerId,
    this.description = '',
    this.propertyType,
    this.surface,
    this.rooms,
    this.address = '',
    this.city = '',
    this.latitude,
    this.longitude,
    this.photos = const [],
    this.status = 'available',
    this.createdAt,
  });

  final String id;
  final String title;
  final num price;
  final String transactionType; // sale | rent
  final String sellerId;
  final String description;
  final String? propertyType;
  final num? surface;
  final int? rooms;
  final String address;
  final String city;
  final double? latitude;
  final double? longitude;
  final List<String> photos;
  final String status; // available | sold | rented
  final DateTime? createdAt;

  factory Listing.fromMap(String id, Map<String, dynamic> d) {
    final created = d['createdAt'];
    return Listing(
      id: id,
      title: (d['title'] as String?) ?? 'Annonce sans titre',
      price: (d['price'] as num?) ?? 0,
      transactionType: (d['transactionType'] as String?) ?? 'sale',
      sellerId: (d['sellerId'] as String?) ?? '',
      description: (d['description'] as String?) ?? '',
      propertyType: d['propertyType'] as String?,
      surface: d['surface'] as num?,
      rooms: (d['rooms'] as num?)?.toInt(),
      address: (d['address'] as String?) ?? '',
      city: (d['city'] as String?) ?? '',
      latitude: (d['latitude'] as num?)?.toDouble(),
      longitude: (d['longitude'] as num?)?.toDouble(),
      photos: ((d['photos'] as List?) ?? const []).whereType<String>().toList(),
      status: (d['status'] as String?) ?? 'available',
      createdAt: created is Timestamp ? created.toDate() : null,
    );
  }
}