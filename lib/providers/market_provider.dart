import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/services/mock_market_service.dart';
import '../models/stock_tick.dart';
import '../core/constants/app_constants.dart';

final marketServiceProvider = Provider<MockMarketService>((ref) {
  final service = MockMarketService();
  ref.onDispose(() => service.dispose());
  return service;
});

final marketTickStreamProvider = StreamProvider<StockTick>((ref) {
  final service = ref.watch(marketServiceProvider);
  return service.tickStream;
});

final stockPriceProvider = StreamProvider.family<StockTick, String>((ref, symbol) {
  final service = ref.watch(marketServiceProvider);
  
  return service.tickStream
      .where((tick) => tick.symbol == symbol)
      .map((tick) => tick);
});

final currentStockTickProvider = Provider.family<StockTick, String>((ref, symbol) {
  final service = ref.watch(marketServiceProvider);
  return service.getCurrentTick(symbol);
});

final allStocksTickProvider = Provider<List<StockTick>>((ref) {
  final service = ref.watch(marketServiceProvider);
  return AppConstants.availableStocks
      .map((symbol) => service.getCurrentTick(symbol))
      .toList();
});
