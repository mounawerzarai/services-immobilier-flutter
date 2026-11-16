import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FavoritesService {
  static DocumentReference<Map<String, dynamic>>? _ref(String listingId) {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return null;
    return FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('favorites')
        .doc(listingId);
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
}
