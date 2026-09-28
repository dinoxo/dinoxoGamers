import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'fixtures/test_repository.dart';
import 'fixtures/prepare_brand_image.dart';
import 'package:dinoxo_gamers/main.dart';

void main() {
  testWidgets('DinoxoGamersApp boots up successfully with Plus tab',
      (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({'has_seen_permissions_notice': true});
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
    expect(find.text('Dinoxo Store'), findsOneWidget);
  });

  testWidgets('DinoxoGamersApp shows first run permissions dialog',
      (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({'has_seen_permissions_notice': false});
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
