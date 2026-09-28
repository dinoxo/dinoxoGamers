import '../../core/constants/app_constants.dart';

enum SubscriptionTier {
  // PlayStation
  psEssential('PS Plus Essential (Juego del Mes)', GamePlatform.playstation),
  psExtra('PS Plus Extra (Catálogo)', GamePlatform.playstation),
  psPremium('PS Plus Premium (Clásicos)', GamePlatform.playstation),

  // Xbox
  xboxUltimate('Game Pass Ultimate', GamePlatform.xbox),
  xboxStandard('Game Pass Premium', GamePlatform.xbox),
  xboxCore('Game Pass Essential', GamePlatform.xbox),
  eaPlay('EA Play (Incluido en GP Ultimate)', GamePlatform.xbox),

  // Nintendo
  nsoStandard('Nintendo Switch Online (NES/SNES/GB)', GamePlatform.nintendo),
  nsoExpansion('NSO + Paquete de Expansión', GamePlatform.nintendo);

  final String displayName;
  final GamePlatform platform;

  const SubscriptionTier(this.displayName, this.platform);

  int get rank => switch (this) {
        psEssential || xboxCore || nsoStandard => 0,
        psExtra || xboxStandard || nsoExpansion || eaPlay => 1,
        psPremium || xboxUltimate => 2,
      };
}

enum SubscriptionStatus {
  included('Incluido en suscripción'),
  leavingSoon('Saliendo pronto'),
  comingSoon('Próximamente');

  final String label;
  const SubscriptionStatus(this.label);
}

enum SubscriptionCategory {
  all('Disponibles ahora'),
  monthly('Altas del mes'),
  catalog('Catálogo'),
  classics('Clásicos / Retro'),
  leavingSoon('Saliendo Pronto'),
  upcoming('Próximos ingresos'),
  benefits('Beneficios'),
  comingSoon('Mes siguiente');

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
  final String sourceUrl;
  final DateTime? checkedAt;
  final DateTime? addedAt;
  final DateTime? availableUntil;
  final bool availabilityConfirmed;

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
    this.sourceUrl = '',
    this.checkedAt,
    this.addedAt,
    this.availableUntil,
    this.availabilityConfirmed = true,
  });

  bool availableAt(DateTime now) =>
      availabilityConfirmed &&
      status != SubscriptionStatus.comingSoon &&
      (addedAt == null || !addedAt!.isAfter(now)) &&
      (availableUntil == null || now.isBefore(availableUntil!));

  SubscriptionItem withAnnouncement(SubscriptionItem announcement) =>
      SubscriptionItem(
          id: id,
          title: title,
          platform: platform,
          tier: tier,
          status: announcement.status == SubscriptionStatus.leavingSoon
              ? announcement.status
              : status,
          category: category,
          coverUrl: coverUrl,
          consoles: consoles,
          officialStoreUrl: officialStoreUrl,
          sourceUrl: announcement.sourceUrl.isEmpty
              ? sourceUrl
              : announcement.sourceUrl,
          checkedAt: checkedAt,
          addedAt: announcement.addedAt ?? addedAt,
          availableUntil: announcement.availableUntil ?? availableUntil,
          releaseDate: announcement.releaseDate ?? releaseDate,
          expiryDate: announcement.expiryDate ?? expiryDate,
          statusNote: announcement.statusNote,
          availabilityConfirmed: availabilityConfirmed);

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
        return 'Game Pass Essential';
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
  final DateTime? verifiedAt;

  const SubscriptionMatch({required this.item, this.verifiedAt});

  bool get isIncluded => item.availableAt(verifiedAt ?? DateTime.now());
  bool get isLeavingSoon => item.status == SubscriptionStatus.leavingSoon;
  bool get isComingSoon =>
      item.status == SubscriptionStatus.comingSoon ||
      item.addedAt?.isAfter(verifiedAt ?? DateTime.now()) == true;

  String get advisoryTitle {
    if (isLeavingSoon) {
      return '⚠️ ¡Atención! Sale pronto de ${item.serviceName}';
    }
    if (isComingSoon) {
      return '⏳ Próximamente en ${item.serviceName}';
    }
    return 'Comprueba tu membresía antes de comprar';
  }

  String get advisoryMessage {
    if (isLeavingSoon) {
      return 'La fuente anuncia la salida de ${item.serviceName} (${item.tier.displayName})${item.expiryDate != null ? ' el ${item.expiryDate}' : ''}. Si ya tienes acceso, comprueba la fecha antes de empezar. Para conservarlo después, revisa la edición y su precio antes de comprar.';
    }
    if (isComingSoon) {
      return 'Este título llegará próximamente al catálogo de ${item.serviceName} (${item.tier.displayName})${item.statusNote != null ? ' (${item.statusNote})' : ''}. Si estás suscrito o pensás suscribirte, te sugerimos esperar y no gastar de más.';
    }
    return 'La fuente USA incluye este juego en ${item.tier.displayName}. Si tienes ese nivel activo, puedes jugar la versión incluida sin comprarla. Comprueba la edición y los complementos: la app no tiene acceso a tu cuenta ni a los juegos que reclamaste antes.';
  }
}
