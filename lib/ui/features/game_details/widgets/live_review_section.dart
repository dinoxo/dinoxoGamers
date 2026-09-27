import 'package:flutter/material.dart';
import '../../../../domain/models/game.dart';
import '../../../../domain/services/whatsapp_service.dart';
import '../../../../core/utils/date_formatter.dart';

class LiveReviewSection extends StatelessWidget {
  final Game game;
  const LiveReviewSection({super.key, required this.game});
  @override
  Widget build(BuildContext context) {
    final review = game.review;
    return Card(
        child: Padding(
            padding: const EdgeInsets.all(16),
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Antes de comprar',
                  style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              Text(review?.summary ??
                  'Aún no hay reseñas verificables disponibles.'),
              const SizedBox(height: 8),
              const Text(
                  'Resumen automático de puntuaciones; no sustituye leer los análisis. La ficha consultada no confirma la plataforma ni el número de reseñas de cada puntuación.'),
              if (review != null)
                Text(
                    'Puntuaciones publicadas por Deku Deals · ${DateFormatter.formatRelativeTime(review.checkedAt)}',
                    style: Theme.of(context).textTheme.bodySmall),
              Wrap(spacing: 8, children: [
                if (review?.metacriticUrl != null)
                  TextButton(
                      onPressed: () => WhatsAppService.launchExternalUrl(
                          review!.metacriticUrl!),
                      child: const Text('Metacritic')),
                if (review?.openCriticUrl != null)
                  TextButton(
                      onPressed: () => WhatsAppService.launchExternalUrl(
                          review!.openCriticUrl!),
                      child: const Text('OpenCritic')),
                TextButton(
                    onPressed: () => WhatsAppService.launchExternalUrl(
                            Uri.https('www.reddit.com', '/search/', {
                          'q': '${game.title} ${game.consoles.join(' ')} review'
                        }).toString()),
                    child: const Text('Buscar opiniones en Reddit')),
                if (review != null)
                  TextButton(
                      onPressed: () =>
                          WhatsAppService.launchExternalUrl(review.sourceUrl),
                      child: const Text('Ver fuente')),
              ]),
            ])));
  }
}
