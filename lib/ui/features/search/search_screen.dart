import 'dart:async';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../../domain/services/ocr_service.dart';
import '../../../core/constants/app_constants.dart';
import '../../../data/datasources/web_scraper_service.dart';
import '../../../data/repositories/game_repository.dart';
import '../../../domain/models/game.dart';
import '../../core/widgets/deal_card.dart';
import '../game_details/game_details_screen.dart';

class SearchScreen extends StatefulWidget {
  final GameRepository repository;
  const SearchScreen({super.key, required this.repository});
  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final _controller = TextEditingController();
  Timer? _debounce;
  int _generation = 0;
  int _page = 1;
  bool _busy = false;
  bool _hasMore = false;
  String? _error;
  String? _warning;
  GamePlatform? _platform;
  List<Game> _games = [];
  Set<String> _favorites = {};
  bool _readingPhoto = false;

  Future<void> _photo(ImageSource source) async {
    setState(() => _readingPhoto = true);
    try {
      final photo = await ImagePicker()
          .pickImage(source: source, maxWidth: 1800, imageQuality: 90);
      if (photo == null) return;
      final lines = await OcrService.recognizeText(photo.path);
      if (!mounted) return;
      if (lines.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text(
                'No se pudo leer el título. Prueba con una foto más clara.')));
        return;
      }
      final query = await showDialog<String>(
          context: context, builder: (_) => _PhotoQueryDialog(lines: lines));
      if (!mounted || query == null) return;
      _controller.text = query;
      _changed(query);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text(
                'No se pudo leer la foto. Revisa los permisos de cámara o busca por texto.')));
      }
    } finally {
      if (mounted) setState(() => _readingPhoto = false);
    }
  }

  @override
  void dispose() {
    _generation++;
    _debounce?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _changed(String value) {
    _debounce?.cancel();
    _generation++;
    setState(() {
      _games = [];
      _hasMore = false;
      _error = null;
      _warning = null;
      _busy = value.trim().length >= 2;
    });
    if (value.trim().length >= 2) {
      _debounce = Timer(const Duration(milliseconds: 600), () => _search());
    }
  }

  Future<void> _search({bool more = false}) async {
    _debounce?.cancel();
    final query = _controller.text.trim();
    if (query.length < 2) return;
    final generation = ++_generation;
    final page = more ? _page + 1 : 1;
    setState(() {
      _busy = true;
      _error = null;
      _warning = null;
      if (!more) _games = [];
    });
    try {
      final result = await widget.repository
          .searchOnline(query, platform: _platform, page: page);
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
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Buscar Juegos'), actions: [
          IconButton(
              tooltip: 'Leer título con la cámara',
              onPressed:
                  _readingPhoto ? null : () => _photo(ImageSource.camera),
              icon: const Icon(Icons.camera_alt_outlined)),
          IconButton(
              tooltip: 'Leer título de una imagen',
              onPressed:
                  _readingPhoto ? null : () => _photo(ImageSource.gallery),
              icon: const Icon(Icons.photo_outlined)),
        ]),
        body: Column(children: [
          Padding(
              padding: const EdgeInsets.all(12),
              child: TextField(
                controller: _controller,
                onChanged: _changed,
                onSubmitted: (_) => _search(),
                textInputAction: TextInputAction.search,
                decoration: InputDecoration(
                    hintText: 'Wolverine, Pokémon, Halo…',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _controller.clear();
                          _changed('');
                        })),
              )),
          SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12),
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
                            _changed(_controller.text);
                          })),
              ])),
          const Padding(
              padding: EdgeInsets.all(8),
              child: Text('USA · USD · Consulta web en Deku Deals')),
          if (_busy || _readingPhoto) const LinearProgressIndicator(),
          if (_error != null)
            Padding(
                padding: const EdgeInsets.all(12),
                child: Text(_error!, key: const Key('search-error'))),
          if (_warning != null)
            Padding(padding: const EdgeInsets.all(8), child: Text(_warning!)),
          Expanded(
              child: RefreshIndicator(
                  onRefresh: () => _search(),
                  child: ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      children: [
                        if (_games.isEmpty && !_busy)
                          Padding(
                              padding: const EdgeInsets.all(24),
                              child: Text(
                                  _controller.text.trim().length < 2
                                      ? 'Escribe al menos dos caracteres para buscar juegos en las tres consolas.'
                                      : _error != null
                                          ? 'La consulta no terminó. No equivale a que el juego no exista.'
                                          : 'No hay precios o fichas disponibles en esta página. Puedes consultar más resultados.',
                                  textAlign: TextAlign.center)),
                        for (final game in _games)
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
                              onPressed:
                                  _busy ? null : () => _search(more: true),
                              child: const Text('Cargar más resultados')),
                        if (_error != null)
                          TextButton(
                              onPressed: _busy ? null : () => _search(),
                              child: const Text('Reintentar búsqueda')),
                        const SizedBox(height: 24),
                      ]))),
        ]),
      );
}

class _PhotoQueryDialog extends StatefulWidget {
  final List<String> lines;
  const _PhotoQueryDialog({required this.lines});
  @override
  State<_PhotoQueryDialog> createState() => _PhotoQueryDialogState();
}

class _PhotoQueryDialogState extends State<_PhotoQueryDialog> {
  final _edit = TextEditingController();
  @override
  void dispose() {
    _edit.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
          title: const Text('Confirma el título'),
          content: SingleChildScrollView(
              child: Column(mainAxisSize: MainAxisSize.min, children: [
            const Text(
                'Selecciona el texto del juego; puedes corregirlo antes de buscar.'),
            Wrap(
                spacing: 6,
                children: widget.lines
                    .take(20)
                    .map((s) => ActionChip(
                        label: Text(s), onPressed: () => _edit.text = s))
                    .toList()),
            TextField(
                controller: _edit,
                decoration:
                    const InputDecoration(labelText: 'Título del juego')),
          ])),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancelar')),
            TextButton(
                onPressed: () {
                  if (_edit.text.trim().length >= 2) {
                    Navigator.pop(context, _edit.text.trim());
                  }
                },
                child: const Text('Buscar en la web'))
          ]);
}
