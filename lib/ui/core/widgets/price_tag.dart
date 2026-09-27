import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/currency_formatter.dart';

class PriceTag extends StatelessWidget {
  final double currentPrice;
  final double regularPrice;
  final int discountPercent;
  final bool isLowestHistorical;
  final bool showAtlBadge;

  const PriceTag({
    super.key,
    required this.currentPrice,
    required this.regularPrice,
    required this.discountPercent,
    this.isLowestHistorical = false,
    this.showAtlBadge = true,
  });

  @override
  Widget build(BuildContext context) {
    final hasDiscount = discountPercent > 0 && currentPrice < regularPrice;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (showAtlBadge && isLowestHistorical)
          Container(
            margin: const EdgeInsets.only(bottom: 4),
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: AppTheme.hotDeal.withAlpha(40),
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: AppTheme.hotDeal, width: 0.8),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.local_fire_department, size: 12, color: AppTheme.hotDeal),
                SizedBox(width: 2),
                Text(
                  'MÍNIMO HISTÓRICO',
                  style: TextStyle(
                    color: AppTheme.hotDeal,
                    fontSize: 9,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.3,
                  ),
                ),
              ],
            ),
          ),
        Row(
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Text(
              CurrencyFormatter.formatUsd(currentPrice),
              style: const TextStyle(
                color: AppTheme.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.w900,
                letterSpacing: -0.3,
              ),
            ),
            if (hasDiscount) ...[
              const SizedBox(width: 8),
              Text(
                CurrencyFormatter.formatUsd(regularPrice),
                style: const TextStyle(
                  color: AppTheme.textMuted,
                  fontSize: 12,
                  decoration: TextDecoration.lineThrough,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: AppTheme.success,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  CurrencyFormatter.formatDiscount(discountPercent),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }
}
