import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/game.dart';
import '../models/game_media.dart';
import 'subscription_title.dart';

class GameMediaService {
  GameMediaService({http.Client? client}) : _client = client ?? http.Client();
  static final instance = GameMediaService();
  final http.Client _client;
  final Map<String, Future<GameMedia>> _pending = {};
  final Map<String, GameMedia> _cache = {};
  void close() => _client.close();

  Future<GameMedia> fetchMedia(Game game) async {
    final key = '${game.id}|${game.title}|${game.coverUrl}';
    if (_cache[key] case final media?) return media;
    return _pending.putIfAbsent(
        key,
        () => _fetch(game).then((media) {
              _cache[key] = media;
              _pending.remove(key);
              return media;
            }));
  }

  Future<GameMedia> _fetch(Game game) async {
    var screenshots = <String>[];
    String? trailerThumbnail;
    final titleKey = subscriptionTitleKey(game.title);
    try {
      final searchUri = Uri.https('store.steampowered.com', '/api/storesearch/',
          {'term': game.title, 'l': 'english', 'cc': 'US'});
      final response =
          await _client.get(searchUri).timeout(const Duration(seconds: 4));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map;
        final matches = (data['items'] as List? ?? [])
            .where((item) =>
                subscriptionTitleKey(item['name'] as String? ?? '') == titleKey)
            .toList();
        // Never select the first fuzzy search result or erase edition/sequel names.
        if (matches.length == 1) {
          final appId = matches.single['id'];
          final detailsUri = Uri.https(
              'store.steampowered.com',
              '/api/appdetails',
              {'appids': '$appId', 'cc': 'US', 'l': 'english'});
          final details =
              await _client.get(detailsUri).timeout(const Duration(seconds: 4));
          if (details.statusCode == 200) {
            final entry = (jsonDecode(details.body) as Map)['$appId'] as Map?;
            final app = entry?['data'] as Map?;
            if (entry?['success'] == true &&
                app != null &&
                subscriptionTitleKey(app['name'] as String? ?? '') ==
                    titleKey) {
              screenshots = (app['screenshots'] as List? ?? [])
                  .map((s) => s['path_full'] ?? s['path_thumbnail'])
                  .whereType<String>()
                  .where(_https)
                  .toSet()
                  .take(12)
                  .toList();
              final movies = app['movies'] as List? ?? [];
              if (movies.isNotEmpty) {
                final image = movies.first['thumbnail'] as String?;
                if (image != null && _https(image)) trailerThumbnail = image;
              }
            }
          }
        }
      }
    } catch (_) {
      // No verified gallery is preferable to pictures from a different game.
    }
    return GameMedia(
        screenshots: screenshots,
        trailer: GameVideo(
            title: 'Buscar tráiler · ${game.title}',
            tag: 'Buscar tráiler',
            channelOrSource: 'Búsqueda en YouTube',
            videoUrl: Uri.https('www.youtube.com', '/results',
                {'search_query': '${game.title} official trailer'}).toString(),
            thumbnailUrl: trailerThumbnail ?? game.coverUrl),
        reviewVideo: GameVideo(
            title: 'Buscar reseñas · ${game.title}',
            tag: 'Buscar reseñas',
            channelOrSource: 'Búsqueda en YouTube',
            videoUrl: Uri.https('www.youtube.com', '/results', {
              'search_query': '${game.title} video review analisis espanol'
            }).toString(),
            thumbnailUrl: game.coverUrl));
  }

  static bool _https(String value) => Uri.tryParse(value)?.scheme == 'https';
}
