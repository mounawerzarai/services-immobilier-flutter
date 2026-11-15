import 'package:flutter/material.dart';
import 'package:services_immobilier/services/favorites_service.dart';

class FavoriteButton extends StatelessWidget {
  final String listingId;
  const FavoriteButton({super.key, required this.listingId});

  @override
  Widget build(BuildContext context) {
    const green = Color(0xFF0B6B5C);
    return StreamBuilder<bool>(
      stream: FavoritesService.isFavorite(listingId),
      builder: (context, snap) {
        final fav = snap.data ?? false;
        return OutlinedButton.icon(
          onPressed: () => FavoritesService.toggle(listingId),
          icon: Icon(fav ? Icons.favorite : Icons.favorite_border, color: green),
          label: Text(fav ? 'Favori' : 'Favori', style: const TextStyle(color: green)),
          style: OutlinedButton.styleFrom(side: const BorderSide(color: green)),
        );
      },
    );
  }
}
