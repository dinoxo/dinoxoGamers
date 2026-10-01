import 'dart:async';

import 'package:flutter/material.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/datasources/preorder_source.dart';
import '../../../data/repositories/game_repository.dart';
import '../../../domain/models/preorder_game.dart';
import '../game_details/game_details_screen.dart';

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
  List<PreorderGame> _games = [];
  List<String> _suggestions = [];

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
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: BorderSide(color: AppTheme.platformColor(game.platform))),
      child: InkWell(
        onTap: () => _open(game),
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: SizedBox(
                width: 84,
                height: 112,
                child: game.coverUrl.isEmpty
                    ? const Icon(Icons.sports_esports, size: 48)
                    : Image.network(game.coverUrl,
                        fit: BoxFit.cover,
                        cacheWidth: 252,
                        errorBuilder: (_, __, ___) =>
                            const Icon(Icons.sports_esports)),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                  Text(game.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          fontSize: 15, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 5),
                  Text(
                      game.publisher.isEmpty
                          ? 'Compañía por confirmar'
                          : game.publisher,
                      style: const TextStyle(
                          color: AppTheme.textSecondary, fontSize: 12)),
                  const SizedBox(height: 7),
                  Wrap(spacing: 4, runSpacing: 4, children: [
                    Chip(
                        label: Text(
                            AppConstants.platformDisplayName(game.platform))),
                    ...game.consoles.map((c) => Chip(label: Text(c))),
                  ]),
                  Text(_countdown(game),
                      style: const TextStyle(
                          color: AppTheme.secondary,
                          fontWeight: FontWeight.w800)),
                  if (date != null)
                    Text('${date.day}/${date.month}/${date.year} · USA',
                        style: const TextStyle(
                            color: AppTheme.textMuted, fontSize: 12)),
                  Text(
                      game.isPreorder
                          ? 'Preventa disponible'
                          : 'Próximo lanzamiento',
                      style: const TextStyle(
                          color: AppTheme.textSecondary, fontSize: 11)),
                  Wrap(spacing: 8, children: [
                    TextButton(
                        onPressed: () => _open(game),
                        child: const Text('Ver detalles')),
                    if (canAlert)
                      TextButton.icon(
                        onPressed: () => _saveAlert(game),
                        icon: const Icon(Icons.notifications_active_outlined,
                            size: 18),
                        label: const Text('Avisarme'),
                      ),
                  ]),
                ])),
          ]),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final grouped = <GamePlatform, List<PreorderGame>>{
      for (final platform in GamePlatform.values)
        platform: _games.where((game) => game.platform == platform).toList(),
    };
    return Scaffold(
      appBar: AppBar(title: const Text('Preventas')),
      body: Column(children: [
        Padding(
          padding: const EdgeInsets.all(14),
          child: TextField(
            controller: _search,
            onChanged: _onSearchChanged,
            onSubmitted: (_) {
              setState(() => _suggestions = []);
              _load();
            },
            decoration: const InputDecoration(
              prefixIcon: Icon(Icons.search),
              hintText: 'Buscar solo próximos lanzamientos',
            ),
          ),
        ),
        if (_suggestions.isNotEmpty)
          ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 180),
            child: ListView(
              shrinkWrap: true,
              children: _suggestions
                  .map((title) => ListTile(
                        dense: true,
                        title: Text(title,
                            maxLines: 1, overflow: TextOverflow.ellipsis),
                        onTap: () => _chooseSuggestion(title),
                      ))
                  .toList(),
            ),
          ),
        Expanded(
            child: RefreshIndicator(
          onRefresh: () => _load(),
          child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              children: [
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 5),
                  child: Text(
                      'Lanzamientos anunciados y preventas en tiendas USA. La fecha puede variar por consola.',
                      style: TextStyle(
                          color: AppTheme.textSecondary, fontSize: 12)),
                ),
                if (_error != null)
                  Padding(
                      padding: const EdgeInsets.all(16),
                      child: Text(_error!,
                          style: const TextStyle(color: AppTheme.warning))),
                for (final platform in GamePlatform.values)
                  if (grouped[platform]!.isNotEmpty) ...[
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 18, 16, 6),
                      child: Text(AppConstants.platformDisplayName(platform),
                          style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              color: AppTheme.platformColor(platform))),
                    ),
                    ...grouped[platform]!.map(_card),
                  ],
                if (!_loading && _games.isEmpty && _error == null)
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
                        child: const Text('Cargar más lanzamientos'),
                      )),
              ]),
        )),
      ]),
    );
  }
}
