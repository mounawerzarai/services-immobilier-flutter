import 'package:flutter/material.dart';

import '../../core/theme.dart';

/// Photo d'annonce avec un fond neutre pendant le chargement ou si elle est absente.
class ListingPhoto extends StatelessWidget {
  const ListingPhoto({super.key, this.url, required this.height});

  final String? url;
  final double height;

  Widget _placeholder(String? text) => Container(
        height: height,
        width: double.infinity,
        color: AppColors.primaryLight,
        alignment: Alignment.center,
        child: text == null
            ? null
            : Text(
                text,
                style: const TextStyle(color: AppColors.muted, fontSize: 13),
              ),
      );

  @override
  Widget build(BuildContext context) {
    final u = url;
    if (u == null || u.isEmpty) return _placeholder('Pas de photo');
    return Image.network(
      u,
      height: height,
      width: double.infinity,
      fit: BoxFit.cover,
      loadingBuilder: (context, child, progress) =>
          progress == null ? child : _placeholder(null),
      errorBuilder: (context, error, stack) => _placeholder('Photo indisponible'),
    );
  }
}