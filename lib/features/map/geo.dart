import 'dart:math' as math;

import 'package:latlong2/latlong.dart';

/// Calculs de distance pour « Recherche autour de moi » (T6.2).
/// Mêmes règles que src/features/map/geo.ts (version React Native).

/// Rayons proposés à l'utilisateur, en kilomètres.
const kRadiusChoices = [1, 2, 5, 10, 20, 50];
const kDefaultRadiusKm = 5;

const double _earthRadiusKm = 6371;
double _rad(double deg) => deg * math.pi / 180;

/// Distance à vol d'oiseau entre deux points (formule de haversine), en km.
double distanceKm(LatLng a, LatLng b) {
  final dLat = _rad(b.latitude - a.latitude);
  final dLon = _rad(b.longitude - a.longitude);
  final h = math.pow(math.sin(dLat / 2), 2) +
      math.cos(_rad(a.latitude)) *
          math.cos(_rad(b.latitude)) *
          math.pow(math.sin(dLon / 2), 2);
  return 2 * _earthRadiusKm * math.asin(math.sqrt(h));
}

/// « 850 m », « 1,2 km », « 12 km ».
String formatDistance(double km) {
  if (km < 1) {
    final m = math.max(10, ((km * 1000) / 10).round() * 10);
    return '$m m';
  }
  if (km < 10) return '${km.toStringAsFixed(1).replaceAll('.', ',')} km';
  return '${km.round()} km';
}

/// Niveau de zoom qui fait tenir le cercle à l'écran (approximation).
double zoomForRadius(num radiusKm) =>
    (14.5 - math.log(radiusKm) / math.ln2).clamp(6, 16).toDouble();

/// Prix court pour les marqueurs : « 420 k DT », « 2 500 DT ».
String shortPrice(num price, String transactionType) {
  String group(int n) => n.toString().replaceAllMapped(
        RegExp(r'\B(?=(\d{3})+(?!\d))'),
        (_) => ' ',
      );
  if (transactionType != 'rent' && price >= 1000) {
    return '${group((price / 1000).round())} k DT';
  }
  return '${group(price.round())} DT';
}

/// Élément accompagné de sa distance à l'utilisateur.
class WithDistance<T> {
  const WithDistance(this.item, this.distanceKm);
  final T item;
  final double distanceKm;
}

/// Garde les éléments situés dans le rayon, triés du plus proche au plus loin.
List<WithDistance<T>> withinRadius<T>(
  Iterable<T> items,
  LatLng center,
  num radiusKm,
  LatLng? Function(T) positionOf,
) {
  final result = <WithDistance<T>>[];
  for (final item in items) {
    final p = positionOf(item);
    if (p == null) continue;
    final d = distanceKm(center, p);
    if (d <= radiusKm) result.add(WithDistance(item, d));
  }
  result.sort((a, b) => a.distanceKm.compareTo(b.distanceKm));
  return result;
}
