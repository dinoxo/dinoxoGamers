import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dinoxo_gamers/main.dart';
import '../fixtures/test_repository.dart';
import '../fixtures/prepare_brand_image.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({'has_seen_permissions_notice': true});
  });
  Future<void> capture(WidgetTester tester, String name) async {
    if (!const bool.fromEnvironment('SAVE_BRAND_PREVIEW')) return;
    final boundary = tester.renderObject<RenderRepaintBoundary>(
        find.byKey(const Key('brand-intro')));
    await tester.runAsync(() async {
      final screenshot = await boundary.toImage(pixelRatio: 2);
      final data = await screenshot.toByteData(format: ui.ImageByteFormat.png);
      final file = File('build/branding/$name.png');
      await file.parent.create(recursive: true);
      await file.writeAsBytes(data!.buffer.asUint8List());
      screenshot.dispose();
    });
  }

  testWidgets('cold start reveals the logo, then the name, then the app',
      (tester) async {
    final previousDisableShadows = debugDisableShadows;
    try {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      if (const bool.fromEnvironment('SAVE_BRAND_PREVIEW')) {
        debugDisableShadows = false;
        await tester.runAsync(() async {
          final font = await File(
                  '/sdks/flutter/bin/cache/artifacts/material_fonts/Roboto-Regular.ttf')
              .readAsBytes();
          await (FontLoader('Roboto')
                ..addFont(Future.value(ByteData.sublistView(font))))
              .load();
        });
      }
      await tester.pumpWidget(DinoxoGamersApp(repository: TestRepository()));
      await prepareBrandImage(tester);
      expect(find.byKey(const Key('brand-intro')), findsOneWidget);
      expect(find.byKey(const Key('brand-logo')), findsOneWidget);
      final reveal = tester
          .widget<FadeTransition>(find.byKey(const Key('brand-name-reveal')));
      expect(reveal.opacity.value, 0);
      await tester.pump(const Duration(milliseconds: 700));
      await capture(tester, 'intro-logo');
      await tester.pump(const Duration(milliseconds: 1100));
      await capture(tester, 'intro-wordmark');
      expect(reveal.opacity.value, greaterThan(.9));
      expect(find.text('dinoxo.Store'), findsOneWidget);
      await tester.pump(const Duration(milliseconds: 1000));
      await tester.pump();
      expect(find.byKey(const Key('brand-intro')), findsNothing);
      expect(find.text('Ofertas Destacadas'), findsOneWidget);
    } finally {
      debugDisableShadows = previousDisableShadows;
    }
  });

  testWidgets(
      'minimize and resume preserves the selected tab without replaying intro',
      (tester) async {
    await tester.pumpWidget(DinoxoGamersApp(repository: TestRepository()));
    await prepareBrandImage(tester);
    await tester.pump(const Duration(seconds: 3));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Buscar'));
    await tester.pumpAndSettle();
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pump();
    expect(find.byKey(const Key('brand-intro')), findsNothing);
    expect(find.text('Buscar Juegos'), findsOneWidget);
  });

  testWidgets(
      'minimizing during the introduction dismisses it before returning',
      (tester) async {
    await tester.pumpWidget(DinoxoGamersApp(repository: TestRepository()));
    await prepareBrandImage(tester);
    expect(find.byKey(const Key('brand-intro')), findsOneWidget);
    await tester.pump(const Duration(milliseconds: 250));
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('brand-intro')), findsNothing);
    expect(find.text('Ofertas Destacadas'), findsOneWidget);
  });
}
