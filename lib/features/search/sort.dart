import '../../data/models/listing.dart';

/// Tri de la liste d'accueil (T5.3).
enum SortKey {
  newest('Plus récentes'),
  oldest('Plus anciennes'),
  priceAsc('Prix croissant'),
  priceDesc('Prix décroissant');

  const SortKey(this.label);

  final String label;
}

const SortKey kDefaultSort = SortKey.newest;

/// La réserve d'annonces arrive déjà de la plus récente à la plus ancienne (createdAt desc) :
/// « récentes » garde cet ordre, « anciennes » l'inverse, et le tri par prix est stable
/// (à prix égal, la plus récente reste en premier).
List<Listing> applySort(List<Listing> items, SortKey sort) {
  switch (sort) {
    case SortKey.oldest:
      return items.reversed.toList();
    case SortKey.priceAsc:
      return _stableSort(items, (a, b) => a.price.compareTo(b.price));
    case SortKey.priceDesc:
      return _stableSort(items, (a, b) => b.price.compareTo(a.price));
    case SortKey.newest:
      return items;
  }
}

// List.sort de Dart n'est pas garanti stable : on départage par la position d'origine.
List<Listing> _stableSort(
  List<Listing> items,
  int Function(Listing a, Listing b) compare,
) {
  final indexed = items.asMap().entries.toList();
  indexed.sort((x, y) {
    final c = compare(x.value, y.value);
    return c != 0 ? c : x.key.compareTo(y.key);
  });
  return indexed.map((e) => e.value).toList();
}
