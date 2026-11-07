import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'image_uploader.dart';

class ListingService {
  final _db = FirebaseFirestore.instance;

  /// Adresse -> (latitude, longitude) avec OpenStreetMap Nominatim
  Future<({double lat, double lng})> _geocode(
      String address, String city) async {
    final uri = Uri.https('nominatim.openstreetmap.org', '/search', {
      'q': '$address, $city',
      'format': 'json',
      'limit': '1',
    });
    final response = await http.get(
      uri,
      headers: {'User-Agent': 'ServicesImmobilier/1.0 (projet etudiant)'},
    );
    if (response.statusCode != 200) {
      throw Exception('Service d\'adresse indisponible (${response.statusCode})');
    }
    final results = jsonDecode(response.body) as List;
    if (results.isEmpty) throw Exception('Adresse introuvable.');
    return (
      lat: double.parse(results.first['lat'] as String),
      lng: double.parse(results.first['lon'] as String),
    );
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
    if (user == null) throw Exception('Vous devez être connecté.');

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
}