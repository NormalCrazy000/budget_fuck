// Helpers for text search in lists.

/// Accented letters (Italian and common variants) and their unaccented form.
const _accents = {
  'à': 'a', 'á': 'a', 'â': 'a', 'ä': 'a',
  'è': 'e', 'é': 'e', 'ê': 'e', 'ë': 'e',
  'ì': 'i', 'í': 'i', 'î': 'i', 'ï': 'i',
  'ò': 'o', 'ó': 'o', 'ô': 'o', 'ö': 'o',
  'ù': 'u', 'ú': 'u', 'û': 'u', 'ü': 'u',
};

/// Normalizes a text for comparison: lowercase, no accents and no
/// leading/trailing spaces (e.g. " Caffè " → "caffe").
String normalizeForSearch(String text) {
  final lower = text.trim().toLowerCase();
  final buffer = StringBuffer();
  for (final char in lower.split('')) {
    buffer.write(_accents[char] ?? char);
  }
  return buffer.toString();
}

/// Whether [text] contains [query], ignoring case and accents.
///
/// An empty (or whitespace-only) query matches any text, so an empty
/// search bar shows the whole list.
bool matchesSearch(String text, String query) {
  final normalizedQuery = normalizeForSearch(query);
  if (normalizedQuery.isEmpty) return true;
  return normalizeForSearch(text).contains(normalizedQuery);
}
