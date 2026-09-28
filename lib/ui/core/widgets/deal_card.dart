import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../domain/models/game.dart';
import '../../../domain/services/subscription_service.dart';
import 'platform_badge.dart';
import 'price_tag.dart';
import 'usa_badge.dart';

class DealCard extends StatelessWidget {
  final Game game;
  final bool isFavorite;
  final VoidCallback onTap;
  final VoidCallback onToggleFavorite;

  const DealCard({
    super.key,
    required this.game,
    this.isFavorite = false,
    required this.onTap,
    required this.onToggleFavorite,
  });

  @override
  Widget build(BuildContext context) {
    final edition = game.primaryEdition;
    final promoEnd = edition?.promoEndDate;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Cover Image
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Container(
                  width: 95,
                  height: 125,
                  color: AppTheme.surfaceElevated,
                  child: Image.network(
                    game.coverUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        color: AppTheme.surfaceElevated,
                        child: const Center(
                          child: Icon(Icons.sports_esports,
                              color: AppTheme.textMuted, size: 36),
                        ),
                      );
                    },
                  ),
                ),
              ),
              const SizedBox(width: 12),

              // Game Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Top Platform & USA Badges
                    Row(
                      children: [
                        PlatformBadge(platform: game.platform, compact: true),
                        const SizedBox(width: 6),
                        const UsaBadge(compact: true),
                        const Spacer(),
                        IconButton(
                          icon: Icon(
                            isFavorite ? Icons.favorite : Icons.favorite_border,
                            color: isFavorite
                                ? AppTheme.danger
                                : AppTheme.textMuted,
                            size: 20,
                          ),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                          onPressed: onToggleFavorite,
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),

                    // Game Title
                    Text(
                      game.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppTheme.textPrimary,
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        height: 1.2,
                      ),
                    ),
                    const SizedBox(height: 3),

                    // Edition & Consoles
                    Text(
                      game.consoles.join(' / '),
                      style: const TextStyle(
                        color: AppTheme.textSecondary,
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 6),

                    // Subscription recommendation / status
                    Builder(builder: (context) {
                      final subMatch = SubscriptionService.instance
                          .checkGame(game.title, platform: game.platform);
                      if (subMatch == null) return const SizedBox.shrink();

                      Color chipColor;
                      IconData chipIcon;
                      String chipText;

                      if (subMatch.isLeavingSoon) {
                        chipColor = AppTheme.warning;
                        chipIcon = Icons.hourglass_bottom_rounded;
                        chipText = 'Sale pronto de ${subMatch.item.shortBadgeLabel}';
                      } else if (subMatch.isComingSoon) {
                        chipColor = const Color(0xFF00C3FF);
                        chipIcon = Icons.upcoming_rounded;
                        chipText = 'Pronto en ${subMatch.item.shortBadgeLabel}';
                      } else {
                        chipColor = AppTheme.success;
                        chipIcon = Icons.card_membership_rounded;
                        chipText = 'En ${subMatch.item.shortBadgeLabel} · No compres';
                      }

                      return Container(
                        margin: const EdgeInsets.only(bottom: 6),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 3),
                        decoration: BoxDecoration(
                          color: chipColor.withAlpha(25),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                              color: chipColor.withAlpha(100), width: 0.9),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(chipIcon, size: 12, color: chipColor),
                            const SizedBox(width: 4),
                            Flexible(
                              child: Text(
                                chipText,
                                style: TextStyle(
                                  color: chipColor,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      );
                    }),

                    // Promo Ending notice
                    if (promoEnd != null) ...[
                      Row(
                        children: [
                          const Icon(Icons.schedule,
                              size: 12, color: AppTheme.warning),
                          const SizedBox(width: 4),
                          Text(
                            DateFormatter.formatPromoEndDate(promoEnd),
                            style: const TextStyle(
                              color: AppTheme.warning,
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                    ],

                    // Price Tag
                    if (edition == null)
                      const Text('Sin precio USA disponible',
                          style: TextStyle(color: AppTheme.textMuted)),
                    if (edition != null)
                      PriceTag(
                        currentPrice: edition.currentPrice,
                        regularPrice: edition.regularPrice,
                        discountPercent: edition.discountPercent,
                        isLowestHistorical: edition.isLowestHistorical,
                      ),
                    if (edition != null)
                      Text(
                          'Consultado ${DateFormatter.formatRelativeTime(edition.lastChecked)} · Deku Deals',
                          style: const TextStyle(
                              color: AppTheme.textMuted, fontSize: 10)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
