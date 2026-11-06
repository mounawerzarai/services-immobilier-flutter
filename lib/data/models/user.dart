/// Utilisateur de l'application (document Firestore users/{uid}).
class AppUser {
  final String uid;
  final String name;
  final String email;
  final DateTime? createdAt;

  const AppUser({
    required this.uid,
    required this.name,
    required this.email,
    this.createdAt,
  });
}
