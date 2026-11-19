import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:services_immobilier/features/map/geo.dart';

void main() {
  const tunis = LatLng(36.8065, 10.1815);
  const lac = LatLng(36.8350, 10.2300); // Les Berges du Lac
  const sousse = LatLng(35.8256, 10.6084);

  test('distance Tunis - Sousse ≈ 115 km', () {
    expect(distanceKm(tunis, sousse), closeTo(115, 5));
  });

  test('distance nulle pour le même point', () {
    expect(distanceKm(tunis, tunis), 0);
  });

  test('withinRadius filtre et trie par distance', () {
    final res = withinRadius<LatLng>([sousse, lac, tunis], tunis, 10, (p) => p);
    expect(res.map((r) => r.item), [tunis, lac]);
    expect(res.first.distanceKm, 0);
  });

  test('formatDistance', () {
    expect(formatDistance(0.853), '850 m');
    expect(formatDistance(1.234), '1,2 km');
    expect(formatDistance(12.6), '13 km');
  });

  test('shortPrice', () {
    expect(shortPrice(420000, 'sale'), '420 k DT');
    expect(shortPrice(2500, 'rent'), '2 500 DT');
  });
}
