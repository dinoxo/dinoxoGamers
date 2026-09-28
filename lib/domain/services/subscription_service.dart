import '../../core/constants/app_constants.dart';
import '../models/subscription_item.dart';

class SubscriptionService {
  SubscriptionService._();
  static final SubscriptionService instance = SubscriptionService._();

  static const List<SubscriptionItem> _database = [
    // ==========================================
    // PLAYSTATION PLUS - JUEGOS DEL MES (ESSENTIAL)
    // ==========================================
    SubscriptionItem(
      id: 'ps-m-1',
      title: 'Harry Potter: Quidditch Champions',
      platform: GamePlatform.playstation,
      tier: SubscriptionTier.psEssential,
      status: SubscriptionStatus.included,
      category: SubscriptionCategory.monthly,
      coverUrl:
          'https://images.igdb.com/igdb/image/upload/t_cover_big/co8j9o.webp',
      consoles: ['PS5', 'PS4'],
      statusNote: 'Juego del mes disponible para reclamar',
      officialStoreUrl:
          'https://store.playstation.com/en-us/concept/10007255',
    ),
    SubscriptionItem(
      id: 'ps-m-2',
      title: 'MLB The Show 24',
      platform: GamePlatform.playstation,
      tier: SubscriptionTier.psEssential,
      status: SubscriptionStatus.included,
      category: SubscriptionCategory.monthly,
      coverUrl:
          'https://images.igdb.com/igdb/image/upload/t_cover_big/co7og3.webp',
      consoles: ['PS5', 'PS4'],
      statusNote: 'Juego del mes de PlayStation Plus',
      officialStoreUrl:
          'https://store.playstation.com/en-us/concept/10008587',
    ),
    SubscriptionItem(
      id: 'ps-m-3',
      title: 'Little Nightmares II',
      platform: GamePlatform.playstation,
      tier: SubscriptionTier.psEssential,
      status: SubscriptionStatus.included,
      category: SubscriptionCategory.monthly,
      coverUrl:
          'https://images.igdb.com/igdb/image/upload/t_cover_big/co20vv.webp',
      consoles: ['PS5', 'PS4'],
      statusNote: 'Juego del mes de PlayStation Plus',
      officialStoreUrl:
          'https://store.playstation.com/en-us/concept/234720',
    ),
    SubscriptionItem(
      id: 'ps-m-4',
      title: 'Ghostrunner 2',
      platform: GamePlatform.playstation,
      tier: SubscriptionTier.psEssential,
      status: SubscriptionStatus.included,
      category: SubscriptionCategory.monthly,
      coverUrl:
          'https://images.igdb.com/igdb/image/upload/t_cover_big/co72i4.webp',
      consoles: ['PS5'],
      statusNote: 'Juego del mes en tu biblioteca Plus',
      officialStoreUrl:
          'https://store.playstation.com/en-us/concept/10004944',
    ),
    SubscriptionItem(
      id: 'ps-m-5',
      title: 'EA Sports FC 24',
      platform: GamePlatform.playstation,
      tier: SubscriptionTier.psEssential,
      status: SubscriptionStatus.included,
      category: SubscriptionCategory.monthly,
      coverUrl:
          'https://images.igdb.com/igdb/image/upload/t_cover_big/co6t8h.webp',
      consoles: ['PS5', 'PS4'],
      statusNote: 'Juego del mes de PlayStation Plus',
      officialStoreUrl:
          'https://store.playstation.com/en-us/concept/10006766',
    ),

    // ==========================================
    // PLAYSTATION PLUS - CATÁLOGO EXTRA
    // ==========================================
    SubscriptionItem(
      id: 'ps-e-1',
      title: "Demon's Souls",
      platform: GamePlatform.playstation,
      tier: SubscriptionTier.psExtra,
      status: SubscriptionStatus.included,
      category: SubscriptionCategory.catalog,
      coverUrl:
          'https://images.igdb.com/igdb/image/upload/t_cover_big/co2kch.webp',
      consoles: ['PS5'],
      statusNote: 'Catálogo de Juegos PS Plus Extra & Deluxe',
      officialStoreUrl:
          'https://store.playstation.com/en-us/concept/10000438',
    ),
    SubscriptionItem(
      id: 'ps-e-2',
      title: 'Returnal',
      platform: GamePlatform.playstation,
      tier: SubscriptionTier.psExtra,
      status: SubscriptionStatus.included,
      category: SubscriptionCategory.catalog,
      coverUrl:
          'https://images.igdb.com/igdb/image/upload/t_cover_big/co2msj.webp',
      consoles: ['PS5'],
      statusNote: 'Catálogo de Juegos PS Plus Extra & Deluxe',
      officialStoreUrl:
          'https://store.playstation.com/en-us/concept/10000853',
    ),
    SubscriptionItem(
      id: 'ps-e-3',
      title: "Marvel's Spider-Man: Miles Morales",
      platform: GamePlatform.playstation,
      tier: SubscriptionTier.psExtra,
      status: SubscriptionStatus.included,
      category: SubscriptionCategory.catalog,
      coverUrl:
          'https://images.igdb.com/igdb/image/upload/t_cover_big/co2822.webp',
      consoles: ['PS5', 'PS4'],
      statusNote: 'Catálogo de Juegos PS Plus Extra & Deluxe',
      officialStoreUrl:
          'https://store.playstation.com/en-us/concept/10000676',
    ),
    SubscriptionItem(
      id: 'ps-e-4',
      title: 'Ghost of Tsushima DIRECTOR’S CUT',
      platform: GamePlatform.playstation,
      tier: SubscriptionTier.psExtra,
      status: SubscriptionStatus.included,
      category: SubscriptionCategory.catalog,
      coverUrl:
          'https://images.igdb.com/igdb/image/upload/t_cover_big/co3p2d.webp',
      consoles: ['PS5', 'PS4'],
      statusNote: 'Catálogo de Juegos PS Plus Extra & Deluxe',
      officialStoreUrl:
          'https://store.playstation.com/en-us/concept/10002534',
    ),
    SubscriptionItem(
      id: 'ps-e-5',
      title: 'Horizon Forbidden West',
      platform: GamePlatform.playstation,
      tier: SubscriptionTier.psExtra,
      status: SubscriptionStatus.included,
      category: SubscriptionCategory.catalog,
      coverUrl:
          'https://images.igdb.com/igdb/image/upload/t_cover_big/co2v0h.webp',
      consoles: ['PS5', 'PS4'],
      statusNote: 'Catálogo de Juegos PS Plus Extra & Deluxe',
      officialStoreUrl:
          'https://store.playstation.com/en-us/concept/10000886',
    ),
    SubscriptionItem(
      id: 'ps-e-6',
      title: 'Death Stranding Director’s Cut',
      platform: GamePlatform.playstation,
      tier: SubscriptionTier.psExtra,
      status: SubscriptionStatus.included,
      category: SubscriptionCategory.catalog,
      coverUrl:
          'https://images.igdb.com/igdb/image/upload/t_cover_big/co3n5y.webp',
      consoles: ['PS5'],
      statusNote: 'Catálogo de Juegos PS Plus Extra & Deluxe',
      officialStoreUrl:
          'https://store.playstation.com/en-us/concept/10002138',
    ),
    SubscriptionItem(
      id: 'ps-e-7',
      title: 'Resident Evil 2',
      platform: GamePlatform.playstation,
      tier: SubscriptionTier.psExtra,
      status: SubscriptionStatus.included,
      category: SubscriptionCategory.catalog,
      coverUrl:
          'https://images.igdb.com/igdb/image/upload/t_cover_big/co1ir9.webp',
      consoles: ['PS5', 'PS4'],
      statusNote: 'Catálogo de Juegos PS Plus Extra & Deluxe',
      officialStoreUrl:
          'https://store.playstation.com/en-us/concept/231792',
    ),
    SubscriptionItem(
      id: 'ps-e-8',
      title: 'Bloodborne',
      platform: GamePlatform.playstation,
      tier: SubscriptionTier.psExtra,
      status: SubscriptionStatus.included,
      category: SubscriptionCategory.catalog,
      coverUrl:
          'https://images.igdb.com/igdb/image/upload/t_cover_big/co1r76.webp',
      consoles: ['PS4', 'PS5'],
      statusNote: 'Catálogo de Juegos PS Plus Extra & Deluxe',
      officialStoreUrl:
          'https://store.playstation.com/en-us/concept/200676',
    ),
    SubscriptionItem(
      id: 'ps-e-9',
      title: 'Grand Theft Auto V',
      platform: GamePlatform.playstation,
      tier: SubscriptionTier.psExtra,
      status: SubscriptionStatus.leavingSoon,
      category: SubscriptionCategory.leavingSoon,
      coverUrl:
          'https://images.igdb.com/igdb/image/upload/t_cover_big/co2lbd.webp',
      consoles: ['PS5', 'PS4'],
      statusNote: 'Sale del catálogo próximamente',
      officialStoreUrl:
          'https://store.playstation.com/en-us/concept/200030',
    ),

    // ==========================================
    // PLAYSTATION PLUS - CLÁSICOS PREMIUM
    // ==========================================
    SubscriptionItem(
      id: 'ps-p-1',
      title: 'The Last of Us Part I',
      platform: GamePlatform.playstation,
      tier: SubscriptionTier.psPremium,
      status: SubscriptionStatus.included,
      category: SubscriptionCategory.classics,
      coverUrl:
          'https://images.igdb.com/igdb/image/upload/t_cover_big/co4xpt.webp',
      consoles: ['PS5'],
      statusNote: 'Catálogo de Clásicos PS Plus Premium',
      officialStoreUrl:
          'https://store.playstation.com/en-us/concept/10002694',
    ),
    SubscriptionItem(
      id: 'ps-p-2',
      title: 'Sly Cooper and the Thievius Raccoonus',
      platform: GamePlatform.playstation,
      tier: SubscriptionTier.psPremium,
      status: SubscriptionStatus.included,
      category: SubscriptionCategory.classics,
      coverUrl:
          'https://images.igdb.com/igdb/image/upload/t_cover_big/co1x3c.webp',
      consoles: ['PS5', 'PS4'],
      statusNote: 'Clásico de PS2 en PS Plus Premium',
      officialStoreUrl:
          'https://store.playstation.com/en-us/concept/10010531',
    ),

    // ==========================================
    // XBOX GAME PASS - ULTIMATE & STANDARD
    // ==========================================
    SubscriptionItem(
      id: 'xb-u-1',
      title: 'Starfield',
      platform: GamePlatform.xbox,
      tier: SubscriptionTier.xboxUltimate,
      status: SubscriptionStatus.included,
      category: SubscriptionCategory.catalog,
      coverUrl:
          'https://images.igdb.com/igdb/image/upload/t_cover_big/co6ra3.webp',
      consoles: ['Xbox Series X/S', 'PC', 'Cloud'],
      statusNote: 'Incluido en Game Pass Ultimate y PC',
      officialStoreUrl:
          'https://www.xbox.com/en-us/games/store/starfield/9ncfl2nhdj18',
    ),
    SubscriptionItem(
      id: 'xb-u-2',
      title: 'Forza Horizon 5',
      platform: GamePlatform.xbox,
      tier: SubscriptionTier.xboxUltimate,
      status: SubscriptionStatus.included,
      category: SubscriptionCategory.catalog,
      coverUrl:
          'https://images.igdb.com/igdb/image/upload/t_cover_big/co3ofx.webp',
      consoles: ['Xbox Series X/S', 'Xbox One', 'PC', 'Cloud'],
      statusNote: 'Incluido en Game Pass Ultimate y Standard',
      officialStoreUrl:
          'https://www.xbox.com/en-us/games/store/forza-horizon-5-standard-edition/9nkx70bb79sd',
    ),
    SubscriptionItem(
      id: 'xb-u-3',
      title: 'Halo Infinite',
      platform: GamePlatform.xbox,
      tier: SubscriptionTier.xboxUltimate,
      status: SubscriptionStatus.included,
      category: SubscriptionCategory.catalog,
      coverUrl:
          'https://images.igdb.com/igdb/image/upload/t_cover_big/co294e.webp',
      consoles: ['Xbox Series X/S', 'Xbox One', 'PC', 'Cloud'],
      statusNote: 'Campaña incluida en Game Pass',
      officialStoreUrl:
          'https://www.xbox.com/en-us/games/store/halo-infinite-campaign/9np1p1w05419',
    ),
    SubscriptionItem(
      id: 'xb-u-4',
      title: 'Persona 3 Reload',
      platform: GamePlatform.xbox,
      tier: SubscriptionTier.xboxUltimate,
      status: SubscriptionStatus.included,
      category: SubscriptionCategory.catalog,
      coverUrl:
          'https://images.igdb.com/igdb/image/upload/t_cover_big/co6t8i.webp',
      consoles: ['Xbox Series X/S', 'Xbox One', 'PC', 'Cloud'],
      statusNote: 'Incluido en Game Pass Ultimate y PC',
      officialStoreUrl:
          'https://www.xbox.com/en-us/games/store/persona-3-reload/9p4n0tgw7csw',
    ),
    SubscriptionItem(
      id: 'xb-u-5',
      title: 'Senua’s Saga: Hellblade II',
      platform: GamePlatform.xbox,
      tier: SubscriptionTier.xboxUltimate,
      status: SubscriptionStatus.included,
      category: SubscriptionCategory.catalog,
      coverUrl:
          'https://images.igdb.com/igdb/image/upload/t_cover_big/co7v0g.webp',
      consoles: ['Xbox Series X/S', 'PC', 'Cloud'],
      statusNote: 'Lanzamiento día uno en Game Pass',
      officialStoreUrl:
          'https://www.xbox.com/en-us/games/store/senuas-saga-hellblade-ii/9nx36q94fnfl',
    ),
    SubscriptionItem(
      id: 'xb-u-6',
      title: 'Hi-Fi RUSH',
      platform: GamePlatform.xbox,
      tier: SubscriptionTier.xboxUltimate,
      status: SubscriptionStatus.included,
      category: SubscriptionCategory.catalog,
      coverUrl:
          'https://images.igdb.com/igdb/image/upload/t_cover_big/co5xi7.webp',
      consoles: ['Xbox Series X/S', 'PC', 'Cloud'],
      statusNote: 'Incluido en Game Pass Ultimate y Standard',
      officialStoreUrl:
          'https://www.xbox.com/en-us/games/store/hi-fi-rush/9nblggh43v3b',
    ),
    SubscriptionItem(
      id: 'xb-u-7',
      title: 'Lies of P',
      platform: GamePlatform.xbox,
      tier: SubscriptionTier.xboxUltimate,
      status: SubscriptionStatus.included,
      category: SubscriptionCategory.catalog,
      coverUrl:
          'https://images.igdb.com/igdb/image/upload/t_cover_big/co6t8g.webp',
      consoles: ['Xbox Series X/S', 'Xbox One', 'PC', 'Cloud'],
      statusNote: 'Incluido en Game Pass Ultimate',
      officialStoreUrl:
          'https://www.xbox.com/en-us/games/store/lies-of-p/9nlwmbrw0xwh',
    ),
    SubscriptionItem(
      id: 'xb-u-8',
      title: 'Dead Space Remake',
      platform: GamePlatform.xbox,
      tier: SubscriptionTier.eaPlay,
      status: SubscriptionStatus.included,
      category: SubscriptionCategory.catalog,
      coverUrl:
          'https://images.igdb.com/igdb/image/upload/t_cover_big/co5p3r.webp',
      consoles: ['Xbox Series X/S', 'PC'],
      statusNote: 'EA Play (Incluido en Game Pass Ultimate)',
      officialStoreUrl:
          'https://www.xbox.com/en-us/games/store/dead-space/9n8q51v5d4r4',
    ),
    SubscriptionItem(
      id: 'xb-u-9',
      title: 'Palworld',
      platform: GamePlatform.xbox,
      tier: SubscriptionTier.xboxUltimate,
      status: SubscriptionStatus.included,
      category: SubscriptionCategory.catalog,
      coverUrl:
          'https://images.igdb.com/igdb/image/upload/t_cover_big/co7og4.webp',
      consoles: ['Xbox Series X/S', 'Xbox One', 'PC', 'Cloud'],
      statusNote: 'Game Preview en Game Pass',
      officialStoreUrl:
          'https://www.xbox.com/en-us/games/store/palworld-game-preview/9nkv34x7pzs0',
    ),
    SubscriptionItem(
      id: 'xb-u-10',
      title: 'Call of Duty: Black Ops 6',
      platform: GamePlatform.xbox,
      tier: SubscriptionTier.xboxUltimate,
      status: SubscriptionStatus.comingSoon,
      category: SubscriptionCategory.comingSoon,
      coverUrl:
          'https://images.igdb.com/igdb/image/upload/t_cover_big/co8j9p.webp',
      consoles: ['Xbox Series X/S', 'Xbox One', 'PC', 'Cloud'],
      statusNote: 'Disponible Día 1 en Game Pass Ultimate',
      officialStoreUrl:
          'https://www.xbox.com/en-us/games/store/call-of-duty-black-ops-6/9pj9k60g4z4p',
    ),
    SubscriptionItem(
      id: 'xb-u-11',
      title: 'Indiana Jones and the Great Circle',
      platform: GamePlatform.xbox,
      tier: SubscriptionTier.xboxUltimate,
      status: SubscriptionStatus.comingSoon,
      category: SubscriptionCategory.comingSoon,
      coverUrl:
          'https://images.igdb.com/igdb/image/upload/t_cover_big/co7v0h.webp',
      consoles: ['Xbox Series X/S', 'PC', 'Cloud'],
      statusNote: 'Lanzamiento Día 1 en Game Pass Ultimate',
      officialStoreUrl:
          'https://www.xbox.com/en-us/games/store/indiana-jones-and-the-great-circle/9p6z11k9wqlk',
    ),
    SubscriptionItem(
      id: 'xb-u-12',
      title: 'Gotham Knights',
      platform: GamePlatform.xbox,
      tier: SubscriptionTier.xboxUltimate,
      status: SubscriptionStatus.leavingSoon,
      category: SubscriptionCategory.leavingSoon,
      coverUrl:
          'https://images.igdb.com/igdb/image/upload/t_cover_big/co5p3s.webp',
      consoles: ['Xbox Series X/S', 'PC', 'Cloud'],
      statusNote: 'Sale del catálogo próximamente',
      officialStoreUrl:
          'https://www.xbox.com/en-us/games/store/gotham-knights/9p40r62w0z6s',
    ),

    // ==========================================
    // NINTENDO SWITCH ONLINE (ESTÁNDAR & EXPANSIÓN)
    // ==========================================
    SubscriptionItem(
      id: 'nso-1',
      title: 'Super Mario World',
      platform: GamePlatform.nintendo,
      tier: SubscriptionTier.nsoStandard,
      status: SubscriptionStatus.included,
      category: SubscriptionCategory.classics,
      coverUrl:
          'https://images.igdb.com/igdb/image/upload/t_cover_big/co1x3d.webp',
      consoles: ['Switch (SNES)'],
      statusNote: 'Incluido en la app Super Nintendo Entertainment System',
      officialStoreUrl:
          'https://www.nintendo.com/us/store/products/super-nintendo-entertainment-system-nintendo-switch-online-switch/',
    ),
    SubscriptionItem(
      id: 'nso-2',
      title: 'The Legend of Zelda: A Link to the Past',
      platform: GamePlatform.nintendo,
      tier: SubscriptionTier.nsoStandard,
      status: SubscriptionStatus.included,
      category: SubscriptionCategory.classics,
      coverUrl:
          'https://images.igdb.com/igdb/image/upload/t_cover_big/co1x3e.webp',
      consoles: ['Switch (SNES)'],
      statusNote: 'Incluido con membresía NSO Estándar',
      officialStoreUrl:
          'https://www.nintendo.com/us/store/products/super-nintendo-entertainment-system-nintendo-switch-online-switch/',
    ),
    SubscriptionItem(
      id: 'nso-3',
      title: 'Super Mario Bros. 3',
      platform: GamePlatform.nintendo,
      tier: SubscriptionTier.nsoStandard,
      status: SubscriptionStatus.included,
      category: SubscriptionCategory.classics,
      coverUrl:
          'https://images.igdb.com/igdb/image/upload/t_cover_big/co1x3f.webp',
      consoles: ['Switch (NES)'],
      statusNote: 'Incluido con membresía NSO Estándar',
      officialStoreUrl:
          'https://www.nintendo.com/us/store/products/nintendo-entertainment-system-nintendo-switch-online-switch/',
    ),
    SubscriptionItem(
      id: 'nso-4',
      title: 'Metroid Fusion',
      platform: GamePlatform.nintendo,
      tier: SubscriptionTier.nsoExpansion,
      status: SubscriptionStatus.included,
      category: SubscriptionCategory.classics,
      coverUrl:
          'https://images.igdb.com/igdb/image/upload/t_cover_big/co1x3g.webp',
      consoles: ['Switch (GBA)'],
      statusNote: 'NSO + Paquete de Expansión (Game Boy Advance)',
      officialStoreUrl:
          'https://www.nintendo.com/us/store/products/game-boy-advance-nintendo-switch-online-switch/',
    ),
    SubscriptionItem(
      id: 'nso-5',
      title: 'The Legend of Zelda: Ocarina of Time',
      platform: GamePlatform.nintendo,
      tier: SubscriptionTier.nsoExpansion,
      status: SubscriptionStatus.included,
      category: SubscriptionCategory.classics,
      coverUrl:
          'https://images.igdb.com/igdb/image/upload/t_cover_big/co1x3h.webp',
      consoles: ['Switch (N64)'],
      statusNote: 'NSO + Paquete de Expansión (Nintendo 64)',
      officialStoreUrl:
          'https://www.nintendo.com/us/store/products/nintendo-64-nintendo-switch-online-switch/',
    ),
    SubscriptionItem(
      id: 'nso-6',
      title: 'Super Mario 64',
      platform: GamePlatform.nintendo,
      tier: SubscriptionTier.nsoExpansion,
      status: SubscriptionStatus.included,
      category: SubscriptionCategory.classics,
      coverUrl:
          'https://images.igdb.com/igdb/image/upload/t_cover_big/co1x3i.webp',
      consoles: ['Switch (N64)'],
      statusNote: 'NSO + Paquete de Expansión (Nintendo 64)',
      officialStoreUrl:
          'https://www.nintendo.com/us/store/products/nintendo-64-nintendo-switch-online-switch/',
    ),
    SubscriptionItem(
      id: 'nso-7',
      title: 'GoldenEye 007',
      platform: GamePlatform.nintendo,
      tier: SubscriptionTier.nsoExpansion,
      status: SubscriptionStatus.included,
      category: SubscriptionCategory.classics,
      coverUrl:
          'https://images.igdb.com/igdb/image/upload/t_cover_big/co1x3j.webp',
      consoles: ['Switch (N64)'],
      statusNote: 'NSO + Paquete de Expansión (Multijugador en línea)',
      officialStoreUrl:
          'https://www.nintendo.com/us/store/products/nintendo-64-nintendo-switch-online-switch/',
    ),
    SubscriptionItem(
      id: 'nso-8',
      title: 'Mario Kart 8 Deluxe Booster Course Pass',
      platform: GamePlatform.nintendo,
      tier: SubscriptionTier.nsoExpansion,
      status: SubscriptionStatus.included,
      category: SubscriptionCategory.catalog,
      coverUrl:
          'https://images.igdb.com/igdb/image/upload/t_cover_big/co4xpu.webp',
      consoles: ['Switch (DLC)'],
      statusNote: 'DLC completo de 48 pistas incluido en el Paquete de Expansión',
      officialStoreUrl:
          'https://www.nintendo.com/us/store/products/mario-kart-8-deluxe-booster-course-pass-switch/',
    ),
  ];

  /// Get all available subscription items with optional filters
  List<SubscriptionItem> getItems({
    GamePlatform? platform,
    SubscriptionCategory? category,
    String? query,
  }) {
    return _database.where((item) {
      if (platform != null && item.platform != platform) return false;
      if (category != null && category != SubscriptionCategory.all) {
        if (item.category != category) return false;
      }
      if (query != null && query.trim().isNotEmpty) {
        final q = _normalize(query);
        final title = _normalize(item.title);
        final note = _normalize(item.statusNote ?? '');
        final tier = _normalize(item.tier.displayName);
        if (!title.contains(q) && !note.contains(q) && !tier.contains(q)) {
          return false;
        }
      }
      return true;
    }).toList();
  }

  /// Check if a game matches any active subscription item
  SubscriptionMatch? checkGame(String gameTitle, {GamePlatform? platform}) {
    if (gameTitle.trim().isEmpty) return null;
    final normalizedSearch = _normalize(gameTitle);

    for (final item in _database) {
      // If platform is specified, must match
      if (platform != null && item.platform != platform) continue;

      final normalizedItem = _normalize(item.title);

      // 1. Direct or fuzzy substring match
      if (normalizedSearch == normalizedItem) {
        return SubscriptionMatch(item: item);
      }

      if (_isSignificantMatch(normalizedSearch, normalizedItem)) {
        return SubscriptionMatch(item: item);
      }
    }
    return null;
  }

  bool _isSignificantMatch(String a, String b) {
    if (a.length >= 5 && b.contains(a)) return true;
    if (b.length >= 5 && a.contains(b)) return true;

    // Check shared key words (ignoring common articles)
    final wordsA = a.split(' ').where((w) => w.length > 3).toSet();
    final wordsB = b.split(' ').where((w) => w.length > 3).toSet();
    if (wordsA.isNotEmpty && wordsB.isNotEmpty) {
      final intersection = wordsA.intersection(wordsB);
      if (intersection.length >= 2 ||
          (wordsA.length == 1 && intersection.isNotEmpty && wordsB.length == 1)) {
        return true;
      }
    }
    return false;
  }

  String _normalize(String input) {
    var text = input.toLowerCase().trim();
    // Strip common edition and bundle suffixes
    text = text
        .replaceAll('standard edition', '')
        .replaceAll('deluxe edition', '')
        .replaceAll('digital edition', '')
        .replaceAll('gold edition', '')
        .replaceAll('ultimate edition', '')
        .replaceAll('cross-gen bundle', '')
        .replaceAll('remastered', '')
        .replaceAll('edition', '')
        .replaceAll(RegExp(r"[-:–—’'.,()!]"), ' ');
    return text.replaceAll(RegExp(r'\s+'), ' ').trim();
  }
}
