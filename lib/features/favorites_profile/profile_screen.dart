import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme.dart';
import '../../data/models/listing_summary.dart';
import '../../data/models/user_profile.dart';
import '../../data/services/profile_service.dart';
import '../../widgets/ui.dart';
import 'profile_avatar.dart';

/// Onglet « Profil » : informations de l'utilisateur et ses annonces.
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final ProfileService _service = ProfileService();
  late final Stream<UserProfile?> _profile = _service.watchProfile();
  late final Stream<List<ListingSummary>> _listings = _service.watchMyListings();

  Future<void> _logout() async {
    await _service.logout();
    if (!mounted) return;
    context.go('/login');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mon profil'),
        actions: [
          IconButton(
            tooltip: 'Se déconnecter',
            icon: const Icon(Icons.logout),
            onPressed: _service.isSignedIn ? _logout : null,
          ),
        ],
      ),
      body: StreamBuilder<UserProfile?>(
        stream: _profile,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const _Message('Impossible de charger le profil.');
          }
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final profile = snapshot.data;
          if (profile == null) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Connectez-vous pour voir votre profil.'),
                  const SizedBox(height: 16),
                  FilledButton(
                    onPressed: () => context.go('/login'),
                    child: const Text('Se connecter'),
                  ),
                ],
              ),
            );
          }
          return _ProfileBody(profile: profile, listings: _listings);
        },
      ),
    );
  }
}

class _ProfileBody extends StatelessWidget {
  const _ProfileBody({required this.profile, required this.listings});

  final UserProfile profile;
  final Stream<List<ListingSummary>> listings;

  Widget _menuRow(IconData icon, String label, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.md),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Row(
          children: [
            IconBadge(icon),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: AppColors.text,
                ),
              ),
            ),
            const Icon(Icons.chevron_right, color: AppColors.subtle),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<ListingSummary>>(
      stream: listings,
      builder: (context, snapshot) {
        final items = snapshot.data ?? const <ListingSummary>[];
        final loading = snapshot.connectionState == ConnectionState.waiting;

        return ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
          children: [
            // Carte d'identité.
            AppCard(
              padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
              child: Column(
                children: [
                  ProfileAvatar(
                    name: profile.name,
                    photoBytes: profile.photoBytes,
                    radius: 44,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    profile.name.isEmpty ? 'Sans nom' : profile.name,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: AppColors.text,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    profile.email,
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: AppColors.muted),
                  ),
                  const SizedBox(height: 2),
                  IconText(
                    Icons.call_outlined,
                    profile.phone.isEmpty ? 'Téléphone non renseigné' : profile.phone,
                  ),
                  const SizedBox(height: 18),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(vertical: 10, horizontal: 24),
                    decoration: BoxDecoration(
                      color: AppColors.primarySoft,
                      borderRadius: BorderRadius.circular(AppRadius.md),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Column(
                          children: [
                            Text(
                              loading ? '–' : '${items.length}',
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w800,
                                color: AppColors.primary,
                              ),
                            ),
                            const Text(
                              'Annonces',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: AppColors.muted,
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
            const SizedBox(height: 16),
            AppCard(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
              child: Column(
                children: [
                  _menuRow(Icons.edit_outlined, 'Modifier le profil',
                      () => context.push('/profile/edit')),
                  _menuRow(Icons.inventory_2_outlined, 'Gérer mes annonces',
                      () => context.push('/my-listings')),
                  _menuRow(Icons.add_circle_outline, 'Publier une annonce',
                      () => context.push('/listing/new')),
                ],
              ),
            ),
            const SectionTitle('Mes annonces'),
            if (snapshot.hasError)
              const _Message('Impossible de charger vos annonces.')
            else if (loading)
              const Padding(
                padding: EdgeInsets.all(24),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (items.isEmpty)
              AppCard(
                child: Column(
                  children: [
                    const _Message("Vous n'avez publié aucune annonce."),
                    OutlinedButton.icon(
                      onPressed: () => context.push('/listing/new'),
                      icon: const Icon(Icons.add),
                      label: const Text('Publier une annonce'),
                    ),
                  ],
                ),
              )
            else
              for (final item in items) _ListingTile(listing: item),
          ],
        );
      },
    );
  }
}

class _ListingTile extends StatelessWidget {
  const _ListingTile({required this.listing});

  final ListingSummary listing;

  @override
  Widget build(BuildContext context) {
    final price = listing.price == null
        ? null
        : '${listing.price!.toStringAsFixed(0)} $kCurrency';
    final subtitle = [
      if (price != null) price,
      if (listing.city.isNotEmpty) listing.city,
    ].join(' · ');

    return AppCard(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      onTap: () => context.push('/listing/${listing.id}'),
      child: Row(
        children: [
          const IconBadge(Icons.home_outlined),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  listing.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppColors.text,
                  ),
                ),
                if (subtitle.isNotEmpty) ...[
                  const SizedBox(height: 3),
                  Text(
                    subtitle,
                    style: const TextStyle(fontSize: 13, color: AppColors.muted),
                  ),
                ],
              ],
            ),
          ),
          const Icon(Icons.chevron_right, color: AppColors.subtle),
        ],
      ),
    );
  }
}

class _Message extends StatelessWidget {
  const _Message(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Center(
        child: Text(
          text,
          textAlign: TextAlign.center,
          style: const TextStyle(color: AppColors.muted),
        ),
      ),
    );
  }
}