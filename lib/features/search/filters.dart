import '../../data/models/listing.dart';
import 'search_listings.dart' show normalize;

/// Filtres de l'écran d'accueil (T5.2). Une valeur absente = pas de filtre.
class Filters {
  const Filters({
    this.transactionType, // 'sale' | 'rent'
    this.propertyType,
    this.city = '',
    this.minPrice,
    this.maxPrice,
    this.minRooms,
  });

  final String? transactionType;
  final String? propertyType;
  final String city;
  final num? minPrice;
  final num? maxPrice;
  final int? minRooms;

  /// Nombre de filtres actifs (affiché sur le bouton « Filtres »).
  int get activeCount => [
        transactionType,
        propertyType,
        city.trim().isEmpty ? null : city,
        minPrice,
        maxPrice,
        minRooms,
      ].where((v) => v != null).length;

  bool get isEmpty => activeCount == 0;
}

const kPropertyTypeKeys = ['apartment', 'house', 'land', 'commercial'];

const kRoomChoices = [1, 2, 3, 4, 5];

/// « 120 000 » ou « 1200,5 » -> nombre ; vide, invalide ou <= 0 -> null.
num? parsePrice(String text) {
  final cleaned = text.replaceAll(RegExp(r'\s'), '').replaceAll(',', '.');
  if (cleaned.isEmpty) return null;
  final n = num.tryParse(cleaned);
  return (n != null && n.isFinite && n > 0) ? n : null;
}

/// Garde les annonces qui respectent TOUS les filtres actifs.
List<Listing> applyFilters(List<Listing> items, Filters f) {
  final city = normalize(f.city);
  return items.where((l) {
    if (f.transactionType != null && l.transactionType != f.transactionType) {
      return false;
    }
    if (f.propertyType != null && l.propertyType != f.propertyType) {
      return false;
    }
    if (city.isNotEmpty && !normalize(l.city).contains(city)) return false;
    if (f.minPrice != null && l.price < f.minPrice!) return false;
    if (f.maxPrice != null && l.price > f.maxPrice!) return false;
    if (f.minRooms != null && (l.rooms ?? 0) < f.minRooms!) return false;
    return true;
  }).toList();
}
