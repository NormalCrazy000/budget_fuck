// Funzioni di supporto per la ricerca testuale nelle liste.

/// Lettere accentate italiane (e varianti comuni) e la loro forma senza accento.
const _accents = {
  'à': 'a', 'á': 'a', 'â': 'a', 'ä': 'a',
  'è': 'e', 'é': 'e', 'ê': 'e', 'ë': 'e',
  'ì': 'i', 'í': 'i', 'î': 'i', 'ï': 'i',
  'ò': 'o', 'ó': 'o', 'ô': 'o', 'ö': 'o',
  'ù': 'u', 'ú': 'u', 'û': 'u', 'ü': 'u',
};

/// Normalizza un testo per il confronto: minuscolo, senza accenti e
/// senza spazi iniziali/finali (es. " Caffè " → "caffe").
String normalizeForSearch(String text) {
  final lower = text.trim().toLowerCase();
  final buffer = StringBuffer();
  for (final char in lower.split('')) {
    buffer.write(_accents[char] ?? char);
  }
  return buffer.toString();
}

/// Restituisce true se [text] contiene [query], ignorando maiuscole e accenti.
///
/// Una query vuota (o fatta solo di spazi) corrisponde a qualsiasi testo,
/// così una barra di ricerca vuota mostra tutta la lista.
bool matchesSearch(String text, String query) {
  final normalizedQuery = normalizeForSearch(query);
  if (normalizedQuery.isEmpty) return true;
  return normalizeForSearch(text).contains(normalizedQuery);
}
