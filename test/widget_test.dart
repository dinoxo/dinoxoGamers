import 'package:flutter_test/flutter_test.dart';
import 'fixtures/test_repository.dart';
import 'fixtures/prepare_brand_image.dart';
import 'package:dinoxo_gamers/main.dart';

void main() {
  testWidgets('DinoxoGamersApp boots up successfully',
      (WidgetTester tester) async {
    final repo = TestRepository();
    await tester.pumpWidget(DinoxoGamersApp(repository: repo));
    await prepareBrandImage(tester);
    await tester.pump();
    await tester.pump(const Duration(seconds: 3));
    await tester.pumpAndSettle();

    // Verify Ofertas title appears in AppBar
    expect(find.text('Ofertas Destacadas'), findsOneWidget);
    // Verify Bottom Navigation items
    expect(find.text('Ofertas'), findsOneWidget);
    expect(find.text('Buscar'), findsOneWidget);
    expect(find.text('Mis Alertas'), findsOneWidget);
    expect(find.text('Dinoxo Store'), findsOneWidget);
  });
}
