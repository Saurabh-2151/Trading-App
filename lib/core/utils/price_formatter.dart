import 'package:decimal/decimal.dart';
import 'package:intl/intl.dart';

class PriceFormatter {
  static final _priceFormat = NumberFormat('#,##0.00');
  static final _percentFormat = NumberFormat('#,##0.00');
  static final _quantityFormat = NumberFormat('#,##0');

  /// Safely convert Decimal to double, returning 0.0 for invalid values
  static double _safeToDouble(Decimal value) {
    try {
      final doubleValue = value.toDouble();
      if (doubleValue.isNaN || doubleValue.isInfinite) {
        return 0.0;
      }
      return doubleValue;
    } catch (e) {
      return 0.0;
    }
  }

  static String formatPrice(Decimal price) {
    return _priceFormat.format(_safeToDouble(price));
  }

  static String formatPercent(Decimal percent) {
    return _percentFormat.format(_safeToDouble(percent));
  }

  static String formatQuantity(int quantity) {
    return _quantityFormat.format(quantity);
  }

  static String formatChange(Decimal change) {
    final doubleValue = _safeToDouble(change);
    final formatted = _priceFormat.format(doubleValue.abs());
    return doubleValue < 0 ? '-$formatted' : '+$formatted';
  }

  static String formatChangePercent(Decimal percent) {
    final doubleValue = _safeToDouble(percent);
    final formatted = _percentFormat.format(doubleValue.abs());
    return doubleValue < 0 ? '-$formatted%' : '+$formatted%';
  }
}
