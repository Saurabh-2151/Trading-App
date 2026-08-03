import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:decimal/decimal.dart';
import '../providers/market_provider.dart';
import '../core/utils/price_formatter.dart';
import '../core/constants/app_constants.dart';
import '../core/theme/app_theme.dart';
import '../models/stock_tick.dart';
import 'stock_logo.dart';
import 'mini_sparkline.dart';
import 'sector_badge.dart';

class MarketStockRow extends ConsumerStatefulWidget {
  final String symbol;
  final VoidCallback onTap;

  const MarketStockRow({
    super.key,
    required this.symbol,
    required this.onTap,
  });

  @override
  ConsumerState<MarketStockRow> createState() => _MarketStockRowState();
}

class _MarketStockRowState extends ConsumerState<MarketStockRow> {
  Color? _flashColor;
  Timer? _flashTimer;

  @override
  void dispose() {
    _flashTimer?.cancel();
    super.dispose();
  }

  void _triggerFlash(Color color) {
    _flashTimer?.cancel();
    setState(() => _flashColor = color);
    _flashTimer = Timer(const Duration(milliseconds: 250), () {
      if (mounted) {
        setState(() => _flashColor = null);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final tickAsync = ref.watch(stockPriceProvider(widget.symbol));
    
    return tickAsync.when(
      data: (tick) => _buildRow(context, tick),
      loading: () => _buildLoading(),
      error: (_, __) => _buildError(),
    );
  }

  Widget _buildRow(BuildContext context, StockTick tick) {
    ref.listen<AsyncValue<StockTick>>(
      stockPriceProvider(widget.symbol),
      (previous, next) {
        next.whenData((newTick) {
          if (previous?.value != null) {
            final oldPrice = previous!.value!.price;
            final newPrice = newTick.price;

            if (newPrice > oldPrice) {
              _triggerFlash(Colors.green.withValues(alpha: 0.2));
            } else if (newPrice < oldPrice) {
              _triggerFlash(Colors.red.withValues(alpha: 0.2));
            }
          }
        });
      },
    );

    return RepaintBoundary(
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        decoration: BoxDecoration(
          color: _flashColor ?? Colors.white,
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
              child: _buildContent(tick),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildContent(StockTick tick) {
    final isNegative = tick.change < Decimal.zero;
    final changeColor = isNegative ? AppTheme.errorColor : AppTheme.successColor;

    return Row(
      children: [
        Hero(
          tag: 'stock_logo_${widget.symbol}',
          child: StockLogo(symbol: widget.symbol, size: 48),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Flexible(
                    child: Text(
                      widget.symbol,
                      style: AppTheme.subtitle1.copyWith(color: AppTheme.textPrimary),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  SectorBadge(sector: AppConstants.getSector(widget.symbol)),
                ],
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  Flexible(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: changeColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            isNegative ? Icons.arrow_downward_rounded : Icons.arrow_upward_rounded,
                            size: 12,
                            color: changeColor,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            PriceFormatter.formatChangePercent(tick.changePercent),
                            style: AppTheme.caption.copyWith(
                              color: changeColor,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      PriceFormatter.formatChange(tick.change),
                      style: AppTheme.caption.copyWith(
                        color: changeColor,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '₹${PriceFormatter.formatPrice(tick.price)}',
              style: AppTheme.subtitle1.copyWith(
                color: AppTheme.textPrimary,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 6),
            MiniSparkline(
              color: changeColor,
              width: 50,
              height: 18,
              showPositiveTrend: !isNegative,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildLoading() {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: AppTheme.cardShadow,
      ),
      child: const Padding(
        padding: EdgeInsets.all(16),
        child: Center(child: CircularProgressIndicator()),
      ),
    );
  }

  Widget _buildError() {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: AppTheme.cardShadow,
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Text('Error loading ${widget.symbol}'),
      ),
    );
  }
}
