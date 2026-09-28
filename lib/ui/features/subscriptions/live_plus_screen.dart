import 'package:flutter/material.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../domain/models/subscription_item.dart';
import '../../../domain/services/subscription_service.dart';
import '../../../domain/services/whatsapp_service.dart';

class PlusScreen extends StatefulWidget {
  const PlusScreen({super.key, this.service, this.autoLoad = true});
  final SubscriptionService? service;
  final bool autoLoad;
  @override
  State<PlusScreen> createState() => _PlusScreenState();
}

class _PlusScreenState extends State<PlusScreen> {
  late final service = widget.service ?? SubscriptionService.instance;
  GamePlatform? _platform;
  SubscriptionCategory _category = SubscriptionCategory.all;
  String _query = '';
  @override
  void initState() {
    super.initState();
    if (widget.autoLoad) service.ensureLoaded();
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
      listenable: service,
      builder: (context, _) {
        final items = service.getItems(
            platform: _platform, category: _category, query: _query);
        final now = DateTime.now();
        return Scaffold(
            appBar: AppBar(title: const Text('Plus & Suscripciones'), actions: [
              IconButton(
                  tooltip: 'Actualizar suscripciones',
                  onPressed: service.loading ? null : service.refresh,
                  icon: const Icon(Icons.refresh)),
            ]),
            body: Column(children: [
              const Padding(
                  padding: EdgeInsets.fromLTRB(14, 8, 14, 6),
                  child: Text(
                      'Estados Unidos · Consulta oficial. Comprueba tu nivel antes de comprar; la app no accede a tu membresía.')),
              Padding(
                  padding: const EdgeInsets.all(12),
                  child: TextField(
                      onChanged: (query) => setState(() => _query = query),
                      decoration: const InputDecoration(
                          hintText: 'Buscar en las suscripciones...',
                          prefixIcon: Icon(Icons.search)))),
              SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Row(children: [
                    for (final platform in <GamePlatform?>[
                      null,
                      ...GamePlatform.values
                    ])
                      Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: ChoiceChip(
                              label: Text(platform == null
                                  ? 'Todas'
                                  : switch (platform) {
                                      GamePlatform.playstation =>
                                        'PlayStation Plus',
                                      GamePlatform.xbox => 'Xbox Game Pass',
                                      GamePlatform.nintendo =>
                                        'Nintendo Switch Online',
                                    }),
                              selected: _platform == platform,
                              onSelected: (_) =>
                                  setState(() => _platform = platform))),
                  ])),
              SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.all(12),
                  child: Row(children: [
                    for (final category in [
                      SubscriptionCategory.all,
                      SubscriptionCategory.monthly,
                      SubscriptionCategory.comingSoon
                    ])
                      Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: ChoiceChip(
                              label: Text(category.label),
                              selected: _category == category,
                              onSelected: (_) =>
                                  setState(() => _category = category))),
                  ])),
              if (service.loading) const LinearProgressIndicator(),
              Expanded(
                  child: RefreshIndicator(
                      onRefresh: service.refresh,
                      child: ListView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          padding: const EdgeInsets.all(12),
                          children: [
                            for (final platform in GamePlatform.values.where(
                                (p) =>
                                    _platform == null || p == _platform)) ...[
                              if (service.errors[platform] != null)
                                Padding(
                                    padding: const EdgeInsets.all(8),
                                    child: Text(service.errors[platform]!,
                                        style: const TextStyle(
                                            color: AppTheme.warning))),
                              if (service.checkedAt[platform] != null)
                                Padding(
                                    padding: const EdgeInsets.only(bottom: 8),
                                    child: Text(
                                        '${AppConstants.platformDisplayName(platform)} · verificado ${DateFormatter.formatShortDate(service.checkedAt[platform]!)}',
                                        style: const TextStyle(
                                            fontSize: 11,
                                            color: AppTheme.textMuted))),
                            ],
                            if (items.isEmpty && !service.loading)
                              Padding(
                                  padding: const EdgeInsets.all(24),
                                  child: Text(
                                      _category ==
                                              SubscriptionCategory.comingSoon
                                          ? 'Aún no hay juegos con fecha confirmada para el mes siguiente en las fuentes consultadas. Actualiza para comprobar nuevos anuncios.'
                                          : _category ==
                                                  SubscriptionCategory.monthly
                                              ? 'No se encontraron altas con fecha confirmada este mes. Revisa los filtros y actualiza las fuentes.'
                                              : 'No hay resultados verificados para estos filtros. Actualiza las suscripciones.',
                                      textAlign: TextAlign.center)),
                            for (final item in items)
                              Card(
                                  child: Padding(
                                      padding: const EdgeInsets.all(12),
                                      child: Row(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            SizedBox(
                                                width: 65,
                                                height: 90,
                                                child: item.coverUrl.isEmpty
                                                    ? const Icon(
                                                        Icons.sports_esports)
                                                    : Image.network(
                                                        item.coverUrl,
                                                        fit: BoxFit.cover,
                                                        errorBuilder: (_, __,
                                                                ___) =>
                                                            const Icon(Icons
                                                                .sports_esports))),
                                            const SizedBox(width: 12),
                                            Expanded(
                                                child: Column(
                                                    crossAxisAlignment:
                                                        CrossAxisAlignment
                                                            .start,
                                                    children: [
                                                  Text(item.title,
                                                      style: const TextStyle(
                                                          fontWeight:
                                                              FontWeight.bold)),
                                                  Text(item.tier.displayName,
                                                      style: const TextStyle(
                                                          fontSize: 12,
                                                          color: AppTheme
                                                              .primaryLight)),
                                                  Text(
                                                      item.consoles.join(' / '),
                                                      style: const TextStyle(
                                                          fontSize: 11)),
                                                  Text(
                                                      item.availableAt(now)
                                                          ? 'Disponible ahora'
                                                          : item.addedAt
                                                                      ?.isAfter(
                                                                          now) ==
                                                                  true
                                                              ? 'Anunciado; aún no disponible'
                                                              : 'Alta del mes; verifica el acceso actual',
                                                      style: TextStyle(
                                                          fontSize: 12,
                                                          color: item
                                                                  .availableAt(
                                                                      now)
                                                              ? AppTheme.success
                                                              : AppTheme
                                                                  .warning)),
                                                  if (item.addedAt != null)
                                                    Text(
                                                        'Alta: ${DateFormatter.formatShortDate(item.addedAt!)}',
                                                        style: const TextStyle(
                                                            fontSize: 11)),
                                                  if (item.expiryDate != null)
                                                    Text(
                                                        'Reclamar hasta: ${item.expiryDate}',
                                                        style: const TextStyle(
                                                            fontSize: 11)),
                                                  if (item.statusNote != null)
                                                    Text(item.statusNote!,
                                                        style: const TextStyle(
                                                            fontSize: 11,
                                                            color: AppTheme
                                                                .textSecondary)),
                                                  TextButton.icon(
                                                      onPressed: () =>
                                                          WhatsAppService
                                                              .launchExternalUrl(
                                                                  item
                                                                      .sourceUrl),
                                                      icon: const Icon(
                                                          Icons.open_in_new,
                                                          size: 14),
                                                      label: const Text(
                                                          'Fuente oficial USA')),
                                                ])),
                                          ]))),
                          ]))),
            ]));
      });
}
