import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../core/theme.dart';
import '../data/models/listing.dart';
import '../data/services/listings_repository.dart';
import '../features/listings/listing_card.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  static const String _loadError =
      'Impossible de charger les annonces. Vérifiez votre connexion.';

  final ListingsRepository _repo = ListingsRepository();
  final ScrollController _scroll = ScrollController();

  List<Listing> _items = [];
  DocumentSnapshot<Map<String, dynamic>>? _cursor;
  bool _loading = true; // premier chargement
  bool _loadingMore = false; // page suivante
  bool _hasMore = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _scroll.addListener(_onScroll);
    _fetchFirstPage();
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  // Charge la page suivante quand on approche du bas de la liste.
  void _onScroll() {
    if (_scroll.position.extentAfter < 300) _loadMore();
  }

  // Première page (ouverture, tirer pour actualiser, bouton Réessayer).
  Future<void> _fetchFirstPage() async {
    try {
      final page = await _repo.getAvailablePage();
      if (!mounted) return;
      setState(() {
        _items = page.items;
        _cursor = page.cursor;
        _hasMore = page.hasMore;
        _error = null;
      });
    } catch (_) {
      if (!mounted) return;
      if (_items.isEmpty) {
        setState(() => _error = _loadError);
      } else {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text(_loadError)));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _retry() {
    setState(() {
      _loading = true;
      _error = null;
    });
    _fetchFirstPage();
  }

  Future<void> _loadMore() async {
    if (!_hasMore || _loadingMore || _loading || _error != null) return;
    setState(() => _loadingMore = true);
    try {
      final page = await _repo.getAvailablePage(_cursor);
      if (!mounted) return;
      setState(() {
        final known = _items.map((i) => i.id).toSet();
        _items = [..._items, ...page.items.where((i) => !known.contains(i.id))];
        _cursor = page.cursor;
        _hasMore = page.hasMore;
      });
    } catch (_) {
      if (mounted) setState(() => _hasMore = false);
    } finally {
      if (mounted) setState(() => _loadingMore = false);
    }
  }

  // Publier, puis recharger la liste au retour pour voir la nouvelle annonce.
  Future<void> _publish() async {
    await context.push('/listing/new');
    if (mounted) _fetchFirstPage();
  }

  Widget _message(String text, String buttonLabel, VoidCallback onPressed) {
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

  Widget _body() {
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_error != null) return _message(_error!, 'Réessayer', _retry);
    if (_items.isEmpty) {
      return _message(
        'Aucune annonce pour le moment.',
        'Publier une annonce',
        _publish,
      );
    }

    return RefreshIndicator(
      onRefresh: _fetchFirstPage,
      child: ListView.builder(
        controller: _scroll,
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
        itemCount: _items.length + (_loadingMore ? 1 : 0),
        itemBuilder: (context, i) {
          if (i >= _items.length) {
            return const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Center(child: CircularProgressIndicator()),
            );
          }
          final item = _items[i];
          return ListingCard(
            item: item,
            onTap: () => context.push('/listing/${item.id}'),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Annonces'),
        actions: [
          TextButton(
            onPressed: () => context.push('/my-listings'),
            child: const Text('Mes annonces'),
          ),
        ],
      ),
      body: _body(),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _publish,
        icon: const Icon(Icons.add),
        label: const Text('Publier'),
      ),
    );
  }
}