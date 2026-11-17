import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../core/theme.dart';
import '../data/models/listing.dart';
import '../features/listings/listing_card.dart';
import '../services/favorites_service.dart';
import '../widgets/favorite_button.dart';
import '../widgets/ui.dart';

/// T7.2 — Écran « Mes favoris » : annonces sauvegardées, en temps réel.
class FavoritesScreen extends StatefulWidget {
  const FavoritesScreen({super.key});

  @override
  State<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends State<FavoritesScreen> {
  late Stream<List<Listing>> _stream = FavoritesService.watchFavoriteListings();

  void _retry() =>
      setState(() => _stream = FavoritesService.watchFavoriteListings());

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: StreamBuilder<List<Listing>>(
          stream: _stream,
          builder: (context, snap) {
            final items = snap.data;
            Widget body;
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
                icon: Icons.favorite_border,
                title: 'Aucun favori pour l’instant',
                text: 'Touchez le cœur d’une annonce pour la retrouver ici.',
                actionLabel: 'Parcourir les annonces',
                onAction: () => context.go('/home'),
              );
            } else {
              body = const SizedBox.shrink();
            }

            return CustomScrollView(
              slivers: [
                SliverToBoxAdapter(child: _Header(count: items?.length ?? 0)),
                if (items != null && items.isNotEmpty && !snap.hasError)
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                    sliver: SliverList.builder(
                      itemCount: items.length,
                      itemBuilder: (context, i) {
                        final item = items[i];
                        return ListingCard(
                          item: item,
                          onTap: () => context.push('/listing/${item.id}'),
                          topRight: FavoriteButton(listingId: item.id, compact: true),
                        );
                      },
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
  const _Header({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    final s = count > 1 ? 's' : '';
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Mes favoris',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w800,
              color: AppColors.text,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            count > 0
                ? '$count bien$s sauvegardé$s'
                : 'Retrouvez ici les biens qui vous plaisent',
            style: const TextStyle(fontSize: 14, color: AppColors.muted),
          ),
        ],
      ),
    );
  }
}
