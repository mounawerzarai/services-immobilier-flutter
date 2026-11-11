import '../../data/models/listing.dart';
import '../../data/models/listing_summary.dart' show kCurrency;

String transactionLabel(String t) => t == 'rent' ? 'Location' : 'Vente';

// 1250000 -> « 1 250 000 » (espace insécable), décimales seulement si nécessaire.
String _group(num n) {
  final fixed = n == n.truncate() ? n.truncate().toString() : n.toStringAsFixed(2);
  final parts = fixed.split('.');
  final grouped = parts[0].replaceAllMapped(
    RegExp(r'\B(?=(\d{3})+(?!\d))'),
    (_) => '\u00A0',
  );
  return parts.length > 1 ? '$grouped,${parts[1]}' : grouped;
}

String _plain(num n) => n == n.truncate() ? n.truncate().toString() : n.toString();

String formatPrice(Listing l) {
  final base = '${_group(l.price)} $kCurrency';
  return l.transactionType == 'rent' ? '$base / mois' : base;
}

String formatDetails(Listing l) {
  final parts = <String>[];
  if (l.city.isNotEmpty) parts.add(l.city);
  if ((l.surface ?? 0) > 0) parts.add('${_plain(l.surface!)} m²');
  if ((l.rooms ?? 0) > 0) parts.add('${l.rooms} pièce${l.rooms! > 1 ? 's' : ''}');
  return parts.join(' · ');
}

const _propertyTypes = {
  'apartment': 'Appartement',
  'house': 'Maison',
  'land': 'Terrain',
  'commercial': 'Local commercial',
};

String propertyTypeLabel(String? t) =>
    t == null || t.isEmpty ? '' : (_propertyTypes[t] ?? t);

// Petites pastilles de la page détail : type, surface, nombre de pièces.
List<String> formatFacts(Listing l) => [
      propertyTypeLabel(l.propertyType),
      if ((l.surface ?? 0) > 0) '${_plain(l.surface!)} m²',
      if ((l.rooms ?? 0) > 0) '${l.rooms} pièce${l.rooms! > 1 ? 's' : ''}',
    ].where((s) => s.isNotEmpty).toList();