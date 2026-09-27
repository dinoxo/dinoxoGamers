import '../../core/constants/app_constants.dart';

class GameEdition {
  final String id;
  final String gameId;
  final String name;
  final ProductType productType;
  final double currentPrice;
  final double regularPrice;
  final int discountPercent;
  final double lowestObservedPrice;
  final DateTime lowestObservedDate;
  final double? providerReportedLowest;
  final bool isLowestHistorical;
  final DateTime? promoEndDate;
  final String? promoEndLabel;
  final bool requiresSubscription;
  final String? subscriptionName;
  final String sourceUrl;
  final String officialStoreUrl;
  final DateTime lastChecked;
  final List<String> includedContent;

  const GameEdition({
    required this.id,
    required this.gameId,
    required this.name,
    this.productType = ProductType.fullGame,
    required this.currentPrice,
    required this.regularPrice,
    required this.discountPercent,
    required this.lowestObservedPrice,
    required this.lowestObservedDate,
    this.providerReportedLowest,
    this.isLowestHistorical = false,
    this.promoEndDate,
    this.promoEndLabel,
    this.requiresSubscription = false,
    this.subscriptionName,
    required this.sourceUrl,
    required this.officialStoreUrl,
    required this.lastChecked,
    this.includedContent = const [],
  });

  bool get hasDiscount => discountPercent > 0 && currentPrice < regularPrice;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'gameId': gameId,
      'name': name,
      'productType': productType.name,
      'currentPrice': currentPrice,
      'regularPrice': regularPrice,
      'discountPercent': discountPercent,
      'lowestObservedPrice': lowestObservedPrice,
      'lowestObservedDate': lowestObservedDate.toIso8601String(),
      'providerReportedLowest': providerReportedLowest,
      'isLowestHistorical': isLowestHistorical ? 1 : 0,
      'promoEndDate': promoEndDate?.toIso8601String(),
      'promoEndLabel': promoEndLabel,
      'requiresSubscription': requiresSubscription ? 1 : 0,
      'subscriptionName': subscriptionName,
      'sourceUrl': sourceUrl,
      'officialStoreUrl': officialStoreUrl,
      'lastChecked': lastChecked.toIso8601String(),
      'includedContent': includedContent,
    };
  }

  factory GameEdition.fromMap(Map<String, dynamic> map) {
    return GameEdition(
      id: map['id'] as String,
      gameId: map['gameId'] as String,
      name: map['name'] as String,
      productType: ProductType.values.firstWhere(
        (e) => e.name == map['productType'],
        orElse: () => ProductType.fullGame,
      ),
      currentPrice: (map['currentPrice'] as num).toDouble(),
      regularPrice: (map['regularPrice'] as num).toDouble(),
      discountPercent: (map['discountPercent'] as num).toInt(),
      lowestObservedPrice: (map['lowestObservedPrice'] as num).toDouble(),
      lowestObservedDate: DateTime.parse(map['lowestObservedDate'] as String),
      providerReportedLowest:
          (map['providerReportedLowest'] as num?)?.toDouble(),
      isLowestHistorical:
          (map['isLowestHistorical'] == 1 || map['isLowestHistorical'] == true),
      promoEndDate: map['promoEndDate'] != null
          ? DateTime.parse(map['promoEndDate'] as String)
          : null,
      promoEndLabel: map['promoEndLabel'] as String?,
      requiresSubscription: (map['requiresSubscription'] == 1 ||
          map['requiresSubscription'] == true),
      subscriptionName: map['subscriptionName'] as String?,
      sourceUrl: map['sourceUrl'] as String? ?? '',
      officialStoreUrl: map['officialStoreUrl'] as String? ?? '',
      lastChecked: DateTime.parse(map['lastChecked'] as String),
      includedContent: (map['includedContent'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
    );
  }
}
