import 'package:flutter/material.dart';
import '../../../core/constants/app_constants.dart';
import '../../../data/datasources/web_scraper_service.dart';
import '../../../data/repositories/game_repository.dart';
import '../../../domain/models/game.dart';
import '../../core/widgets/deal_card.dart';
import '../game_details/game_details_screen.dart';

class DealsScreen extends StatefulWidget {
  final GameRepository repository;
  const DealsScreen({super.key, required this.repository});
  @override
  State<DealsScreen> createState() => _DealsScreenState();
}

class _DealsScreenState extends State<DealsScreen> {
  GamePlatform? _platform;
  List<Game> _games = [];
  Set<String> _favorites = {};
  bool _busy = true;
  bool _hasMore = false;
  int _page = 1;
  int _generation = 0;
  double? _maxPrice;
  String? _error;
  String? _warning;
  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _generation++;
    super.dispose();
  }

  Future<void> _load({bool more = false}) async {
    final generation = ++_generation;
    final page = more ? _page + 1 : 1;
    setState(() {
      _busy = true;
      _error = null;
      _warning = null;
      if (!more) {
        _games = [];
        _hasMore = false;
      }
    });
    try {
      final result = await widget.repository
          .refreshLiveDeals(platform: _platform, page: page);
      final favorites = await widget.repository.getFavoriteGames();
      if (!mounted || generation != _generation) return;
      setState(() {
        _games = {
          if (more)
            for (final g in _games) g.id: g,
          for (final g in result.games) g.id: g
        }.values.toList();
        _favorites = favorites.map((g) => g.id).toSet();
        _page = page;
        _hasMore = result.hasMore;
        _warning = result.warnings.isEmpty ? null : result.warnings.join('\n');
      });
    } catch (e) {
      if (!mounted || generation != _generation) return;
      setState(() => _error = e is CatalogException
          ? e.message
          : 'No se pudo consultar la web. Comprueba tu conexión y reintenta.');
    } finally {
      if (mounted && generation == _generation) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final games = _games
        .where((g) => _maxPrice == null || g.currentPrice <= _maxPrice!)
        .toList();
    return Scaffold(
        appBar: AppBar(title: const Text('Ofertas Destacadas'), actions: [
          IconButton(
              tooltip: 'Actualizar desde la web',
              onPressed: _busy ? null : () => _load(),
              icon: const Icon(Icons.refresh)),
        ]),
        body: Column(children: [
          SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.all(12),
              child: Row(children: [
                for (final p in <GamePlatform?>[null, ...GamePlatform.values])
                  Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ChoiceChip(
                          label: Text(p == null
                              ? 'Todas'
                              : AppConstants.platformDisplayName(p)),
                          selected: p == _platform,
                          onSelected: (_) {
                            setState(() => _platform = p);
                            _load();
                          })),
              ])),
          Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Row(children: [
                const Expanded(child: Text('Tiendas digitales USA · USD')),
                DropdownButton<double>(
                    value: _maxPrice,
                    hint: const Text('Cualquier precio'),
                    items: [
                      const DropdownMenuItem<double>(
                          value: null, child: Text('Cualquier precio')),
                      for (final p in [10.0, 20.0, 30.0, 50.0])
                        DropdownMenuItem(
                            value: p, child: Text('Hasta \$${p.toInt()}')),
                    ],
                    onChanged: (v) => setState(() => _maxPrice = v)),
              ])),
          const Padding(
              padding: EdgeInsets.all(8),
              child: Text(
                  'Precios publicados por Deku Deals. Confirma el importe final en la tienda.',
                  textAlign: TextAlign.center)),
          if (_busy) const LinearProgressIndicator(),
          if (_error != null)
            Padding(padding: const EdgeInsets.all(12), child: Text(_error!)),
          if (_warning != null)
            Padding(padding: const EdgeInsets.all(8), child: Text(_warning!)),
          Expanded(
              child: RefreshIndicator(
                  onRefresh: () => _load(),
                  child: ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      children: [
                        if (games.isEmpty && !_busy)
                          Padding(
                              padding: const EdgeInsets.all(24),
                              child: Text(
                                  _error == null
                                      ? 'No hay descuentos digitales verificados en esta página con estos filtros.'
                                      : 'No pudimos actualizar las ofertas. Pulsa Reintentar.',
                                  textAlign: TextAlign.center)),
                        for (final game in games)
                          DealCard(
                              game: game,
                              isFavorite: _favorites.contains(game.id),
                              onToggleFavorite: () async {
                                await widget.repository.toggleFavorite(game.id);
                                if (mounted) {
                                  setState(() {
                                    _favorites.contains(game.id)
                                        ? _favorites.remove(game.id)
                                        : _favorites.add(game.id);
                                  });
                                }
                              },
                              onTap: () => Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                      builder: (_) => GameDetailsScreen(
                                          game: game,
                                          repository: widget.repository)))),
                        if (_hasMore && _error == null)
                          TextButton(
                              onPressed: _busy ? null : () => _load(more: true),
                              child: const Text('Consultar más ofertas')),
                        if (_error != null)
                          TextButton(
                              onPressed: _busy ? null : () => _load(),
                              child: const Text('Reintentar')),
                        const SizedBox(height: 24),
                      ]))),
        ]));
  }
}
