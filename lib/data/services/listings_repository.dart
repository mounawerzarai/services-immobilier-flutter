import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/listing.dart';
import '../models/user_profile.dart';

class ListingsPage {
  const ListingsPage({
    required this.items,
    required this.cursor,
    required this.hasMore,
  });

  final List<Listing> items;
  final DocumentSnapshot<Map<String, dynamic>>? cursor;
  final bool hasMore;
}

class ListingDetail {
  const ListingDetail({required this.listing, this.seller});

  final Listing listing;
  final UserProfile? seller;
}

/// Lecture des annonces publiques (liste, recherche, détail).
/// L'écriture (publier, modifier, supprimer) reste dans services/listing_service.dart.
class ListingsRepository {
  static const int pageSize = 20;
  static const int searchPoolSize = 200;

  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // Annonces disponibles, de la plus récente à la plus ancienne.
  // Utilise l'index status + createdAt (déjà déployé).
  Query<Map<String, dynamic>> get _available => _db
      .collection('listings')
      .where('status', isEqualTo: 'available')
      .orderBy('createdAt', descending: true);

  Listing _toListing(QueryDocumentSnapshot<Map<String, dynamic>> d) =>
      Listing.fromMap(d.id, d.data());

  /// Une page de 20 annonces. Passer le `cursor` de la page précédente pour la suivante.
  Future<ListingsPage> getAvailablePage([
    DocumentSnapshot<Map<String, dynamic>>? cursor,
  ]) async {
    var query = _available.limit(pageSize);
    if (cursor != null) query = query.startAfterDocument(cursor);
    final snap = await query.get();
    return ListingsPage(
      items: snap.docs.map(_toListing).toList(),
      cursor: snap.docs.isEmpty ? cursor : snap.docs.last,
      hasMore: snap.docs.length == pageSize,
    );
  }

  /// Réserve d'annonces pour la recherche texte (T5.1) : les 200 plus récentes.
  Future<List<Listing>> getSearchPool() async {
    final snap = await _available.limit(searchPoolSize).get();
    return snap.docs.map(_toListing).toList();
  }

  /// Une annonce et son vendeur. Renvoie null si l'annonce n'existe plus.
  Future<ListingDetail?> getDetail(String id) async {
    final snap = await _db.collection('listings').doc(id).get();
    final data = snap.data();
    if (!snap.exists || data == null) return null;

    final listing = Listing.fromMap(snap.id, data);
    UserProfile? seller;
    try {
      final s = await _db.collection('users').doc(listing.sellerId).get();
      final sd = s.data();
      if (sd != null) seller = UserProfile.fromMap(s.id, sd);
    } catch (_) {
      // Le vendeur reste optionnel : l'annonce s'affiche quand même.
    }
    return ListingDetail(listing: listing, seller: seller);
  }
}