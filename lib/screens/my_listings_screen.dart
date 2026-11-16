import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../core/theme.dart';
import '../data/models/listing.dart';
import '../features/listings/format.dart';
import '../widgets/listing_actions_menu.dart';
import '../widgets/ui.dart';

class MyListingsScreen extends StatelessWidget {
  const MyListingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Mes annonces')),
        body: const EmptyState(
          icon: Icons.person_outline,
          title: 'Connectez-vous pour voir vos annonces.',
        ),
      );
    }
    final stream = FirebaseFirestore.instance
        .collection('listings')
        .where('sellerId', isEqualTo: uid)
        .orderBy('createdAt', descending: true)
        .snapshots();

    return Scaffold(
      appBar: AppBar(title: const Text('Mes annonces')),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: stream,
        builder: (context, snap) {
          if (snap.hasError) {
            return EmptyState(
              icon: Icons.cloud_off_outlined,
              danger: true,
              title: 'Impossible de charger vos annonces',
              text: '${snap.error}',
            );
          }
          if (!snap.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final items = snap.data!.docs
              .map((d) => Listing.fromMap(d.id, d.data()))
              .toList();
          if (items.isEmpty) {
            return EmptyState(
              icon: Icons.inventory_2_outlined,
              title: 'Aucune annonce publiée',
              text: 'Publiez votre premier bien en quelques minutes.',
              actionLabel: 'Publier une annonce',
              onAction: () => context.push('/listing/new'),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
            itemCount: items.length + 1,
            itemBuilder: (context, i) {
              if (i == 0) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Text(
                    '${items.length} annonce${items.length > 1 ? 's' : ''} '
                    'publiée${items.length > 1 ? 's' : ''}',
                    style: const TextStyle(
                      color: AppColors.muted,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                );
              }
              return _MyListingCard(item: items[i - 1]);
            },
          );
        },
      ),
    );
  }
}

class _MyListingCard extends StatelessWidget {
  const _MyListingCard({required this.item});

  final Listing item;

  @override
  Widget build(BuildContext context) {
    final available = item.status == 'available';
    return AppCard(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(12),
      onTap: () => context.push('/listing/${item.id}'),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(AppRadius.md),
            child: SizedBox(
              width: 84,
              height: 84,
              child: item.photos.isEmpty
                  ? Container(
                      color: AppColors.primarySoft,
                      child: const Icon(Icons.image_outlined, color: AppColors.subtle),
                    )
                  : Image.network(
                      item.photos.first,
                      fit: BoxFit.cover,
                      errorBuilder: (c, e, s) => Container(color: AppColors.primarySoft),
                    ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                    color: AppColors.text,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  formatPrice(item),
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 16,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    if (item.city.isNotEmpty)
                      Flexible(child: IconText(Icons.location_on_outlined, item.city)),
                    const SizedBox(width: 8),
                    Pill(
                      statusLabel(item.status),
                      tone: available ? PillTone.primary : PillTone.neutral,
                    ),
                  ],
                ),
              ],
            ),
          ),
          ListingActionsMenu(
            listingId: item.id,
            status: item.status,
            transactionType: item.transactionType,
          ),
        ],
      ),
    );
  }
}
