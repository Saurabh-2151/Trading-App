import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:decimal/decimal.dart';
import '../providers/market_provider.dart';
import '../providers/wallet_provider.dart';
import '../providers/holdings_provider.dart';
import '../providers/trading_provider.dart';
import '../core/utils/price_formatter.dart';
import '../core/theme/app_theme.dart';
import '../widgets/stock_logo.dart';

class TradeTicketScreen extends ConsumerStatefulWidget {
  final String symbol;

  const TradeTicketScreen({
    super.key,
    required this.symbol,
  });

  @override
  ConsumerState<TradeTicketScreen> createState() => _TradeTicketScreenState();
}

class _TradeTicketScreenState extends ConsumerState<TradeTicketScreen> {
  bool _isBuy = true;
  final _quantityController = TextEditingController();
  String? _errorMessage;

  @override
  void dispose() {
    _quantityController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.symbol.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('Trade')),
        body: const Center(child: Text('No symbol selected')),
      );
    }

    // OPTIMIZED: Single subscription pattern - use tick from stream
    final tickAsync = ref.watch(stockPriceProvider(widget.symbol));
    
    // Use cached tick while waiting for stream update
    final tick = tickAsync.maybeWhen(
      data: (t) => t,
      orElse: () => ref.read(marketServiceProvider).getCurrentTick(widget.symbol),
    );

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: Text(widget.symbol),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildStockHeader(),
            const SizedBox(height: 24),
            _buildBuySellToggle(),
            const SizedBox(height: 20),
            _buildCurrentPriceCard(tick),
            const SizedBox(height: 20),
            _buildQuantityField(),
            const SizedBox(height: 12),
            _buildQuickQuantityChips(),
            const SizedBox(height: 20),
            _buildOrderValue(tick.price),
            if (_errorMessage != null) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.errorColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  _errorMessage!,
                  style: AppTheme.body2.copyWith(
                    color: AppTheme.errorColor,
                  ),
                ),
              ),
            ],
            const SizedBox(height: 20),
            _buildInfoCard(),
            const SizedBox(height: 20),
            _buildExecuteButton(tick.price),
            const SizedBox(height: 100),
          ],
        ),
      ),
    );
  }

  Widget _buildStockHeader() {
    return Center(
      child: Column(
        children: [
          Hero(
            tag: 'stock_logo_${widget.symbol}',
            child: StockLogo(symbol: widget.symbol, size: 56),
          ),
          const SizedBox(height: 12),
          Text(
            widget.symbol,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickQuantityChips() {
    final quantities = [1, 5, 10, 25, 50, 100];
    
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: quantities.map((qty) {
        return ActionChip(
          label: Text(
            qty.toString(),
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
          onPressed: () {
            setState(() {
              _quantityController.text = qty.toString();
              _errorMessage = null;
            });
          },
          backgroundColor: Colors.grey[100],
          side: BorderSide(color: Colors.grey[300]!),
          padding: const EdgeInsets.symmetric(horizontal: 8),
        );
      }).toList(),
    );
  }

  Widget _buildBuySellToggle() {
    return SegmentedButton<bool>(
      segments: const [
        ButtonSegment(value: true, label: Text('BUY'), icon: Icon(Icons.add_circle)),
        ButtonSegment(value: false, label: Text('SELL'), icon: Icon(Icons.remove_circle)),
      ],
      selected: {_isBuy},
      onSelectionChanged: (Set<bool> newSelection) {
        setState(() {
          _isBuy = newSelection.first;
          _errorMessage = null;
        });
      },
    );
  }

  Widget _buildCurrentPriceCard(tick) {
    final isProfit = tick.change >= Decimal.zero;
    
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: AppTheme.cardShadow,
      ),
      child: Column(
        children: [
          Text(
            'Current LTP',
            style: AppTheme.body2.copyWith(
              color: AppTheme.textSecondary,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            '₹${PriceFormatter.formatPrice(tick.price)}',
            style: AppTheme.heading1.copyWith(
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: isProfit 
                  ? AppTheme.successColor.withValues(alpha: 0.1)
                  : AppTheme.errorColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  isProfit 
                      ? Icons.arrow_upward_rounded
                      : Icons.arrow_downward_rounded,
                  size: 14,
                  color: isProfit 
                      ? AppTheme.successColor
                      : AppTheme.errorColor,
                ),
                const SizedBox(width: 6),
                Text(
                  '${PriceFormatter.formatChange(tick.change)} (${PriceFormatter.formatChangePercent(tick.changePercent)})',
                  style: AppTheme.subtitle2.copyWith(
                    color: isProfit 
                        ? AppTheme.successColor
                        : AppTheme.errorColor,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuantityField() {
    return TextField(
      controller: _quantityController,
      decoration: InputDecoration(
        labelText: 'Quantity',
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        hintText: 'Enter quantity',
        filled: true,
        fillColor: Colors.grey[50],
      ),
      keyboardType: TextInputType.number,
      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
      onChanged: (_) {
        setState(() => _errorMessage = null);
      },
    );
  }

  Widget _buildOrderValue(Decimal price) {
    final quantityText = _quantityController.text;
    if (quantityText.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: AppTheme.cardShadow,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Order Value',
              style: AppTheme.body2.copyWith(
                color: AppTheme.textSecondary,
              ),
            ),
            Text(
              '₹0.00',
              style: AppTheme.subtitle1.copyWith(
                color: AppTheme.textSecondary,
              ),
            ),
          ],
        ),
      );
    }

    final quantity = int.tryParse(quantityText) ?? 0;
    final orderValue = Decimal.parse((price * Decimal.fromInt(quantity)).toString());

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: AppTheme.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Order Value',
            style: AppTheme.body2.copyWith(
              color: AppTheme.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '₹${PriceFormatter.formatPrice(orderValue)}',
            style: AppTheme.heading2.copyWith(
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '${PriceFormatter.formatQuantity(quantity)} × ₹${PriceFormatter.formatPrice(price)}',
            style: AppTheme.caption.copyWith(
              color: AppTheme.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExecuteButton(Decimal price) {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: () => _executeOrder(price),
        style: ElevatedButton.styleFrom(
          backgroundColor: _isBuy ? AppTheme.successColor : AppTheme.errorColor,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        child: Text(
          _isBuy ? 'BUY' : 'SELL',
          style: const TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.5,
          ),
        ),
      ),
    );
  }

  Widget _buildInfoCard() {
    final balance = ref.watch(walletBalanceProvider);
    final holdingQty = ref.read(holdingsProvider.notifier).getHoldingQuantity(widget.symbol);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: AppTheme.cardShadow,
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Wallet Balance',
                style: AppTheme.body2.copyWith(
                  color: AppTheme.textSecondary,
                ),
              ),
              Text(
                '₹${PriceFormatter.formatPrice(balance)}',
                style: AppTheme.subtitle2.copyWith(
                  color: AppTheme.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Holdings',
                style: AppTheme.body2.copyWith(
                  color: AppTheme.textSecondary,
                ),
              ),
              Text(
                PriceFormatter.formatQuantity(holdingQty),
                style: AppTheme.subtitle2.copyWith(
                  color: AppTheme.textPrimary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _executeOrder(Decimal price) async {
    final quantityText = _quantityController.text.trim();
    
    if (quantityText.isEmpty) {
      setState(() => _errorMessage = 'Please enter quantity');
      return;
    }

    final quantity = int.tryParse(quantityText);
    if (quantity == null || quantity <= 0) {
      setState(() => _errorMessage = 'Quantity must be positive');
      return;
    }

    final tradingService = ref.read(tradingServiceProvider);
    
    final result = _isBuy
        ? await tradingService.executeBuy(
            symbol: widget.symbol,
            quantity: quantity,
            price: price,
          )
        : await tradingService.executeSell(
            symbol: widget.symbol,
            quantity: quantity,
            price: price,
          );

    if (!mounted) return;

    if (!result.success) {
      setState(() => _errorMessage = result.message);
      return;
    }

    ref.invalidate(walletBalanceProvider);
    ref.invalidate(holdingsProvider);

    final orderValue = price * Decimal.fromInt(quantity);

    context.pushReplacement(
      '/order-confirmation?symbol=${widget.symbol}&type=${_isBuy ? "BUY" : "SELL"}&quantity=$quantity&price=${price.toString()}&total=${orderValue.toString()}',
    );
  }
}
