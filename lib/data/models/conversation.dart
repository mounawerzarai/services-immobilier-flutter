import 'package:cloud_firestore/cloud_firestore.dart';

DateTime? _date(Object? v) => v is Timestamp ? v.toDate() : null;

/// Conversation entre un acheteur / locataire et un vendeur, liée à une annonce
/// (collection Firestore : conversations).
class Conversation {
  const Conversation({
    required this.id,
    required this.participants,
    this.listingId,
    this.listingTitle,
    this.listingPhoto,
    this.names = const {},
    this.lastMessage,
    this.lastSenderId,
    this.updatedAt,
    this.readAt = const {},
  });

  final String id;
  final List<String> participants;
  final String? listingId;
  final String? listingTitle;
  final String? listingPhoto;

  /// Nom affiché de chaque participant, enregistré à la création.
  final Map<String, String> names;
  final String? lastMessage;
  final String? lastSenderId;
  final DateTime? updatedAt;

  /// Dernière lecture de chaque participant.
  final Map<String, DateTime> readAt;

  factory Conversation.fromMap(String id, Map<String, dynamic> d) {
    final names = <String, String>{};
    (d['names'] as Map?)?.forEach((k, v) {
      if (v is String) names['$k'] = v;
    });
    final readAt = <String, DateTime>{};
    (d['readAt'] as Map?)?.forEach((k, v) {
      final t = _date(v);
      if (t != null) readAt['$k'] = t;
    });
    return Conversation(
      id: id,
      participants: ((d['participants'] as List?) ?? const []).whereType<String>().toList(),
      listingId: d['listingId'] as String?,
      listingTitle: d['listingTitle'] as String?,
      listingPhoto: d['listingPhoto'] as String?,
      names: names,
      lastMessage: d['lastMessage'] as String?,
      lastSenderId: d['lastSenderId'] as String?,
      updatedAt: _date(d['updatedAt']) ?? _date(d['createdAt']),
      readAt: readAt,
    );
  }

  /// L'autre participant de la conversation.
  String otherOf(String me) =>
      participants.firstWhere((p) => p != me, orElse: () => me);

  /// true si le dernier message vient de l'autre et n'a pas encore été lu.
  bool isUnreadFor(String me) {
    final last = updatedAt;
    if (lastSenderId == null || lastSenderId == me || last == null) return false;
    final read = readAt[me];
    return read == null || read.isBefore(last);
  }
}

/// Message d'une conversation (sous-collection messages).
class ChatMessage {
  const ChatMessage({
    required this.id,
    required this.senderId,
    required this.text,
    this.sentAt,
  });

  final String id;
  final String senderId;
  final String text;

  /// null tant que le serveur n'a pas confirmé l'envoi.
  final DateTime? sentAt;

  factory ChatMessage.fromMap(String id, Map<String, dynamic> d) => ChatMessage(
        id: id,
        senderId: (d['senderId'] as String?) ?? '',
        text: (d['text'] as String?) ?? '',
        sentAt: _date(d['sentAt']),
      );
}
