import '../../core/constants/app_constants.dart';

class SaleEstimation {
  final bool hasEnoughData;
  final String? estimatedWindow;
  final EstimationConfidence confidence;
  final String reason;
  final int historicalCyclesCount;
  final double? estimatedPrice;
  final int? estimatedDiscountPercent;
  final String? campaignName;
  final bool isAlgorithmicProjection;

  const SaleEstimation({
    required this.hasEnoughData,
    this.estimatedWindow,
    this.confidence = EstimationConfidence.low,
    required this.reason,
    required this.historicalCyclesCount,
    this.estimatedPrice,
    this.estimatedDiscountPercent,
    this.campaignName,
    this.isAlgorithmicProjection = false,
  });

  static SaleEstimation insufficient() {
    return const SaleEstimation(
      hasEnoughData: false,
      reason: 'Historial insuficiente para calcular un patrón estadístico confiable de rebajas.',
      historicalCyclesCount: 0,
    );
  }

  String get confidenceDisplay {
    if (isAlgorithmicProjection) {
      return confidence == EstimationConfidence.medium
          ? 'Predictiva Media'
          : 'Proyección de Mercado';
    }
    switch (confidence) {
      case EstimationConfidence.low:
        return 'Baja';
      case EstimationConfidence.medium:
        return 'Media';
      case EstimationConfidence.high:
        return 'Alta';
    }
  }
}
