import 'package:flutter_test/flutter_test.dart';
import 'package:dinoxo_gamers/domain/models/price_observation.dart';
import 'package:dinoxo_gamers/domain/services/price_estimator_service.dart';

void main() {
  group('PriceEstimatorService Tests', () {
    test('expired historical pattern does not promise an imminent sale', () {
      final observations = List.generate(6, (i) => PriceObservation(
        id: '$i', editionId: 'old', price: i.isEven ? 60 : 30,
        recordedAt: DateTime.now().subtract(Duration(days: 365 - i * 15)),
      ));
      final result = PriceEstimatorService.estimateNextSale(observations: observations, regularPrice: 60);
      expect(result.hasEnoughData, false);
      expect(result.estimatedWindow, isNull);
      expect(result.reason, contains('ya pasó'));
    });
    test('estimateNextSale returns insufficient data when fewer than 3 discount events exist', () {
      final now = DateTime.now();
      final observations = [
        PriceObservation(
          id: '1',
          editionId: 'ed1',
          price: 69.99,
          recordedAt: now.subtract(const Duration(days: 90)),
        ),
        PriceObservation(
          id: '2',
          editionId: 'ed1',
          price: 49.99,
          recordedAt: now.subtract(const Duration(days: 30)),
        ),
      ];

      final estimation = PriceEstimatorService.estimateNextSale(
        observations: observations,
        regularPrice: 69.99,
      );

      expect(estimation.hasEnoughData, false);
      expect(estimation.historicalCyclesCount, 0);
      expect(estimation.reason.contains('Historial insuficiente'), true);
    });

    test('estimateNextSale calculates projection when >= 3 discount events exist', () {
      final now = DateTime.now();
      final observations = [
        PriceObservation(
          id: '1',
          editionId: 'ed1',
          price: 69.99,
          recordedAt: now.subtract(const Duration(days: 200)),
        ),
        PriceObservation(
          id: '2',
          editionId: 'ed1',
          price: 49.99, // Event 1
          recordedAt: now.subtract(const Duration(days: 180)),
        ),
        PriceObservation(
          id: '3',
          editionId: 'ed1',
          price: 69.99,
          recordedAt: now.subtract(const Duration(days: 165)),
        ),
        PriceObservation(
          id: '4',
          editionId: 'ed1',
          price: 44.99, // Event 2
          recordedAt: now.subtract(const Duration(days: 120)),
        ),
        PriceObservation(
          id: '5',
          editionId: 'ed1',
          price: 69.99,
          recordedAt: now.subtract(const Duration(days: 105)),
        ),
        PriceObservation(
          id: '6',
          editionId: 'ed1',
          price: 39.99, // Event 3
          recordedAt: now.subtract(const Duration(days: 60)),
        ),
      ];

      final estimation = PriceEstimatorService.estimateNextSale(
        observations: observations,
        regularPrice: 69.99,
      );

      expect(estimation.hasEnoughData, true);
      expect(estimation.historicalCyclesCount, 3);
      expect(estimation.estimatedWindow, isNotNull);
      expect(estimation.confidence, isNotNull);
      expect(estimation.reason.contains('rebajas previas'), true);
    });
  });
}
