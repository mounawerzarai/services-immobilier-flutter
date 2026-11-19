import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../core/router.dart';
import '../../core/theme.dart';
import '../../data/models/conversation.dart';
import '../../services/messaging_service.dart';

class _Alert {
  const _Alert(this.conversationId, this.title, this.body);

  final String conversationId;
  final String title;
  final String body;
}

/// T9 (version gratuite) : alerte dans l'appli quand un message arrive pendant que l'appli
/// est ouverte. Les vraies notifications push (appli fermée) demandent Cloud Functions,
/// donc le plan Blaze de Firebase.
///
/// À placer au-dessus de l'application (dans le `builder` de MaterialApp.router).
class MessageAlerts extends StatefulWidget {
  const MessageAlerts({super.key, required this.child});

  final Widget child;

  @override
  State<MessageAlerts> createState() => _MessageAlertsState();
}

class _MessageAlertsState extends State<MessageAlerts> {
  static const Duration _visibleFor = Duration(milliseconds: 4500);
  static const Duration _slide = Duration(milliseconds: 220);

  /// Un message plus vieux que ça n'est pas « nouveau » (évite les fausses alertes quand
  /// Firestore rend d'abord des données en cache après une longue absence).
  static const Duration _freshFor = Duration(minutes: 2);

  StreamSubscription<User?>? _authSub;
  StreamSubscription<List<Conversation>>? _convSub;
  Map<String, int>? _known; // conversation -> dernier updatedAt vu (ms)
  Timer? _hideTimer;
  Timer? _clearTimer;
  _Alert? _alert;
  bool _shown = false;

  @override
  void initState() {
    super.initState();
    _authSub = FirebaseAuth.instance.authStateChanges().listen(_onUser);
  }

  @override
  void dispose() {
    _authSub?.cancel();
    _convSub?.cancel();
    _hideTimer?.cancel();
    _clearTimer?.cancel();
    super.dispose();
  }

  int _ms(Conversation c) => c.updatedAt?.millisecondsSinceEpoch ?? 0;

  void _onUser(User? user) {
    _convSub?.cancel();
    _convSub = null;
    _known = null; // le premier envoi de données ne déclenche pas d'alerte
    if (user == null) return;
    _convSub = MessagingService.watchConversations().listen(
      (items) => _onConversations(user.uid, items),
      onError: (_) {},
    );
  }

  void _onConversations(String me, List<Conversation> items) {
    final known = _known;
    if (known == null) {
      _known = {for (final c in items) c.id: _ms(c)};
      return;
    }
    final path = router.routeInformationProvider.value.uri.path;
    final now = DateTime.now();

    Conversation? latest;
    for (final c in items) {
      final before = known[c.id] ?? 0;
      final updated = _ms(c);
      known[c.id] = updated;
      final fresh = c.updatedAt != null && now.difference(c.updatedAt!) < _freshFor;
      final inThisChat = path == '/chat/${c.id}';
      if (updated > before && fresh && c.isUnreadFor(me) && !inThisChat) {
        if (latest == null || updated > _ms(latest)) latest = c;
      }
    }
    if (latest != null) _show(latest);
  }

  void _show(Conversation c) {
    final sender = c.lastSenderId == null ? null : c.names[c.lastSenderId];
    final next = _Alert(
      c.id,
      (sender == null || sender.isEmpty) ? 'Nouveau message' : sender,
      c.lastMessage ?? '',
    );
    _hideTimer?.cancel();
    _clearTimer?.cancel();
    final wasVisible = _alert != null && _shown;
    setState(() {
      _alert = next;
      _shown = wasVisible;
    });
    if (!wasVisible) {
      // Une image plus tard, pour que le glissement vers le bas s'anime.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _alert != null) setState(() => _shown = true);
      });
    }
    _hideTimer = Timer(_visibleFor, _hide);
  }

  void _hide() {
    _hideTimer?.cancel();
    if (!mounted) return;
    setState(() => _shown = false);
    _clearTimer?.cancel();
    _clearTimer = Timer(_slide + const Duration(milliseconds: 40), () {
      if (mounted) setState(() => _alert = null);
    });
  }

  void _open(_Alert alert) {
    _hide();
    router.push('/chat/${alert.conversationId}');
  }

  @override
  Widget build(BuildContext context) {
    final alert = _alert;
    return Stack(
      fit: StackFit.expand,
      children: [
        widget.child,
        if (alert != null)
          Positioned(
            top: MediaQuery.of(context).padding.top + 8,
            left: 12,
            right: 12,
            child: IgnorePointer(
              ignoring: !_shown,
              child: AnimatedSlide(
                offset: _shown ? Offset.zero : const Offset(0, -1.5),
                duration: _slide,
                curve: Curves.easeOut,
                child: AnimatedOpacity(
                  opacity: _shown ? 1 : 0,
                  duration: _slide,
                  child: _AlertCard(
                    alert: alert,
                    onOpen: () => _open(alert),
                    onClose: _hide,
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _AlertCard extends StatelessWidget {
  const _AlertCard({required this.alert, required this.onOpen, required this.onClose});

  final _Alert alert;
  final VoidCallback onOpen;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(AppRadius.card);
    return Material(
      color: AppColors.surface,
      elevation: 6,
      shadowColor: AppColors.text.withValues(alpha: 0.25),
      shape: RoundedRectangleBorder(
        borderRadius: radius,
        side: const BorderSide(color: AppColors.border),
      ),
      child: InkWell(
        borderRadius: radius,
        onTap: onOpen,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 12, 4, 12),
          child: Row(
            children: [
              const CircleAvatar(
                radius: 18,
                backgroundColor: AppColors.primary,
                child: Icon(Icons.chat_bubble, size: 18, color: Colors.white),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      alert.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: AppColors.text,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      alert.body,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 13, color: AppColors.muted),
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: onClose,
                icon: const Icon(Icons.close, size: 20, color: AppColors.muted),
                visualDensity: VisualDensity.compact,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
