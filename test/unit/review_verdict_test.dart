import 'package:flutter_test/flutter_test.dart';
import 'package:dinoxo_gamers/domain/models/review_snapshot.dart';

void main() {
  group('ReviewSnapshot verdict and recommendation tests', () {
    test('score >= 85 produces Compra Imprescindible', () {
      final review = ReviewSnapshot(
        criticScore: 92,
        userScore: 8.8,
        sourceUrl: 'https://dekudeals.com/items/zelda',
        checkedAt: DateTime.now(),
      );

      expect(review.isWorthBuying, isTrue);
      expect(review.verdictBadgeLabel, '¡Compra Imprescindible!');
      expect(review.verdictExplanation, contains('sobresaliente'));
      expect(review.verdictExplanation, contains('vale totalmente la pena'));
    });

    test('score 75-84 produces Muy Recomendado', () {
      final review = ReviewSnapshot(
        criticScore: 78,
        userScore: 7.6,
        sourceUrl: 'https://dekudeals.com/items/game',
        checkedAt: DateTime.now(),
      );

      expect(review.isWorthBuying, isTrue);
      expect(review.verdictBadgeLabel, '¡Muy Recomendado!');
      expect(review.verdictExplanation, contains('experiencia sólida y muy divertida'));
    });

    test('score 65-74 produces Vale la pena con oferta', () {
      final review = ReviewSnapshot(
        criticScore: 68,
        sourceUrl: 'https://dekudeals.com/items/game',
        checkedAt: DateTime.now(),
      );

      expect(review.isWorthBuying, isFalse);
      expect(review.verdictBadgeLabel, 'Vale la pena con oferta');
      expect(review.verdictExplanation, contains('esperar una buena oferta'));
    });

    test('score 50-64 produces Solo para fans', () {
      final review = ReviewSnapshot(
        criticScore: 56,
        sourceUrl: 'https://dekudeals.com/items/game',
        checkedAt: DateTime.now(),
      );

      expect(review.isWorthBuying, isFalse);
      expect(review.verdictBadgeLabel, 'Solo para fans');
      expect(review.verdictExplanation, contains('Solo vale la pena si sos fanático'));
    });

    test('score < 50 produces No recomendado', () {
      final review = ReviewSnapshot(
        criticScore: 42,
        sourceUrl: 'https://dekudeals.com/items/game',
        checkedAt: DateTime.now(),
      );

      expect(review.isWorthBuying, isFalse);
      expect(review.verdictBadgeLabel, 'No recomendado');
      expect(review.verdictExplanation, contains('No te recomendamos gastar en este juego'));
    });

    test('empty scores produces Sin calificar', () {
      final review = ReviewSnapshot(
        sourceUrl: 'https://dekudeals.com/items/game',
        checkedAt: DateTime.now(),
      );

      expect(review.isWorthBuying, isFalse);
      expect(review.verdictBadgeLabel, 'Sin calificar');
      expect(review.verdictExplanation, contains('No hay suficientes calificaciones registradas'));
    });
  });
}
