import 'package:flutter/material.dart';
import '../../../../domain/models/game.dart';
import '../../../../domain/services/whatsapp_service.dart';
import '../../../../core/utils/date_formatter.dart';

import '../../../../core/theme/app_theme.dart';

class LiveReviewSection extends StatelessWidget {
  final Game game;
  const LiveReviewSection({super.key, required this.game});

  Color _getVerdictColor(double? score) {
    if (score == null) return AppTheme.textMuted;
    if (score >= 85) return const Color(0xFF00CE7A); // Vibrant green
    if (score >= 75) return AppTheme.success; // Good green
    if (score >= 65) return AppTheme.warning; // Amber
    if (score >= 50) return Colors.orange;
    return AppTheme.danger; // Red
  }

  IconData _getVerdictIcon(double? score) {
    if (score == null) return Icons.help_outline_rounded;
    if (score >= 85) return Icons.stars_rounded;
    if (score >= 75) return Icons.thumb_up_alt_rounded;
    if (score >= 65) return Icons.savings_outlined;
    if (score >= 50) return Icons.flaky_rounded;
    return Icons.thumb_down_alt_rounded;
  }

  @override
  Widget build(BuildContext context) {
    final review = game.review;
    final primaryScore = review?.primaryScore;
    final verdictColor = _getVerdictColor(primaryScore);
    final verdictIcon = _getVerdictIcon(primaryScore);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.analytics_outlined,
                    color: AppTheme.primaryLight, size: 20),
                const SizedBox(width: 8),
                Expanded(
                    child: Text(
                  'Antes de comprar · ¿Vale la pena?',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                )),
              ],
            ),
            const SizedBox(height: 12),

            // Prominent Verdict Box
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: verdictColor.withAlpha(25),
                borderRadius: BorderRadius.circular(10),
                border:
                    Border.all(color: verdictColor.withAlpha(120), width: 1.2),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(verdictIcon, color: verdictColor, size: 22),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          review?.verdictBadgeLabel ??
                              'Sin puntuaciones verificables',
                          style: TextStyle(
                            color: verdictColor,
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      if (primaryScore != null)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: verdictColor,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            '${primaryScore.toStringAsFixed(0)}/100',
                            style: const TextStyle(
                              color: Colors.black,
                              fontWeight: FontWeight.w900,
                              fontSize: 12,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    review?.verdictExplanation ??
                        'No hay reseñas verificables disponibles de Metacritic u OpenCritic para este título en la base de datos.',
                    style: const TextStyle(
                      color: AppTheme.textPrimary,
                      fontSize: 12,
                      height: 1.35,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // Scores Breakdown Chips
            if (review != null &&
                (review.criticScore != null ||
                    review.userScore != null ||
                    review.openCriticScore != null)) ...[
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  if (review.criticScore != null)
                    _buildScoreChip(
                      label: 'Metascore',
                      value: '${review.criticScore!.toStringAsFixed(0)}/100',
                      color: _getVerdictColor(review.criticScore),
                    ),
                  if (review.userScore != null)
                    _buildScoreChip(
                      label: 'Usuarios Metacritic',
                      value: '${review.userScore!.toStringAsFixed(1)}/10',
                      color: _getVerdictColor(review.userScore! * 10),
                    ),
                  if (review.openCriticScore != null)
                    _buildScoreChip(
                      label: 'OpenCritic',
                      value:
                          '${review.openCriticScore!.toStringAsFixed(0)}/100',
                      color: _getVerdictColor(review.openCriticScore),
                    ),
                ],
              ),
              const SizedBox(height: 10),
            ],

            if (review != null)
              Text(
                'Puntuaciones recopiladas · ${DateFormatter.formatRelativeTime(review.checkedAt)}',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppTheme.textMuted,
                      fontSize: 11,
                    ),
              ),
            const SizedBox(height: 8),

            // Action / Reference Links
            Wrap(
              spacing: 8,
              children: [
                if (review?.metacriticUrl != null)
                  TextButton.icon(
                    icon: const Icon(Icons.open_in_new, size: 14),
                    onPressed: () => WhatsAppService.launchExternalUrl(
                        review!.metacriticUrl!),
                    label: const Text('Metacritic'),
                  ),
                if (review?.openCriticUrl != null)
                  TextButton.icon(
                    icon: const Icon(Icons.open_in_new, size: 14),
                    onPressed: () => WhatsAppService.launchExternalUrl(
                        review!.openCriticUrl!),
                    label: const Text('OpenCritic'),
                  ),
                TextButton.icon(
                  icon: const Icon(Icons.forum_outlined, size: 14),
                  onPressed: () => WhatsAppService.launchExternalUrl(
                    Uri.https('www.reddit.com', '/search/', {
                      'q': '${game.title} ${game.consoles.join(' ')} review'
                    }).toString(),
                  ),
                  label: const Text('Opiniones en Reddit'),
                ),
                if (review != null)
                  TextButton.icon(
                    icon: const Icon(Icons.link, size: 14),
                    onPressed: () =>
                        WhatsAppService.launchExternalUrl(review.sourceUrl),
                    label: const Text('Ver fuente'),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildScoreChip({
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppTheme.surfaceElevated,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppTheme.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '$label: ',
            style: const TextStyle(
              color: AppTheme.textSecondary,
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
