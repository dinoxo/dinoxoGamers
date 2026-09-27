import 'package:flutter/material.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../domain/models/sale_estimation.dart';

class SaleEstimationCard extends StatelessWidget {
  final SaleEstimation estimation;

  const SaleEstimationCard({
    super.key,
    required this.estimation,
  });

  @override
  Widget build(BuildContext context) {
    Color confidenceColor;
    switch (estimation.confidence) {
      case EstimationConfidence.high:
        confidenceColor = AppTheme.success;
        break;
      case EstimationConfidence.medium:
        confidenceColor = AppTheme.warning;
        break;
      case EstimationConfidence.low:
        confidenceColor = AppTheme.textMuted;
        break;
    }

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.surfaceElevated,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: estimation.hasEnoughData ? AppTheme.primary.withAlpha(80) : AppTheme.border,
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.auto_awesome, size: 16, color: AppTheme.secondary),
              const SizedBox(width: 6),
              const Text(
                'Estimación de Próxima Rebaja',
                style: TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const Spacer(),
              if (estimation.hasEnoughData)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                  decoration: BoxDecoration(
                    color: confidenceColor.withAlpha(30),
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: confidenceColor, width: 0.8),
                  ),
                  child: Text(
                    'Confianza ${estimation.confidenceDisplay}',
                    style: TextStyle(
                      color: confidenceColor,
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                )
              else
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceSubtle,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Text(
                    'Historial insuficiente',
                    style: TextStyle(
                      color: AppTheme.textMuted,
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 10),
          if (estimation.hasEnoughData) ...[
            Text(
              estimation.estimatedWindow ?? 'Ventana no disponible',
              style: const TextStyle(
                color: AppTheme.secondary,
                fontSize: 14,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              estimation.reason,
              style: const TextStyle(
                color: AppTheme.textSecondary,
                fontSize: 12,
                height: 1.35,
              ),
            ),
            const SizedBox(height: 8),
            const Row(
              children: [
                Icon(Icons.info_outline, size: 12, color: AppTheme.textMuted),
                SizedBox(width: 4),
                Expanded(
                  child: Text(
                    'Estimación estadística basada en historial previo. No garantiza fechas ni precios futuros.',
                    style: TextStyle(
                      color: AppTheme.textMuted,
                      fontSize: 10,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),
              ],
            ),
          ] else ...[
            Text(
              estimation.reason,
              style: const TextStyle(
                color: AppTheme.textSecondary,
                fontSize: 12,
                height: 1.35,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
