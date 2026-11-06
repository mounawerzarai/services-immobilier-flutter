import 'dart:convert';
import 'dart:typed_data';

/// Profil d'un utilisateur, stocké dans Firestore : users/{uid}.
class UserProfile {
  const UserProfile({
    required this.uid,
    required this.name,
    required this.email,
    this.phone = '',
    this.photoBase64,
  });

  final String uid;
  final String name;
  final String email;
  final String phone;

  /// Photo de profil réduite (400 px max), encodée en base64.
  final String? photoBase64;

  /// Octets de la photo, ou null s'il n'y a pas de photo (ou si elle est illisible).
  Uint8List? get photoBytes {
    final data = photoBase64;
    if (data == null || data.isEmpty) return null;
    try {
      return base64Decode(data);
    } catch (_) {
      return null;
    }
  }

  factory UserProfile.fromMap(String uid, Map<String, dynamic> data) {
    return UserProfile(
      uid: uid,
      name: (data['name'] as String?) ?? '',
      email: (data['email'] as String?) ?? '',
      phone: (data['phone'] as String?) ?? '',
      photoBase64: data['photoBase64'] as String?,
    );
  }
}