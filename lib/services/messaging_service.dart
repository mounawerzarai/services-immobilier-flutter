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

  // ---------- T8.2 — Chat en temps réel ----------

  static const int maxMessageLength = 2000;
  static const int messagesLimit = 200;

  static DocumentReference<Map<String, dynamic>> _conv(String id) =>
      _db.collection('conversations').doc(id);

  /// Une conversation en temps réel (null si elle n'existe pas).
  static Stream<Conversation?> watchConversation(String id) =>
      _conv(id).snapshots().map((s) {
        final data = s.data();
        return (s.exists && data != null) ? Conversation.fromMap(s.id, data) : null;
      });

  /// Messages, du plus récent au plus ancien (pour une liste inversée).
  static Stream<List<ChatMessage>> watchMessages(String conversationId) => _conv(conversationId)
      .collection('messages')
      .orderBy('sentAt', descending: true)
      .limit(messagesLimit)
      .snapshots()
      .map((snap) => snap.docs.map((d) => ChatMessage.fromMap(d.id, d.data())).toList());

  /// Envoie un message et met à jour l'aperçu de la conversation (écriture atomique).
  static Future<void> sendMessage(String conversationId, String text) async {
    final uid = _uid;
    var body = text.trim();
    if (uid == null || body.isEmpty) return;
    if (body.length > maxMessageLength) body = body.substring(0, maxMessageLength);
    final conv = _conv(conversationId);
    final batch = _db.batch();
    batch.set(conv.collection('messages').doc(), {
      'senderId': uid,
      'text': body,
      'sentAt': FieldValue.serverTimestamp(),
    });
    batch.update(conv, {
      'lastMessage': body,
      'lastSenderId': uid,
      'updatedAt': FieldValue.serverTimestamp(),
      'readAt.$uid': FieldValue.serverTimestamp(),
    });
    await batch.commit();
  }

  /// Marque la conversation comme lue par l'utilisateur connecté.
  static Future<void> markRead(String conversationId) async {
    final uid = _uid;
    if (uid == null) return;
    await _conv(conversationId).update({'readAt.$uid': FieldValue.serverTimestamp()});
  }

  // ---------- T8.3 — Démarrer une conversation depuis une annonce ----------

  /// Identifiant unique pour (annonce, acheteur, vendeur) : recontacter le même
  /// vendeur pour la même annonce rouvre la même conversation.
  static String conversationIdFor(String listingId, String a, String b) {
    final ids = [a, b]..sort();
    return '${listingId}_${ids[0]}_${ids[1]}';
  }

  /// Ouvre la conversation existante ou la crée. Renvoie son identifiant.
  static Future<String> startConversation({
    required String listingId,
    required String listingTitle,
    String? listingPhoto,
    required String sellerId,
    String? sellerName,
  }) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw StateError('Connectez-vous pour contacter le vendeur.');
    if (user.uid == sellerId) throw StateError('Vous êtes le vendeur de cette annonce.');

    final id = conversationIdFor(listingId, user.uid, sellerId);
    final ref = _conv(id);
    try {
      final snap = await ref.get();
      if (snap.exists) return id;
    } on FirebaseException catch (e) {
      // Les règles refusent la lecture d'une conversation qui n'existe pas encore.
      if (e.code != 'permission-denied') rethrow;
    }

    final myName = (user.displayName?.trim().isNotEmpty ?? false)
        ? user.displayName!.trim()
        : (await userName(user.uid) ?? 'Utilisateur');
    final participants = [user.uid, sellerId]..sort();
    await ref.set({
      'participants': participants,
      'listingId': listingId,
      'listingTitle': listingTitle,
      'listingPhoto': listingPhoto,
      'names': {
        user.uid: myName,
        sellerId: (sellerName == null || sellerName.isEmpty) ? 'Vendeur' : sellerName,
      },
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
      'readAt': {user.uid: FieldValue.serverTimestamp()},
    });
    return id;
  }
}
