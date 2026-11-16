import 'package:flutter/material.dart';

import '../../core/theme.dart';
import '../../data/models/listing.dart';
import '../../widgets/ui.dart';
import 'format.dart';
import 'listing_photo.dart';

/// Carte d'une annonce (accueil, favoris, autour de moi).
class ListingCard extends StatelessWidget {
  const ListingCard({
    super.key,
    required this.item,
    required this.onTap,
    this.topRight,
    this.photoNote,
  });

  final Listing item;
  final VoidCallback onTap;

  /// Élément en haut à droite de la photo (ex. bouton favori).
  final Widget? topRight;

  /// Texte en bas à gauche de la photo (ex. « 1,2 km »).
  final String? photoNote;

  @override
  Widget build(BuildContext context) {
    final place = [item.address, item.city].where((s) => s.isNotEmpty).join(', ');
    final closed = item.status != 'available';

    return Container(
      margin: const EdgeInsets.only(bottom: 18),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        boxShadow: AppShadows.card,
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Stack(
                children: [
                  ListingPhoto(
                    url: item.photos.isEmpty ? null : item.photos.first,
                    height: 200,
                  ),
                  Positioned(
                    top: 12,
                    left: 12,
                    child: Row(
                      children: [
                        TransactionBadge(item.transactionType),
                        if (closed) ...[
                          const SizedBox(width: 6),
                          Pill(statusLabel(item.status), tone: PillTone.danger),
                        ],
                      ],
                    ),
                  ),
                  if (topRight != null)
                    Positioned(top: 10, right: 10, child: topRight!),
                  if (photoNote != null)
                    Positioned(
                      left: 12,
                      bottom: 12,
                      child: Pill(photoNote!, tone: PillTone.dark, icon: Icons.near_me),
                    ),
                ],
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      formatPrice(item),
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: AppColors.primary,
                        letterSpacing: -0.3,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      item.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppColors.text,
                      ),
                    ),
                    if (place.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      IconText(Icons.location_on_outlined, place),
                    ],
                    const SizedBox(height: 10),
                    const Divider(height: 1),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 14,
                      runSpacing: 6,
                      children: [
                        if ((item.propertyType ?? '').isNotEmpty)
                          IconText(
                            Icons.apartment_outlined,
                            propertyTypeLabel(item.propertyType),
                            color: AppColors.text,
                          ),
                        if ((item.surface ?? 0) > 0)
                          IconText(
                            Icons.straighten,
                            formatSurface(item.surface!),
                            color: AppColors.text,
                          ),
                        if ((item.rooms ?? 0) > 0)
                          IconText(
                            Icons.bed_outlined,
                            '${item.rooms} pièce${item.rooms! > 1 ? 's' : ''}',
                            color: AppColors.text,
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Pastille « Vente » (verte) / « Location » (ambrée).
class TransactionBadge extends StatelessWidget {
  const TransactionBadge(this.transactionType, {super.key});

  final String transactionType;

  @override
  Widget build(BuildContext context) {
    return Pill(
      transactionLabel(transactionType),
      tone: transactionType == 'rent' ? PillTone.accent : PillTone.primary,
    );
  }
}
