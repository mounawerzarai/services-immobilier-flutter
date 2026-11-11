import '../../data/models/listing.dart';
import '../listings/format.dart';

// Lettres accentuées et leur équivalent sans accent (même longueur, même ordre).
const String _from = 'àáâãäåçèéêëìíîïñòóôõöùúûüýÿ';
const String _to = 'aaaaaaceeeeiiiinooooouuuuyy';

/// Minuscules + sans accents, pour que « Résidence » trouve « residence ».
String normalize(String s) {
  final lower = s.toLowerCase().replaceAll('œ', 'oe').replaceAll('æ', 'ae');
  final out = StringBuffer();
  for (final ch in lower.runes.map(String.fromCharCode)) {
    final i = _from.indexOf(ch);
    out.write(i >= 0 ? _to[i] : ch);
  }
  return out.toString().trim();
}

/// Garde les annonces dont le titre, la description, la ville, l'adresse, le type
/// (en français : « Appartement », « Maison »…) ou « Vente » / « Location »
/// contiennent TOUS les mots saisis.
List<Listing> filterListings(List<Listing> items, String term) {
  final tokens = normalize(term)
      .split(RegExp(r'\s+'))
      .where((t) => t.isNotEmpty)
      .toList();
  if (tokens.isEmpty) return items;

  return items.where((l) {
    final haystack = normalize([
      l.title,
      l.description,
      l.city,
      l.address,
      propertyTypeLabel(l.propertyType),
      transactionLabel(l.transactionType),
    ].join(' '));
    return tokens.every((t) => haystack.contains(t));
  }).toList();
}
