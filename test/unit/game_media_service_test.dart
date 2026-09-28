import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:dinoxo_gamers/core/constants/app_constants.dart';
import 'package:dinoxo_gamers/domain/models/game.dart';
import 'package:dinoxo_gamers/domain/services/game_media_service.dart';

const game = Game(
    id: 'ghost_media',
    title: "Ghost of Tsushima DIRECTOR'S CUT",
    slug: 'ghost',
    coverUrl: '',
    platform: GamePlatform.playstation,
    consoles: ['PS5'],
    genres: [],
    developer: '',
    publisher: '',
    releaseDate: null);

void main() {
  test('accepts only images from a uniquely matching Steam name and details',
      () async {
    var calls = 0;
    final service = GameMediaService(client: MockClient((request) async {
      calls++;
      if (request.url.path.contains('storesearch')) {
        expect(request.url.queryParameters['term'], game.title);
        return http.Response(
            jsonEncode({
              'items': [
                {'id': 1, 'name': 'The Legend of Zelda: Breath of the Wild'},
                {'id': 2, 'name': game.title},
              ]
            }),
            200);
      }
      expect(request.url.queryParameters['appids'], '2');
      return http.Response(
          jsonEncode({
            '2': {
              'success': true,
              'data': {
                'name': game.title,
                'screenshots': [
                  {'path_full': 'https://cdn.steampowered.com/ghost-1.jpg'},
                  {'path_full': 'http://unsafe/image.jpg'}
                ]
              }
            }
          }),
          200);
    }));
    final media = await service.fetchMedia(game);
    expect(media.screenshots, ['https://cdn.steampowered.com/ghost-1.jpg']);
    await service.fetchMedia(game);
    expect(calls, 2);
  });
  test('different sequel or details name never supplies a gallery', () async {
    for (final badSearch in [true, false]) {
      final service = GameMediaService(
          client: MockClient((request) async => http.Response(
              jsonEncode(request.url.path.contains('storesearch')
                  ? {
                      'items': [
                        {
                          'id': 2,
                          'name': badSearch ? 'Ghost of Tsushima 2' : game.title
                        }
                      ]
                    }
                  : {
                      '2': {
                        'success': true,
                        'data': {
                          'name': 'The Legend of Zelda: Breath of the Wild',
                          'screenshots': [
                            {'path_full': 'https://example.com/zelda.jpg'}
                          ]
                        }
                      }
                    }),
              200)));
      expect((await service.fetchMedia(game)).screenshots, isEmpty);
    }
  });
  test('a remastered edition is not replaced with the original game', () async {
    const remaster = Game(
        id: 'remaster',
        title: 'Example Remastered',
        slug: 'example',
        coverUrl: '',
        platform: GamePlatform.xbox,
        consoles: ['Xbox One'],
        genres: [],
        developer: '',
        publisher: '',
        releaseDate: null);
    final service = GameMediaService(
        client: MockClient((_) async =>
            http.Response('{"items":[{"id":1,"name":"Example"}]}', 200)));
    expect((await service.fetchMedia(remaster)).screenshots, isEmpty);
  });
}
