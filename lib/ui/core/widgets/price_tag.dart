import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/currency_formatter.dart';

class PriceTag extends StatelessWidget {
  final double currentPrice;
  final double regularPrice;
  final int discountPercent;
  final bool isLowestHistorical;
  final bool showAtlBadge;
  final bool compact;
  const PriceTag(
      {super.key,
      required this.currentPrice,
      required this.regularPrice,
      required this.discountPercent,
      this.isLowestHistorical = false,
      this.showAtlBadge = true,
      this.compact = false});
  @override
  Widget build(BuildContext context) {
    final hasDiscount = discountPercent > 0 && currentPrice < regularPrice;
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      if (hasDiscount || (showAtlBadge && isLowestHistorical)) ...[
        Wrap(spacing: 4, runSpacing: 4, children: [
          if (hasDiscount)
            Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                    gradient: const LinearGradient(
                        colors: [AppTheme.primary, Color(0xFF5145FF)]),
                    borderRadius: BorderRadius.circular(6)),
                child: Text(CurrencyFormatter.formatDiscount(discountPercent),
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.w800))),
          if (showAtlBadge && isLowestHistorical)
            Container(
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                decoration: BoxDecoration(
                    color: AppTheme.hotDeal.withAlpha(25),
                    borderRadius: BorderRadius.circular(6)),
                child: const Text('MÍNIMO HISTÓRICO',
                    style: TextStyle(
                        color: AppTheme.hotDeal,
                        fontSize: 9,
                        fontWeight: FontWeight.w800))),
        ]),
        const SizedBox(height: 4),
      ],
      Wrap(
          spacing: 6,
          runSpacing: 2,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Text(CurrencyFormatter.formatUsd(currentPrice),
                style: TextStyle(
                    color: AppTheme.textPrimary,
                    fontSize: compact ? 20 : 24,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -.6)),
            if (hasDiscount)
              Text(CurrencyFormatter.formatUsd(regularPrice),
                  style: const TextStyle(
                      color: AppTheme.textSecondary,
                      fontSize: 11,
                      decoration: TextDecoration.lineThrough)),
          ]),
    ]);
  }
}
