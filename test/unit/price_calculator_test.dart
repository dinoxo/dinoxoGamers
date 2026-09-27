import 'package:flutter_test/flutter_test.dart';
import 'package:dinoxo_gamers/core/utils/currency_formatter.dart';

void main() {
  group('CurrencyFormatter Tests', () {
    test('calculateDiscountPercent calculates accurately for standard MSRP', () {
      final discount = CurrencyFormatter.calculateDiscountPercent(
        regularPrice: 69.99,
        currentPrice: 49.69,
      );
      expect(discount, 29);
    });

    test('calculateDiscountPercent returns 0 when current price equals regular price', () {
      final discount = CurrencyFormatter.calculateDiscountPercent(
        regularPrice: 59.99,
        currentPrice: 59.99,
      );
      expect(discount, 0);
    });

    test('calculateDiscountPercent returns 0 when current price exceeds regular price', () {
      final discount = CurrencyFormatter.calculateDiscountPercent(
        regularPrice: 59.99,
        currentPrice: 69.99,
      );
      expect(discount, 0);
    });

    test('formatUsd formats dollar amounts with 2 decimal places', () {
      expect(CurrencyFormatter.formatUsd(29.99), '\$29.99');
      expect(CurrencyFormatter.formatUsd(10.0), '\$10.00');
    });

    test('formatDiscount prefixes with minus and appends percentage', () {
      expect(CurrencyFormatter.formatDiscount(40), '-40%');
      expect(CurrencyFormatter.formatDiscount(0), '0%');
    });
  });
}
