import 'package:flutter/material.dart';
import 'dart:async';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'core/theme/app_theme.dart';
import 'data/repositories/game_repository.dart';
import 'domain/services/notification_service.dart';
import 'domain/services/subscription_service.dart';
import 'ui/features/startup/startup_gate.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final gameRepository = GameRepository();
  runApp(DinoxoGamersApp(repository: gameRepository));
  WidgetsBinding.instance.addPostFrameCallback((_) async {
    await NotificationService.instance.initialize();
    unawaited(gameRepository.synchronizeAlertMonitoring());
    unawaited(gameRepository.synchronizeReleaseNotifications());
    unawaited(SubscriptionService.instance.ensureLoaded());
  });
}

class DinoxoGamersApp extends StatelessWidget {
  final GameRepository repository;

  const DinoxoGamersApp({
    super.key,
    required this.repository,
  });

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Dinoxo Gamers',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('es', 'ES'),
        Locale('en', 'US'),
      ],
      home: StartupGate(repository: repository),
    );
  }
}
