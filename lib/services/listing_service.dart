
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'image_uploader.dart';

class ListingService {
  final _db = FirebaseFirestore.instance;

  /// Recherche d'adresse avec OpenStreetMap Nominatim
  Future<({double lat, double lng})?> _nominatim(String q) async {
    final uri = Uri.https('nominatim.openstreetmap.org', '/search', {
      'q': q,
      'format': 'json',
      'limit': '1',
      'countrycodes': 'tn',
    });

    final response = await http.get(
      uri,
      headers: {
        'User-Agent': 'ServicesImmobilier/1.0 (projet etudiant)',
      },
    );

    if (response.statusCode != 200) {
      throw Exception(
        'Service d\'adresse indisponible (${response.statusCode})',
      );
    }

    final results = jsonDecode(response.body) as List;

    if (results.isEmpty) return null;

    return (
      lat: double.parse(results.first['lat'] as String),
      lng: double.parse(results.first['lon'] as String),
    );
  }

  /// Essaie l'adresse complète, puis la ville seule
  Future<({double lat, double lng})> _geocode(
    String address,
    String city,
  ) async {
    final found =
        await _nominatim('$address, $city') ?? await _nominatim(city);

    if (found == null) {
      throw Exception('Ville introuvable. Vérifiez son orthographe.');
    }

    return found;
  }

  Future<void> createListing({
    required String title,
    required String description,
    required double price,
    required double surface,
    required int? rooms,
    required String propertyType,
    required String transactionType,
    required String address,
    required String city,
    required List<XFile> photos,
  }) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      throw Exception('Vous devez être connecté.');
    }

    // 1. Adresse -> latitude / longitude
    final position = await _geocode(address, city);

    // 2. Réserver l'identifiant du document
    final ref = _db.collection('listings').doc();

    // 3. Envoyer les photos vers Cloudinary
    final urls = <String>[];
    for (final photo in photos) {
      urls.add(await ImageUploader.upload(photo));
    }

    // 4. Enregistrer l'annonce
    await ref.set({
      'title': title,
      'titleLower': title.toLowerCase(),
      'description': description,
      'price': price,
      'surface': surface,
      'rooms': rooms,
      'propertyType': propertyType,
      'transactionType': transactionType,
      'address': address,
      'city': city,
      'latitude': position.lat,
      'longitude': position.lng,
      'photos': urls,
      'status': 'available',
      'sellerId': user.uid,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> updateListing({
    required String id,
    required String title,
    required String description,
    required double price,
    required double surface,
    required int? rooms,
    required String propertyType,
    required String transactionType,
    required String address,
    required String city,
    required List<String> keptPhotos,
    required List<XFile> newPhotos,
    required bool addressChanged,
  }) async {
    if (FirebaseAuth.instance.currentUser == null) {
      throw Exception('Vous devez être connecté.');
    }

    final update = <String, dynamic>{
      'title': title,
      'titleLower': title.toLowerCase(),
      'description': description,
      'price': price,
      'surface': surface,
      'rooms': rooms ?? FieldValue.delete(),
      'propertyType': propertyType,
      'transactionType': transactionType,
      'address': address,
      'city': city,
    };

    if (addressChanged) {
      final position = await _geocode(address, city);
      update['latitude'] = position.lat;
      update['longitude'] = position.lng;
    }

    final urls = [...keptPhotos];

    for (final photo in newPhotos) {
      urls.add(await ImageUploader.upload(photo));
    }

    update['photos'] = urls;

    await _db.collection('listings').doc(id).update(update);
  }

  // Supprimer une annonce
  Future<void> deleteListing(String id) =>
      _db.collection('listings').doc(id).delete();

  // Modifier le statut d'une annonce
  Future<void> setStatus(String id, String status) =>
      _db.collection('listings').doc(id).update({
        'status': status,
      });
}
