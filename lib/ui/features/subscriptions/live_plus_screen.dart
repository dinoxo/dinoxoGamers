import 'dart:async';
import 'package:flutter/material.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../domain/models/subscription_item.dart';
import '../../../domain/models/membership_benefits.dart';
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
  Timer? _debounce;
  @override
  void initState() {
    super.initState();
    if (widget.autoLoad) service.ensureLoaded();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }

  String get _emptyMessage => switch (_category) {
        SubscriptionCategory.comingSoon =>
          'Aún no hay juegos con fecha confirmada para el mes siguiente en las fuentes consultadas. Actualiza para comprobar nuevos anuncios.',
        SubscriptionCategory.monthly =>
          'No se encontraron altas con fecha confirmada este mes. Revisa los filtros y actualiza las fuentes.',
        SubscriptionCategory.upcoming =>
          'No hay nuevos ingresos con fecha futura confirmada en las fuentes consultadas.',
        SubscriptionCategory.leavingSoon =>
          'No se encontraron retiradas futuras con fecha publicada en las fuentes consultadas. Esto no garantiza que no haya salidas; revisa los avisos de cada compañía.',
        SubscriptionCategory.benefits =>
          'No se pudieron comprobar los beneficios con estos filtros. Actualiza para reintentar.',
        _ =>
          'No hay resultados verificados para estos filtros. Actualiza las suscripciones.'
      };

  @override
  Widget build(BuildContext context) => ListenableBuilder(
        listenable: service,
        builder: (context, _) {
          final items = service.getItems(
              platform: _platform, category: _category, query: _query);
          final platforms = GamePlatform.values
              .where((p) => _platform == null || p == _platform);
          final benefits = service.getBenefits(platform: _platform);
          final showBenefits = _category == SubscriptionCategory.benefits;
          final rowCount = showBenefits ? benefits.length : items.length;
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
                      'Estados Unidos · Comprueba tu nivel antes de comprar; la app no accede a tu membresía.')),
              Padding(
                  padding: const EdgeInsets.all(12),
                  child: TextField(
                      onChanged: (query) {
                        _debounce?.cancel();
                        _debounce =
                            Timer(const Duration(milliseconds: 250), () {
                          if (mounted) setState(() => _query = query);
                        });
                      },
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
                      SubscriptionCategory.upcoming,
                      SubscriptionCategory.comingSoon,
                      SubscriptionCategory.leavingSoon,
                      SubscriptionCategory.benefits
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
                      child: ListView.builder(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.all(12),
                        key: ValueKey('${_platform?.name}_${_category.name}'),
                        itemCount: rowCount + 1,
                        itemBuilder: (context, index) {
                          if (index == 0) {
                            return Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  for (final platform in platforms) ...[
                                    if (service.errors[platform] != null)
                                      Padding(
                                          padding: const EdgeInsets.all(8),
                                          child: Text(service.errors[platform]!,
                                              style: const TextStyle(
                                                  color: AppTheme.warning))),
                                    if (service.checkedAt[platform] != null)
                                      Padding(
                                          padding:
                                              const EdgeInsets.only(bottom: 8),
                                          child: Text(
                                              '${AppConstants.platformDisplayName(platform)} · verificado ${DateFormatter.formatShortDate(service.checkedAt[platform]!)}',
                                              style: const TextStyle(
                                                  fontSize: 11,
                                                  color: AppTheme.textMuted))),
                                    for (final notice
                                        in service.notices[platform] ??
                                            <String>[])
                                      Padding(
                                          padding:
                                              const EdgeInsets.only(bottom: 8),
                                          child: Text(notice,
                                              style: const TextStyle(
                                                  fontSize: 11,
                                                  color: AppTheme.warning))),
                                  ],
                                  if (rowCount == 0 && !service.loading)
                                    Padding(
                                        padding: const EdgeInsets.all(24),
                                        child: Text(_emptyMessage,
                                            textAlign: TextAlign.center)),
                                ]);
                          }
                          if (showBenefits) {
                            return _BenefitsCard(plan: benefits[index - 1]);
                          }
                          final item = items[index - 1];
                          return _SubscriptionCard(
                              key: ValueKey(item.id),
                              item: item,
                              now: service.now);
                        },
                      ))),
            ]),
          );
        },
      );
}

class _SubscriptionCard extends StatelessWidget {
  const _SubscriptionCard({super.key, required this.item, required this.now});
  final SubscriptionItem item;
  final DateTime now;
  @override
  Widget build(BuildContext context) {
    final cover = item.coverUrl;
    final included = item.availableAt(now);
    return Card(
        child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              SizedBox(
                  width: 65,
                  height: 90,
                  child: cover.isEmpty
                      ? const Icon(Icons.sports_esports)
                      : Image.network(cover,
                          fit: BoxFit.cover,
                          cacheWidth: 195,
                          errorBuilder: (_, __, ___) =>
                              const Icon(Icons.sports_esports))),
              const SizedBox(width: 12),
              Expanded(
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                    Text(item.title,
                        style: const TextStyle(fontWeight: FontWeight.bold)),
                    Text(
                        item.status == SubscriptionStatus.leavingSoon &&
                                !item.availabilityConfirmed
                            ? 'Salida anunciada · Nivel por confirmar'
                            : item.tier.displayName,
                        style: const TextStyle(
                            fontSize: 12, color: AppTheme.primaryLight)),
                    Text(item.consoles.join(' / '),
                        style: const TextStyle(fontSize: 11)),
                    Text(
                        item.status == SubscriptionStatus.leavingSoon
                            ? 'Sale próximamente del catálogo'
                            : included
                                ? 'Disponible ahora'
                                : item.addedAt?.isAfter(now) == true
                                    ? 'Anunciado; aún no disponible'
                                    : 'Alta del mes; verifica el acceso actual',
                        style: TextStyle(
                            fontSize: 12,
                            color: item.status == SubscriptionStatus.leavingSoon
                                ? AppTheme.warning
                                : included
                                    ? AppTheme.success
                                    : AppTheme.warning)),
                    if (item.addedAt != null)
                      Text(
                          'Alta: ${DateFormatter.formatShortDate(item.addedAt!)}',
                          style: const TextStyle(fontSize: 11)),
                    if (item.expiryDate != null)
                      Text(
                          '${item.status == SubscriptionStatus.leavingSoon ? 'Último día anunciado' : 'Reclamar hasta'}: ${item.expiryDate}',
                          style: const TextStyle(fontSize: 11)),
                    if (item.statusNote != null)
                      Text(item.statusNote!,
                          style: const TextStyle(
                              fontSize: 11, color: AppTheme.textSecondary)),
                    TextButton.icon(
                        onPressed: () =>
                            WhatsAppService.launchExternalUrl(item.sourceUrl),
                        icon: const Icon(Icons.open_in_new, size: 14),
                        label: const Text('Fuente oficial USA')),
                  ])),
            ])));
  }
}

class _BenefitsCard extends StatelessWidget {
  const _BenefitsCard({required this.plan});
  final MembershipBenefits plan;
  @override
  Widget build(BuildContext context) => Card(
      child: Padding(
          padding: const EdgeInsets.all(14),
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(plan.tier.displayName,
                style: const TextStyle(
                    fontWeight: FontWeight.bold, color: AppTheme.primaryLight)),
            const SizedBox(height: 8),
            for (final feature in plan.features)
              Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Text('• $feature')),
            Text(
                'USA · verificado ${DateFormatter.formatShortDate(plan.checkedAt)}',
                style:
                    const TextStyle(fontSize: 11, color: AppTheme.textMuted)),
            const Text(
                'La disponibilidad y los requisitos varían por juego, consola y plan.',
                style: TextStyle(fontSize: 11, color: AppTheme.textMuted)),
            TextButton.icon(
                onPressed: () =>
                    WhatsAppService.launchExternalUrl(plan.sourceUrl),
                icon: const Icon(Icons.open_in_new, size: 14),
                label: const Text('Ver beneficios y condiciones oficiales')),
          ])));
}
