import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../core/theme.dart';
import '../data/models/conversation.dart';
import '../features/messaging/format.dart';
import '../features/messaging/user_name.dart';
import '../services/messaging_service.dart';
import '../widgets/ui.dart';

/// T8.1 — Liste des conversations, en temps réel.
class MessagesScreen extends StatefulWidget {
  const MessagesScreen({super.key});

  @override
  State<MessagesScreen> createState() => _MessagesScreenState();
}

class _MessagesScreenState extends State<MessagesScreen> {
  late Stream<List<Conversation>> _stream = MessagingService.watchConversations();

  void _retry() =>
      setState(() => _stream = MessagingService.watchConversations());

  @override
  Widget build(BuildContext context) {
    final me = FirebaseAuth.instance.currentUser?.uid ?? '';
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: StreamBuilder<List<Conversation>>(
          stream: _stream,
          builder: (context, snap) {
            final items = snap.data;
            final unread = items?.where((c) => c.isUnreadFor(me)).length ?? 0;

            Widget? body;
            if (snap.hasError) {
              body = EmptyState(
                icon: Icons.cloud_off_outlined,
                danger: true,
                title: 'Chargement impossible',
                text: 'Vérifiez votre connexion puis réessayez.',
                actionLabel: 'Réessayer',
                onAction: _retry,
              );
            } else if (items == null) {
              body = const Padding(
                padding: EdgeInsets.only(top: 40),
                child: Center(child: CircularProgressIndicator()),
              );
            } else if (items.isEmpty) {
              body = EmptyState(
                icon: Icons.forum_outlined,
                title: 'Aucune conversation',
                text: 'Contactez un vendeur depuis une annonce pour démarrer une discussion.',
                actionLabel: 'Voir les annonces',
                onAction: () => context.go('/home'),
              );
            }

            return CustomScrollView(
              slivers: [
                SliverToBoxAdapter(child: _Header(unread: unread)),
                if (body == null)
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                    sliver: SliverList.separated(
                      itemCount: items!.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 10),
                      itemBuilder: (context, i) => _ConversationTile(
                        item: items[i],
                        me: me,
                        onTap: () => context.push('/chat/${items[i].id}'),
                      ),
                    ),
                  )
                else
                  SliverFillRemaining(hasScrollBody: false, child: body),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.unread});

  final int unread;

  @override
  Widget build(BuildContext context) {
    final s = unread > 1 ? 's' : '';
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Messages',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w800,
              color: AppColors.text,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            unread > 0
                ? '$unread conversation$s non lue$s'
                : 'Échangez avec les vendeurs et les acheteurs',
            style: const TextStyle(fontSize: 14, color: AppColors.muted),
          ),
        ],
      ),
    );
  }
}

class _ConversationTile extends StatelessWidget {
  const _ConversationTile({required this.item, required this.me, required this.onTap});

  final Conversation item;
  final String me;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final other = item.otherOf(me);
    final unread = item.isUnreadFor(me);
    final last = item.lastMessage;
    final preview = last == null || last.isEmpty
        ? 'Nouvelle conversation'
        : '${item.lastSenderId == me ? 'Vous : ' : ''}$last';
    final photo = item.listingPhoto;

    return UserName(
      uid: other,
      fallback: item.names[other],
      builder: (context, name) => Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadius.card),
          boxShadow: AppShadows.soft,
        ),
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(AppRadius.card),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  Stack(
                    clipBehavior: Clip.none,
                    children: [
                      InitialsAvatar(name: name, size: 52),
                      if (photo != null && photo.isNotEmpty)
                        Positioned(
                          right: -4,
                          bottom: -4,
                          child: Container(
                            width: 26,
                            height: 26,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: AppColors.surface, width: 2),
                              color: AppColors.border,
                              image: DecorationImage(
                                image: NetworkImage(photo),
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: unread ? FontWeight.w800 : FontWeight.w600,
                                  color: AppColors.text,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              formatConversationDate(item.updatedAt),
                              style: TextStyle(
                                fontSize: 12,
                                color: unread ? AppColors.primary : AppColors.subtle,
                                fontWeight: unread ? FontWeight.w700 : FontWeight.w400,
                              ),
                            ),
                          ],
                        ),
                        if (item.listingTitle != null && item.listingTitle!.isNotEmpty) ...[
                          const SizedBox(height: 2),
                          Row(
                            children: [
                              const Icon(Icons.home_outlined, size: 13, color: AppColors.primary),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  item.listingTitle!,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: AppColors.primary,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                        const SizedBox(height: 3),
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                preview,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 14,
                                  color: unread ? AppColors.text : AppColors.muted,
                                  fontWeight: unread ? FontWeight.w600 : FontWeight.w400,
                                ),
                              ),
                            ),
                            if (unread)
                              Container(
                                margin: const EdgeInsets.only(left: 8),
                                width: 10,
                                height: 10,
                                decoration: const BoxDecoration(
                                  color: AppColors.primary,
                                  shape: BoxShape.circle,
                                ),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
