import 'package:decimal/decimal.dart';

class StockTick {
  final String symbol;
  final Decimal price;
  final Decimal change;
  final Decimal changePercent;
  final Decimal previousClose;
  final DateTime timestamp;

  StockTick({
    required this.symbol,
    required this.price,
    required this.change,
    required this.changePercent,
    required this.previousClose,
    required this.timestamp,
  });

  StockTick copyWith({
    String? symbol,
    Decimal? price,
    Decimal? change,
    Decimal? changePercent,
    Decimal? previousClose,
    DateTime? timestamp,
  }) {
    return StockTick(
      symbol: symbol ?? this.symbol,
      price: price ?? this.price,
      change: change ?? this.change,
      changePercent: changePercent ?? this.changePercent,
      previousClose: previousClose ?? this.previousClose,
      timestamp: timestamp ?? this.timestamp,
    );
  }
}
