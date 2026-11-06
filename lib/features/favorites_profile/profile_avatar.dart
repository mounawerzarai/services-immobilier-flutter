import 'dart:typed_data';

import 'package:flutter/material.dart';

/// Photo de profil ronde. Sans photo, affiche l'initiale du nom.
class ProfileAvatar extends StatelessWidget {
  const ProfileAvatar({
    super.key,
    required this.name,
    this.photoBytes,
    this.radius = 48,
  });

  final String name;
  final Uint8List? photoBytes;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.primary;
    final initial = name.trim().isEmpty ? '?' : name.trim()[0].toUpperCase();

    return CircleAvatar(
      radius: radius,
      backgroundColor: color.withValues(alpha: 0.12),
      backgroundImage: photoBytes != null ? MemoryImage(photoBytes!) : null,
      child: photoBytes == null
          ? Text(
              initial,
              style: TextStyle(
                fontSize: radius * 0.8,
                fontWeight: FontWeight.w700,
                color: color,
              ),
            )
          : null,
    );
  }
}