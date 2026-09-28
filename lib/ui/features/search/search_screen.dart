import 'dart:async';
import '../../../domain/services/subscription_title.dart';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/theme/app_theme.dart';
import '../../../domain/services/ocr_service.dart';
import '../../../core/constants/app_constants.dart';
import '../../../data/datasources/web_scraper_service.dart';
import '../../../data/repositories/game_repository.dart';
import '../../../domain/models/game.dart';
import '../../core/widgets/deal_card.dart';
import '../game_details/game_details_screen.dart';

class SearchScreen extends StatefulWidget {
  final GameRepository repository;
  final Future<XFile?> Function(ImageSource)? pickPhoto;
  final Future<List<String>> Function(String)? readPhoto;
  final VoidCallback? onRecoveredPhoto;
  const SearchScreen(
      {super.key,
      required this.repository,
      this.pickPhoto,
      this.readPhoto,
      this.onRecoveredPhoto});
  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final _controller = TextEditingController();
  TextEditingController? _autoController;
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
  bool _photoFlow = false;

  @override
  void initState() {
    super.initState();
    if (Platform.isAndroid) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _restorePhoto());
    }
  }

  Future<void> _restorePhoto() async {
    if (_photoFlow) return;
    _photoFlow = true;
    try {
      final lost = await ImagePicker().retrieveLostData();
      if (!mounted || lost.isEmpty) return;
      widget.onRecoveredPhoto?.call();
      if (lost.files?.isNotEmpty == true) {
        setState(() => _readingPhoto = true);
        await _readPhoto(lost.files!.first);
      } else if (lost.exception != null) {
        await _confirmPhoto([],
            error: OcrService.errorMessage(lost.exception!));
      }
    } catch (_) {
      // No pending selection is a normal state when the picker was not used.
    } finally {
      _photoFlow = false;
      if (mounted) setState(() => _readingPhoto = false);
    }
  }

  Future<void> _photo(ImageSource source) async {
    if (!mounted || _photoFlow) return;
    _photoFlow = true;
    setState(() => _readingPhoto = true);
    try {
      final photo = widget.pickPhoto != null
          ? await widget.pickPhoto!(source)
          : await ImagePicker().pickImage(source: source);
      if (mounted && photo != null) await _readPhoto(photo);
    } catch (error) {
      await _confirmPhoto([], error: OcrService.errorMessage(error));
    } finally {
      _photoFlow = false;
      if (mounted) setState(() => _readingPhoto = false);
    }
  }

  Future<void> _readPhoto(XFile photo) async {
    if (!mounted) return;
    try {
      final recognition = widget.readPhoto == null
          ? await OcrService.recognizePhoto(photo.path)
          : PhotoRecognition(await widget.readPhoto!(photo.path)
              .timeout(const Duration(seconds: 20)));
      final lines = recognition.candidates;
      await _confirmPhoto(lines,
          platform: recognition.platform,
          error: lines.isEmpty
              ? 'No se reconoció texto en la imagen. Escribe el título o prueba una foto donde se vea con claridad.'
              : null);
    } catch (error) {
      await _confirmPhoto([], error: OcrService.errorMessage(error));
    }
  }

  Future<void> _confirmPhoto(List<String> lines,
      {String? error, GamePlatform? platform}) async {
    if (!mounted) return;
    setState(() => _readingPhoto = false);

    final query = await showDialog<String>(
        context: context,
        builder: (_) => _PhotoQueryDialog(lines: lines, error: error));

    if (!mounted || query == null || query.trim().isEmpty) return;
    _controller.text = query.trim();
    _autoController?.text = query.trim();
    setState(() => _platform = platform);
    await _search(openPhotoMatch: true);
  }

  @override
  void dispose() {
    if (_readingPhoto && widget.readPhoto == null) {
      unawaited(OcrService.cancelRecognition());
    }
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

  Future<void> _search({bool more = false, bool openPhotoMatch = false}) async {
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
      if (openPhotoMatch) {
        final matches = result.games
            .where((game) =>
                subscriptionTitleKey(game.title) == subscriptionTitleKey(query))
            .toList();
        if (matches.length == 1 && !result.hasMore && result.warnings.isEmpty) {
          unawaited(Navigator.push(
              context,
              MaterialPageRoute<void>(
                  builder: (_) => GameDetailsScreen(
                      game: matches.single, repository: widget.repository))));
        }
      }
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

  Widget _buildPage(BuildContext context) => Scaffold(
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
              child: Autocomplete<String>(
                optionsBuilder: (textEditingValue) async {
                  final query = textEditingValue.text.trim();
                  if (query.length < 2) return const Iterable<String>.empty();
                  return await widget.repository.fetchAutocomplete(query);
                },
                onSelected: (selection) {
                  _controller.text = selection;
                  _search();
                },
                fieldViewBuilder: (context, textEditingController, focusNode, onFieldSubmitted) {
                  _autoController = textEditingController;
                  return TextField(
                    controller: textEditingController,
                    focusNode: focusNode,
                    onChanged: (value) {
                      _controller.text = value;
                      _changed(value);
                    },
                    onSubmitted: (_) {
                      onFieldSubmitted();
                      _search();
                    },
                    textInputAction: TextInputAction.search,
                    decoration: InputDecoration(
                        hintText: 'Escribe Tu Juego',
                        prefixIcon: const Icon(Icons.search),
                        suffixIcon: IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              textEditingController.clear();
                              _controller.clear();
                              _changed('');
                            })),
                  );
                },
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
  final String? error;
  const _PhotoQueryDialog({required this.lines, this.error});
  @override
  State<_PhotoQueryDialog> createState() => _PhotoQueryDialogState();
}

class _PhotoQueryDialogState extends State<_PhotoQueryDialog> {
  final _edit = TextEditingController();
  @override
  void initState() {
    super.initState();
    if (widget.lines.isNotEmpty) _edit.text = widget.lines.first;
  }

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
            Text(widget.error ??
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
