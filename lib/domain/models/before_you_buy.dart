// Before You Buy ("Antes de comprar") detailed evaluation model

class BeforeYouBuyData {
  final int? criticScore;
  final String criticScoreSource;
  final int? criticReviewCount;
  final double? userScore;
  final int? userReviewCount;
  final List<String> pros;
  final List<String> cons;
  final String? trailerUrl;
  final String? gameplayUrl;
  final Map<String, String> consolePerformance;
  final List<String> usLanguages;
  final double? mainStoryHours;
  final double? completionistHours;
  final String playtimeSource;
  final bool isMultiplayer;
  final bool isCoop;
  final bool hasCrossplay;
  final bool requiresOnline;
  final String? subscriptionRequirement;
  final String? additionalPurchases;

  const BeforeYouBuyData({
    this.criticScore,
    this.criticScoreSource = 'Metacritic / OpenCritic',
    this.criticReviewCount,
    this.userScore,
    this.userReviewCount,
    this.pros = const [],
    this.cons = const [],
    this.trailerUrl,
    this.gameplayUrl,
    this.consolePerformance = const {},
    this.usLanguages = const [],
    this.mainStoryHours,
    this.completionistHours,
    this.playtimeSource = 'HowLongToBeat',
    this.isMultiplayer = false,
    this.isCoop = false,
    this.hasCrossplay = false,
    this.requiresOnline = false,
    this.subscriptionRequirement,
    this.additionalPurchases,
  });

  Map<String, dynamic> toMap() {
    return {
      'criticScore': criticScore,
      'criticScoreSource': criticScoreSource,
      'criticReviewCount': criticReviewCount,
      'userScore': userScore,
      'userReviewCount': userReviewCount,
      'pros': pros,
      'cons': cons,
      'trailerUrl': trailerUrl,
      'gameplayUrl': gameplayUrl,
      'consolePerformance': consolePerformance,
      'usLanguages': usLanguages,
      'mainStoryHours': mainStoryHours,
      'completionistHours': completionistHours,
      'playtimeSource': playtimeSource,
      'isMultiplayer': isMultiplayer,
      'isCoop': isCoop,
      'hasCrossplay': hasCrossplay,
      'requiresOnline': requiresOnline,
      'subscriptionRequirement': subscriptionRequirement,
      'additionalPurchases': additionalPurchases,
    };
  }

  factory BeforeYouBuyData.fromMap(Map<String, dynamic> map) {
    return BeforeYouBuyData(
      criticScore: map['criticScore'] as int?,
      criticScoreSource: map['criticScoreSource'] as String? ?? 'Metacritic / OpenCritic',
      criticReviewCount: map['criticReviewCount'] as int?,
      userScore: (map['userScore'] as num?)?.toDouble(),
      userReviewCount: map['userReviewCount'] as int?,
      pros: (map['pros'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
      cons: (map['cons'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
      trailerUrl: map['trailerUrl'] as String?,
      gameplayUrl: map['gameplayUrl'] as String?,
      consolePerformance: (map['consolePerformance'] as Map<dynamic, dynamic>?)?.map(
            (k, v) => MapEntry(k.toString(), v.toString()),
          ) ??
          {},
      usLanguages: (map['usLanguages'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
      mainStoryHours: (map['mainStoryHours'] as num?)?.toDouble(),
      completionistHours: (map['completionistHours'] as num?)?.toDouble(),
      playtimeSource: map['playtimeSource'] as String? ?? 'HowLongToBeat',
      isMultiplayer: map['isMultiplayer'] as bool? ?? false,
      isCoop: map['isCoop'] as bool? ?? false,
      hasCrossplay: map['hasCrossplay'] as bool? ?? false,
      requiresOnline: map['requiresOnline'] as bool? ?? false,
      subscriptionRequirement: map['subscriptionRequirement'] as String?,
      additionalPurchases: map['additionalPurchases'] as String?,
    );
  }
}
