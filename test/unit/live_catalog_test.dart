import 'package:flutter_test/flutter_test.dart';
import 'package:dinoxo_gamers/data/repositories/game_repository.dart';

void main() {
  test('production catalog starts empty instead of manufacturing offers',
      () async {
    expect(await GameRepository().getGames(), isEmpty);
  });

  test('unknown editions never get synthetic price history', () async {
    expect(await GameRepository().getPriceHistory('web_unknown_std', 69.99),
        isEmpty);
  });
}
