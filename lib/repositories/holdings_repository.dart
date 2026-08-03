import 'package:decimal/decimal.dart';
import '../models/holding.dart';
import '../storage/hive_storage.dart';

class HoldingsRepository {
  List<Holding> getAllHoldings() {
    return HiveStorage.holdingsBoxInstance.values.toList();
  }

  Holding? getHolding(String symbol) {
    return HiveStorage.holdingsBoxInstance.values
        .where((h) => h.symbol == symbol)
        .firstOrNull;
  }

  Future<void> updateHolding(String symbol, int quantity, Decimal averageCost) async {
    final existing = getHolding(symbol);
    
    if (existing != null) {
      final updated = existing.copyWith(
        quantity: quantity,
        averageCost: averageCost.toString(),
      );
      final index = HiveStorage.holdingsBoxInstance.values
          .toList()
          .indexWhere((h) => h.symbol == symbol);
      if (index != -1) {
        await HiveStorage.holdingsBoxInstance.putAt(index, updated);
      }
    } else {
      final holding = Holding(
        symbol: symbol,
        quantity: quantity,
        averageCost: averageCost.toString(),
      );
      await HiveStorage.holdingsBoxInstance.add(holding);
    }
  }

  Future<void> deleteHolding(String symbol) async {
    final holding = getHolding(symbol);
    if (holding != null) {
      await holding.delete();
    }
  }

  Future<void> buyStock(String symbol, int quantity, Decimal price) async {
    final existing = getHolding(symbol);
    
    if (existing != null) {
      final existingQty = Decimal.fromInt(existing.quantity);
      final existingAvg = Decimal.parse(existing.averageCost);
      final newQty = existingQty + Decimal.fromInt(quantity);
      
      final totalCost = (existingQty * existingAvg) + (Decimal.fromInt(quantity) * price);
      final newAvg = (totalCost / newQty).toDecimal(scaleOnInfinitePrecision: 10);
      
      await updateHolding(symbol, newQty.toBigInt().toInt(), newAvg);
    } else {
      await updateHolding(symbol, quantity, price);
    }
  }

  Future<void> sellStock(String symbol, int quantity) async {
    final existing = getHolding(symbol);
    
    if (existing != null) {
      final newQuantity = existing.quantity - quantity;
      
      if (newQuantity <= 0) {
        await deleteHolding(symbol);
      } else {
        await updateHolding(
          symbol,
          newQuantity,
          Decimal.parse(existing.averageCost),
        );
      }
    }
  }
}
