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

class WatchlistStockRow extends ConsumerStatefulWidget {
  final String symbol;
  final String watchlistId;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const WatchlistStockRow({
    super.key,
    required this.symbol,
    required this.watchlistId,
    required this.onTap,
    required this.onDelete,
  });

  @override
  ConsumerState<WatchlistStockRow> createState() => _WatchlistStockRowState();
}

class _WatchlistStockRowState extends ConsumerState<WatchlistStockRow> {
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
    // Only watch for price updates, don't read on every build
    final tickAsync = ref.watch(stockPriceProvider(widget.symbol));
    
    return tickAsync.when(
      data: (tick) => _buildRow(context, tick),
      loading: () => _buildLoading(),
      error: (_, __) => _buildError(),
    );
  }

  Widget _buildRow(BuildContext context, StockTick tick) {
    // Listen for price changes for flash animation
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
        margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
        decoration: BoxDecoration(
          color: _flashColor ?? Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: AppTheme.cardShadow,
        ),
        child: Dismissible(
          key: ValueKey('${widget.watchlistId}_${widget.symbol}'),
          direction: DismissDirection.endToStart,
          background: _buildDismissBackground(),
          confirmDismiss: (_) => _confirmDismiss(context),
          onDismissed: (_) => widget.onDelete(),
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

  Widget _buildDismissBackground() {
    return Container(
      alignment: Alignment.centerRight,
      padding: const EdgeInsets.only(right: 24),
      decoration: BoxDecoration(
        gradient: AppTheme.errorGradient,
        borderRadius: BorderRadius.circular(16),
      ),
      child: const Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.delete_rounded, color: Colors.white, size: 28),
          SizedBox(height: 4),
          Text(
            'Delete',
            style: TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Future<bool?> _confirmDismiss(BuildContext context) {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Remove Stock'),
        content: Text('Remove ${widget.symbol} from watchlist?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.errorColor),
            child: const Text('Remove'),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(StockTick tick) {
    final isNegative = tick.change < Decimal.zero;
    final changeColor = isNegative ? AppTheme.errorColor : AppTheme.successColor;

    return Row(
      children: [
        // Drag Handle
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 12),
          child: Icon(
            Icons.drag_indicator_rounded,
            color: AppTheme.textTertiary,
            size: 20,
          ),
        ),
        const SizedBox(width: 8),
        
        // Stock Logo
        Hero(
          tag: 'stock_logo_${widget.symbol}',
          child: StockLogo(symbol: widget.symbol, size: 44),
        ),
        const SizedBox(width: 12),
        
        // Stock Info
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
                  SectorBadge(
                    sector: AppConstants.getSector(widget.symbol),
                    fontSize: 9,
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  MiniSparkline(
                    color: changeColor,
                    width: 50,
                    height: 18,
                    showPositiveTrend: !isNegative,
                  ),
                  const SizedBox(width: 10),
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
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        
        // Price
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
            const SizedBox(height: 4),
            Text(
              PriceFormatter.formatChange(tick.change),
              style: AppTheme.caption.copyWith(
                color: changeColor,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildLoading() {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
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
      margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
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
