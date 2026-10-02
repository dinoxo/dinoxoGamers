import 'dart:async';
import 'package:flutter/material.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/datasources/web_scraper_service.dart';
import '../../../data/repositories/game_repository.dart';
import '../../../domain/models/game.dart';
import '../../core/widgets/deal_card.dart';
import '../../core/widgets/gaming_header.dart';
import '../../core/widgets/platform_filter.dart';
import '../../core/widgets/live_game_autocomplete.dart';
import '../game_details/game_details_screen.dart';

class DealsScreen extends StatefulWidget {
  final GameRepository repository;
  const DealsScreen({super.key, required this.repository});
  @override
  State<DealsScreen> createState() => _DealsScreenState();
}

class _DealsScreenState extends State<DealsScreen> {
  final _searchController = TextEditingController();
  Timer? _searchDebounce;
  GamePlatform? _platform;
  List<Game> _games = [];
  Set<String> _favorites = {};
  String _searchQuery = '';
  bool _busy = true;
  bool _hasMore = false;
  int _page = 1;
  int _generation = 0;
  double? _maxPrice;
  String _sort = 'relevant';
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
    _searchDebounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  void _changed(String text) {
    _searchDebounce?.cancel();
    final query = text.trim();
    ++_generation;
    setState(() {
      _searchQuery = query;
      _games = [];
      _hasMore = false;
      _error = null;
      _warning = null;
      _busy = query.isEmpty || query.length >= 2;
    });
    if (query.isEmpty) {
      _load();
    } else if (query.length >= 2) {
      _searchDebounce = Timer(const Duration(milliseconds: 450), _load);
    }
  }

  Future<void> _load({bool more = false}) async {
    if (_searchQuery.length == 1) {
      ++_generation;
      setState(() {
        _busy = false;
        _games = [];
        _hasMore = false;
      });
      return;
    }
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
      final query = _searchQuery;
      final result = query.length >= 2
          ? await widget.repository
              .searchLiveDeals(query, platform: _platform, page: page)
          : await widget.repository
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
  Widget build(BuildContext context) => _platform == null
      ? _buildPage(context)
      : Theme(
          data: AppTheme.forPlatform(Theme.of(context), _platform!),
          child: Builder(builder: _buildPage));

  Widget _buildPage(BuildContext context) {
    final games = _games
        .where((g) => _maxPrice == null || g.currentPrice <= _maxPrice!)
        .toList();
    if (_sort == 'lowest') {
      games.sort((a, b) => a.currentPrice.compareTo(b.currentPrice));
    }
    if (_sort == 'discount') {
      games.sort((a, b) => (b.primaryEdition?.discountPercent ?? 0)
          .compareTo(a.primaryEdition?.discountPercent ?? 0));
    }
    return Scaffold(
      appBar: GamingHeader.adaptive(context,
          title: 'Ofertas Destacadas',
          subtitle:
              'Los mejores precios en juegos digitales para tus plataformas.',
          accent: _platform == null
              ? AppTheme.secondary
              : AppTheme.platformColor(_platform!),
          actions: [
            IconButton(
                tooltip: 'Actualizar desde la web',
                onPressed: _busy ? null : () => _load(),
                icon: const Icon(Icons.refresh_rounded))
          ]),
      body: RefreshIndicator(
          onRefresh: () => _load(),
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              SliverToBoxAdapter(
                  child: Column(children: [
                Padding(
                    padding: const EdgeInsets.fromLTRB(14, 12, 14, 4),
                    child: LiveGameAutocomplete(
                      key: ValueKey('deals_${_platform?.name ?? 'all'}'),
                      controller: _searchController,
                      hintText: 'Busca Tu oferta',
                      suggestions: (query) => widget.repository
                          .fetchAutocomplete(query, platform: _platform),
                      onChanged: _changed,
                      onSubmitted: (_) {
                        _searchDebounce?.cancel();
                        if (_searchQuery.length >= 2) _load();
                      },
                      onSelected: (selection) {
                        _searchDebounce?.cancel();
                        setState(() => _searchQuery = selection);
                        _load();
                      },
                    )),
                PlatformFilter(
                    selected: _platform,
                    onChanged: (p) {
                      setState(() => _platform = p);
                      _searchDebounce?.cancel();
                      _load();
                    }),
                Padding(
                    padding: const EdgeInsets.fromLTRB(14, 4, 14, 4),
                    child: Row(children: [
                      Expanded(
                          child: DropdownButtonFormField<double>(
                              initialValue: _maxPrice,
                              isExpanded: true,
                              decoration: const InputDecoration(
                                  contentPadding: EdgeInsets.symmetric(
                                      horizontal: 10, vertical: 8),
                                  isDense: true),
                              hint: const Text('Cualquier precio',
                                  style: TextStyle(fontSize: 11)),
                              items: [
                                const DropdownMenuItem<double>(
                                    value: null,
                                    child: Text('Cualquier precio',
                                        style: TextStyle(fontSize: 11))),
                                for (final price in [10.0, 20.0, 30.0, 50.0])
                                  DropdownMenuItem(
                                      value: price,
                                      child: Text('Hasta \$${price.toInt()}',
                                          style:
                                              const TextStyle(fontSize: 11))),
                              ],
                              onChanged: (value) =>
                                  setState(() => _maxPrice = value))),
                      const SizedBox(width: 8),
                      Expanded(
                          child: DropdownButtonFormField<String>(
                              initialValue: _sort,
                              isExpanded: true,
                              decoration: const InputDecoration(
                                  contentPadding: EdgeInsets.symmetric(
                                      horizontal: 10, vertical: 8),
                                  isDense: true),
                              items: const [
                                DropdownMenuItem(
                                    value: 'relevant',
                                    child: Text('Más relevantes',
                                        style: TextStyle(fontSize: 11))),
                                DropdownMenuItem(
                                    value: 'lowest',
                                    child: Text('Menor precio',
                                        style: TextStyle(fontSize: 11))),
                                DropdownMenuItem(
                                    value: 'discount',
                                    child: Text('Mayor descuento',
                                        style: TextStyle(fontSize: 11))),
                              ],
                              onChanged: (value) =>
                                  setState(() => _sort = value ?? 'relevant'))),
                    ])),
                const Padding(
                    padding: EdgeInsets.fromLTRB(16, 5, 16, 8),
                    child: Text(
                        'Precios USA · USD de Deku Deals. Confirma en la tienda.\nFiltros y orden sobre las ofertas consultadas.',
                        textAlign: TextAlign.center,
                        style:
                            TextStyle(color: AppTheme.textMuted, fontSize: 9))),
                if (_busy) const LinearProgressIndicator(minHeight: 2),
                if (_error != null)
                  Padding(
                      padding: const EdgeInsets.all(12), child: Text(_error!)),
                if (_warning != null && _games.isEmpty)
                  Padding(
                      padding: const EdgeInsets.all(8), child: Text(_warning!)),
                if (games.isEmpty && !_busy)
                  Padding(
                      padding: const EdgeInsets.all(24),
                      child: Text(
                          _error == null
                              ? _searchQuery.length == 1
                                  ? 'Escribe al menos dos caracteres para consultar ofertas.'
                                  : 'No hay descuentos digitales verificados en esta página con estos filtros.'
                              : 'No pudimos actualizar las ofertas. Pulsa Reintentar.',
                          textAlign: TextAlign.center)),
              ])),
              SliverList.builder(
                  itemCount: games.length,
                  itemBuilder: (context, index) {
                    final game = games[index];
                    return DealCard(
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
                                    repository: widget.repository))));
                  }),
              SliverToBoxAdapter(
                  child: Column(children: [
                if (_hasMore && _error == null)
                  TextButton(
                      onPressed: _busy ? null : () => _load(more: true),
                      child: const Text('Consultar más ofertas')),
                if (_error != null)
                  TextButton(
                      onPressed: _busy ? null : () => _load(),
                      child: const Text('Reintentar')),
                const SizedBox(height: 24),
              ])),
            ],
          )),
    );
  }
}
