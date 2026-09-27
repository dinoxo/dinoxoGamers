import '../../core/constants/app_constants.dart';
import 'before_you_buy.dart';
import 'game_edition.dart';
import 'review_snapshot.dart';

class Game {
  final String id;
  final String title;
  final String slug;
  final String coverUrl;
  final GamePlatform platform;
  final List<String> consoles;
  final List<String> genres;
  final String developer;
  final String publisher;
  final DateTime? releaseDate;
  final ReviewSnapshot? review;
  final bool isSampleData;
  final List<GameEdition> editions;
  final BeforeYouBuyData? beforeYouBuy;

  const Game({
    required this.id,
    required this.title,
    required this.slug,
    required this.coverUrl,
    required this.platform,
    required this.consoles,
    required this.genres,
    required this.developer,
    required this.publisher,
    required this.releaseDate,
    this.review,
    this.isSampleData = false,
    this.editions = const [],
    this.beforeYouBuy,
  });

  GameEdition? get primaryEdition =>
      editions.isNotEmpty ? editions.first : null;

  double get currentPrice => primaryEdition?.currentPrice ?? 0.0;
  double get regularPrice => primaryEdition?.regularPrice ?? 0.0;
  int get discountPercent => primaryEdition?.discountPercent ?? 0;
  bool get hasDiscount => primaryEdition?.hasDiscount ?? false;
  bool get isLowestHistorical => primaryEdition?.isLowestHistorical ?? false;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'slug': slug,
      'coverUrl': coverUrl,
      'platform': platform.name,
      'consoles': consoles.join(','),
      'genres': genres.join(','),
      'developer': developer,
      'publisher': publisher,
      'releaseDate': releaseDate?.toIso8601String(),
      'review': review?.toMap(),
      'isSampleData': isSampleData ? 1 : 0,
    };
  }

  factory Game.fromMap(Map<String, dynamic> map,
      {List<GameEdition>? editions, BeforeYouBuyData? beforeYouBuy}) {
    final rawConsoles = map['consoles'];
    final List<String> consoleList = rawConsoles is List
        ? rawConsoles.map((e) => e.toString()).toList()
        : (rawConsoles is String ? rawConsoles.split(',') : []);

    final rawGenres = map['genres'];
    final List<String> genreList = rawGenres is List
        ? rawGenres.map((e) => e.toString()).toList()
        : (rawGenres is String ? rawGenres.split(',') : []);

    return Game(
      id: map['id'] as String,
      title: map['title'] as String,
      slug: map['slug'] as String,
      coverUrl: map['coverUrl'] as String? ?? '',
      platform: GamePlatform.values.firstWhere(
        (e) => e.name == map['platform'],
        orElse: () => GamePlatform.playstation,
      ),
      consoles: consoleList,
      genres: genreList,
      developer: map['developer'] as String? ?? '',
      publisher: map['publisher'] as String? ?? '',
      releaseDate: DateTime.tryParse(map['releaseDate'] as String? ?? ''),
      review: map['review'] == null
          ? null
          : ReviewSnapshot.fromMap(
              Map<String, dynamic>.from(map['review'] as Map)),
      isSampleData: (map['isSampleData'] == 1 || map['isSampleData'] == true),
      editions: editions ?? [],
      beforeYouBuy: beforeYouBuy,
    );
  }
}
