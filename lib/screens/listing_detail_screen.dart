import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../core/theme.dart';
import '../data/services/listings_repository.dart';
import '../features/listings/format.dart';
import '../features/listings/listing_card.dart' show TransactionBadge;
import '../features/listings/photo_carousel.dart';

enum _LoadState { loading, ready, notFound, error }

class ListingDetailScreen extends StatefulWidget {
  final String id;

  const ListingDetailScreen({super.key, required this.id});

  @override
  State<ListingDetailScreen> createState() => _ListingDetailScreenState();
}

class _ListingDetailScreenState extends State<ListingDetailScreen> {
  final ListingsRepository _repo = ListingsRepository();

  _LoadState _state = _LoadState.loading;
  ListingDetail? _detail;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final found = await _repo.getDetail(widget.id);
      if (!mounted) return;
      setState(() {
        _detail = found;
        _state = found == null ? _LoadState.notFound : _LoadState.ready;
      });
    } catch (_) {
      if (mounted) setState(() => _state = _LoadState.error);
    }
  }

  void _retry() {
    setState(() => _state = _LoadState.loading);
    _load();
  }

  Widget _centerMessage(String text, String buttonLabel, VoidCallback onPressed) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              text,
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.muted),
            ),
            const SizedBox(height: 16),
            OutlinedButton(onPressed: onPressed, child: Text(buttonLabel)),
          ],
        ),
      ),
    );
  }

  Widget _section(String title) => Padding(
        padding: const EdgeInsets.only(top: 18, bottom: 8),
        child: Text(
          title,
          style: const TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w700,
            color: AppColors.text,
          ),
        ),
      );

  // Barre du bas : Favori (T7) et Contacter (T8) seront branchés dans leurs tâches.
  Widget _bottomBar() {
    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
        decoration: const BoxDecoration(
          color: AppColors.background,
          border: Border(top: BorderSide(color: AppColors.border)),
        ),
        child: const Row(
          children: [
            Expanded(
              child: OutlinedButton(onPressed: null, child: Text('♡ Favori')),
            ),
            SizedBox(width: 12),
            Expanded(
              child: FilledButton(onPressed: null, child: Text('Contacter')),
            ),
          ],
        ),
      ),
    );
  }

  Widget _content(ListingDetail detail) {
    final l = detail.listing;
    final seller = detail.seller;
    final isMine = FirebaseAuth.instance.currentUser?.uid == l.sellerId;
    final closed = l.status != 'available';
    final facts = formatFacts(l);
    final place = [l.address, l.city].where((s) => s.isNotEmpty).join(', ');
    final sellerName =
        seller != null && seller.name.isNotEmpty ? seller.name : 'Vendeur';
    final sellerPhone = seller?.phone ?? '';

    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                PhotoCarousel(photos: l.photos),
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (closed)
                        Container(
                          width: double.infinity,
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFCEAE8),
                            borderRadius: BorderRadius.circular(AppRadius.input),
                          ),
                          child: Text(
                            'Cette annonce est ${l.status == 'rented' ? 'louée' : 'vendue'}.',
                            style: const TextStyle(
                              color: Color(0xFFB3261E),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Flexible(
                            child: Text(
                              formatPrice(l),
                              style: const TextStyle(
                                fontSize: 26,
                                fontWeight: FontWeight.w700,
                                color: AppColors.text,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          TransactionBadge(l.transactionType),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        l.title,
                        style: const TextStyle(fontSize: 18, color: AppColors.text),
                      ),
                      if (place.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          place,
                          style: const TextStyle(fontSize: 14, color: AppColors.muted),
                        ),
                      ],
                      if (facts.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            for (final f in facts)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  border: Border.all(color: AppColors.border),
                                  borderRadius: BorderRadius.circular(AppRadius.pill),
                                ),
                                child: Text(
                                  f,
                                  style: const TextStyle(
                                    fontSize: 13,
                                    color: AppColors.text,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ],
                      if (l.description.isNotEmpty) ...[
                        _section('Description'),
                        Text(
                          l.description,
                          style: const TextStyle(
                            fontSize: 15,
                            height: 1.45,
                            color: AppColors.text,
                          ),
                        ),
                      ],
                      _section('Vendeur'),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          border: Border.all(color: AppColors.border),
                          borderRadius: BorderRadius.circular(AppRadius.card),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              sellerName,
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: AppColors.text,
                              ),
                            ),
                            if (sellerPhone.isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.only(top: 2),
                                child: Text(
                                  sellerPhone,
                                  style: const TextStyle(
                                    fontSize: 14,
                                    color: AppColors.muted,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        if (!isMine) _bottomBar(),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final Widget body;
    switch (_state) {
      case _LoadState.loading:
        body = const Center(child: CircularProgressIndicator());
      case _LoadState.notFound:
        body = _centerMessage(
          'Cette annonce n’existe plus.',
          'Retour',
          () => Navigator.of(context).pop(),
        );
      case _LoadState.error:
        body = _centerMessage(
          'Impossible de charger l’annonce. Vérifiez votre connexion.',
          'Réessayer',
          _retry,
        );
      case _LoadState.ready:
        body = _content(_detail!);
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Détail')),
      body: body,
    );
  }
}