import 'dart:math';
import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../../../domain/models/price_observation.dart';

class PriceHistoryChart extends StatefulWidget {
  final List<PriceObservation> observations;
  final double regularPrice;
  final double lowestObservedPrice;
  final double? providerReportedLowest;

  const PriceHistoryChart({
    super.key,
    required this.observations,
    required this.regularPrice,
    required this.lowestObservedPrice,
    this.providerReportedLowest,
  });

  @override
  State<PriceHistoryChart> createState() => _PriceHistoryChartState();
}

class _PriceHistoryChartState extends State<PriceHistoryChart> {
  int? _selectedPointIndex;

  @override
  Widget build(BuildContext context) {
    if (widget.observations.isEmpty) {
      return Container(
        height: 160,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: AppTheme.surfaceElevated,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppTheme.border),
        ),
        child: const Text(
          'Sin observaciones históricas suficientes.',
          style: TextStyle(color: AppTheme.textMuted, fontSize: 12),
        ),
      );
    }

    final sorted = List<PriceObservation>.from(widget.observations)
      ..sort((a, b) => a.recordedAt.compareTo(b.recordedAt));

    final firstDate = sorted.first.recordedAt;
    final lastDate = sorted.last.recordedAt;
    final totalDays = lastDate.difference(firstDate).inDays;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header with legend and coverage
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: AppTheme.primaryLight,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 5),
                const Text(
                  'Historial de Precio (USD)',
                  style: TextStyle(
                    color: AppTheme.textPrimary,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
            Text(
              'Cobertura: ${totalDays > 0 ? '$totalDays días' : 'Reciente'}',
              style: const TextStyle(
                color: AppTheme.textMuted,
                fontSize: 11,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),

        // Selected point preview
        if (_selectedPointIndex != null && _selectedPointIndex! < sorted.length) ...[
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            margin: const EdgeInsets.only(bottom: 8),
            decoration: BoxDecoration(
              color: AppTheme.surfaceSubtle,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: AppTheme.border),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  DateFormatter.formatShortDate(sorted[_selectedPointIndex!].recordedAt),
                  style: const TextStyle(color: AppTheme.textSecondary, fontSize: 11),
                ),
                Text(
                  CurrencyFormatter.formatUsd(sorted[_selectedPointIndex!].price),
                  style: const TextStyle(
                    color: AppTheme.success,
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
        ],

        // Canvas Chart
        Container(
          height: 180,
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppTheme.surfaceElevated,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppTheme.border),
          ),
          child: LayoutBuilder(
            builder: (context, constraints) {
              return GestureDetector(
                onTapDown: (details) {
                  final xRatio = details.localPosition.dx / constraints.maxWidth;
                  final index = (xRatio * (sorted.length - 1)).round().clamp(0, sorted.length - 1);
                  setState(() {
                    _selectedPointIndex = index;
                  });
                },
                child: CustomPaint(
                  size: Size(constraints.maxWidth, constraints.maxHeight),
                  painter: _PriceChartPainter(
                    observations: sorted,
                    regularPrice: widget.regularPrice,
                    lowestObserved: widget.lowestObservedPrice,
                    selectedIndex: _selectedPointIndex,
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 8),

        // Minimum Comparison Footer
        Row(
          children: [
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppTheme.surface,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppTheme.border),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Mínimo registrado',
                      style: TextStyle(color: AppTheme.textMuted, fontSize: 10),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      CurrencyFormatter.formatUsd(widget.lowestObservedPrice),
                      style: const TextStyle(
                        color: AppTheme.hotDeal,
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 8),
            if (widget.providerReportedLowest != null)
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppTheme.surface,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppTheme.border),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Mínimo de proveedor',
                        style: TextStyle(color: AppTheme.textMuted, fontSize: 10),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        CurrencyFormatter.formatUsd(widget.providerReportedLowest!),
                        style: const TextStyle(
                          color: AppTheme.secondary,
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }
}

class _PriceChartPainter extends CustomPainter {
  final List<PriceObservation> observations;
  final double regularPrice;
  final double lowestObserved;
  final int? selectedIndex;

  _PriceChartPainter({
    required this.observations,
    required this.regularPrice,
    required this.lowestObserved,
    this.selectedIndex,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (observations.length < 2) return;

    final prices = observations.map((e) => e.price).toList()..add(regularPrice);
    final minPrice = max(0.0, prices.reduce(min) * 0.85);
    final maxPrice = prices.reduce(max) * 1.05;
    final priceRange = (maxPrice - minPrice) > 0 ? (maxPrice - minPrice) : 1.0;

    final gridPaint = Paint()
      ..color = AppTheme.border.withAlpha(80)
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;

    // Draw horizontal grid lines (min, middle, max)
    canvas.drawLine(const Offset(0, 0), Offset(size.width, 0), gridPaint);
    canvas.drawLine(Offset(0, size.height / 2), Offset(size.width, size.height / 2), gridPaint);
    canvas.drawLine(Offset(0, size.height), Offset(size.width, size.height), gridPaint);

    // Build chart points
    final points = <Offset>[];
    for (int i = 0; i < observations.length; i++) {
      final x = (i / (observations.length - 1)) * size.width;
      final y = size.height - ((observations[i].price - minPrice) / priceRange) * size.height;
      points.add(Offset(x, y.clamp(5.0, size.height - 5.0)));
    }

    // Draw connecting gradient line
    final linePaint = Paint()
      ..color = AppTheme.primaryLight
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final path = Path()..moveTo(points.first.dx, points.first.dy);
    for (int i = 1; i < points.length; i++) {
      path.lineTo(points[i].dx, points[i].dy);
    }
    canvas.drawPath(path, linePaint);

    // Draw points & markers
    for (int i = 0; i < points.length; i++) {
      final pt = points[i];
      final isAtl = (observations[i].price - lowestObserved).abs() < 0.05;
      final isSelected = selectedIndex == i;

      final pointPaint = Paint()
        ..color = isSelected
            ? Colors.white
            : (isAtl ? AppTheme.hotDeal : AppTheme.primaryLight)
        ..style = PaintingStyle.fill;

      canvas.drawCircle(pt, isSelected ? 5.5 : (isAtl ? 4.5 : 3.0), pointPaint);

      if (isAtl) {
        final haloPaint = Paint()
          ..color = AppTheme.hotDeal.withAlpha(70)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3;
        canvas.drawCircle(pt, 7.0, haloPaint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _PriceChartPainter oldDelegate) {
    return oldDelegate.selectedIndex != selectedIndex ||
        oldDelegate.observations != observations;
  }
}
