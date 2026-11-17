import 'package:flutter/material.dart';

import '../../services/messaging_service.dart';

/// Affiche le nom d'un utilisateur (lu une fois dans users/{uid}).
class UserName extends StatelessWidget {
  const UserName({
    super.key,
    required this.uid,
    this.fallback,
    required this.builder,
  });

  final String uid;
  final String? fallback;
  final Widget Function(BuildContext context, String name) builder;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<String?>(
      future: MessagingService.userName(uid),
      builder: (context, snap) {
        final name = snap.data ?? fallback;
        return builder(context, (name == null || name.isEmpty) ? 'Utilisateur' : name);
      },
    );
  }
}

/// Avatar rond avec les initiales.
class InitialsAvatar extends StatelessWidget {
  const InitialsAvatar({super.key, required this.name, this.size = 44});

  final String name;
  final double size;

  @override
  Widget build(BuildContext context) {
    final words = name.trim().split(RegExp(r'\s+')).where((w) => w.isNotEmpty);
    final initials = words.take(2).map((w) => w[0].toUpperCase()).join();
    final color = Theme.of(context).colorScheme.primary;
    return CircleAvatar(
      radius: size / 2,
      backgroundColor: color.withValues(alpha: 0.12),
      child: Text(
        initials.isEmpty ? '?' : initials,
        style: TextStyle(
          fontSize: size * 0.38,
          fontWeight: FontWeight.w800,
          color: color,
        ),
      ),
    );
  }
}
