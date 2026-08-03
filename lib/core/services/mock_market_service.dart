import 'dart:async';
import 'dart:math';
import 'package:decimal/decimal.dart';
import '../../models/stock_tick.dart';
import '../constants/app_constants.dart';

class MockMarketService {
  final _random = Random();
  final _controller = StreamController<StockTick>.broadcast();
  final Map<String, Decimal> _currentPrices = {};
  final Map<String, Decimal> _previousCloses = {};
  final Map<String, StockTick> _cachedTicks = {};
  Timer? _timer;

  // Price constraints
  static final Decimal _minPrice = Decimal.parse('1.0');
  static final Decimal _maxPrice = Decimal.parse('100000.0');
  static final Decimal _maxChangePercent = Decimal.parse('10.0'); // ±10%

  Stream<StockTick> get tickStream => _controller.stream;

  MockMarketService() {
    _initializePrices();
    _startTicking();
  }

  void _initializePrices() {
    for (final entry in AppConstants.initialPrices.entries) {
      final price = Decimal.parse(entry.value.toString());
      final validPrice = _validatePrice(price);
      _currentPrices[entry.key] = validPrice;
      _previousCloses[entry.key] = validPrice;
      
      // Initialize cached tick
      _cachedTicks[entry.key] = StockTick(
        symbol: entry.key,
        price: validPrice,
        change: Decimal.zero,
        changePercent: Decimal.zero,
        previousClose: validPrice,
        timestamp: DateTime.now(),
      );
    }
  }

  void _startTicking() {
    _timer = Timer.periodic(
      const Duration(milliseconds: AppConstants.tickRateMilliseconds),
      (_) => _generateTick(),
    );
  }

  /// Validate and clamp price to safe range
  Decimal _validatePrice(Decimal price) {
    if (price <= Decimal.zero || price.toDouble().isNaN || price.toDouble().isInfinite) {
      return Decimal.parse('100.0'); // Default fallback
    }
    if (price < _minPrice) return _minPrice;
    if (price > _maxPrice) return _maxPrice;
    return price;
  }

  /// Safely calculate percentage with bounds
  Decimal _safePercentageCalc(Decimal numerator, Decimal denominator) {
    if (denominator <= Decimal.zero) return Decimal.zero;
    
    try {
      final ratio = (numerator / denominator).toDecimal(scaleOnInfinitePrecision: 10);
      final percent = ratio * Decimal.fromInt(100);
      
      // Clamp to reasonable range
      if (percent > _maxChangePercent) return _maxChangePercent;
      if (percent < -_maxChangePercent) return -_maxChangePercent;
      
      return percent;
    } catch (e) {
      return Decimal.zero;
    }
  }

  void _generateTick() {
    final symbols = AppConstants.availableStocks;
    final symbol = symbols[_random.nextInt(symbols.length)];
    
    final currentPrice = _currentPrices[symbol]!;
    final previousClose = _previousCloses[symbol]!;
    
    // Generate realistic price movement: ±2%
    final changePercent = (_random.nextDouble() * 4.0) - 2.0;
    final changePercentDecimal = Decimal.parse(changePercent.toStringAsFixed(4));
    final divisor = Decimal.fromInt(100);
    
    try {
      final changeAmount = (currentPrice * changePercentDecimal / divisor).toDecimal(scaleOnInfinitePrecision: 10);
      var newPrice = currentPrice + changeAmount;
      
      // Validate and clamp new price
      newPrice = _validatePrice(newPrice);
      
      // Ensure minimum movement
      if (newPrice == currentPrice) {
        newPrice = currentPrice * Decimal.parse('1.001'); // 0.1% minimum
      }
      
      _currentPrices[symbol] = newPrice;
      
      final change = newPrice - previousClose;
      final changePercentValue = _safePercentageCalc(change, previousClose);
      
      final tick = StockTick(
        symbol: symbol,
        price: newPrice,
        change: change,
        changePercent: changePercentValue,
        previousClose: previousClose,
        timestamp: DateTime.now(),
      );
      
      // Cache the tick
      _cachedTicks[symbol] = tick;
      
      // Emit tick
      if (!_controller.isClosed) {
        _controller.add(tick);
      }
    } catch (e) {
      // If any error occurs, skip this tick
      return;
    }
  }

  Decimal getCurrentPrice(String symbol) {
    return _currentPrices[symbol] ?? Decimal.parse('100.0');
  }

  StockTick getCurrentTick(String symbol) {
    // Return cached tick if available (major performance improvement)
    if (_cachedTicks.containsKey(symbol)) {
      return _cachedTicks[symbol]!;
    }
    
    // Fallback: create tick (should rarely happen)
    final price = _currentPrices[symbol] ?? Decimal.parse('100.0');
    final previousClose = _previousCloses[symbol] ?? price;
    final change = price - previousClose;
    final changePercent = _safePercentageCalc(change, previousClose);

    final tick = StockTick(
      symbol: symbol,
      price: price,
      change: change,
      changePercent: changePercent,
      previousClose: previousClose,
      timestamp: DateTime.now(),
    );
    
    _cachedTicks[symbol] = tick;
    return tick;
  }

  void dispose() {
    _timer?.cancel();
    _controller.close();
    _cachedTicks.clear();
  }
}
