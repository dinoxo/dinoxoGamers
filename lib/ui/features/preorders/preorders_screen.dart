import 'dart:async';

import 'package:flutter/material.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/datasources/preorder_source.dart';
import '../../../data/repositories/game_repository.dart';
import '../../../domain/models/preorder_game.dart';
import '../game_details/game_details_screen.dart';
import '../../core/widgets/gaming_header.dart';
import '../../core/widgets/platform_filter.dart';
import '../../core/widgets/game_card_frame.dart';
import '../../core/widgets/platform_badge.dart';
import '../../core/widgets/usa_badge.dart';

class PreordersScreen extends StatefulWidget {
  const PreordersScreen({
    super.key,
    required this.repository,
    required this.onCreateReleaseAlert,
    this.source,
  });

  final GameRepository repository;
  final Future<void> Function(PreorderGame game) onCreateReleaseAlert;
  final PreorderSource? source;

  @override
  State<PreordersScreen> createState() => _PreordersScreenState();
}

class _PreordersScreenState extends State<PreordersScreen> {
  late final PreorderSource _source = widget.source ?? PreorderSource();
  final _search = TextEditingController();
  Timer? _debounce;
  int _generation = 0;
  int _page = 1;
  bool _loading = true;
  bool _hasMore = false;
  String? _error;
  GamePlatform? _platform;
  List<PreorderGame> _games = [];
  List<String> _suggestions = [];

  static int _gamePriority(PreorderGame game) {
    final title = game.title.toLowerCase();
    if (title.contains('grand theft auto vi') ||
        title.contains('gta 6') ||
        title.contains('gta vi') ||
        title.contains('grand theft auto 6')) {
      return 100;
    }
    if (title.contains('zelda') || title.contains('ocarina of time')) {
      return 95;
    }
    if (title.contains('metroid prime 4') || title.contains('beyond')) {
      return 90;
    }
    if (title.contains('monster hunter wilds')) {
      return 88;
    }
    if (title.contains('ghost of yōtei') || title.contains('ghost of yotei')) {
      return 86;
    }
    if (title.contains('doom: the dark ages') ||
        title.contains('doom the dark ages')) {
      return 85;
    }
    if (title.contains('death stranding 2')) {
      return 84;
    }
    if (title.contains('wolverine') || title.contains("marvel's wolverine")) {
      return 83;
    }
    if (title.contains('fable')) {
      return 82;
    }
    if (title.contains('gears of war: e-day') ||
        title.contains('gears of war')) {
      return 81;
    }
    if (title.contains('pokemon') || title.contains('pokémon')) {
      return 80;
    }
    if (title.contains('mario') || title.contains('donkey kong')) {
      return 78;
    }
    if (title.contains('witcher') || title.contains('cyberpunk')) {
      return 75;
    }
    if (title.contains('elder scrolls') || title.contains('fallout')) {
      return 74;
    }
    return 0;
  }

  static List<PreorderGame> _sortedGames(List<PreorderGame> list) {
    final copy = List<PreorderGame>.from(list);
    copy.sort((a, b) {
      final pA = _gamePriority(a);
      final pB = _gamePriority(b);
      if (pA != pB) return pB.compareTo(pA);
      final dateA = a.releaseDate;
      final dateB = b.releaseDate;
      if (dateA != null && dateB != null) return dateA.compareTo(dateB);
      if (dateA != null) return -1;
      if (dateB != null) return 1;
      return a.title.compareTo(b.title);
    });
    return copy;
  }

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _generation++;
    _debounce?.cancel();
    _search.dispose();
    if (widget.source == null) _source.close();
    super.dispose();
  }

  Future<void> _load({bool more = false}) async {
    final generation = ++_generation;
    final query = _search.text.trim();
    setState(() {
      _loading = true;
      _error = null;
      if (!more) {
        _page = 1;
        _games = [];
      }
    });
    try {
      final nextPage = more ? _page + 1 : 1;
      final result = query.length >= 2
          ? await _source.search(query, page: nextPage)
          : await _source.fetchPage(page: nextPage);
      if (!mounted || generation != _generation) return;
      setState(() {
        _page = nextPage;
        _games = more
            ? {
                for (final game in [..._games, ...result.games]) game.id: game
              }.values.toList()
            : result.games;
        _hasMore = result.hasMore;
        _loading = false;
      });
    } catch (_) {
      if (!mounted || generation != _generation) return;
      setState(() {
        _error =
            'No se pudieron cargar los próximos lanzamientos. Inténtalo de nuevo.';
        _loading = false;
      });
    }
  }

  void _onSearchChanged(String value) {
    _debounce?.cancel();
    final generation = ++_generation;
    final query = value.trim();
    if (query.length < 2) {
      setState(() => _suggestions = []);
      _debounce = Timer(const Duration(milliseconds: 350), _load);
      return;
    }
    _debounce = Timer(const Duration(milliseconds: 350), () async {
      try {
        final suggestions = await _source.autocomplete(query);
        if (!mounted || generation != _generation) return;
        setState(() => _suggestions = suggestions);
        await _load();
      } catch (_) {
        if (mounted && generation == _generation) await _load();
      }
    });
  }

  void _chooseSuggestion(String title) {
    _debounce?.cancel();
    _generation++;
    _search.text = title;
    _search.selection = TextSelection.collapsed(offset: title.length);
    FocusScope.of(context).unfocus();
    setState(() => _suggestions = []);
    _load();
  }

  void _open(PreorderGame item) {
    Navigator.push(
        context,
        MaterialPageRoute<void>(
          builder: (_) => GameDetailsScreen(
              game: item.toGame(), repository: widget.repository),
        ));
  }

  Future<void> _saveAlert(PreorderGame item) async {
    await widget.onCreateReleaseAlert(item);
  }

  String _countdown(PreorderGame game) {
    final days = game.daysRemaining(DateTime.now());
    if (days == null) return 'Fecha por confirmar';
    if (days <= 0) return 'Sale hoy';
    return days == 1 ? 'Falta 1 día' : 'Faltan $days días';
  }

  Widget _card(PreorderGame game) {
    final date = game.releaseDate;
    final canAlert = date != null && game.daysRemaining(DateTime.now())! > 0;
    final color =
        Color.lerp(AppTheme.platformColor(game.platform), Colors.white, .45)!;
    return GameCardFrame(
        platform: game.platform,
        coverUrl: game.coverUrl,
        onTap: () => _open(game),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Wrap(spacing: 4, runSpacing: 4, children: [
            PlatformBadge(platform: game.platform, compact: true),
            const UsaBadge(compact: true)
          ]),
          const SizedBox(height: 8),
          Text(game.title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                  fontSize: 15, fontWeight: FontWeight.w800, height: 1.2)),
          const SizedBox(height: 4),
          Text(game.consoles.join(' / '),
              style:
                  const TextStyle(fontSize: 11, color: AppTheme.textSecondary)),
          if (game.publisher.isNotEmpty)
            Text(game.publisher,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style:
                    const TextStyle(fontSize: 10, color: AppTheme.textMuted)),
          const SizedBox(height: 8),
          Text(_countdown(game),
              style: TextStyle(
                  color: color, fontSize: 16, fontWeight: FontWeight.w900)),
          if (date != null)
            Text('${date.day}/${date.month}/${date.year} · USA',
                style: const TextStyle(
                    color: AppTheme.textSecondary, fontSize: 11)),
          Text(game.isPreorder ? 'Preventa disponible' : 'Próximo lanzamiento',
              style: const TextStyle(color: AppTheme.textMuted, fontSize: 10)),
          const SizedBox(height: 6),
          Wrap(spacing: 4, children: [
            if (canAlert)
              TextButton.icon(
                  onPressed: () => _saveAlert(game),
                  icon:
                      const Icon(Icons.notifications_active_outlined, size: 16),
                  label: const Text('Avisarme')),
            TextButton.icon(
                onPressed: () => _open(game),
                icon: const Icon(Icons.chevron_right_rounded, size: 18),
                label: const Text('Ver detalles')),
          ]),
        ]));
  }

  @override
  Widget build(BuildContext context) => _platform == null
      ? _buildPage(context)
      : Theme(
          data: AppTheme.forPlatform(Theme.of(context), _platform!),
          child: Builder(builder: _buildPage));

  Widget _buildPage(BuildContext context) {
    final active = _platform == null
        ? _games
        : _games.where((game) => game.platform == _platform).toList();
    final sorted = _sortedGames(active);
    final platforms = _platform == null ? GamePlatform.values : [_platform!];
    final rows = <Object>[];
    for (final platform in platforms) {
      final games = sorted.where((game) => game.platform == platform);
      if (games.isNotEmpty) {
        rows.add(platform);
        rows.addAll(games);
      }
    }
    return Scaffold(
      appBar: GamingHeader.adaptive(context,
          title: 'Preventas',
          subtitle: 'Tu próxima aventura. Sigue su cuenta regresiva.',
          accent: _platform == null
              ? AppTheme.secondary
              : AppTheme.platformColor(_platform!)),
      body: RefreshIndicator(
          onRefresh: () => _load(),
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              SliverToBoxAdapter(
                  child: Column(children: [
                Padding(
                    padding: const EdgeInsets.fromLTRB(14, 12, 14, 4),
                    child: TextField(
                        controller: _search,
                        onChanged: _onSearchChanged,
                        onSubmitted: (_) {
                          setState(() => _suggestions = []);
                          _load();
                        },
                        decoration: const InputDecoration(
                            prefixIcon: Icon(Icons.search),
                            hintText: 'Buscar solo próximos lanzamientos'))),
                PlatformFilter(
                    selected: _platform,
                    onChanged: (p) => setState(() => _platform = p)),
                if (_suggestions.isNotEmpty)
                  ConstrainedBox(
                      constraints: const BoxConstraints(maxHeight: 180),
                      child: ListView(
                          shrinkWrap: true,
                          children: _suggestions
                              .map((title) => ListTile(
                                  dense: true,
                                  title: Text(title,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis),
                                  onTap: () => _chooseSuggestion(title)))
                              .toList())),
                const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Text(
                        'Lanzamientos anunciados y preventas en tiendas USA. La fecha puede variar por consola.',
                        style: TextStyle(
                            color: AppTheme.textSecondary, fontSize: 10))),
                if (_error != null)
                  Padding(
                      padding: const EdgeInsets.all(16),
                      child: Text(_error!,
                          style: const TextStyle(color: AppTheme.warning))),
              ])),
              SliverList.builder(
                  itemCount: rows.length,
                  itemBuilder: (context, index) {
                    final row = rows[index];
                    if (row is PreorderGame) return _card(row);
                    final platform = row as GamePlatform;
                    return Padding(
                        padding: const EdgeInsets.fromLTRB(16, 14, 16, 6),
                        child: Text(AppConstants.platformDisplayName(platform),
                            style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w800,
                                color: Color.lerp(
                                    AppTheme.platformColor(platform),
                                    Colors.white,
                                    .4))));
                  }),
              SliverToBoxAdapter(
                  child: Column(children: [
                if (!_loading && sorted.isEmpty && _error == null)
                  const Padding(
                      padding: EdgeInsets.all(24),
                      child: Text(
                          'No hay juegos anunciados que coincidan con la búsqueda.')),
                if (_loading)
                  const Padding(
                      padding: EdgeInsets.all(24),
                      child: Center(child: CircularProgressIndicator())),
                if (_hasMore && !_loading)
                  Padding(
                      padding: const EdgeInsets.all(16),
                      child: OutlinedButton(
                          onPressed: () => _load(more: true),
                          child: const Text('Cargar más lanzamientos'))),
                const SizedBox(height: 24),
              ])),
            ],
          )),
    );
  }
}
