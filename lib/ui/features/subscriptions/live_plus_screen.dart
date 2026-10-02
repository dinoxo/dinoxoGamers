import 'dart:async';
import 'package:flutter/material.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../domain/models/subscription_item.dart';
import '../../../domain/models/membership_benefits.dart';
import '../../../domain/services/subscription_service.dart';
import '../../../data/repositories/game_repository.dart';
import '../../../domain/models/game.dart';
import '../game_details/game_details_screen.dart';
import '../../core/widgets/gaming_header.dart';
import '../../core/widgets/platform_filter.dart';
import '../../core/widgets/game_card_frame.dart';
import '../../core/widgets/platform_badge.dart';
import '../../core/widgets/usa_badge.dart';

class PlusScreen extends StatefulWidget {
  const PlusScreen(
      {super.key, this.service, this.repository, this.autoLoad = true});
  final SubscriptionService? service;
  final GameRepository? repository;
  final bool autoLoad;
  @override
  State<PlusScreen> createState() => _PlusScreenState();
}

class _PlusScreenState extends State<PlusScreen> {
  late final service = widget.service ?? SubscriptionService.instance;
  late final GameRepository repository = widget.repository ?? GameRepository();
  GamePlatform? _platform;
  SubscriptionCategory _category = SubscriptionCategory.all;
  String _query = '';
  final _searchController = TextEditingController();
  Timer? _debounce;
  @override
  void initState() {
    super.initState();
    if (widget.autoLoad) service.ensureLoaded();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _openGame(SubscriptionItem item) async {
    Game? game;
    try {
      final page =
          await repository.searchOnline(item.title, platform: item.platform);
      final sameTitle = page.games.where((candidate) =>
          candidate.platform == item.platform &&
          subscriptionTitleKey(candidate.title) ==
              subscriptionTitleKey(item.title));
      if (sameTitle.isNotEmpty) game = sameTitle.first;
    } catch (_) {
      // Membership details remain available when the shop listing is offline.
    }
    if (!mounted) return;
    game ??= Game(
        id: 'subscription_${item.id}',
        title: item.title,
        slug: item.id,
        coverUrl: item.coverUrl,
        platform: item.platform,
        consoles: item.consoles,
        genres: const [],
        developer: '',
        publisher: '',
        releaseDate: null);
    await Navigator.push(
        context,
        MaterialPageRoute<void>(
            builder: (_) =>
                GameDetailsScreen(game: game!, repository: repository)));
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
            appBar: GamingHeader.adaptive(context,
                title: 'Plus & Suscripciones',
                subtitle: 'Descubre qué incluye tu membresía en USA.',
                accent: _platform == null
                    ? AppTheme.secondary
                    : AppTheme.platformColor(_platform!),
                actions: [
                  IconButton(
                      tooltip: 'Actualizar suscripciones',
                      onPressed: service.loading ? null : service.refresh,
                      icon: const Icon(Icons.refresh_rounded))
                ]),
            body: RefreshIndicator(
                onRefresh: service.refresh,
                child: CustomScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  key: ValueKey('${_platform?.name}_${_category.name}'),
                  slivers: [
                    SliverToBoxAdapter(
                        child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                          Padding(
                              padding: const EdgeInsets.fromLTRB(14, 12, 14, 4),
                              child: TextField(
                                  controller: _searchController,
                                  onChanged: (query) {
                                    _debounce?.cancel();
                                    _debounce = Timer(
                                        const Duration(milliseconds: 250), () {
                                      if (mounted) {
                                        setState(() => _query = query);
                                      }
                                    });
                                  },
                                  decoration: const InputDecoration(
                                      hintText:
                                          'Buscar en las suscripciones...',
                                      prefixIcon: Icon(Icons.search)))),
                          PlatformFilter(
                              selected: _platform,
                              memberships: true,
                              onChanged: (platform) => setState(() {
                                    _platform = platform;
                                    _category = platform == null
                                        ? SubscriptionCategory.all
                                        : SubscriptionCategory.benefits;
                                  })),
                          SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 14, vertical: 4),
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
                                      padding: const EdgeInsets.only(right: 6),
                                      child: ChoiceChip(
                                          label: Text(category.label,
                                              style: const TextStyle(
                                                  fontSize: 11)),
                                          selected: _category == category,
                                          onSelected: (_) => setState(
                                              () => _category = category))),
                              ])),
                          const Padding(
                              padding: EdgeInsets.fromLTRB(16, 4, 16, 8),
                              child: Text(
                                  'Estados Unidos · Comprueba tu nivel antes de comprar; la app no accede a tu membresía.',
                                  style: TextStyle(
                                      fontSize: 10,
                                      color: AppTheme.textSecondary))),
                          if (service.loading)
                            const LinearProgressIndicator(minHeight: 2),
                          for (final platform in platforms) ...[
                            if (service.errors[platform] != null)
                              Padding(
                                  padding: const EdgeInsets.all(14),
                                  child: Text(service.errors[platform]!,
                                      style: const TextStyle(
                                          color: AppTheme.warning,
                                          fontSize: 12))),
                            if (service.checkedAt[platform] != null)
                              Padding(
                                  padding:
                                      const EdgeInsets.fromLTRB(16, 2, 16, 6),
                                  child: Text(
                                      '${AppConstants.platformDisplayName(platform)} · última consulta ${DateFormatter.formatShortDate(service.checkedAt[platform]!)}',
                                      style: const TextStyle(
                                          fontSize: 10,
                                          color: AppTheme.textMuted))),
                            for (final notice
                                in service.notices[platform] ?? <String>[])
                              Padding(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 16, vertical: 4),
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
                        ])),
                    SliverList.builder(
                        itemCount: rowCount,
                        itemBuilder: (context, index) {
                          if (showBenefits) {
                            return Padding(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 4),
                                child: _BenefitsCard(
                                    plan: benefits[index],
                                    onOpen: () => Navigator.push(
                                        context,
                                        MaterialPageRoute<void>(
                                            builder: (_) => _MembershipScreen(
                                                plan: benefits[index],
                                                service: service,
                                                onOpenGame: _openGame)))));
                          }
                          final item = items[index];
                          return _SubscriptionCard(
                              key: ValueKey(item.id),
                              item: item,
                              onOpen: () => _openGame(item),
                              stale: service.errors.containsKey(item.platform),
                              now: service.now);
                        }),
                    const SliverToBoxAdapter(child: SizedBox(height: 24)),
                  ],
                )),
          );
        },
      );
}

class _SubscriptionCard extends StatelessWidget {
  const _SubscriptionCard(
      {super.key,
      required this.item,
      required this.now,
      required this.onOpen,
      this.stale = false});
  final SubscriptionItem item;
  final VoidCallback onOpen;
  final DateTime now;
  final bool stale;
  @override
  Widget build(BuildContext context) {
    final included = item.availableAt(now);
    final accent = AppTheme.platformColor(item.platform);
    return GameCardFrame(
        platform: item.platform,
        coverUrl: item.coverUrl,
        onTap: onOpen,
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Wrap(spacing: 4, runSpacing: 4, children: [
            PlatformBadge(platform: item.platform, compact: true),
            const UsaBadge(compact: true),
          ]),
          const SizedBox(height: 8),
          Text(item.title,
              style: const TextStyle(
                  fontSize: 15, fontWeight: FontWeight.w800, height: 1.2)),
          const SizedBox(height: 4),
          Text(item.consoles.join(' / '),
              style:
                  const TextStyle(fontSize: 11, color: AppTheme.textSecondary)),
          const SizedBox(height: 5),
          Text(
              item.status == SubscriptionStatus.leavingSoon &&
                      !item.availabilityConfirmed
                  ? 'Salida anunciada · Nivel por confirmar'
                  : item.tier.displayName,
              style: TextStyle(
                  fontSize: 11,
                  color: Color.lerp(accent, Colors.white, .5),
                  fontWeight: FontWeight.w700)),
          const SizedBox(height: 5),
          Text(
              stale
                  ? 'Última consulta guardada · Pendiente de verificar'
                  : item.status == SubscriptionStatus.leavingSoon
                      ? 'Sale próximamente del catálogo'
                      : included
                          ? 'Disponible ahora'
                          : item.addedAt?.isAfter(now) == true
                              ? 'Anunciado; aún no disponible'
                              : 'Alta del mes; verifica el acceso actual',
              style: TextStyle(
                  fontSize: 11,
                  color: item.status == SubscriptionStatus.leavingSoon
                      ? AppTheme.warning
                      : included
                          ? AppTheme.success
                          : AppTheme.warning)),
          if (item.addedAt != null)
            Text('Alta: ${DateFormatter.formatShortDate(item.addedAt!)}',
                style: const TextStyle(fontSize: 10)),
          if (item.expiryDate != null)
            Text(
                '${item.status == SubscriptionStatus.leavingSoon ? 'Último día anunciado' : 'Reclamar hasta'}: ${item.expiryDate}',
                style: const TextStyle(fontSize: 10)),
          if (item.statusNote != null)
            Text(item.statusNote!,
                style: const TextStyle(
                    fontSize: 10, color: AppTheme.textSecondary)),
          Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                  onPressed: onOpen,
                  icon: const Icon(Icons.chevron_right_rounded, size: 18),
                  label: const Text('Ver detalles'))),
        ]));
  }
}

class _BenefitsCard extends StatelessWidget {
  const _BenefitsCard({required this.plan, required this.onOpen});
  final MembershipBenefits plan;
  final VoidCallback onOpen;
  @override
  Widget build(BuildContext context) => Card(
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: AppTheme.platformColor(plan.tier.platform))),
      child: Padding(
          padding: const EdgeInsets.all(14),
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(plan.tier.displayName,
                style: const TextStyle(fontWeight: FontWeight.bold)),
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
                onPressed: onOpen,
                icon: const Icon(Icons.library_books, size: 14),
                label: const Text('Ver membresía')),
          ])));
}

class _MembershipScreen extends StatefulWidget {
  const _MembershipScreen(
      {required this.plan, required this.service, required this.onOpenGame});
  final MembershipBenefits plan;
  final SubscriptionService service;
  final Future<void> Function(SubscriptionItem) onOpenGame;
  @override
  State<_MembershipScreen> createState() => _MembershipScreenState();
}

class _MembershipScreenState extends State<_MembershipScreen> {
  String? _console;
  String _query = '';
  @override
  Widget build(BuildContext context) => ListenableBuilder(
      listenable: widget.service,
      builder: (context, _) {
        final tier = widget.plan.tier;
        final plans = widget.service.getBenefits(platform: tier.platform);
        final plan =
            plans.where((p) => p.tier == tier).firstOrNull ?? widget.plan;
        final features = <String>{
          if (tier.platform == GamePlatform.nintendo)
            for (final includedPlan
                in plans.where((p) => p.tier.rank < tier.rank))
              ...includedPlan.features,
          ...plan.features,
        };
        final all = widget.service
            .getItems(platform: tier.platform)
            .where((i) => i.tier.rank <= tier.rank)
            .toList();
        final consoles = all.expand((i) => i.consoles).toSet().toList()..sort();
        final items = all
            .where((i) =>
                (_console == null || i.consoles.contains(_console)) &&
                i.title.toLowerCase().contains(_query.toLowerCase()))
            .toList();
        return Scaffold(
            appBar: GamingHeader.adaptive(context,
                title: tier.displayName,
                subtitle: 'Beneficios, DLC y juegos incluidos · USA',
                accent: AppTheme.platformColor(tier.platform)),
            body: Column(children: [
              Padding(
                  padding: const EdgeInsets.all(12),
                  child: TextField(
                      onChanged: (v) => setState(() => _query = v),
                      decoration: const InputDecoration(
                          labelText: 'Buscar juego en esta membresía',
                          prefixIcon: Icon(Icons.search)))),
              SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Row(children: [
                    Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: ChoiceChip(
                            label: const Text('Todas las consolas'),
                            selected: _console == null,
                            onSelected: (_) =>
                                setState(() => _console = null))),
                    for (final console in consoles)
                      Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: ChoiceChip(
                              label: Text(console),
                              selected: _console == console,
                              onSelected: (_) =>
                                  setState(() => _console = console))),
                  ])),
              Expanded(
                  child: ListView.builder(
                      padding: const EdgeInsets.all(12),
                      itemCount: items.length + 1,
                      itemBuilder: (context, index) {
                        if (index == 0) {
                          return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (widget.service.errors[tier.platform] !=
                                    null)
                                  Text(widget.service.errors[tier.platform]!,
                                      style: const TextStyle(
                                          color: AppTheme.warning)),
                                ExpansionTile(
                                    title: const Text('Beneficios y DLC'),
                                    children: [
                                      for (final feature in features)
                                        ListTile(
                                            dense: true, title: Text(feature)),
                                      Padding(
                                          padding: const EdgeInsets.all(12),
                                          child: SelectableText(plan.sourceUrl))
                                    ]),
                                const SizedBox(height: 12),
                                Text('Juegos incluidos',
                                    style:
                                        Theme.of(context).textTheme.titleLarge),
                                Text(
                                    '${items.length} entradas · Acceso con membresía activa'),
                                if (tier.platform == GamePlatform.nintendo)
                                  const Text(
                                      'Los clásicos se juegan mediante las aplicaciones Nintendo Classics de cada consola. GameCube requiere Switch 2. Los DLC requieren el juego base.'),
                                if (items.isEmpty)
                                  const Padding(
                                      padding: EdgeInsets.all(16),
                                      child: Text(
                                          'No hay juegos disponibles para estos filtros.')),
                              ]);
                        }
                        return _SubscriptionCard(
                            item: items[index - 1],
                            onOpen: () => widget.onOpenGame(items[index - 1]),
                            now: widget.service.now,
                            stale: widget.service.errors
                                .containsKey(tier.platform));
                      })),
            ]));
      });
}
