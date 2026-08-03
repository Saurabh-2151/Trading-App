import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:decimal/decimal.dart';
import '../models/holding.dart';
import '../providers/market_provider.dart';
import '../core/utils/price_formatter.dart';
import '../core/theme/app_theme.dart';
import 'stock_logo.dart';

class HoldingRow extends ConsumerStatefulWidget {
  final Holding holding;
  final VoidCallback onTap;

  const HoldingRow({
    super.key,
    required this.holding,
    required this.onTap,
  });

  @override
  ConsumerState<HoldingRow> createState() => _HoldingRowState();
}

class _HoldingRowState extends ConsumerState<HoldingRow> {
  @override
  Widget build(BuildContext context) {
    final tickAsync = ref.watch(stockPriceProvider(widget.holding.symbol));
    
    final tick = tickAsync.maybeWhen(
      data: (t) => t,
      orElse: () => ref.read(marketServiceProvider).getCurrentTick(widget.holding.symbol),
    );

    final avgCost = Decimal.parse(widget.holding.averageCost);
    final quantity = widget.holding.quantity;
    final invested = avgCost * Decimal.fromInt(quantity);
    final currentValue = tick.price * Decimal.fromInt(quantity);
    final pnl = currentValue - invested;
    
    Decimal pnlPercent;
    if (invested > Decimal.zero) {
      final ratio = (pnl / invested).toDecimal(scaleOnInfinitePrecision: 10);
      final hundred = Decimal.fromInt(100);
      pnlPercent = ratio * hundred;
    } else {
      pnlPercent = Decimal.zero;
    }

    final isProfit = pnl >= Decimal.zero;

    return RepaintBoundary(
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: AppTheme.cardShadow,
        ),
        child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: widget.onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                StockLogo(symbol: widget.holding.symbol, size: 44),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.holding.symbol,
                        style: AppTheme.subtitle1.copyWith(
                          color: AppTheme.textPrimary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Qty: ${PriceFormatter.formatQuantity(quantity)} • Avg: ₹${PriceFormatter.formatPrice(avgCost)}',
                        style: AppTheme.caption.copyWith(
                          color: AppTheme.textSecondary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Invested: ₹${PriceFormatter.formatPrice(invested)}',
                        style: AppTheme.caption.copyWith(
                          color: AppTheme.textSecondary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '₹${PriceFormatter.formatPrice(currentValue)}',
                      style: AppTheme.subtitle1.copyWith(
                        color: AppTheme.textPrimary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: isProfit 
                            ? AppTheme.successColor.withValues(alpha: 0.1)
                            : AppTheme.errorColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            isProfit 
                                ? Icons.arrow_upward_rounded
                                : Icons.arrow_downward_rounded,
                            size: 12,
                            color: isProfit 
                                ? AppTheme.successColor
                                : AppTheme.errorColor,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            PriceFormatter.formatChangePercent(pnlPercent),
                            style: AppTheme.caption.copyWith(
                              color: isProfit 
                                  ? AppTheme.successColor
                                  : AppTheme.errorColor,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      PriceFormatter.formatChange(pnl),
                      style: AppTheme.caption.copyWith(
                        color: isProfit 
                            ? AppTheme.successColor
                            : AppTheme.errorColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    ));
  }
}
