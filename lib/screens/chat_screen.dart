import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../core/theme.dart';
import '../data/models/conversation.dart';
import '../features/messaging/format.dart';
import '../features/messaging/user_name.dart';
import '../services/messaging_service.dart';
import '../widgets/ui.dart';

/// T8.2 — Chat en temps réel.
class ChatScreen extends StatefulWidget {
  final String id;

  const ChatScreen({super.key, required this.id});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _text = TextEditingController();
  final _focus = FocusNode();
  late final Stream<Conversation?> _conv = MessagingService.watchConversation(widget.id);
  late final Stream<List<ChatMessage>> _messages = MessagingService.watchMessages(widget.id);
  final String _me = FirebaseAuth.instance.currentUser?.uid ?? '';
  bool _sending = false;
  DateTime? _markedFor;

  @override
  void initState() {
    super.initState();
    _text.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _text.dispose();
    _focus.dispose();
    super.dispose();
  }

  /// Marque comme lu une seule fois par nouveau message reçu.
  void _markReadIfNeeded(Conversation c) {
    if (!c.isUnreadFor(_me) || c.updatedAt == _markedFor) return;
    _markedFor = c.updatedAt;
    unawaited(MessagingService.markRead(widget.id).catchError((_) {}));
  }

  Future<void> _send() async {
    final body = _text.text.trim();
    if (body.isEmpty || _sending) return;
    setState(() => _sending = true);
    _text.clear();
    try {
      await MessagingService.sendMessage(widget.id, body);
    } catch (_) {
      _text.text = body;
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Message non envoyé. Vérifiez votre connexion.')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _sending = false);
        _focus.requestFocus();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<Conversation?>(
      stream: _conv,
      builder: (context, convSnap) {
        if (convSnap.hasError || (convSnap.connectionState == ConnectionState.active && convSnap.data == null)) {
          final missing = !convSnap.hasError;
          return Scaffold(
            appBar: AppBar(title: const Text('Conversation')),
            body: EmptyState(
              icon: missing ? Icons.forum_outlined : Icons.cloud_off_outlined,
              danger: !missing,
              title: missing ? 'Conversation introuvable' : 'Chargement impossible',
              actionLabel: 'Retour',
              onAction: () => context.pop(),
            ),
          );
        }
        final conv = convSnap.data;
        if (conv == null) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }
        _markReadIfNeeded(conv);
        final other = conv.otherOf(_me);

        return Scaffold(
          appBar: AppBar(
            titleSpacing: 0,
            title: UserName(
              uid: other,
              fallback: conv.names[other],
              builder: (context, name) => Row(
                children: [
                  InitialsAvatar(name: name, size: 36),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
                        ),
                        if (conv.listingTitle != null)
                          Text(
                            conv.listingTitle!,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w400,
                              color: AppColors.muted,
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          body: Column(
            children: [
              if (conv.listingId != null) _ListingBanner(conv: conv),
              Expanded(child: _messagesList()),
              _composer(context),
            ],
          ),
        );
      },
    );
  }

  Widget _messagesList() {
    return StreamBuilder<List<ChatMessage>>(
      stream: _messages,
      builder: (context, snap) {
        if (snap.hasError) {
          return const EmptyState(
            icon: Icons.cloud_off_outlined,
            danger: true,
            title: 'Impossible de charger les messages',
          );
        }
        final items = snap.data;
        if (items == null) return const Center(child: CircularProgressIndicator());
        if (items.isEmpty) {
          return const EmptyState(
            icon: Icons.chat_outlined,
            title: 'Démarrez la conversation',
            text: 'Présentez-vous et posez vos questions sur le bien.',
          );
        }
        final now = DateTime.now();
        return ListView.builder(
          reverse: true,
          padding: const EdgeInsets.all(16),
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          itemCount: items.length,
          itemBuilder: (context, i) {
            final m = items[i];
            final at = m.sentAt ?? now;
            final older = i + 1 < items.length ? items[i + 1] : null;
            final showDay = older == null || !sameDay(older.sentAt ?? now, at);
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (showDay) _DayChip(label: formatDayLabel(at)),
                _Bubble(message: m, at: at, mine: m.senderId == _me),
              ],
            );
          },
        );
      },
    );
  }

  Widget _composer(BuildContext context) {
    final canSend = _text.text.trim().isNotEmpty && !_sending;
    return Container(
      padding: EdgeInsets.fromLTRB(12, 10, 12, 10 + MediaQuery.of(context).padding.bottom),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(top: BorderSide(color: AppColors.border, width: 0.5)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: CallbackShortcuts(
              // Entrée envoie (web / ordinateur) ; Maj + Entrée va à la ligne.
              bindings: {
                const SingleActivator(LogicalKeyboardKey.enter): _send,
              },
              child: TextField(
                controller: _text,
                focusNode: _focus,
                minLines: 1,
                maxLines: 5,
                maxLength: MessagingService.maxMessageLength,
                // Compteur seulement à l'approche de la limite (rouge une fois atteinte).
                buildCounter: (context,
                    {required int currentLength,
                    required bool isFocused,
                    required int? maxLength}) {
                  if (maxLength == null || currentLength < 1800) return null;
                  final atLimit = currentLength >= maxLength;
                  return Text(
                    atLimit
                        ? 'Limite atteinte : $currentLength / $maxLength caractères'
                        : '$currentLength / $maxLength',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: atLimit ? AppColors.danger : AppColors.muted,
                    ),
                  );
                },
                textCapitalization: TextCapitalization.sentences,
                decoration: InputDecoration(
                  hintText: 'Écrire un message…',
                  counterText: '',
                  filled: true,
                  fillColor: AppColors.canvas,
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(22),
                    borderSide: BorderSide.none,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(22),
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(22),
                    borderSide: const BorderSide(color: AppColors.primaryLight),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          SizedBox(
            width: 44,
            height: 44,
            child: IconButton.filled(
              tooltip: 'Envoyer',
              onPressed: canSend ? _send : null,
              style: IconButton.styleFrom(
                backgroundColor: AppColors.primary,
                disabledBackgroundColor: AppColors.primaryLight,
                foregroundColor: Colors.white,
                disabledForegroundColor: Colors.white,
              ),
              icon: _sending
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Icon(Icons.send_rounded, size: 20),
            ),
          ),
        ],
      ),
    );
  }
}

class _ListingBanner extends StatelessWidget {
  const _ListingBanner({required this.conv});

  final Conversation conv;

  @override
  Widget build(BuildContext context) {
    final photo = conv.listingPhoto;
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.md),
        boxShadow: AppShadows.soft,
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(AppRadius.md),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () => context.push('/listing/${conv.listingId}'),
          child: Padding(
            padding: const EdgeInsets.all(10),
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: SizedBox(
                    width: 44,
                    height: 44,
                    child: photo != null && photo.isNotEmpty
                        ? Image.network(
                            photo,
                            fit: BoxFit.cover,
                            errorBuilder: (_, _, _) => const ColoredBox(color: AppColors.border),
                          )
                        : const ColoredBox(
                            color: AppColors.primarySoft,
                            child: Icon(Icons.home_outlined, color: AppColors.primary, size: 20),
                          ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'ANNONCE',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: AppColors.primary,
                        ),
                      ),
                      Text(
                        conv.listingTitle ?? 'Voir l’annonce',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: AppColors.text,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right, color: AppColors.subtle),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _DayChip extends StatelessWidget {
  const _DayChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 10),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        decoration: BoxDecoration(
          color: AppColors.segment,
          borderRadius: BorderRadius.circular(AppRadius.pill),
        ),
        child: Text(
          label,
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.muted),
        ),
      ),
    );
  }
}

class _Bubble extends StatelessWidget {
  const _Bubble({required this.message, required this.at, required this.mine});

  final ChatMessage message;
  final DateTime at;
  final bool mine;

  @override
  Widget build(BuildContext context) {
    final fg = mine ? Colors.white : AppColors.text;
    final metaColor = mine ? Colors.white.withValues(alpha: 0.75) : AppColors.subtle;
    return Align(
      alignment: mine ? Alignment.centerRight : Alignment.centerLeft,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.78),
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 3),
          padding: const EdgeInsets.fromLTRB(14, 9, 14, 6),
          decoration: BoxDecoration(
            color: mine ? AppColors.primary : AppColors.surface,
            borderRadius: BorderRadius.only(
              topLeft: const Radius.circular(18),
              topRight: const Radius.circular(18),
              bottomLeft: Radius.circular(mine ? 18 : 6),
              bottomRight: Radius.circular(mine ? 6 : 18),
            ),
            boxShadow: mine ? null : AppShadows.soft,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Align(
                alignment: Alignment.centerLeft,
                widthFactor: 1,
                child: Text(message.text, style: TextStyle(fontSize: 15, height: 1.4, color: fg)),
              ),
              const SizedBox(height: 2),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(formatTime(at), style: TextStyle(fontSize: 11, color: metaColor)),
                  if (mine) ...[
                    const SizedBox(width: 4),
                    Icon(
                      message.sentAt == null ? Icons.schedule : Icons.done_all,
                      size: 13,
                      color: metaColor,
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
