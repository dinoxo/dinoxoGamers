import '../../core/constants/app_constants.dart';

class UserAlert {
  final String id;
  final String gameId;
  final String editionId;
  final String gameTitle;
  final GamePlatform platform;
  final String editionName;
  final double targetPrice;
  final bool alertOnAllTimeLow;
  final bool alertOnPromoEnding;
  final bool isActive;
  final DateTime createdAt;
  final DateTime? lastNotifiedAt;

  const UserAlert({
    required this.id,
    required this.gameId,
    required this.editionId,
    required this.gameTitle,
    required this.platform,
    required this.editionName,
    required this.targetPrice,
    this.alertOnAllTimeLow = true,
    this.alertOnPromoEnding = false,
    this.isActive = true,
    required this.createdAt,
    this.lastNotifiedAt,
  });

  UserAlert copyWith({
    String? id,
    String? gameId,
    String? editionId,
    String? gameTitle,
    GamePlatform? platform,
    String? editionName,
    double? targetPrice,
    bool? alertOnAllTimeLow,
    bool? alertOnPromoEnding,
    bool? isActive,
    DateTime? createdAt,
    DateTime? lastNotifiedAt,
  }) {
    return UserAlert(
      id: id ?? this.id,
      gameId: gameId ?? this.gameId,
      editionId: editionId ?? this.editionId,
      gameTitle: gameTitle ?? this.gameTitle,
      platform: platform ?? this.platform,
      editionName: editionName ?? this.editionName,
      targetPrice: targetPrice ?? this.targetPrice,
      alertOnAllTimeLow: alertOnAllTimeLow ?? this.alertOnAllTimeLow,
      alertOnPromoEnding: alertOnPromoEnding ?? this.alertOnPromoEnding,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      lastNotifiedAt: lastNotifiedAt ?? this.lastNotifiedAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'gameId': gameId,
      'editionId': editionId,
      'gameTitle': gameTitle,
      'platform': platform.name,
      'editionName': editionName,
      'targetPrice': targetPrice,
      'alertOnAllTimeLow': alertOnAllTimeLow ? 1 : 0,
      'alertOnPromoEnding': alertOnPromoEnding ? 1 : 0,
      'isActive': isActive ? 1 : 0,
      'createdAt': createdAt.toIso8601String(),
      'lastNotifiedAt': lastNotifiedAt?.toIso8601String(),
    };
  }

  factory UserAlert.fromMap(Map<String, dynamic> map) {
    return UserAlert(
      id: map['id'] as String,
      gameId: map['gameId'] as String,
      editionId: map['editionId'] as String,
      gameTitle: map['gameTitle'] as String,
      platform: GamePlatform.values.firstWhere(
        (e) => e.name == map['platform'],
        orElse: () => GamePlatform.playstation,
      ),
      editionName: map['editionName'] as String,
      targetPrice: (map['targetPrice'] as num).toDouble(),
      alertOnAllTimeLow: (map['alertOnAllTimeLow'] == 1 || map['alertOnAllTimeLow'] == true),
      alertOnPromoEnding: (map['alertOnPromoEnding'] == 1 || map['alertOnPromoEnding'] == true),
      isActive: (map['isActive'] == 1 || map['isActive'] == true),
      createdAt: DateTime.parse(map['createdAt'] as String),
      lastNotifiedAt: map['lastNotifiedAt'] != null ? DateTime.parse(map['lastNotifiedAt'] as String) : null,
    );
  }
}
