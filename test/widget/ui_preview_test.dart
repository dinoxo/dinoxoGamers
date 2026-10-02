import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dinoxo_gamers/core/constants/app_constants.dart';
import 'package:dinoxo_gamers/core/theme/app_theme.dart';
import 'package:dinoxo_gamers/data/datasources/web_scraper_service.dart';
import 'package:dinoxo_gamers/domain/models/game.dart';
import 'package:dinoxo_gamers/ui/navigation/main_shell.dart';
import '../fixtures/test_repository.dart';

class _PreviewRepository extends TestRepository {
  _PreviewRepository(this.games);
  final List<Game> games;
  @override
  Future<LiveCatalogPage> refreshLiveDeals(
          {GamePlatform? platform, int page = 1}) async =>
      LiveCatalogPage(games
          .where((g) => platform == null || g.platform == platform)
          .toList());
}

class _RealImageHttp extends HttpOverrides {}

void main() {
  testWidgets('opt-in visual preview with archived real USA catalog entries',
      (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    SharedPreferences.setMockInitialValues(
        {'has_seen_permissions_notice': true});
    late HttpClient imageClient;
    await tester.runAsync(() => HttpOverrides.runWithHttpOverrides(() async {
          imageClient = HttpClient();
          final fonts =
              Directory('/sdks/flutter/bin/cache/artifacts/material_fonts');
          final roboto = FontLoader('Roboto');
          for (final name in [
            'Roboto-Regular.ttf',
            'Roboto-Bold.ttf',
            'Roboto-Black.ttf'
          ]) {
            roboto.addFont(Future.value(ByteData.sublistView(
                await File('${fonts.path}/$name').readAsBytes())));
          }
          await roboto.load();
          final icons = FontLoader('MaterialIcons')
            ..addFont(Future.value(ByteData.sublistView(
                await File('${fonts.path}/MaterialIcons-Regular.otf')
                    .readAsBytes())));
          await icons.load();
        }, _RealImageHttp()));
    debugNetworkImageHttpClientProvider = () => imageClient;
    addTearDown(() {
      debugNetworkImageHttpClientProvider = null;
      imageClient.close();
    });
    final games = <Game>[];
    await tester.runAsync(() async {
      final manifest = jsonDecode(
          await File('build/live-probe/manifest.json').readAsString()) as List;
      for (final entry in manifest) {
        final parsed = LiveWebScraperService.parseItem(
            await File('build/live-probe/${entry['file']}').readAsString(),
            Uri.parse(entry['url'] as String),
            DateTime.now());
        for (final game in parsed) {
          if (!games.any((g) => g.platform == game.platform)) games.add(game);
        }
      }
    });
    expect(
        games.map((g) => g.platform).toSet(), containsAll(GamePlatform.values));
    final previewKey = GlobalKey();
    await tester.pumpWidget(RepaintBoundary(
        key: previewKey,
        child: MaterialApp(
            debugShowCheckedModeBanner: false,
            theme: AppTheme.darkTheme.copyWith(
                textTheme:
                    AppTheme.darkTheme.textTheme.apply(fontFamily: 'Roboto')),
            home: MainShell(repository: _PreviewRepository(games)))));
    await tester.runAsync(() => HttpOverrides.runWithHttpOverrides(() async {
          final context = previewKey.currentContext!;
          await precacheImage(
              const AssetImage('assets/images/dinoxo_store_badge.png'),
              context);
          for (final game in games) {
            if (game.coverUrl.isNotEmpty) {
              await precacheImage(
                  ResizeImage(NetworkImage(game.coverUrl), width: 369), context,
                  onError: (_, __) {});
            }
          }
        }, _RealImageHttp()));
    await tester.pumpAndSettle();
    Future<void> save(String name) async {
      await tester.runAsync(() async {
        final image = await (previewKey.currentContext!.findRenderObject()!
                as RenderRepaintBoundary)
            .toImage(pixelRatio: 2);
        final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
        final file = File('build/ui-preview/$name.png');
        await file.parent.create(recursive: true);
        await file.writeAsBytes(bytes!.buffer.asUint8List());
        image.dispose();
      });
    }

    await save('ofertas');
    await tester.tap(find.text('Más'));
    await tester.pumpAndSettle();
    await tester.runAsync(() => precacheImage(
        const ResizeImage(AssetImage('assets/images/dinoxo_store_badge.png'),
            width: 336),
        previewKey.currentContext!));
    await tester.pumpAndSettle();
    await save('mas');
    debugNetworkImageHttpClientProvider = null;
    expect(tester.takeException(), isNull);
  }, skip: !const bool.fromEnvironment('UI_PREVIEW'));
}
