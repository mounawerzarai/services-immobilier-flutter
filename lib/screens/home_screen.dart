import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../core/theme.dart';
import '../data/models/listing.dart';
import '../data/services/listings_repository.dart';
import '../features/listings/listing_card.dart';
import '../features/search/search_listings.dart';

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
  final TextEditingController _searchController = TextEditingController();

  // Liste normale (pagination).
  List<Listing> _items = [];
  DocumentSnapshot<Map<String, dynamic>>? _cursor;
  bool _loading = true; // premier chargement
  bool _loadingMore = false; // page suivante
  bool _hasMore = false;
  String? _error;

  // Recherche texte : on charge une réserve d'annonces une seule fois (à la première
  // lettre tapée), puis on filtre dans l'appli à chaque frappe.
  String _term = '';
  List<Listing>? _pool;
  bool _poolLoading = false;
  bool _poolError = false;

  bool get _searching => _term.trim().isNotEmpty;

  @override
  void initState() {
    super.initState();
    _scroll.addListener(_onScroll);
    _fetchFirstPage();
  }

  @override
  void dispose() {
    _scroll.dispose();
    _searchController.dispose();
    super.dispose();
  }

  // Charge la page suivante quand on approche du bas de la liste.
  void _onScroll() {
    if (_scroll.hasClients && _scroll.position.extentAfter < 300) _loadMore();
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
    if (_searching || !_hasMore || _loadingMore || _loading || _error != null) {
      return;
    }
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

  // Charge (ou recharge) la réserve d'annonces utilisée par la recherche.
  Future<void> _loadPool() async {
    if (_poolLoading) return;
    setState(() {
      _poolLoading = true;
      _poolError = false;
    });
    try {
      final pool = await _repo.getSearchPool();
      if (!mounted) return;
      setState(() => _pool = pool);
    } catch (_) {
      if (mounted) setState(() => _poolError = true);
    } finally {
      if (mounted) setState(() => _poolLoading = false);
    }
  }

  void _onTermChanged(String text) {
    setState(() => _term = text);
    if (text.trim().isNotEmpty && _pool == null && !_poolLoading && !_poolError) {
      _loadPool();
    }
  }

  void _clearSearch() {
    _searchController.clear();
    _onTermChanged('');
  }

  // Publier, puis recharger la liste au retour pour voir la nouvelle annonce.
  Future<void> _publish() async {
    await context.push('/listing/new');
    if (!mounted) return;
    setState(() => _pool = null); // la réserve de recherche est périmée
    _fetchFirstPage();
    if (_searching) _loadPool();
  }

  Widget _message(String text, {String? buttonLabel, VoidCallback? onPressed}) {
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
            if (buttonLabel != null) ...[
              const SizedBox(height: 16),
              OutlinedButton(onPressed: onPressed, child: Text(buttonLabel)),
            ],
          ],
        ),
      ),
    );
  }

  Widget _cardList(
    List<Listing> data, {
    required Future<void> Function() onRefresh,
    ScrollController? controller,
    bool moreSpinner = false,
  }) {
    return RefreshIndicator(
      onRefresh: onRefresh,
      child: ListView.builder(
        controller: controller,
        physics: const AlwaysScrollableScrollPhysics(),
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
        itemCount: data.length + (moreSpinner ? 1 : 0),
        itemBuilder: (context, i) {
          if (i >= data.length) {
            return const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Center(child: CircularProgressIndicator()),
            );
          }
          final item = data[i];
          return ListingCard(
            item: item,
            onTap: () => context.push('/listing/${item.id}'),
          );
        },
      ),
    );
  }

  // Liste normale, sans recherche.
  Widget _browseArea() {
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_error != null) {
      return _message(_error!, buttonLabel: 'Réessayer', onPressed: _retry);
    }
    if (_items.isEmpty) {
      return _message(
        'Aucune annonce pour le moment.',
        buttonLabel: 'Publier une annonce',
        onPressed: _publish,
      );
    }
    return _cardList(
      _items,
      controller: _scroll,
      moreSpinner: _loadingMore,
      onRefresh: () {
        _pool = null; // la réserve de recherche sera rechargée à la prochaine recherche
        return _fetchFirstPage();
      },
    );
  }

  // Résultats de la recherche (results == null tant que la réserve n'est pas chargée).
  Widget _searchArea(List<Listing>? results) {
    if (results == null) {
      if (_poolError) {
        return _message(
          'Impossible de lancer la recherche. Vérifiez votre connexion.',
          buttonLabel: 'Réessayer',
          onPressed: _loadPool,
        );
      }
      return const Center(child: CircularProgressIndicator());
    }
    if (results.isEmpty) {
      return _message('Aucun résultat pour « ${_term.trim()} ».');
    }
    return _cardList(results, onRefresh: _loadPool);
  }

  @override
  Widget build(BuildContext context) {
    final List<Listing>? results =
        _searching && _pool != null ? filterListings(_pool!, _term) : null;

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
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 4),
            child: TextField(
              controller: _searchController,
              onChanged: _onTermChanged,
              textInputAction: TextInputAction.search,
              autocorrect: false,
              decoration: InputDecoration(
                hintText: 'Rechercher (ville, titre, type…)',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _term.isEmpty
                    ? null
                    : IconButton(
                        tooltip: 'Effacer',
                        icon: const Icon(Icons.close),
                        onPressed: _clearSearch,
                      ),
              ),
            ),
          ),
          if (results != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  '${results.length} résultat${results.length > 1 ? 's' : ''}',
                  style: const TextStyle(color: AppColors.muted),
                ),
              ),
            ),
          Expanded(child: _searching ? _searchArea(results) : _browseArea()),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _publish,
        icon: const Icon(Icons.add),
        label: const Text('Publier'),
      ),
    );
  }
}
