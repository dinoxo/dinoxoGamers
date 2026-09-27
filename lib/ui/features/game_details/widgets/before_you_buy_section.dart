import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../domain/models/before_you_buy.dart';
import '../../../../domain/services/whatsapp_service.dart';

class BeforeYouBuySection extends StatelessWidget {
  final BeforeYouBuyData data;

  const BeforeYouBuySection({
    super.key,
    required this.data,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Title
        const Row(
          children: [
            Icon(Icons.fact_check_outlined, color: AppTheme.secondary, size: 20),
            SizedBox(width: 8),
            Text(
              'Antes de Comprar',
              style: TextStyle(
                color: AppTheme.textPrimary,
                fontSize: 17,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        const Text(
          'Dossier técnico y análisis neutral para evaluar si este juego encaja contigo.',
          style: TextStyle(color: AppTheme.textSecondary, fontSize: 12),
        ),
        const SizedBox(height: 14),

        // Scores (Critic vs User)
        Row(
          children: [
            if (data.criticScore != null)
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceElevated,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppTheme.border),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Crítica',
                            style: TextStyle(color: AppTheme.textMuted, fontSize: 11),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppTheme.success,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              '${data.criticScore}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 13,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        data.criticScoreSource,
                        style: const TextStyle(color: AppTheme.textSecondary, fontSize: 10),
                      ),
                    ],
                  ),
                ),
              ),
            const SizedBox(width: 10),
            if (data.userScore != null)
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceElevated,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppTheme.border),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Comunidad',
                            style: TextStyle(color: AppTheme.textMuted, fontSize: 11),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppTheme.primary,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              '${data.userScore}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 13,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${data.userReviewCount ?? 'Múltiples'} opiniones registradas',
                        style: const TextStyle(color: AppTheme.textSecondary, fontSize: 10),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 14),

        // Pros & Cons
        if (data.pros.isNotEmpty || data.cons.isNotEmpty) ...[
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppTheme.surfaceElevated,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppTheme.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (data.pros.isNotEmpty) ...[
                  const Row(
                    children: [
                      Icon(Icons.thumb_up_alt_outlined, size: 14, color: AppTheme.success),
                      SizedBox(width: 6),
                      Text(
                        'Puntos Fuertes',
                        style: TextStyle(
                          color: AppTheme.success,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  ...data.pros.map(
                    (pro) => Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('• ', style: TextStyle(color: AppTheme.success)),
                          Expanded(
                            child: Text(
                              pro,
                              style: const TextStyle(color: AppTheme.textPrimary, fontSize: 11, height: 1.3),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                ],
                if (data.cons.isNotEmpty) ...[
                  const Row(
                    children: [
                      Icon(Icons.thumb_down_alt_outlined, size: 14, color: AppTheme.warning),
                      SizedBox(width: 6),
                      Text(
                        'Puntos a Considerar',
                        style: TextStyle(
                          color: AppTheme.warning,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  ...data.cons.map(
                    (con) => Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('• ', style: TextStyle(color: AppTheme.warning)),
                          Expanded(
                            child: Text(
                              con,
                              style: const TextStyle(color: AppTheme.textPrimary, fontSize: 11, height: 1.3),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 14),
        ],

        // Performance & Console specifics
        if (data.consolePerformance.isNotEmpty) ...[
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppTheme.surfaceElevated,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppTheme.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.speed, size: 14, color: AppTheme.secondary),
                    SizedBox(width: 6),
                    Text(
                      'Rendimiento Técnico Documentado',
                      style: TextStyle(
                        color: AppTheme.textPrimary,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ...data.consolePerformance.entries.map(
                  (entry) => Padding(
                    padding: const EdgeInsets.only(bottom: 5),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          entry.key,
                          style: const TextStyle(
                            color: AppTheme.primaryLight,
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        Text(
                          entry.value,
                          style: const TextStyle(color: AppTheme.textSecondary, fontSize: 11),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
        ],

        // Playtime & Specs
        Row(
          children: [
            if (data.mainStoryHours != null)
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceElevated,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppTheme.border),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Historia Principal',
                        style: TextStyle(color: AppTheme.textMuted, fontSize: 10),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '~${data.mainStoryHours} horas',
                        style: const TextStyle(
                          color: AppTheme.textPrimary,
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      Text(
                        data.playtimeSource,
                        style: const TextStyle(color: AppTheme.textMuted, fontSize: 9),
                      ),
                    ],
                  ),
                ),
              ),
            const SizedBox(width: 10),
            if (data.completionistHours != null)
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceElevated,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppTheme.border),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        '100% Completista',
                        style: TextStyle(color: AppTheme.textMuted, fontSize: 10),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '~${data.completionistHours} horas',
                        style: const TextStyle(
                          color: AppTheme.textPrimary,
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      Text(
                        data.playtimeSource,
                        style: const TextStyle(color: AppTheme.textMuted, fontSize: 9),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 14),

        // Languages & Connectivity
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppTheme.surfaceElevated,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppTheme.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Idiomas de la Edición USA',
                style: TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                data.usLanguages.isNotEmpty
                    ? data.usLanguages.join('\n')
                    : 'Audio y textos en Inglés (consultar paquete adicional)',
                style: const TextStyle(color: AppTheme.textSecondary, fontSize: 11, height: 1.3),
              ),
              if (data.subscriptionRequirement != null) ...[
                const SizedBox(height: 10),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.info_outline, size: 14, color: AppTheme.warning),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        data.subscriptionRequirement!,
                        style: const TextStyle(
                          color: AppTheme.warning,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 14),

        // Trailer / Gameplay buttons
        if (data.trailerUrl != null || data.gameplayUrl != null)
          Row(
            children: [
              if (data.trailerUrl != null)
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => WhatsAppService.launchExternalUrl(data.trailerUrl!),
                    icon: const Icon(Icons.play_circle_outline, size: 16),
                    label: const Text('Ver Tráiler', style: TextStyle(fontSize: 12)),
                  ),
                ),
              if (data.trailerUrl != null && data.gameplayUrl != null) const SizedBox(width: 10),
              if (data.gameplayUrl != null)
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => WhatsAppService.launchExternalUrl(data.gameplayUrl!),
                    icon: const Icon(Icons.videocam_outlined, size: 16),
                    label: const Text('Ver Gameplay', style: TextStyle(fontSize: 12)),
                  ),
                ),
            ],
          ),
      ],
    );
  }
}
