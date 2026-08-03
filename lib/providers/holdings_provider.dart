import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:decimal/decimal.dart';
import '../models/holding.dart';
import '../repositories/holdings_repository.dart';

final holdingsRepositoryProvider = Provider<HoldingsRepository>((ref) {
  return HoldingsRepository();
});

final holdingsProvider = StateNotifierProvider<HoldingsNotifier, List<Holding>>((ref) {
  final repository = ref.watch(holdingsRepositoryProvider);
  return HoldingsNotifier(repository);
});

class HoldingsNotifier extends StateNotifier<List<Holding>> {
  final HoldingsRepository _repository;

  HoldingsNotifier(this._repository) : super([]) {
    _loadHoldings();
  }

  void _loadHoldings() {
    state = _repository.getAllHoldings();
  }

  Future<void> buyStock(String symbol, int quantity, Decimal price) async {
    await _repository.buyStock(symbol, quantity, price);
    _loadHoldings();
  }

  Future<void> sellStock(String symbol, int quantity) async {
    await _repository.sellStock(symbol, quantity);
    _loadHoldings();
  }

  int getHoldingQuantity(String symbol) {
    final holding = state.where((h) => h.symbol == symbol).firstOrNull;
    return holding?.quantity ?? 0;
  }

  Holding? getHolding(String symbol) {
    return state.where((h) => h.symbol == symbol).firstOrNull;
  }
}
