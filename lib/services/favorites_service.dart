import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../data/models/listing.dart';

class FavoritesService {
  static FirebaseFirestore get _db => FirebaseFirestore.instance;

  static DocumentReference<Map<String, dynamic>>? _ref(String listingId) {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return null;
    return _db.collection('users').doc(uid).collection('favorites').doc(listingId);
  }

  /// true si l'annonce est dans mes favoris (mise à jour en temps réel)
  static Stream<bool> isFavorite(String listingId) {
    final ref = _ref(listingId);
    if (ref == null) return Stream.value(false);
    return ref.snapshots().map((s) => s.exists);
  }

  /// Ajoute si absent, retire si présent
  static Future<void> toggle(String listingId) async {
    final ref = _ref(listingId);
    if (ref == null) return;
    final snap = await ref.get();
    if (snap.exists) {
      await ref.delete();
    } else {
      await ref.set({'addedAt': FieldValue.serverTimestamp()});
    }
  }

  /// T7.2 — Mes favoris en temps réel (du plus récent au plus ancien).
  /// Un favori dont l'annonce a été supprimée est retiré automatiquement.
  static Stream<List<Listing>> watchFavoriteListings() {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return Stream.value(const <Listing>[]);
    final favs = _db
        .collection('users')
        .doc(uid)
        .collection('favorites')
        .orderBy('addedAt', descending: true);

    return favs.snapshots().asyncMap((snap) async {
      final docs = await Future.wait(
        snap.docs.map((f) => _db.collection('listings').doc(f.id).get()),
      );
      final items = <Listing>[];
      for (var i = 0; i < docs.length; i++) {
        final d = docs[i];
        final data = d.data();
        if (d.exists && data != null) {
          items.add(Listing.fromMap(d.id, data));
        } else {
          snap.docs[i].reference.delete().ignore();
        }
      }
      return items;
    });
  }
}
