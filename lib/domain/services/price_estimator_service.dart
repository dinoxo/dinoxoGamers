import 'dart:math';
import '../../core/constants/app_constants.dart';
import '../models/price_observation.dart';
import '../models/sale_estimation.dart';

class PriceEstimatorService {
  PriceEstimatorService._();

  /// Analyzes price observations to project a possible next discount window.
  /// Strictly requires at least 3 distinct discount cycles; otherwise returns insufficient.
  static SaleEstimation estimateNextSale({
    required List<PriceObservation> observations,
    required double regularPrice,
  }) {
    if (observations.isEmpty || regularPrice <= 0) {
      return SaleEstimation.insufficient();
    }

    // Sort observations chronologically
    final sorted = List<PriceObservation>.from(observations)
      ..sort((a, b) => a.recordedAt.compareTo(b.recordedAt));

    // Identify start of each discount event
    final List<PriceObservation> discountEvents = [];
    bool inDiscountPeriod = false;

    for (final obs in sorted) {
      final isDiscounted = obs.price < (regularPrice - 0.01);
      if (isDiscounted && !inDiscountPeriod) {
        discountEvents.add(obs);
        inDiscountPeriod = true;
      } else if (!isDiscounted) {
        inDiscountPeriod = false;
      }
    }

    // Rule: Must have at least 3 distinct discount cycles
    if (discountEvents.length < 3) {
      return SaleEstimation.insufficient();
    }

    // Compute intervals in days between consecutive discount starts
    final List<int> intervals = [];
    double totalDiscountPrices = 0;

    for (int i = 1; i < discountEvents.length; i++) {
      final diffDays = discountEvents[i].recordedAt.difference(discountEvents[i - 1].recordedAt).inDays;
      if (diffDays > 0) {
        intervals.add(diffDays);
      }
    }

    for (final event in discountEvents) {
      totalDiscountPrices += event.price;
    }
    final avgDiscountPrice = totalDiscountPrices / discountEvents.length;

    if (intervals.length < 2) {
      return SaleEstimation.insufficient();
    }

    // Compute Mean and Standard Deviation
    final double mean = intervals.reduce((a, b) => a + b) / intervals.length;
    double varianceSum = 0;
    for (final days in intervals) {
      varianceSum += pow(days - mean, 2);
    }
    final double stdDev = sqrt(varianceSum / intervals.length);
    final double cv = mean > 0 ? (stdDev / mean) : 1.0;

    // Determine confidence
    EstimationConfidence confidence;
    if (cv < 0.25) {
      confidence = EstimationConfidence.high;
    } else if (cv <= 0.50) {
      confidence = EstimationConfidence.medium;
    } else {
      confidence = EstimationConfidence.low;
    }

    final lastEventDate = discountEvents.last.recordedAt;
    final estimatedDate = lastEventDate.add(Duration(days: mean.round()));
    final windowMargin = max(7, (stdDev * 0.75).round());

    final windowStart = estimatedDate.subtract(Duration(days: windowMargin));
    final windowEnd = estimatedDate.add(Duration(days: windowMargin));

    const months = [
      'enero', 'febrero', 'marzo', 'abril', 'mayo', 'junio',
      'julio', 'agosto', 'septiembre', 'octubre', 'noviembre', 'diciembre'
    ];

    final String windowText;
    final now = DateTime.now();
    if (windowEnd.isBefore(now)) {
      return SaleEstimation(
        hasEnoughData: false,
        reason: 'El patrón observado proyectaba una ventana que ya pasó. Hace falta un historial más reciente para estimar otra rebaja.',
        historicalCyclesCount: discountEvents.length,
      );
    } else {
      final startStr = '${windowStart.day} de ${months[windowStart.month - 1]}';
      final endStr = '${windowEnd.day} de ${months[windowEnd.month - 1]}';
      windowText = 'Aproximadamente entre el $startStr y el $endStr';
    }

    final reason =
        'Basado en ${discountEvents.length} rebajas previas con intervalo medio de ${mean.round()} días (variabilidad ±${stdDev.round()} días). Estimación estadística no garantizada.';

    return SaleEstimation(
      hasEnoughData: true,
      estimatedWindow: windowText,
      confidence: confidence,
      reason: reason,
      historicalCyclesCount: discountEvents.length,
      estimatedPrice: avgDiscountPrice,
    );
  }
}
