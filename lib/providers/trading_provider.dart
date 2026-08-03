import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/services/trading_service.dart';
import 'wallet_provider.dart';
import 'holdings_provider.dart';
import 'order_provider.dart';

final tradingServiceProvider = Provider<TradingService>((ref) {
  return TradingService(
    walletRepository: ref.watch(walletRepositoryProvider),
    holdingsRepository: ref.watch(holdingsRepositoryProvider),
    orderRepository: ref.watch(orderRepositoryProvider),
  );
});
