import 'dart:io';
import 'package:flutter/widgets.dart';
import 'package:workmanager/workmanager.dart';
import '../../data/repositories/game_repository.dart';
import 'notification_service.dart';

@pragma('vm:entry-point')
void priceAlertDispatcher() {
  Workmanager().executeTask((task, data) async {
    WidgetsFlutterBinding.ensureInitialized();
    if (task != PriceAlertScheduler.taskName) return true;
    await NotificationService.instance.initialize();
    try {
      return (await GameRepository().refreshAlertPrices()).isEmpty;
    } catch (_) {
      return false; // WorkManager retries transient failures with backoff.
    }
  });
}

class PriceAlertScheduler {
  PriceAlertScheduler._();
  static final instance = PriceAlertScheduler._();
  static const taskName = 'dinoxo.price-alert-check';
  bool _initialized = false;

  Future<void> synchronize({required bool hasActiveAlerts}) async {
    if (!Platform.isAndroid) return;
    try {
      if (!_initialized) {
        await Workmanager().initialize(priceAlertDispatcher);
        _initialized = true;
      }
      if (!hasActiveAlerts) {
        await Workmanager().cancelByUniqueName(taskName);
        return;
      }
      await Workmanager().registerPeriodicTask(taskName, taskName,
          frequency: const Duration(minutes: 15),
          existingWorkPolicy: ExistingPeriodicWorkPolicy.keep,
          constraints: Constraints(networkType: NetworkType.connected),
          backoffPolicy: BackoffPolicy.exponential,
          backoffPolicyDelay: const Duration(minutes: 5));
    } catch (_) {
      // Foreground checks remain usable if the OS temporarily rejects scheduling.
    }
  }
}
