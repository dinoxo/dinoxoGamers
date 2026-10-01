import 'dart:async';
import '../../../domain/services/subscription_title.dart';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/theme/app_theme.dart';
import '../../../domain/services/ocr_service.dart';
import '../../../domain/services/gemini_image_service.dart';
import '../../../domain/services/gemini_key_store.dart';
import '../../../core/constants/app_constants.dart';
import '../../../data/datasources/web_scraper_service.dart';
import '../../../data/repositories/game_repository.dart';
import '../../../domain/models/game.dart';
import '../../core/widgets/deal_card.dart';
import '../../core/widgets/live_game_autocomplete.dart';
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
        _showPhotoError(OcrService.errorMessage(lost.exception!));
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
          : await ImagePicker().pickImage(
              source: source,
              maxWidth: 2048,
              maxHeight: 2048,
              imageQuality: 85);
      if (mounted && photo != null) await _readPhoto(photo);
    } catch (error) {
      _showPhotoError(OcrService.errorMessage(error));
    } finally {
      _photoFlow = false;
      if (mounted) setState(() => _readingPhoto = false);
    }
  }

  Future<void> _readPhoto(XFile photo) async {
    if (!mounted) return;
    PhotoRecognition? visualResult;
    String? visualError;
    if (widget.readPhoto == null) {
      try {
        final key = await GeminiKeyStore.activeKey();
        if (key != null) {
          final length = await photo.length();
          if (length > GeminiImageService.maxImageBytes) {
            throw const GeminiImageException(
                'La foto supera el límite de Gemini; se intentará leer localmente.');
          }
          final bytes = await photo.readAsBytes();
          final mime = GeminiImageService.detectImageMime(bytes);
          if (mime == null) {
            throw const GeminiImageException(
                'Gemini no reconoce el formato de esta foto.');
          }
          final gemini = GeminiImageService();
          try {
            final titles =
                await gemini.identifyGames(bytes, mimeType: mime, apiKey: key);
            if (titles.isNotEmpty) visualResult = PhotoRecognition(titles);
          } finally {
            gemini.close();
          }
        }
      } on GeminiImageException catch (error) {
        visualError = error.message;
      } catch (_) {
        visualError = 'Gemini no pudo analizar la foto.';
      }
    }
    try {
      final recognition = visualResult ??
          (widget.readPhoto == null
              ? await OcrService.recognizePhoto(photo.path)
              : PhotoRecognition(await widget.readPhoto!(photo.path)
                  .timeout(const Duration(seconds: 20))));
      await _searchRecognizedPhoto(recognition);
    } catch (error) {
      _showPhotoError(visualError == null
          ? OcrService.errorMessage(error)
          : '$visualError ${OcrService.errorMessage(error)}');
    }
  }

  Future<void> _showPhotoSettings() async {
    final controller = TextEditingController();
    bool enabled = false;
    try {
      enabled = await GeminiKeyStore.isEnabled();
    } catch (_) {}
    if (!mounted) {
      controller.dispose();
      return;
    }
    await showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        builder: (sheetContext) => SafeArea(
                child: Padding(
              padding: EdgeInsets.fromLTRB(20, 20, 20,
                  MediaQuery.viewInsetsOf(sheetContext).bottom + 20),
              child: SingleChildScrollView(
                  child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                    Text('Lectura de fotos',
                        style: Theme.of(sheetContext).textTheme.titleLarge),
                    const SizedBox(height: 10),
                    Text(enabled
                        ? 'Gemini con tu clave personal está activo.'
                        : 'Por defecto, el lector gratuito analiza la foto en tu teléfono.'),
                    const SizedBox(height: 8),
                    const Text(
                        'Si activas Gemini, la foto se envía a Google para '
                        'identificar hasta tres juegos. La app comprueba luego los '
                        'títulos en el catálogo USA. El plan gratuito tiene límites.'),
                    const SizedBox(height: 14),
                    TextField(
                        controller: controller,
                        obscureText: true,
                        enableSuggestions: false,
                        autocorrect: false,
                        decoration: const InputDecoration(
                            labelText: 'Tu clave API de Gemini')),
                    const SizedBox(height: 12),
                    Wrap(spacing: 8, children: [
                      TextButton(
                          onPressed: () async {
                            await GeminiKeyStore.useLocalReader();
                            if (sheetContext.mounted) {
                              Navigator.pop(sheetContext);
                            }
                          },
                          child: const Text('Usar lector gratuito')),
                      FilledButton(
                          onPressed: () async {
                            try {
                              await GeminiKeyStore.save(controller.text);
                              if (sheetContext.mounted) {
                                Navigator.pop(sheetContext);
                              }
                            } catch (_) {
                              if (sheetContext.mounted) {
                                ScaffoldMessenger.of(sheetContext).showSnackBar(
                                    const SnackBar(
                                        content: Text(
                                            'No se pudo guardar la clave. Revisa el texto e inténtalo.')));
                              }
                            }
                          },
                          child: const Text('Guardar y usar Gemini')),
                      TextButton(
                          onPressed: () async {
                            await GeminiKeyStore.deleteKey();
                            if (sheetContext.mounted) {
                              Navigator.pop(sheetContext);
                            }
                          },
                          child: const Text('Borrar clave')),
                    ]),
                  ])),
            )));
    controller.dispose();
  }

  void _showPhotoError(String message) {
    if (!mounted) return;
    setState(() => _error = message);
  }

  static String _photoKey(String title) => subscriptionTitleKey(title)
      .replaceAll(RegExp(r'[áàâäãå]'), 'a')
      .replaceAll(RegExp(r'[éèêë]'), 'e')
      .replaceAll(RegExp(r'[íìîï]'), 'i')
      .replaceAll(RegExp(r'[óòôöõ]'), 'o')
      .replaceAll(RegExp(r'[úùûü]'), 'u');

  Future<void> _searchRecognizedPhoto(PhotoRecognition recognition) async {
    if (!mounted) return;
    final candidates = recognition.candidates
        .map((line) => line.trim())
        .where((line) => line.length >= 2 && line.length <= 160)
        .take(8)
        .toList();
    if (candidates.isEmpty) {
      _showPhotoError(
          'No se reconoció un juego en la imagen. Prueba otra foto o escribe el título.');
      return;
    }
    final checks = await Future.wait(candidates.map((candidate) async {
      try {
        final suggestions = await widget.repository
            .fetchAutocomplete(candidate, platform: recognition.platform)
            .timeout(const Duration(seconds: 5));
        return suggestions
            .where((title) => _photoKey(title) == _photoKey(candidate))
            .toList();
      } catch (_) {
        // A failed suggestion request must not suppress the actual title search.
        return <String>[];
      }
    }));
    final verified = checks.expand((titles) => titles).toSet();
    if (!mounted) return;
    final titles = verified
        .where((title) => !verified.any((other) =>
            other != title && _photoKey(other).contains(_photoKey(title))))
        .take(3)
        .toList();
    final query = titles.isEmpty ? candidates.first : titles.first;
    _controller.text = query;
    setState(() {
      _platform = recognition.platform;
      _error = null;
    });
    if (titles.length > 1) {
      await _searchPhotoTitles(titles);
    } else {
      await _search(openPhotoMatch: true);
    }
  }

  Future<void> _searchPhotoTitles(List<String> titles) async {
    final generation = ++_generation;
    setState(() {
      _busy = true;
      _games = [];
      _error = null;
    });
    try {
      final pages = await Future.wait(titles.map((title) async {
        try {
          return await widget.repository
              .searchOnline(title, platform: _platform);
        } catch (e) {
          return LiveCatalogPage(const [], warnings: [
            e is CatalogException ? e.message : 'No se pudo consultar $title.'
          ]);
        }
      }));
      final favorites = await widget.repository.getFavoriteGames();
      if (!mounted || generation != _generation) return;
      setState(() {
        _games = {for (final g in pages.expand((p) => p.games)) g.id: g}
            .values
            .toList();
        _favorites = favorites.map((g) => g.id).toSet();
        _hasMore = pages.any((p) => p.hasMore);
        final warnings = pages.expand((p) => p.warnings).toList();
        _warning = warnings.isEmpty ? null : warnings.join('\n');
      });
    } catch (e) {
      if (mounted && generation == _generation) {
        _showPhotoError(e is CatalogException
            ? e.message
            : 'No se pudieron consultar los juegos reconocidos. Reintenta.');
      }
    } finally {
      if (mounted && generation == _generation) setState(() => _busy = false);
    }
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
            .where((game) => _photoKey(game.title) == _photoKey(query))
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
              tooltip: 'Configurar análisis de fotos',
              onPressed: _readingPhoto ? null : _showPhotoSettings,
              icon: const Icon(Icons.auto_awesome_outlined)),
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
              child: LiveGameAutocomplete(
                key: ValueKey('search_${_platform?.name ?? 'all'}'),
                controller: _controller,
                hintText: 'Escribe Tu Juego',
                suggestions: (query) => widget.repository
                    .fetchAutocomplete(query, platform: _platform),
                onSelected: (selection) {
                  _controller.text = selection;
                  _search();
                },
                onChanged: _changed,
                onSubmitted: (_) => _search(),
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
