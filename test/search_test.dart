import 'package:flutter_test/flutter_test.dart';
import 'package:budget_fuck/utils/search.dart';

void main() {
  group('normalizeForSearch', () {
    test('lowercases and trims leading/trailing spaces', () {
      expect(normalizeForSearch('  Spesa  '), 'spesa');
    });

    test('removes accents', () {
      expect(normalizeForSearch('Caffè Città Perché'), 'caffe citta perche');
    });
  });

  group('matchesSearch', () {
    test('an empty or whitespace-only query matches everything', () {
      expect(matchesSearch('Affitto', ''), isTrue);
      expect(matchesSearch('Affitto', '   '), isTrue);
    });

    test('finds a substring ignoring case', () {
      expect(matchesSearch('Spese mediche', 'MED'), isTrue);
      expect(matchesSearch('Spese mediche', 'spese'), isTrue);
    });

    test('ignores accents in both directions', () {
      expect(matchesSearch('Caffè', 'caffe'), isTrue);
      expect(matchesSearch('Caffe', 'caffè'), isTrue);
    });

    test('does not find missing text', () {
      expect(matchesSearch('Affitto', 'bollette'), isFalse);
    });
  });
}
