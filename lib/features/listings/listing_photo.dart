import 'package:flutter/material.dart';

import '../../core/theme.dart';

/// Photo d'annonce avec un fond neutre pendant le chargement ou si elle est absente.
class ListingPhoto extends StatelessWidget {
  const ListingPhoto({super.key, this.url, required this.height});

  final String? url;
  final double height;

  Widget _placeholder({String? text, bool loading = false}) => Container(
        height: height,
        width: double.infinity,
        color: AppColors.primarySoft,
        alignment: Alignment.center,
        child: loading
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.image_outlined, size: 34, color: AppColors.subtle),
                  if (text != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      text,
                      style: const TextStyle(color: AppColors.muted, fontSize: 13),
                    ),
                  ],
                ],
              ),
      );

  @override
  Widget build(BuildContext context) {
    final u = url;
    if (u == null || u.isEmpty) return _placeholder(text: 'Pas de photo');
    return Image.network(
      u,
      height: height,
      width: double.infinity,
      fit: BoxFit.cover,
      loadingBuilder: (context, child, progress) =>
          progress == null ? child : _placeholder(loading: true),
      errorBuilder: (context, error, stack) =>
          _placeholder(text: 'Photo indisponible'),
    );
  }
}
