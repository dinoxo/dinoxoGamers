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
    double? currentPrice,
    double? providerReportedLowest,
    GamePlatform? platform,
    String? gameTitle,
    DateTime? promoEndDate,
    bool allowMarketProjection = false,
  }) {
    if (regularPrice <= 0) {
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

    // If fewer than 3 distinct discount cycles, use algorithmic market projection if allowed
    if (discountEvents.length < 3) {
      if (!allowMarketProjection) {
        return SaleEstimation.insufficient();
      }
      return _calculateMarketProjection(
        regularPrice: regularPrice,
        currentPrice: currentPrice,
        providerReportedLowest: providerReportedLowest,
        platform: platform,
        promoEndDate: promoEndDate,
      );
    }

    // Compute intervals in days between consecutive discount starts
    final List<int> intervals = [];
    double totalDiscountPrices = 0;

    for (int i = 1; i < discountEvents.length; i++) {
      final diffDays = discountEvents[i]
          .recordedAt
          .difference(discountEvents[i - 1].recordedAt)
          .inDays;
      if (diffDays > 0) {
        intervals.add(diffDays);
      }
    }

    for (final event in discountEvents) {
      totalDiscountPrices += event.price;
    }
    final avgDiscountPrice = totalDiscountPrices / discountEvents.length;
    final discountPercent = regularPrice > 0
        ? ((regularPrice - avgDiscountPrice) / regularPrice * 100).round()
        : 0;

    if (intervals.length < 2) {
      if (!allowMarketProjection) return SaleEstimation.insufficient();
      return _calculateMarketProjection(
        regularPrice: regularPrice,
        currentPrice: currentPrice,
        providerReportedLowest: providerReportedLowest,
        platform: platform,
        promoEndDate: promoEndDate,
      );
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
    var estimatedDate = lastEventDate.add(Duration(days: mean.round()));
    final windowMargin = max(7, (stdDev * 0.75).round());

    var windowStart = estimatedDate.subtract(Duration(days: windowMargin));
    var windowEnd = estimatedDate.add(Duration(days: windowMargin));

    const months = [
      'enero', 'febrero', 'marzo', 'abril', 'mayo', 'junio',
      'julio', 'agosto', 'septiembre', 'octubre', 'noviembre', 'diciembre'
    ];

    final now = DateTime.now();
    if (windowEnd.isBefore(now)) {
      if (!allowMarketProjection) {
        return SaleEstimation(
          hasEnoughData: false,
          reason:
              'El patrón observado proyectaba una ventana que ya pasó. Hace falta un historial más reciente para estimar otra rebaja.',
          historicalCyclesCount: discountEvents.length,
        );
      }
      // Project forward to next cyclical window
      while (windowEnd.isBefore(now)) {
        windowStart = windowStart.add(Duration(days: max(20, mean.round())));
        windowEnd = windowEnd.add(Duration(days: max(20, mean.round())));
      }
    }

    final startStr = '${windowStart.day} de ${months[windowStart.month - 1]}';
    final endStr = '${windowEnd.day} de ${months[windowEnd.month - 1]}';
    final windowText = 'Aproximadamente entre el $startStr y el $endStr';

    final reason =
        'Basado en ${discountEvents.length} rebajas previas con intervalo medio de ${mean.round()} días (variabilidad ±${stdDev.round()} días) hacia un precio proyectado de \$${avgDiscountPrice.toStringAsFixed(2)} USD (-$discountPercent%).';

    return SaleEstimation(
      hasEnoughData: true,
      estimatedWindow: windowText,
      confidence: confidence,
      reason: reason,
      historicalCyclesCount: discountEvents.length,
      estimatedPrice: avgDiscountPrice,
      estimatedDiscountPercent: discountPercent,
    );
  }

  static SaleEstimation _calculateMarketProjection({
    required double regularPrice,
    double? currentPrice,
    double? providerReportedLowest,
    GamePlatform? platform,
    DateTime? promoEndDate,
  }) {
    // 1. Determine projected target price
    double projectedPrice;
    if (providerReportedLowest != null && providerReportedLowest > 0) {
      projectedPrice = providerReportedLowest;
    } else if (currentPrice != null && currentPrice < regularPrice) {
      projectedPrice = currentPrice;
    } else {
      if (platform == GamePlatform.nintendo) {
        projectedPrice = (regularPrice * 0.70 * 100).round() / 100;
      } else {
        projectedPrice = (regularPrice * 0.50 * 100).round() / 100;
      }
    }

    final discountPercent = regularPrice > 0
        ? ((regularPrice - projectedPrice) / regularPrice * 100).round()
        : 0;

    // 2. Predict seasonal campaign and window
    final now = DateTime.now();
    DateTime windowStart;
    DateTime windowEnd;
    String campaignName;

    if (promoEndDate != null && promoEndDate.isAfter(now)) {
      windowStart = promoEndDate.add(const Duration(days: 35));
      windowEnd = promoEndDate.add(const Duration(days: 55));
      campaignName = 'Próximo Ciclo Promocional';
    } else {
      final month = now.month;
      final year = now.year;
      if (month <= 2) {
        windowStart = DateTime(year, 3, 10);
        windowEnd = DateTime(year, 3, 28);
        campaignName = 'Ofertas de Primavera / MAR10 Day';
      } else if (month <= 4) {
        windowStart = DateTime(year, 4, 25);
        windowEnd = DateTime(year, 5, 12);
        campaignName = 'Ventas de Primavera / Golden Week';
      } else if (month <= 6) {
        windowStart = DateTime(year, 6, 12);
        windowEnd = DateTime(year, 7, 5);
        campaignName = 'Rebajas de Verano / Days of Play';
      } else if (month <= 8) {
        windowStart = DateTime(year, 8, 25);
        windowEnd = DateTime(year, 9, 15);
        campaignName = 'Ofertas de Regreso / Fin de Verano';
      } else if (month <= 10) {
        windowStart = DateTime(year, 11, 18);
        windowEnd = DateTime(year, 11, 30);
        campaignName = 'Black Friday & Cyber Deals';
      } else {
        windowStart = DateTime(year, 12, 16);
        windowEnd = DateTime(year + 1, 1, 6);
        campaignName = 'Ofertas de Fin de Año y Navidad';
      }
    }

    const months = [
      'enero', 'febrero', 'marzo', 'abril', 'mayo', 'junio',
      'julio', 'agosto', 'septiembre', 'octubre', 'noviembre', 'diciembre'
    ];

    final startStr = '${windowStart.day} de ${months[windowStart.month - 1]}';
    final endStr = '${windowEnd.day} de ${months[windowEnd.month - 1]}';
    final windowText = 'Aproximadamente entre el $startStr y el $endStr';

    final platformName = platform != null
        ? AppConstants.platformDisplayName(platform)
        : 'tiendas oficiales';

    final reason =
        'Análisis predictivo de Dinoxo Gamers: Proyecta que este título bajará a \$${projectedPrice.toStringAsFixed(2)} USD (-$discountPercent%) durante la campaña $campaignName en $platformName, considerando su mínimo histórico de referencia y el ciclo comercial del catálogo.';

    return SaleEstimation(
      hasEnoughData: true,
      estimatedWindow: windowText,
      confidence: providerReportedLowest != null
          ? EstimationConfidence.medium
          : EstimationConfidence.low,
      reason: reason,
      historicalCyclesCount: 0,
      estimatedPrice: projectedPrice,
      estimatedDiscountPercent: discountPercent,
      campaignName: campaignName,
      isAlgorithmicProjection: true,
    );
  }
}
