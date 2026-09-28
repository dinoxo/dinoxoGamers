import 'dart:async';
import 'package:dinoxo_gamers/core/utils/background_job.dart';
import 'package:flutter_test/flutter_test.dart';

int _expensiveParse() {
  final watch = Stopwatch()..start();
  while (watch.elapsedMilliseconds < 300) {/* Simulate synchronous decoding. */}
  return 42;
}

Never _stalledParse() {
  while (true) {/* A timed-out worker must be terminated. */}
}

void main() {
  test('CPU-heavy catalog work leaves the caller event loop responsive',
      () async {
    var ticks = 0;
    final timer =
        Timer.periodic(const Duration(milliseconds: 10), (_) => ticks++);
    try {
      expect(await runBackgroundJob(_expensiveParse), 42);
      expect(ticks, greaterThan(3));
    } finally {
      timer.cancel();
    }
  });
  test('a stalled catalog worker times out and a new job can complete',
      () async {
    await expectLater(
        runBackgroundJob<int>(_stalledParse,
            timeout: const Duration(milliseconds: 80)),
        throwsA(isA<TimeoutException>()));
    expect(await runBackgroundJob(_expensiveParse), 42);
  });
}
