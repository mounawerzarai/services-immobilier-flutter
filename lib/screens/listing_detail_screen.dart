
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../core/theme.dart';
import '../data/services/listings_repository.dart';
import '../features/listings/format.dart';
import '../features/listings/listing_card.dart' show TransactionBadge;
import '../features/listings/photo_carousel.dart';
import '../features/favorites_profile/profile_avatar.dart';
import '../services/listing_service.dart';
import '../widgets/ui.dart';
import 'package:services_immobilier/widgets/favorite_button.dart';

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

  Widget _centerMessage(
    String text,
    String buttonLabel,
    VoidCallback onPressed, {
    IconData icon = Icons.cloud_off_outlined,
    bool danger = true,
  }) {
    return EmptyState(
      icon: icon,
      danger: danger,
      title: text,
      actionLabel: buttonLabel,
      onAction: onPressed,
    );
  }

  Widget _section(String title) => Padding(
        padding: const EdgeInsets.only(top: 22, bottom: 10),
        child: Text(
          title,
          style: const TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w800,
            color: AppColors.text,
          ),
        ),
      );

  Future<void> _delete(String title) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text("Supprimer l'annonce ?"),
        content: Text('« $title » sera définitivement supprimée.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(c, false),
            child: const Text('Annuler'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.danger,
              minimumSize: const Size(0, 44),
            ),
            onPressed: () => Navigator.pop(c, true),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    try {
      await ListingService().deleteListing(widget.id);
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Annonce supprimée')));
      context.pop();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Erreur : $e')));
      }
    }
  }

  // Barre du bas : Favori + Contacter, ou Modifier + Supprimer pour le propriétaire.
  Widget _bottomBar({required bool isMine, required String title}) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(AppRadius.lg)),
        boxShadow: AppShadows.raised,
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
          child: Row(
            children: isMine
                ? [
                    Expanded(
                      child: OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(minimumSize: const Size(0, 52)),
                        onPressed: () => context.push('/listing/${widget.id}/edit'),
                        icon: const Icon(Icons.edit_outlined),
                        label: const Text('Modifier'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: FilledButton.icon(
                        style: FilledButton.styleFrom(backgroundColor: AppColors.danger),
                        onPressed: () => _delete(title),
                        icon: const Icon(Icons.delete_outline),
                        label: const Text('Supprimer'),
                      ),
                    ),
                  ]
                : [
                    FavoriteButton(listingId: widget.id),
                    const SizedBox(width: 12),
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: null,
                        icon: const Icon(Icons.chat_bubble_outline),
                        label: const Text('Contacter'),
                      ),
                    ),
                  ],
          ),
        ),
      ),
    );
  }

  Widget _fact(IconData icon, String label, String value) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 6),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadius.card),
          boxShadow: AppShadows.soft,
        ),
        child: Column(
          children: [
            IconBadge(icon, size: 36, square: false),
            const SizedBox(height: 6),
            Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: AppColors.text,
              ),
            ),
            const SizedBox(height: 2),
            Text(label, style: const TextStyle(fontSize: 12, color: AppColors.muted)),
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
                Transform.translate(
                  offset: const Offset(0, -26),
                  child: Container(
                    decoration: const BoxDecoration(
                      color: AppColors.canvas,
                      borderRadius:
                          BorderRadius.vertical(top: Radius.circular(AppRadius.xl)),
                    ),
                    padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Wrap(
                          spacing: 6,
                          runSpacing: 6,
                          children: [
                            TransactionBadge(l.transactionType),
                            if ((l.propertyType ?? '').isNotEmpty)
                              Pill(propertyTypeLabel(l.propertyType),
                                  tone: PillTone.neutral),
                            if (closed)
                              Pill(l.status == 'rented' ? 'Loué' : 'Vendu',
                                  tone: PillTone.danger),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Text(
                          l.title,
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                            color: AppColors.text,
                            letterSpacing: -0.3,
                          ),
                        ),
                        if (place.isNotEmpty) ...[
                          const SizedBox(height: 6),
                          IconText(Icons.location_on_outlined, place, size: 14),
                        ],
                        const SizedBox(height: 10),
                        Text(
                          formatPrice(l),
                          style: const TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.w800,
                            color: AppColors.primary,
                            letterSpacing: -0.5,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            _fact(
                              Icons.apartment_outlined,
                              'Type',
                              (l.propertyType ?? '').isEmpty
                                  ? '—'
                                  : propertyTypeLabel(l.propertyType),
                            ),
                            const SizedBox(width: 10),
                            _fact(
                              Icons.straighten,
                              'Surface',
                              (l.surface ?? 0) > 0 ? formatSurface(l.surface!) : '—',
                            ),
                            const SizedBox(width: 10),
                            _fact(
                              Icons.bed_outlined,
                              'Pièces',
                              (l.rooms ?? 0) > 0 ? '${l.rooms}' : '—',
                            ),
                          ],
                        ),
                        if (l.description.isNotEmpty) ...[
                          _section('Description'),
                          Text(
                            l.description,
                            style: const TextStyle(
                              fontSize: 15,
                              height: 1.5,
                              color: Color(0xFF3A4651),
                            ),
                          ),
                        ],
                        _section(isMine ? 'Votre annonce' : 'Vendeur'),
                        AppCard(
                          padding: const EdgeInsets.all(14),
                          child: Row(
                            children: [
                              ProfileAvatar(
                                name: sellerName,
                                photoBytes: seller?.photoBytes,
                                radius: 24,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      sellerName,
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w700,
                                        color: AppColors.text,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      sellerPhone.isEmpty
                                          ? 'Téléphone non renseigné'
                                          : sellerPhone,
                                      style: const TextStyle(
                                        fontSize: 13,
                                        color: AppColors.muted,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              if (sellerPhone.isNotEmpty && !isMine)
                                const IconBadge(Icons.call_outlined, square: false),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        _bottomBar(isMine: isMine, title: l.title),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final Widget body;

    switch (_state) {
      case _LoadState.loading:
        body = const Center(child: CircularProgressIndicator());
        break;

      case _LoadState.notFound:
        body = _centerMessage(
          'Cette annonce n’existe plus.',
          'Retour',
          () => Navigator.of(context).pop(),
          icon: Icons.delete_outline,
          danger: false,
        );
        break;

      case _LoadState.error:
        body = _centerMessage(
          'Impossible de charger l’annonce. Vérifiez votre connexion.',
          'Réessayer',
          _retry,
        );
        break;

      case _LoadState.ready:
        body = _content(_detail!);
        break;
    }

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        automaticallyImplyLeading: false,
        leading: Padding(
          padding: const EdgeInsets.only(left: 12),
          child: Center(
            child: RoundIconButton(
              icon: Icons.arrow_back_ios_new,
              tooltip: 'Retour',
              size: 40,
              onPressed: () => Navigator.of(context).maybePop(),
            ),
          ),
        ),
        leadingWidth: 56,
      ),
      body: body,
    );
  }
}
