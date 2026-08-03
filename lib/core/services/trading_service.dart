import 'package:decimal/decimal.dart';
import '../../repositories/wallet_repository.dart';
import '../../repositories/holdings_repository.dart';
import '../../repositories/order_repository.dart';

class TradingService {
  final WalletRepository _walletRepository;
  final HoldingsRepository _holdingsRepository;
  final OrderRepository _orderRepository;

  TradingService({
    required WalletRepository walletRepository,
    required HoldingsRepository holdingsRepository,
    required OrderRepository orderRepository,
  })  : _walletRepository = walletRepository,
        _holdingsRepository = holdingsRepository,
        _orderRepository = orderRepository;

  Future<TradingResult> executeBuy({
    required String symbol,
    required int quantity,
    required Decimal price,
  }) async {
    if (quantity <= 0) {
      return TradingResult(
        success: false,
        message: 'Quantity must be positive',
      );
    }

    final totalValue = price * Decimal.fromInt(quantity);

    if (!_walletRepository.hasSufficientBalance(totalValue)) {
      return TradingResult(
        success: false,
        message: 'Insufficient wallet balance',
      );
    }

    await _walletRepository.deductBalance(totalValue);
    await _holdingsRepository.buyStock(symbol, quantity, price);
    await _orderRepository.createOrder(
      symbol: symbol,
      type: 'BUY',
      quantity: quantity,
      price: price.toString(),
      totalValue: totalValue.toString(),
    );

    return TradingResult(
      success: true,
      message: 'Buy order executed successfully',
      orderId: 'order_${DateTime.now().millisecondsSinceEpoch}',
    );
  }

  Future<TradingResult> executeSell({
    required String symbol,
    required int quantity,
    required Decimal price,
  }) async {
    if (quantity <= 0) {
      return TradingResult(
        success: false,
        message: 'Quantity must be positive',
      );
    }

    final holding = _holdingsRepository.getHolding(symbol);
    if (holding == null || holding.quantity < quantity) {
      return TradingResult(
        success: false,
        message: 'Insufficient holding quantity',
      );
    }

    final totalValue = price * Decimal.fromInt(quantity);

    await _walletRepository.addBalance(totalValue);
    await _holdingsRepository.sellStock(symbol, quantity);
    await _orderRepository.createOrder(
      symbol: symbol,
      type: 'SELL',
      quantity: quantity,
      price: price.toString(),
      totalValue: totalValue.toString(),
    );

    return TradingResult(
      success: true,
      message: 'Sell order executed successfully',
      orderId: 'order_${DateTime.now().millisecondsSinceEpoch}',
    );
  }
}

class TradingResult {
  final bool success;
  final String message;
  final String? orderId;

  TradingResult({
    required this.success,
    required this.message,
    this.orderId,
  });
}
