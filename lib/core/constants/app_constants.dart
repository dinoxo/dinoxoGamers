// Dinoxo Gamers - Application Constants

enum GamePlatform {
  playstation,
  nintendo,
  xbox,
}

enum ProductType {
  unknown,
  fullGame,
  dlc,
  bundle,
}

enum EstimationConfidence {
  low,
  medium,
  high,
}

class AppConstants {
  AppConstants._();

  // App Metadata
  static const String appName = 'Dinoxo Gamers';
  static const String appVersion = '1.7.0+8';
  static const String commercialRegion = 'USA';
  static const String currencyCode = 'USD';
  static const String currencySymbol = '\$';

  // Dinoxo Store Official Information
  static const String storeName = 'Dinoxo Store';
  static const String storeWebsite = 'https://dinoxostore.com/';
  static const String storeInstagram =
      'https://www.instagram.com/dinoxo.store/';
  static const String storeTikTok = 'https://www.tiktok.com/@dinoxo.store';
  static const String storeWhatsAppPhone = '+584268158785';
  static const String storeWhatsAppVisiblePhone = '0426 815 8785';
  static const String storeWhatsAppBaseUrl = 'https://wa.me/584268158785';

  // Reference Tracker URLs (USA)
  static const String psDealsUrl = 'https://psdeals.net/us-store';
  static const String ntDealsUrl = 'https://ntdeals.net/us-store';
  static const String xbDealsUrl = 'https://xbdeals.net/us-store';

  // Official Store Base URLs (USA)
  static const String playStationStoreUsUrl =
      'https://store.playstation.com/en-us/';
  static const String nintendoEshopUsUrl = 'https://www.nintendo.com/us/store/';
  static const String xboxStoreUsUrl =
      'https://www.xbox.com/en-us/games/store/';

  // Official Store Deals Pages (USA)
  static const String playStationDealsUsUrl =
      'https://store.playstation.com/en-us/pages/deals';
  static const String nintendoDealsUsUrl =
      'https://www.nintendo.com/us/store/games/#sort=df&f=deals';
  static const String xboxDealsUsUrl =
      'https://www.xbox.com/en-us/games/store/great-xbox-deals';

  // Build official store URL for a game title or general store
  static String officialStoreUrlForGame(GamePlatform platform,
      [String? gameTitle]) {
    if (gameTitle == null || gameTitle.trim().isEmpty) {
      switch (platform) {
        case GamePlatform.playstation:
          return playStationStoreUsUrl;
        case GamePlatform.nintendo:
          return nintendoEshopUsUrl;
        case GamePlatform.xbox:
          return xboxStoreUsUrl;
      }
    }
    final encoded = Uri.encodeComponent(gameTitle.trim());
    switch (platform) {
      case GamePlatform.playstation:
        return 'https://store.playstation.com/en-us/search/$encoded';
      case GamePlatform.nintendo:
        return 'https://www.nintendo.com/us/search/#q=$encoded';
      case GamePlatform.xbox:
        return 'https://www.xbox.com/en-us/search?q=$encoded';
    }
  }

  // Build deals tracker URL for a game title or general tracker
  static String dealsTrackerUrlForGame(GamePlatform platform,
      [String? gameTitle]) {
    if (gameTitle == null || gameTitle.trim().isEmpty) {
      switch (platform) {
        case GamePlatform.playstation:
          return psDealsUrl;
        case GamePlatform.nintendo:
          return ntDealsUrl;
        case GamePlatform.xbox:
          return xbDealsUrl;
      }
    }
    final encoded = Uri.encodeComponent(gameTitle.trim());
    switch (platform) {
      case GamePlatform.playstation:
        return 'https://psdeals.net/us-store/search?search_query=$encoded';
      case GamePlatform.nintendo:
        return 'https://ntdeals.net/us-store/search?search_query=$encoded';
      case GamePlatform.xbox:
        return 'https://xbdeals.net/us-store/search?search_query=$encoded';
    }
  }

  // Platform Names & Codes
  static String platformDisplayName(GamePlatform platform) {
    switch (platform) {
      case GamePlatform.playstation:
        return 'PlayStation';
      case GamePlatform.nintendo:
        return 'Nintendo';
      case GamePlatform.xbox:
        return 'Xbox';
    }
  }

  static String productTypeDisplayName(ProductType type) {
    switch (type) {
      case ProductType.unknown:
        return 'Consultar contenido en la tienda';
      case ProductType.fullGame:
        return 'Juego Completo';
      case ProductType.dlc:
        return 'DLC / Expansión';
      case ProductType.bundle:
        return 'Paquete / Bundle';
    }
  }
}
