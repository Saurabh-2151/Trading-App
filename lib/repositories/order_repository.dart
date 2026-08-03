import 'package:uuid/uuid.dart';
import '../models/order.dart';
import '../storage/hive_storage.dart';

class OrderRepository {
  final _uuid = const Uuid();

  List<Order> getAllOrders() {
    return HiveStorage.ordersBoxInstance.values.toList();
  }

  Future<void> createOrder({
    required String symbol,
    required String type,
    required int quantity,
    required String price,
    required String totalValue,
  }) async {
    final order = Order(
      id: _uuid.v4(),
      symbol: symbol,
      type: type,
      quantity: quantity,
      price: price,
      totalValue: totalValue,
      timestamp: DateTime.now(),
    );
    await HiveStorage.ordersBoxInstance.add(order);
  }
}
