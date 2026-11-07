import 'package:cloud_firestore/cloud_firestore.dart';

/// Devise affichée à côté des prix.
const String kCurrency = 'DT';

/// Version réduite d'une annonce (collection Firestore : listings),
/// suffisante pour la liste « Mes annonces » du profil.
class ListingSummary {
  const ListingSummary({
    required this.id,
    required this.title,
    this.price,
    this.city = '',
    this.createdAt,
  });

  final String id;
  final String title;
  final num? price;
  final String city;
  final DateTime? createdAt;

  factory ListingSummary.fromMap(String id, Map<String, dynamic> data) {
    final created = data['createdAt'];
    return ListingSummary(
      id: id,
      title: (data['title'] as String?) ?? 'Annonce sans titre',
      price: data['price'] as num?,
      city: (data['city'] as String?) ?? '',
      createdAt: created is Timestamp ? created.toDate() : null,
    );
  }
}