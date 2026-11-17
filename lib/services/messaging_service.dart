import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../data/models/conversation.dart';

/// Messagerie (Firestore) :
///   conversations/{id}                 participants, annonce, dernier message, lectures
///   conversations/{id}/messages/{id}   senderId, text, sentAt
/// Les règles sont dans firebase/firestore.rules (projet RN).
class MessagingService {
  static FirebaseFirestore get _db => FirebaseFirestore.instance;
  static String? get _uid => FirebaseAuth.instance.currentUser?.uid;

  static final Map<String, String> _names = {};

  /// T8.1 — Mes conversations en temps réel, de la plus récente à la plus
  /// ancienne. Tri côté appli : pas besoin d'index composite.
  static Stream<List<Conversation>> watchConversations() {
    final uid = _uid;
    if (uid == null) return Stream.value(const <Conversation>[]);
    return _db
        .collection('conversations')
        .where('participants', arrayContains: uid)
        .snapshots()
        .map((snap) {
      final items = snap.docs
          .map((d) => Conversation.fromMap(d.id, d.data()))
          .toList()
        ..sort((a, b) {
          final ta = a.updatedAt?.millisecondsSinceEpoch ?? 0;
          final tb = b.updatedAt?.millisecondsSinceEpoch ?? 0;
          return tb.compareTo(ta);
        });
      return items;
    });
  }

  /// Nombre de conversations non lues (badge de l'onglet Messages).
  static Stream<int> watchUnreadCount() {
    final uid = _uid;
    if (uid == null) return Stream.value(0);
    return watchConversations()
        .map((items) => items.where((c) => c.isUnreadFor(uid)).length)
        .handleError((_) {});
  }

  /// Nom d'un utilisateur (users/{uid}), mis en cache pour la session.
  static Future<String?> userName(String uid) async {
    final cached = _names[uid];
    if (cached != null) return cached;
    try {
      final snap = await _db.collection('users').doc(uid).get();
      final name = (snap.data()?['name'] as String?)?.trim();
      if (name != null && name.isNotEmpty) _names[uid] = name;
      return name;
    } catch (_) {
      return null;
    }
  }
}
