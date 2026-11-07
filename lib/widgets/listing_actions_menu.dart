import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../services/listing_service.dart';

class ListingActionsMenu extends StatelessWidget {
  final String listingId;
  final String status; // available | sold | rented
  final String transactionType; // sale | rent

  const ListingActionsMenu({
    super.key,
    required this.listingId,
    required this.status,
    required this.transactionType,
  });

  void _msg(BuildContext c, String t) =>
      ScaffoldMessenger.of(c).showSnackBar(SnackBar(content: Text(t)));

  Future<void> _delete(BuildContext context) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('Supprimer l\'annonce ?'),
        content: const Text('Cette action est définitive.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(c, false),
              child: const Text('Annuler')),
          FilledButton(
              onPressed: () => Navigator.pop(c, true),
              child: const Text('Supprimer')),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await ListingService().deleteListing(listingId);
      if (context.mounted) _msg(context, 'Annonce supprimée');
    } catch (e) {
      if (context.mounted) _msg(context, 'Erreur : $e');
    }
  }

  Future<void> _setStatus(BuildContext context, String newStatus) async {
    try {
      await ListingService().setStatus(listingId, newStatus);
      if (context.mounted) _msg(context, 'Statut mis à jour');
    } catch (e) {
      if (context.mounted) _msg(context, 'Erreur : $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final isRent = transactionType == 'rent';
    final closedStatus = isRent ? 'rented' : 'sold';
    final available = status == 'available';

    return PopupMenuButton<String>(
      onSelected: (v) {
        switch (v) {
          case 'edit':
            context.push('/listing/$listingId/edit');
          case 'status':
            _setStatus(context, available ? closedStatus : 'available');
          case 'delete':
            _delete(context);
        }
      },
      itemBuilder: (c) => [
        const PopupMenuItem(value: 'edit', child: Text('Modifier')),
        PopupMenuItem(
          value: 'status',
          child: Text(available
              ? (isRent ? 'Marquer comme loué' : 'Marquer comme vendu')
              : 'Remettre en ligne'),
        ),
        const PopupMenuItem(value: 'delete', child: Text('Supprimer')),
      ],
    );
  }
}