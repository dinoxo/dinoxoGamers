import 'package:dinoxo_gamers/core/constants/app_constants.dart';
import 'package:dinoxo_gamers/data/datasources/web_scraper_service.dart';
import 'package:dinoxo_gamers/data/repositories/game_repository.dart';
import 'package:dinoxo_gamers/domain/models/game.dart';
import 'package:dinoxo_gamers/domain/models/user_alert.dart';
import 'package:dinoxo_gamers/domain/models/price_observation.dart';

class TestRepository extends GameRepository {
  @override
  Future<LiveCatalogPage> refreshLiveDeals(
          {GamePlatform? platform, int page = 1}) async =>
      const LiveCatalogPage([]);
  @override
  Future<List<Game>> getFavoriteGames() async => [];
  @override
  Future<List<UserAlert>> getAlerts() async => [];
  @override
  Future<Game?> getGameById(String id) async => null;
  @override
  Future<bool> isFavorite(String gameId) async => false;
  @override
  Future<bool> isGameOwned(String gameId) async => false;
  @override
  Future<List<PriceObservation>> getPriceHistory(
          String editionId, double regularPrice) async =>
      [];
  @override
  Future<Game> refreshGame(Game game) async => game;
}
