import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../domain/models/game.dart';
import '../../../domain/services/subscription_service.dart';
import 'game_card_frame.dart';
import 'platform_badge.dart';
import 'price_tag.dart';
import 'usa_badge.dart';

class DealCard extends StatelessWidget {
  final Game game;
  final bool isFavorite;
  final VoidCallback onTap;
  final VoidCallback onToggleFavorite;
  const DealCard(
      {super.key,
      required this.game,
      this.isFavorite = false,
      required this.onTap,
      required this.onToggleFavorite});

  @override
  Widget build(BuildContext context) {
    final edition = game.primaryEdition;
    final promoEnd = edition?.promoEndDate;
    return GameCardFrame(
      platform: game.platform,
      coverUrl: game.coverUrl,
      onTap: onTap,
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Expanded(
              child: Wrap(spacing: 4, runSpacing: 4, children: [
            PlatformBadge(platform: game.platform, compact: true),
            const UsaBadge(compact: true),
          ])),
          IconButton(
              onPressed: onToggleFavorite,
              tooltip:
                  isFavorite ? 'Quitar de favoritos' : 'Añadir a favoritos',
              visualDensity: VisualDensity.compact,
              padding: EdgeInsets.zero,
              icon: Icon(
                  isFavorite
                      ? Icons.favorite_rounded
                      : Icons.favorite_border_rounded,
                  size: 20,
                  color:
                      isFavorite ? AppTheme.danger : AppTheme.textSecondary)),
        ]),
        const SizedBox(height: 4),
        Text(game.title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
                fontSize: 15, fontWeight: FontWeight.w800, height: 1.15)),
        const SizedBox(height: 3),
        Text(game.consoles.join(' / '),
            style:
                const TextStyle(fontSize: 11, color: AppTheme.textSecondary)),
        const SizedBox(height: 6),
        ListenableBuilder(
            listenable: SubscriptionService.instance,
            builder: (context, _) {
              final match = SubscriptionService.instance.checkGame(game.title,
                  platform: game.platform, consoles: game.consoles);
              if (match == null) return const SizedBox.shrink();
              final color = match.isLeavingSoon
                  ? AppTheme.warning
                  : match.isComingSoon
                      ? AppTheme.secondary
                      : AppTheme.success;
              final text = match.isLeavingSoon
                  ? 'Sale pronto de ${match.item.shortBadgeLabel}'
                  : match.isComingSoon
                      ? 'Pronto en ${match.item.shortBadgeLabel}'
                      : 'En ${match.item.shortBadgeLabel} · Revisa tu membresía';
              return Padding(
                  padding: const EdgeInsets.only(bottom: 5),
                  child: Text(text,
                      style: TextStyle(
                          color: color,
                          fontSize: 10,
                          fontWeight: FontWeight.w700)));
            }),
        if (promoEnd != null)
          Padding(
              padding: const EdgeInsets.only(bottom: 5),
              child: Text(DateFormatter.formatPromoEndDate(promoEnd),
                  style:
                      const TextStyle(color: AppTheme.warning, fontSize: 10))),
        Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
          Expanded(
              child: edition == null
                  ? const Text('Sin precio USA disponible',
                      style: TextStyle(color: AppTheme.textMuted, fontSize: 12))
                  : PriceTag(
                      currentPrice: edition.currentPrice,
                      regularPrice: edition.regularPrice,
                      discountPercent: edition.discountPercent,
                      isLowestHistorical: edition.isLowestHistorical,
                      compact: true)),
          const SizedBox(width: 4),
          GameCardArrow(platform: game.platform, onTap: onTap),
        ]),
        if (edition != null)
          Padding(
              padding: const EdgeInsets.only(top: 5),
              child: Text(
                  'Consultado ${DateFormatter.formatRelativeTime(edition.lastChecked)} · Deku Deals',
                  style:
                      const TextStyle(color: AppTheme.textMuted, fontSize: 9))),
      ]),
    );
  }
}
