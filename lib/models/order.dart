import 'package:hive/hive.dart';

part 'order.g.dart';

@HiveType(typeId: 2)
class Order extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String symbol;

  @HiveField(2)
  String type;

  @HiveField(3)
  int quantity;

  @HiveField(4)
  String price;

  @HiveField(5)
  String totalValue;

  @HiveField(6)
  DateTime timestamp;

  Order({
    required this.id,
    required this.symbol,
    required this.type,
    required this.quantity,
    required this.price,
    required this.totalValue,
    required this.timestamp,
  });
}
