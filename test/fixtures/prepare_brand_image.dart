import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Let the real asset decoder complete before advancing the fake animation clock.
Future<void> prepareBrandImage(WidgetTester tester) async {
  await tester.runAsync(() => precacheImage(
        const AssetImage('assets/images/dinoxo_store_badge.png'),
        tester.element(find.byKey(const Key('brand-logo'))),
      ));
  await tester.pump();
}
