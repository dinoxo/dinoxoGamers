import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../models/user_alert.dart';

class NotificationService {
  NotificationService._();
  static final NotificationService instance = NotificationService._();

  final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();
  bool _isInitialized = false;

  // Duplicate prevention cache
  final Map<String, DateTime> _recentlyDispatchedAlerts = {};

  Future<void> initialize() async {
    if (_isInitialized) return;

    const androidSettings =
        AndroidInitializationSettings('ic_stat_price_alert');
    const initSettings = InitializationSettings(android: androidSettings);

    try {
      await _notificationsPlugin.initialize(
        initSettings,
        onDidReceiveNotificationResponse: (details) {
          // Handle payload navigation
        },
      );
      _isInitialized = true;
    } catch (e) {
      // Graceful fallback if platform is not ready
      _isInitialized = false;
    }
  }

  /// Request notification permission in context
  Future<bool> requestPermission() async {
    try {
      await initialize();
      final androidImplementation =
          _notificationsPlugin.resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();
      final granted =
          await androidImplementation?.requestNotificationsPermission();
      return granted ??
          await androidImplementation?.areNotificationsEnabled() ??
          false;
    } catch (_) {
      return false;
    }
  }

  /// Check if the current time falls into quiet hours (e.g. 22:00 to 08:00)
  bool isQuietHours(int quietStartHour, int quietEndHour) {
    final now = DateTime.now();
    final hour = now.hour;

    if (quietStartHour > quietEndHour) {
      // Crosses midnight, e.g. 22 to 8
      return hour >= quietStartHour || hour < quietEndHour;
    } else {
      return hour >= quietStartHour && hour < quietEndHour;
    }
  }

  /// Send an alert notification with duplicate prevention and quiet hours validation
  Future<bool> showPriceAlertNotification({
    required UserAlert alert,
    required double newPrice,
    int quietStartHour = 22,
    int quietEndHour = 8,
    bool respectQuietHours = true,
  }) async {
    // 1. Check duplicate cooldown
    final alertKey = '${alert.id}_${newPrice.toStringAsFixed(2)}';
    final previous = _recentlyDispatchedAlerts[alertKey];
    if (previous != null && DateTime.now().difference(previous).inHours < 24) {
      return false; // Prevent duplicate
    }

    // 2. Check quiet hours
    if (respectQuietHours && isQuietHours(quietStartHour, quietEndHour)) {
      return false; // Silenced during quiet hours
    }

    // 3. Dispatch notification
    const androidDetails = AndroidNotificationDetails(
      'dinoxo_gamers_alerts',
      'Alertas de Ofertas Dinoxo',
      channelDescription:
          'Avisos al consultar un juego que alcanza tu precio objetivo.',
      importance: Importance.high,
      priority: Priority.high,
      icon: 'ic_stat_price_alert',
    );
    const notificationDetails = NotificationDetails(android: androidDetails);

    final title = '¡Oferta en ${alert.gameTitle}!';
    final body =
        'Precio consultado: \$${newPrice.toStringAsFixed(2)} USD (${alert.editionName}).';

    try {
      if (!_isInitialized) await initialize();
      if (!_isInitialized) return false;
      final android =
          _notificationsPlugin.resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();
      if (await android?.areNotificationsEnabled() != true) return false;
      await _notificationsPlugin.show(
        alert.id.hashCode & 0x7fffffff,
        title,
        body,
        notificationDetails,
        payload: alert.gameId,
      );
      _recentlyDispatchedAlerts[alertKey] = DateTime.now();
      return true;
    } catch (_) {
      return false;
    }
  }
}
