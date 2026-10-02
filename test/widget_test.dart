import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'fixtures/test_repository.dart';
import 'fixtures/prepare_brand_image.dart';
import 'package:dinoxo_gamers/main.dart';

void main() {
  testWidgets('DinoxoGamersApp boots up successfully with Plus tab',
      (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues(
        {'has_seen_permissions_notice': true});
    final repo = TestRepository();
    await tester.pumpWidget(DinoxoGamersApp(repository: repo));
    await prepareBrandImage(tester);
    await tester.pump();
    await tester.pump(const Duration(seconds: 3));
    await tester.pumpAndSettle();

    // Verify Ofertas title appears in AppBar
    expect(find.text('Ofertas Destacadas'), findsOneWidget);
    // Verify Bottom Navigation items including new Plus tab
    expect(find.text('Ofertas'), findsOneWidget);
    expect(find.text('Buscar'), findsOneWidget);
    expect(find.text('Plus'), findsOneWidget);
    expect(find.text('Mis Alertas'), findsOneWidget);
    expect(find.text('Más'), findsOneWidget);
    expect(find.text('Noticias'), findsNothing);
    expect(find.text('Dinoxo Store'), findsNothing);
  });

  testWidgets('Más exposes the remaining modules and returns to the same tab',
      (tester) async {
    SharedPreferences.setMockInitialValues(
        {'has_seen_permissions_notice': true});
    await tester.pumpWidget(DinoxoGamersApp(repository: TestRepository()));
    await prepareBrandImage(tester);
    await tester.pump(const Duration(seconds: 3));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Más'));
    await tester.pumpAndSettle();
    expect(find.text('Noticias'), findsOneWidget);
    expect(find.text('Dinoxo Store'), findsOneWidget);
    expect(find.text('Mi Biblioteca'), findsOneWidget);
    expect(find.text('Acerca de Dinoxo Gamers'), findsOneWidget);
    await tester.tap(find.text('Mi Biblioteca'));
    await tester.pumpAndSettle();
    expect(find.text('Biblioteca y Herramientas'), findsOneWidget);
    await tester.pageBack();
    await tester.pumpAndSettle();
    final navigation =
        tester.widget<BottomNavigationBar>(find.byType(BottomNavigationBar));
    expect(navigation.currentIndex, 5);
    expect(find.text('Noticias'), findsOneWidget);
    await tester.tap(find.text('Dinoxo Store'));
    await tester.pumpAndSettle();
    expect(find.text('Dinoxo Store USA'), findsOneWidget);
    await tester.pageBack();
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Acerca de Dinoxo Gamers'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Acerca de Dinoxo Gamers'));
    await tester.pumpAndSettle();
    expect(find.byType(AlertDialog), findsOneWidget);
    await tester.tap(find.text('Cerrar'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });

  testWidgets('DinoxoGamersApp shows first run permissions dialog',
      (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues(
        {'has_seen_permissions_notice': false});
    final repo = TestRepository();
    await tester.pumpWidget(DinoxoGamersApp(repository: repo));
    await prepareBrandImage(tester);
    await tester.pump();
    await tester.pump(const Duration(seconds: 3));
    await tester.pumpAndSettle();

    // Verify Permissions notice dialog is shown
    expect(find.text('Permisos en Dinoxo Gamers'), findsOneWidget);
    expect(find.text('Notificaciones (Recomendado)'), findsOneWidget);
    expect(find.text('Activar y Continuar'), findsOneWidget);

    // Dismiss dialog
    await tester.tap(find.text('Más tarde'));
    await tester.pumpAndSettle();

    expect(find.text('Permisos en Dinoxo Gamers'), findsNothing);
  });
}
