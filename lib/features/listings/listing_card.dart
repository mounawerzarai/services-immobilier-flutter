import 'package:flutter/material.dart';

import '../../core/theme.dart';
import '../../data/models/listing.dart';
import 'format.dart';
import 'listing_photo.dart';

/// Carte d'une annonce dans la liste de l'accueil.
class ListingCard extends StatelessWidget {
  const ListingCard({super.key, required this.item, required this.onTap});

  final Listing item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final details = formatDetails(item);

    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Material(
        color: AppColors.background,
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.card),
          side: const BorderSide(color: AppColors.border),
        ),
        child: InkWell(
          onTap: onTap,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ListingPhoto(
                url: item.photos.isEmpty ? null : item.photos.first,
                height: 170,
              ),
              Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Flexible(
                          child: Text(
                            formatPrice(item),
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: AppColors.text,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        TransactionBadge(item.transactionType),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      item.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 15, color: AppColors.text),
                    ),
                    if (details.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        details,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 13, color: AppColors.muted),
                      ),
                    ],
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

/// Petite pastille « Vente » / « Location ».
class TransactionBadge extends StatelessWidget {
  const TransactionBadge(this.transactionType, {super.key});

  final String transactionType;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.primaryLight,
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      child: Text(
        transactionLabel(transactionType),
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: AppColors.primary,
        ),
      ),
    );
  }
}