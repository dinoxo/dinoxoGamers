import 'dart:async';
import 'dart:isolate';

// A deadline must stop the work, not just stop awaiting a still-running parser.
Future<T> runBackgroundJob<T>(FutureOr<T> Function() job,
    {Duration timeout = const Duration(seconds: 40)}) async {
  final port = ReceivePort();
  Isolate? worker;
  try {
    worker = await Isolate.spawn(_executeJob<T>, (job, port.sendPort),
        onError: port.sendPort, onExit: port.sendPort);
    final result = await port.first.timeout(timeout);
    if (result is List && result.length == 2 && result.first == true) {
      return result[1] as T;
    }
    throw StateError('No se pudo completar la consulta: $result');
  } finally {
    worker?.kill(priority: Isolate.immediate);
    port.close();
  }
}

void _executeJob<T>((FutureOr<T> Function(), SendPort) task) async {
  try {
    final result = await task.$1();
    Isolate.exit(task.$2, [true, result]);
  } catch (error) {
    Isolate.exit(task.$2, [false, error.toString()]);
  }
}
