import '../../core/constants/app_constants.dart';

class DinoxoStoreItem {
  final String id;
  final GamePlatform platform;
  final int denominationUsd;
  final String categoryName;
  final bool isAvailable;
  final String region;
  final String notes;

  const DinoxoStoreItem({
    required this.id,
    required this.platform,
    required this.denominationUsd,
    required this.categoryName,
    this.isAvailable = true,
    this.region = 'USA',
    this.notes = 'Tarjeta digital oficial región USA.',
  });

  String get displayName => '${AppConstants.platformDisplayName(platform)} Gift Card \$$denominationUsd USD';

  static List<DinoxoStoreItem> getStandardCatalog() {
    return const [
      // PlayStation USA
      DinoxoStoreItem(
        id: 'ps_10',
        platform: GamePlatform.playstation,
        denominationUsd: 10,
        categoryName: 'PlayStation Network (PSN)',
      ),
      DinoxoStoreItem(
        id: 'ps_25',
        platform: GamePlatform.playstation,
        denominationUsd: 25,
        categoryName: 'PlayStation Network (PSN)',
      ),
      DinoxoStoreItem(
        id: 'ps_50',
        platform: GamePlatform.playstation,
        denominationUsd: 50,
        categoryName: 'PlayStation Network (PSN)',
      ),
      DinoxoStoreItem(
        id: 'ps_100',
        platform: GamePlatform.playstation,
        denominationUsd: 100,
        categoryName: 'PlayStation Network (PSN)',
      ),

      // Nintendo USA
      DinoxoStoreItem(
        id: 'nin_10',
        platform: GamePlatform.nintendo,
        denominationUsd: 10,
        categoryName: 'Nintendo eShop',
      ),
      DinoxoStoreItem(
        id: 'nin_20',
        platform: GamePlatform.nintendo,
        denominationUsd: 20,
        categoryName: 'Nintendo eShop',
      ),
      DinoxoStoreItem(
        id: 'nin_35',
        platform: GamePlatform.nintendo,
        denominationUsd: 35,
        categoryName: 'Nintendo eShop',
      ),
      DinoxoStoreItem(
        id: 'nin_50',
        platform: GamePlatform.nintendo,
        denominationUsd: 50,
        categoryName: 'Nintendo eShop',
      ),

      // Xbox USA
      DinoxoStoreItem(
        id: 'xb_15',
        platform: GamePlatform.xbox,
        denominationUsd: 15,
        categoryName: 'Xbox Gift Card',
      ),
      DinoxoStoreItem(
        id: 'xb_25',
        platform: GamePlatform.xbox,
        denominationUsd: 25,
        categoryName: 'Xbox Gift Card',
      ),
      DinoxoStoreItem(
        id: 'xb_50',
        platform: GamePlatform.xbox,
        denominationUsd: 50,
        categoryName: 'Xbox Gift Card',
      ),
      DinoxoStoreItem(
        id: 'xb_100',
        platform: GamePlatform.xbox,
        denominationUsd: 100,
        categoryName: 'Xbox Gift Card',
      ),
    ];
  }
}
