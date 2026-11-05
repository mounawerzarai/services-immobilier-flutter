import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  /// Émet l'utilisateur connecté, ou null s'il est déconnecté.
  Stream<User?> get authState => _auth.authStateChanges();

  /// Crée le compte, enregistre le nom, puis crée le document users/{uid}.
  Future<User> register(String name, String email, String password) async {
    final cred = await _auth.createUserWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
    await cred.user!.updateDisplayName(name);
    await _db.collection('users').doc(cred.user!.uid).set({
      'name': name,
      'email': email.trim(),
      'createdAt': FieldValue.serverTimestamp(),
    });
    return cred.user!;
  }

  Future<void> login(String email, String password) =>
      _auth.signInWithEmailAndPassword(email: email.trim(), password: password);

  Future<void> resetPassword(String email) =>
      _auth.sendPasswordResetEmail(email: email.trim());

  Future<void> logout() => _auth.signOut();

  /// Traduit un code d'erreur Firebase en message français.
  static String errorMessage(String code) {
    switch (code) {
      case 'invalid-email':
        return 'Adresse email invalide.';
      case 'invalid-credential':
      case 'wrong-password':
      case 'user-not-found':
        return 'Email ou mot de passe incorrect.';
      case 'email-already-in-use':
        return 'Cet email est déjà utilisé.';
      case 'weak-password':
        return 'Mot de passe trop court (6 caractères minimum).';
      case 'too-many-requests':
        return 'Trop de tentatives. Réessayez plus tard.';
      case 'network-request-failed':
        return 'Problème de connexion réseau.';
      default:
        return 'Une erreur est survenue. Réessayez.';
    }
  }
}