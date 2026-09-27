import 'package:intl/intl.dart';

class CurrencyFormatter {
  CurrencyFormatter._();

  static final NumberFormat _usdFormat = NumberFormat.currency(
    locale: 'en_US',
    symbol: '\$',
    decimalDigits: 2,
  );

  static String formatUsd(double amount) {
    return _usdFormat.format(amount);
  }

  static String formatDiscount(int percent) {
    if (percent <= 0) return '0%';
    return '-$percent%';
  }

  /// Calculates discount percentage from regular (MSRP) and current price.
  static int calculateDiscountPercent({
    required double regularPrice,
    required double currentPrice,
  }) {
    if (regularPrice <= 0 || currentPrice >= regularPrice) return 0;
    final diff = regularPrice - currentPrice;
    final percent = ((diff / regularPrice) * 100).round();
    return percent.clamp(0, 100);
  }
}
