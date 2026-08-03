import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:decimal/decimal.dart';
import '../providers/holdings_provider.dart';
import '../providers/market_provider.dart';
import '../core/theme/app_theme.dart';
import '../widgets/holding_row.dart';
import '../core/utils/price_formatter.dart';

enum HoldingSortType {
  pnlDesc,
  symbol,
  currentValue,
}

class HoldingsScreen extends ConsumerStatefulWidget {
  const HoldingsScreen({super.key});

  @override
  ConsumerState<HoldingsScreen> createState() => _HoldingsScreenState();
}

class _HoldingsScreenState extends ConsumerState<HoldingsScreen> {
  HoldingSortType _sortType = HoldingSortType.pnlDesc;

  @override
  Widget build(BuildContext context) {
    final holdings = ref.watch(holdingsProvider);

    if (holdings.isEmpty) {
      return Scaffold(
        backgroundColor: AppTheme.backgroundColor,
        appBar: AppBar(title: const Text('Portfolio')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.account_balance_wallet_outlined, 
                size: 80, 
                color: AppTheme.textTertiary,
              ),
              const SizedBox(height: 24),
              Text(
                'No Holdings Yet',
                style: AppTheme.heading3.copyWith(
                  color: AppTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Start by placing your first trade',
                style: AppTheme.body2.copyWith(
                  color: AppTheme.textSecondary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Go to Market to buy stocks',
                style: AppTheme.caption.copyWith(
                  color: AppTheme.textTertiary,
                ),
              ),
            ],
          ),
        ),
      );
    }

    // Individual holding rows watch their own prices for row-level updates
    // Summary calculated once when holdings change
    
    final sortedHoldings = _sortHoldings(holdings);
    final summary = _calculateSummary(sortedHoldings);

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text('Holdings'),
        actions: [
          PopupMenuButton<HoldingSortType>(
            icon: const Icon(Icons.sort_rounded),
            onSelected: (value) {
              setState(() => _sortType = value);
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: HoldingSortType.pnlDesc,
                child: Text('P&L Descending'),
              ),
              const PopupMenuItem(
                value: HoldingSortType.symbol,
                child: Text('Symbol'),
              ),
              const PopupMenuItem(
                value: HoldingSortType.currentValue,
                child: Text('Current Value'),
              ),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          _buildSummaryCard(summary),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
              itemCount: sortedHoldings.length,
              cacheExtent: 500, // OPTIMIZATION: Cache off-screen items
              itemBuilder: (context, index) {
                final holding = sortedHoldings[index];
                return Padding(
                  key: ValueKey(holding.symbol), // OPTIMIZATION: Stable keys
                  padding: const EdgeInsets.only(bottom: 8),
                  child: HoldingRow(
                    holding: holding,
                    onTap: () => context.push('/trade?symbol=${holding.symbol}'),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // OPTIMIZATION: Reduced Decimal allocations in sorting
  List _sortHoldings(List holdings) {
    final marketService = ref.read(marketServiceProvider);
    final holdingsWithData = holdings.map((h) {
      final tick = marketService.getCurrentTick(h.symbol);
      final avgCost = Decimal.parse(h.averageCost);
      final quantity = Decimal.fromInt(h.quantity);
      final invested = avgCost * quantity;
      final current = tick.price * quantity;
      final pnl = current - invested;
      return {'holding': h, 'pnl': pnl, 'current': current};
    }).toList();

    switch (_sortType) {
      case HoldingSortType.pnlDesc:
        holdingsWithData.sort((a, b) => (b['pnl'] as Decimal).compareTo(a['pnl'] as Decimal));
        break;
      case HoldingSortType.symbol:
        holdingsWithData.sort((a, b) => (a['holding'].symbol as String).compareTo(b['holding'].symbol as String));
        break;
      case HoldingSortType.currentValue:
        holdingsWithData.sort((a, b) => (b['current'] as Decimal).compareTo(a['current'] as Decimal));
        break;
    }

    return holdingsWithData.map((e) => e['holding']).toList();
  }

  // OPTIMIZATION: Memoized calculation, rebuilt only when holdings change
  Map<String, Decimal> _calculateSummary(List holdings) {
    final marketService = ref.read(marketServiceProvider);
    var totalInvested = Decimal.zero;
    var totalCurrent = Decimal.zero;

    // OPTIMIZATION: Single pass calculation with reduced Decimal allocations
    for (final holding in holdings) {
      final avgCost = Decimal.parse(holding.averageCost);
      final tick = marketService.getCurrentTick(holding.symbol);
      final quantity = Decimal.fromInt(holding.quantity);
      
      final invested = avgCost * quantity;
      final current = tick.price * quantity;

      totalInvested = totalInvested + invested;
      totalCurrent = totalCurrent + current;
    }

    final totalPnl = totalCurrent - totalInvested;
    
    Decimal totalPnlPercent;
    if (totalInvested > Decimal.zero) {
      final ratio = (totalPnl / totalInvested).toDecimal(scaleOnInfinitePrecision: 10);
      final hundred = Decimal.fromInt(100);
      totalPnlPercent = ratio * hundred;
    } else {
      totalPnlPercent = Decimal.zero;
    }

    return {
      'invested': totalInvested,
      'current': totalCurrent,
      'pnl': totalPnl,
      'pnlPercent': totalPnlPercent,
    };
  }

  Widget _buildSummaryCard(Map<String, Decimal> summary) {
    final pnl = summary['pnl']!;
    final pnlPercent = summary['pnlPercent']!;
    final isProfit = pnl >= Decimal.zero;

    return RepaintBoundary( // OPTIMIZATION: Isolate repaints
      child: Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Total P&L',
            style: AppTheme.body2.copyWith(
              color: AppTheme.textSecondary,
              letterSpacing: 0.3,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            PriceFormatter.formatChange(pnl),
            style: AppTheme.heading1.copyWith(
              color: isProfit ? AppTheme.successColor : AppTheme.errorColor,
              fontSize: 36,
            ),
          ),
          const SizedBox(height: 8),
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
                  isProfit ? Icons.trending_up_rounded : Icons.trending_down_rounded,
                  color: isProfit ? AppTheme.successColor : AppTheme.errorColor,
                  size: 16,
                ),
                const SizedBox(width: 6),
                Text(
                  PriceFormatter.formatChangePercent(pnlPercent),
                  style: AppTheme.subtitle2.copyWith(
                    color: isProfit ? AppTheme.successColor : AppTheme.errorColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Container(
            height: 1,
            color: AppTheme.dividerColor,
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(
                      'Invested',
                      style: AppTheme.caption.copyWith(
                        color: AppTheme.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '₹${PriceFormatter.formatPrice(summary['invested']!)}',
                      style: AppTheme.subtitle2.copyWith(
                        color: AppTheme.textPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              Container(
                width: 1,
                height: 44,
                color: AppTheme.dividerColor,
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(
                      'Current',
                      style: AppTheme.caption.copyWith(
                        color: AppTheme.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '₹${PriceFormatter.formatPrice(summary['current']!)}',
                      style: AppTheme.subtitle2.copyWith(
                        color: AppTheme.textPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    ));
  }
}
