import 'package:flutter/material.dart';
import 'package:services_immobilier/core/theme.dart';
import 'package:services_immobilier/services/favorites_service.dart';

/// Bouton favori. [compact] : petit cœur rond (posé sur une photo).
class FavoriteButton extends StatelessWidget {
  final String listingId;
  final bool compact;
  const FavoriteButton({super.key, required this.listingId, this.compact = false});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<bool>(
      stream: FavoritesService.isFavorite(listingId),
      builder: (context, snap) {
        final fav = snap.data ?? false;
        final icon = Icon(
          fav ? Icons.favorite : Icons.favorite_border,
          color: fav ? AppColors.danger : (compact ? AppColors.text : AppColors.primary),
          size: compact ? 20 : 22,
        );

        if (compact) {
          return Tooltip(
            message: fav ? 'Retirer des favoris' : 'Ajouter aux favoris',
            child: Material(
              color: Colors.white.withValues(alpha: 0.95),
              shape: const CircleBorder(),
              elevation: 2,
              shadowColor: Colors.black26,
              child: InkWell(
                customBorder: const CircleBorder(),
                onTap: () => FavoritesService.toggle(listingId),
                child: SizedBox(width: 38, height: 38, child: icon),
              ),
            ),
          );
        }

        return OutlinedButton.icon(
          onPressed: () => FavoritesService.toggle(listingId),
          icon: icon,
          label: Text(fav ? 'Favori' : 'Sauver'),
          style: OutlinedButton.styleFrom(
            minimumSize: const Size(0, 52),
            padding: const EdgeInsets.symmetric(horizontal: 18),
            foregroundColor: fav ? AppColors.danger : AppColors.primary,
            backgroundColor: fav ? AppColors.dangerSoft : AppColors.surface,
            side: BorderSide(
              color: fav ? AppColors.danger : AppColors.primary,
              width: 1.5,
            ),
          ),
        );
      },
    );
  }
}
