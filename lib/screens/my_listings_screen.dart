import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../widgets/listing_actions_menu.dart';

class MyListingsScreen extends StatelessWidget {
  const MyListingsScreen({super.key});

  static const _labels = {
    'available': 'Disponible',
    'sold': 'Vendu',
    'rented': 'Loué',
  };

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Mes annonces')),
        body: const Center(child: Text('Connectez-vous pour voir vos annonces.')),
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
            return Padding(
                padding: const EdgeInsets.all(24),
                child: Text('Erreur : ${snap.error}'));
          }
          if (!snap.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final docs = snap.data!.docs;
          if (docs.isEmpty) {
            return const Center(child: Text('Vous n\'avez aucune annonce.'));
          }
          return ListView.separated(
            itemCount: docs.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (context, i) {
              final d = docs[i].data();
              final photos = (d['photos'] as List?) ?? [];
              final status = (d['status'] as String?) ?? 'available';
              return ListTile(
                leading: SizedBox(
                  width: 56,
                  height: 56,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: photos.isEmpty
                        ? Container(color: const Color(0xFFD4E4DE))
                        : Image.network(photos.first as String,
                            fit: BoxFit.cover),
                  ),
                ),
                title: Text(d['title'] ?? ''),
                subtitle: Text(
                    '${d['price'] ?? ''} · ${d['city'] ?? ''} · ${_labels[status] ?? status}'),
                trailing: ListingActionsMenu(
                  listingId: docs[i].id,
                  status: status,
                  transactionType: (d['transactionType'] as String?) ?? 'sale',
                ),
              );
            },
          );
        },
      ),
    );
  }
}