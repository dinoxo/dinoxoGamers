import '../../core/constants/app_constants.dart';

enum SubscriptionTier {
  // PlayStation
  psEssential('PS Plus Essential (Juego del Mes)', GamePlatform.playstation),
  psExtra('PS Plus Extra (Catálogo)', GamePlatform.playstation),
  psPremium('PS Plus Premium (Clásicos)', GamePlatform.playstation),

  // Xbox
  xboxUltimate('Game Pass Ultimate / PC', GamePlatform.xbox),
  xboxStandard('Game Pass Standard', GamePlatform.xbox),
  xboxCore('Game Pass Core', GamePlatform.xbox),
  eaPlay('EA Play (Incluido en GP Ultimate)', GamePlatform.xbox),

  // Nintendo
  nsoStandard('Nintendo Switch Online (NES/SNES/GB)', GamePlatform.nintendo),
  nsoExpansion('NSO + Paquete de Expansión (N64/GBA/DLCs)', GamePlatform.nintendo);

  final String displayName;
  final GamePlatform platform;

  const SubscriptionTier(this.displayName, this.platform);
}

enum SubscriptionStatus {
  included('Incluido en suscripción'),
  leavingSoon('Saliendo pronto'),
  comingSoon('Próximamente');

  final String label;
  const SubscriptionStatus(this.label);
}

enum SubscriptionCategory {
  all('Todos'),
  monthly('Juegos del Mes'),
  catalog('Catálogo'),
  classics('Clásicos / Retro'),
  leavingSoon('Saliendo Pronto'),
  comingSoon('Próximamente');

  final String label;
  const SubscriptionCategory(this.label);
}

class SubscriptionItem {
  final String id;
  final String title;
  final GamePlatform platform;
  final SubscriptionTier tier;
  final SubscriptionStatus status;
  final SubscriptionCategory category;
  final String coverUrl;
  final List<String> consoles;
  final String? statusNote;
  final String? expiryDate;
  final String? releaseDate;
  final String? officialStoreUrl;

  const SubscriptionItem({
    required this.id,
    required this.title,
    required this.platform,
    required this.tier,
    required this.status,
    required this.category,
    required this.coverUrl,
    required this.consoles,
    this.statusNote,
    this.expiryDate,
    this.releaseDate,
    this.officialStoreUrl,
  });

  String get serviceName {
    switch (platform) {
      case GamePlatform.playstation:
        return 'PlayStation Plus';
      case GamePlatform.xbox:
        return 'Xbox Game Pass';
      case GamePlatform.nintendo:
        return 'Nintendo Switch Online';
    }
  }

  String get shortBadgeLabel {
    if (status == SubscriptionStatus.leavingSoon) {
      return 'Sale pronto de $serviceName';
    }
    if (status == SubscriptionStatus.comingSoon) {
      return 'Pronto en $serviceName';
    }
    switch (tier) {
      case SubscriptionTier.psEssential:
        return 'PS Plus (Mes)';
      case SubscriptionTier.psExtra:
        return 'PS Plus Extra';
      case SubscriptionTier.psPremium:
        return 'PS Plus Premium';
      case SubscriptionTier.xboxUltimate:
        return 'Game Pass';
      case SubscriptionTier.xboxStandard:
        return 'Game Pass';
      case SubscriptionTier.xboxCore:
        return 'Game Pass Core';
      case SubscriptionTier.eaPlay:
        return 'EA Play / Game Pass';
      case SubscriptionTier.nsoStandard:
        return 'NSO';
      case SubscriptionTier.nsoExpansion:
        return 'NSO + Expansión';
    }
  }
}

class SubscriptionMatch {
  final SubscriptionItem item;

  const SubscriptionMatch({required this.item});

  bool get isIncluded => item.status == SubscriptionStatus.included;
  bool get isLeavingSoon => item.status == SubscriptionStatus.leavingSoon;
  bool get isComingSoon => item.status == SubscriptionStatus.comingSoon;

  String get advisoryTitle {
    if (isLeavingSoon) {
      return '⚠️ ¡Atención! Sale pronto de ${item.serviceName}';
    }
    if (isComingSoon) {
      return '⏳ Próximamente en ${item.serviceName}';
    }
    return '💡 Te recomendamos no comprar este juego';
  }

  String get advisoryMessage {
    if (isLeavingSoon) {
      return 'Este juego dejará de estar disponible pronto en ${item.serviceName} (${item.tier.displayName})${item.statusNote != null ? ' - ${item.statusNote}' : ''}. Si querés conservarlo para siempre, ¡este es el mejor momento para aprovechar la oferta antes de que salga!';
    }
    if (isComingSoon) {
      return 'Este título llegará próximamente al catálogo de ${item.serviceName} (${item.tier.displayName})${item.statusNote != null ? ' (${item.statusNote})' : ''}. Si estás suscrito o pensás suscribirte, te sugerimos esperar y no gastar de más.';
    }
    return 'Este juego está incluido actualmente en ${item.serviceName} (${item.tier.displayName}). Si tenés esta suscripción de ${AppConstants.platformDisplayName(item.platform)}, ¡podés jugarlo gratis sin comprarlo!';
  }
}
