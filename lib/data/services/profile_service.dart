import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/listing_summary.dart';
import '../models/user_profile.dart';

/// Champ de la collection `listings` qui contient l'uid du propriétaire.
/// Adaptez-le si votre modèle d'annonce utilise un autre nom (ex. `userId`).
const String kListingOwnerField = 'sellerId';

/// Erreur lisible par l'utilisateur.
class ProfileException implements Exception {
  ProfileException(this.message);
  final String message;

  @override
  String toString() => message;
}

/// Seul fichier qui accède à Firebase pour le profil
/// (les écrans n'appellent jamais Firebase directement).
class ProfileService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  bool get isSignedIn => _auth.currentUser != null;

  /// Profil de l'utilisateur connecté, mis à jour en temps réel.
  /// Émet null si personne n'est connecté.
  Stream<UserProfile?> watchProfile() {
    final user = _auth.currentUser;
    if (user == null) return Stream.value(null);

    return _db.collection('users').doc(user.uid).snapshots().map((snap) {
      final data = snap.data() ?? <String, dynamic>{};
      final profile = UserProfile.fromMap(user.uid, data);
      // Si le document Firestore est incomplet, on se rabat sur le compte Auth.
      return UserProfile(
        uid: user.uid,
        name: profile.name.isNotEmpty ? profile.name : (user.displayName ?? ''),
        email: profile.email.isNotEmpty ? profile.email : (user.email ?? ''),
        phone: profile.phone,
        photoBase64: profile.photoBase64,
      );
    });
  }

  /// Annonces publiées par l'utilisateur connecté, les plus récentes d'abord.
  Stream<List<ListingSummary>> watchMyListings() {
    final user = _auth.currentUser;
    if (user == null) return Stream.value(const <ListingSummary>[]);

    return _db
        .collection('listings')
        .where(kListingOwnerField, isEqualTo: user.uid)
        .snapshots()
        .map((snap) {
      final list = snap.docs
          .map((d) => ListingSummary.fromMap(d.id, d.data()))
          .toList();
      list.sort((a, b) {
        final da = a.createdAt;
        final dbb = b.createdAt;
        if (da == null && dbb == null) return 0;
        if (da == null) return 1;
        if (dbb == null) return -1;
        return dbb.compareTo(da);
      });
      return list;
    });
  }

  /// Enregistre le nom, le téléphone et (option) la photo.
  /// - [photoBase64] null  : la photo n'est pas modifiée
  /// - [removePhoto] true  : la photo est supprimée
  Future<void> updateProfile({
    required String name,
    required String phone,
    String? photoBase64,
    bool removePhoto = false,
  }) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw ProfileException('Vous devez être connecté.');
    }

    final data = <String, dynamic>{
      'name': name.trim(),
      'phone': phone.trim(),
      'email': user.email ?? '',
      'updatedAt': FieldValue.serverTimestamp(),
    };
    if (removePhoto) {
      data['photoBase64'] = FieldValue.delete();
    } else if (photoBase64 != null) {
      data['photoBase64'] = photoBase64;
    }

    try {
      await _db
          .collection('users')
          .doc(user.uid)
          .set(data, SetOptions(merge: true));
      await user.updateDisplayName(name.trim());
    } on FirebaseException catch (e) {
      throw ProfileException(_message(e.code));
    }
  }

  Future<void> logout() => _auth.signOut();

  String _message(String code) {
    switch (code) {
      case 'permission-denied':
        return "Accès refusé. Vérifiez les règles Firestore de la collection users.";
      case 'unavailable':
      case 'network-request-failed':
        return 'Problème de connexion réseau.';
      default:
        return "Impossible d'enregistrer. Réessayez.";
    }
  }
}