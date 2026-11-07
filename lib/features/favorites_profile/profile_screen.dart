import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../data/models/listing_summary.dart';
import '../../data/models/user_profile.dart';
import '../../data/services/profile_service.dart';
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
        title: const Text('Profil'),
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

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        Center(
          child: ProfileAvatar(
            name: profile.name,
            photoBytes: profile.photoBytes,
          ),
        ),
        const SizedBox(height: 16),
        Text(
          profile.name.isEmpty ? 'Sans nom' : profile.name,
          textAlign: TextAlign.center,
          style: textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 4),
        Text(
          profile.email,
          textAlign: TextAlign.center,
          style: textTheme.bodyMedium?.copyWith(color: Colors.grey.shade700),
        ),
        const SizedBox(height: 4),
        Text(
          profile.phone.isEmpty ? 'Téléphone non renseigné' : profile.phone,
          textAlign: TextAlign.center,
          style: textTheme.bodyMedium?.copyWith(color: Colors.grey.shade700),
        ),
        const SizedBox(height: 20),
        OutlinedButton.icon(
          onPressed: () => context.push('/profile/edit'),
          icon: const Icon(Icons.edit_outlined),
          label: const Text('Modifier le profil'),
          style: OutlinedButton.styleFrom(
            minimumSize: const Size.fromHeight(48),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
        ),
        const SizedBox(height: 28),
        Text(
          'Mes annonces',
          style: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 12),
        StreamBuilder<List<ListingSummary>>(
          stream: listings,
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return const _Message('Impossible de charger vos annonces.');
            }
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Padding(
                padding: EdgeInsets.all(24),
                child: Center(child: CircularProgressIndicator()),
              );
            }
            final items = snapshot.data ?? const <ListingSummary>[];
            if (items.isEmpty) {
              return Column(
                children: [
                  const _Message("Vous n'avez publié aucune annonce."),
                  FilledButton(
                    onPressed: () => context.push('/listing/new'),
                    child: const Text('Publier une annonce'),
                  ),
                ],
              );
            }
            return Column(
              children: [
                for (final item in items) _ListingTile(listing: item),
              ],
            );
          },
        ),
      ],
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

    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: Colors.grey.shade300),
      ),
      child: ListTile(
        title: Text(listing.title, maxLines: 1, overflow: TextOverflow.ellipsis),
        subtitle: subtitle.isEmpty ? null : Text(subtitle),
        trailing: const Icon(Icons.chevron_right),
        onTap: () => context.push('/listing/${listing.id}'),
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
          style: TextStyle(color: Colors.grey.shade700),
        ),
      ),
    );
  }
}