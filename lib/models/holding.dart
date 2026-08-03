import 'package:hive/hive.dart';

part 'holding.g.dart';

@HiveType(typeId: 1)
class Holding extends HiveObject {
  @HiveField(0)
  String symbol;

  @HiveField(1)
  int quantity;

  @HiveField(2)
  String averageCost;

  Holding({
    required this.symbol,
    required this.quantity,
    required this.averageCost,
  });

  Holding copyWith({
    String? symbol,
    int? quantity,
    String? averageCost,
  }) {
    return Holding(
      symbol: symbol ?? this.symbol,
      quantity: quantity ?? this.quantity,
      averageCost: averageCost ?? this.averageCost,
    );
  }
}
