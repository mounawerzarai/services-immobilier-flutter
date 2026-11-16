import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../core/theme.dart';
import '../data/models/listing.dart';
import '../data/services/listings_repository.dart';
import '../features/listings/format.dart';
import '../features/listings/listing_card.dart';
import '../features/search/filter_sheet.dart';
import '../features/search/filters.dart';
import '../features/search/search_listings.dart';
import '../features/search/sort.dart';
import '../widgets/ui.dart';

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

  // Recherche texte (T5.1) et filtres (T5.2) : on charge une réserve d'annonces une seule
  // fois (dès qu'on tape une lettre ou qu'on applique un filtre), puis on filtre dans l'appli.
  String _term = '';
  Filters _filters = const Filters();
  SortKey _sort = kDefaultSort;
  List<Listing>? _pool;
  bool _poolLoading = false;
  bool _poolError = false;

  bool get _searching => _term.trim().isNotEmpty;

  // Recherche, filtre ou tri : on travaille sur la réserve complète (sans pagination), car un
  // tri par prix n'a de sens que sur toutes les annonces, pas seulement sur la page chargée.
  bool get _filtering =>
      _searching || !_filters.isEmpty || _sort != kDefaultSort;

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
    if (_filtering || !_hasMore || _loadingMore || _loading || _error != null) {
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

  void _ensurePool() {
    if (_pool == null && !_poolLoading && !_poolError) _loadPool();
  }

  void _onTermChanged(String text) {
    setState(() => _term = text);
    if (text.trim().isNotEmpty) _ensurePool();
  }

  void _onSortChanged(SortKey next) {
    setState(() => _sort = next);
    if (next != kDefaultSort) _ensurePool();
  }

  Future<void> _openFilters() async {
    final next = await showFilterSheet(context, _filters);
    if (next == null || !mounted) return;
    setState(() => _filters = next);
    if (!next.isEmpty) _ensurePool();
  }

  void _clearFilters() => setState(() => _filters = const Filters());

  // Puces rapides « Appartement / Maison… » : raccourci vers le filtre « type de bien ».
  void _pickType(String? type) {
    final f = _filters;
    final next = Filters(
      transactionType: f.transactionType,
      propertyType: type,
      city: f.city,
      minPrice: f.minPrice,
      maxPrice: f.maxPrice,
      minRooms: f.minRooms,
    );
    setState(() => _filters = next);
    if (!next.isEmpty) _ensurePool();
  }

  static const Map<String, IconData> _typeIcons = {
    'apartment': Icons.apartment_outlined,
    'house': Icons.house_outlined,
    'land': Icons.landscape_outlined,
    'commercial': Icons.storefront_outlined,
  };

  String get _firstName {
    final name = FirebaseAuth.instance.currentUser?.displayName?.trim() ?? '';
    return name.isEmpty ? '' : name.split(RegExp(r'\s+')).first;
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
    if (_filtering) _loadPool();
  }

  Widget _message(
    String text, {
    String? buttonLabel,
    VoidCallback? onPressed,
    IconData icon = Icons.home_outlined,
    bool danger = false,
    String? title,
  }) {
    return ListView(
      // ListView : garde le « tirer pour actualiser » et évite les débordements clavier.
      children: [
        EmptyState(
          icon: icon,
          danger: danger,
          title: title ?? text,
          text: title == null ? null : text,
          actionLabel: buttonLabel,
          onAction: onPressed,
        ),
      ],
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
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 100),
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
      return _message(
        _error!,
        title: 'Connexion impossible',
        icon: Icons.cloud_off_outlined,
        danger: true,
        buttonLabel: 'Réessayer',
        onPressed: _retry,
      );
    }
    if (_items.isEmpty) {
      return _message(
        'Soyez le premier à publier un bien.',
        title: 'Aucune annonce pour le moment',
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

  // Résultats de la recherche / des filtres (results == null tant que la réserve n'est pas chargée).
  Widget _searchArea(List<Listing>? results) {
    if (results == null) {
      if (_poolError) {
        return _message(
          'Vérifiez votre connexion puis réessayez.',
          title: 'Recherche impossible',
          icon: Icons.cloud_off_outlined,
          danger: true,
          buttonLabel: 'Réessayer',
          onPressed: _loadPool,
        );
      }
      return const Center(child: CircularProgressIndicator());
    }
    if (results.isEmpty) {
      return _message(
        _filters.isEmpty
            ? 'Essayez avec un autre mot-clé.'
            : 'Essayez d’élargir vos critères de recherche.',
        title: _searching
            ? 'Aucun résultat pour « ${_term.trim()} »'
            : 'Aucune annonce trouvée',
        icon: Icons.search_off,
        buttonLabel: _filters.isEmpty ? null : 'Effacer les filtres',
        onPressed: _clearFilters,
      );
    }
    return _cardList(results, onRefresh: _loadPool);
  }

  @override
  Widget build(BuildContext context) {
    final List<Listing>? results =
        _filtering && _pool != null
            ? applySort(
                applyFilters(filterListings(_pool!, _term), _filters),
                _sort,
              )
            : null;
    final activeFilters = _filters.activeCount;
    final name = _firstName;

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // En-tête : salutation + accès à « Mes annonces ».
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          name.isEmpty ? 'Bonjour 👋' : 'Bonjour, $name 👋',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: AppColors.muted,
                          ),
                        ),
                        const SizedBox(height: 2),
                        const Text(
                          'Trouvez le bien idéal',
                          style: TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.w800,
                            color: AppColors.text,
                            letterSpacing: -0.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                  RoundIconButton(
                    icon: Icons.inventory_2_outlined,
                    tooltip: 'Mes annonces',
                    color: AppColors.primary,
                    onPressed: () => context.push('/my-listings'),
                  ),
                ],
              ),
            ),
            // Recherche + filtres.
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 4),
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(AppRadius.md),
                        boxShadow: AppShadows.soft,
                      ),
                      child: TextField(
                        controller: _searchController,
                        onChanged: _onTermChanged,
                        textInputAction: TextInputAction.search,
                        autocorrect: false,
                        decoration: InputDecoration(
                          hintText: 'Ville, titre, type de bien…',
                          prefixIcon: const Icon(Icons.search, color: AppColors.muted),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(AppRadius.md),
                            borderSide: BorderSide.none,
                          ),
                          suffixIcon: _term.isEmpty
                              ? null
                              : IconButton(
                                  tooltip: 'Effacer',
                                  icon: const Icon(Icons.cancel, color: AppColors.subtle),
                                  onPressed: _clearSearch,
                                ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  RoundIconButton(
                    icon: Icons.tune,
                    tooltip: 'Filtres',
                    size: 52,
                    radius: AppRadius.md,
                    badge: activeFilters,
                    color: activeFilters > 0 ? Colors.white : AppColors.primary,
                    background:
                        activeFilters > 0 ? AppColors.primary : AppColors.surface,
                    onPressed: _openFilters,
                  ),
                ],
              ),
            ),
            // Puces rapides par type de bien.
            SizedBox(
              height: 56,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.fromLTRB(20, 10, 20, 8),
                children: [
                  _TypeChip(
                    label: 'Tous',
                    icon: Icons.grid_view_rounded,
                    selected: _filters.propertyType == null,
                    onTap: () => _pickType(null),
                  ),
                  for (final k in kPropertyTypeKeys)
                    _TypeChip(
                      label: propertyTypeLabel(k),
                      icon: _typeIcons[k] ?? Icons.home_outlined,
                      selected: _filters.propertyType == k,
                      onTap: () => _pickType(k),
                    ),
                ],
              ),
            ),
            // Titre de liste + tri.
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 6, 12, 0),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      results != null
                          ? '${results.length} résultat${results.length > 1 ? 's' : ''}'
                          : 'Annonces récentes',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: AppColors.text,
                      ),
                    ),
                  ),
                  if (activeFilters > 0)
                    TextButton(
                      onPressed: _clearFilters,
                      child: const Text('Effacer les filtres'),
                    ),
                ],
              ),
            ),
            SizedBox(
              height: 42,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.fromLTRB(16, 4, 20, 6),
                children: [
                  const Padding(
                    padding: EdgeInsets.only(left: 4, right: 4),
                    child: Icon(Icons.swap_vert, size: 18, color: AppColors.muted),
                  ),
                  for (final o in SortKey.values)
                    Padding(
                      padding: const EdgeInsets.only(right: 4),
                      child: TextButton(
                        onPressed: () => _onSortChanged(o),
                        style: TextButton.styleFrom(
                          minimumSize: const Size(0, 32),
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          backgroundColor:
                              _sort == o ? AppColors.primarySoft : Colors.transparent,
                          foregroundColor:
                              _sort == o ? AppColors.primary : AppColors.muted,
                          shape: const StadiumBorder(),
                          textStyle: TextStyle(
                            fontSize: 13,
                            fontWeight:
                                _sort == o ? FontWeight.w700 : FontWeight.w500,
                          ),
                        ),
                        child: Text(o.label),
                      ),
                    ),
                ],
              ),
            ),
            Expanded(child: _filtering ? _searchArea(results) : _browseArea()),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _publish,
        icon: const Icon(Icons.add),
        label: const Text(
          'Publier',
          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
        ),
      ),
    );
  }
}

/// Puce « type de bien » avec icône.
class _TypeChip extends StatelessWidget {
  const _TypeChip({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: Material(
        color: selected ? AppColors.primary : AppColors.surface,
        shape: StadiumBorder(
          side: BorderSide(color: selected ? AppColors.primary : AppColors.border),
        ),
        child: InkWell(
          customBorder: const StadiumBorder(),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 16, color: selected ? Colors.white : AppColors.muted),
                const SizedBox(width: 6),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                    color: selected ? Colors.white : AppColors.text,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
