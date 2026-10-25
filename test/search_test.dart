import 'package:flutter_test/flutter_test.dart';
import 'package:budget_fuck/utils/search.dart';

void main() {
  group('normalizeForSearch', () {
    test('rende minuscolo e toglie spazi iniziali/finali', () {
      expect(normalizeForSearch('  Spesa  '), 'spesa');
    });

    test('rimuove gli accenti', () {
      expect(normalizeForSearch('Caffè Città Perché'), 'caffe citta perche');
    });
  });

  group('matchesSearch', () {
    test('query vuota o di soli spazi corrisponde a tutto', () {
      expect(matchesSearch('Affitto', ''), isTrue);
      expect(matchesSearch('Affitto', '   '), isTrue);
    });

    test('trova una sottostringa ignorando maiuscole', () {
      expect(matchesSearch('Spese mediche', 'MED'), isTrue);
      expect(matchesSearch('Spese mediche', 'spese'), isTrue);
    });

    test('ignora gli accenti in entrambe le direzioni', () {
      expect(matchesSearch('Caffè', 'caffe'), isTrue);
      expect(matchesSearch('Caffe', 'caffè'), isTrue);
    });

    test('non trova testo assente', () {
      expect(matchesSearch('Affitto', 'bollette'), isFalse);
    });
  });
}
