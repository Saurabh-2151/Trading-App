import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:decimal/decimal.dart';
import '../providers/watchlist_provider.dart';
import '../providers/holdings_provider.dart';
import '../providers/wallet_provider.dart';
import '../providers/market_provider.dart';
import '../widgets/create_watchlist_dialog.dart';
import '../widgets/watchlist_card.dart';
import '../widgets/premium_bottom_nav.dart';
import '../core/utils/price_formatter.dart';
import '../core/theme/app_theme.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    final watchlists = ref.watch(watchlistsProvider);

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: SafeArea(
        bottom: false,
        child: IndexedStack(
          index: _selectedIndex,
          children: [
            _buildHomeTab(watchlists),
            Container(),
            Container(),
          ],
        ),
      ),
      bottomNavigationBar: PremiumBottomNav(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (index) {
          if (index == 1) {
            context.push('/market');
          } else if (index == 2) {
            context.push('/holdings');
          } else {
            setState(() => _selectedIndex = index);
          }
        },
      ),
    );
  }

  Widget _buildHomeTab(List watchlists) {
    final holdings = ref.watch(holdingsProvider);
    final balance = ref.watch(walletBalanceProvider);
    final hour = DateTime.now().hour;
    String greeting;
    if (hour < 12) {
      greeting = 'Good Morning';
    } else if (hour < 17) {
      greeting = 'Good Afternoon';
    } else {
      greeting = 'Good Evening';
    }
    
    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              hour < 12 ? Icons.wb_sunny_rounded : (hour < 17 ? Icons.wb_cloudy_rounded : Icons.nights_stay_rounded),
                              color: AppTheme.primaryColor,
                              size: 24,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              greeting,
                              style: AppTheme.heading3.copyWith(
                                color: AppTheme.textPrimary,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Welcome back',
                          style: AppTheme.body2.copyWith(
                            color: AppTheme.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              
              if (holdings.isNotEmpty) _buildPortfolioSummary(holdings, balance),
              
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Watchlists',
                      style: AppTheme.heading3.copyWith(
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    InkWell(
                      onTap: () => _showCreateWatchlistDialog(context),
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryColor,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: const [
                            Icon(Icons.add, color: Colors.white, size: 18),
                            SizedBox(width: 4),
                            Text(
                              'New',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        
        // Watchlists
        watchlists.isEmpty
            ? SliverFillRemaining(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.list_alt_outlined,
                        size: 80,
                        color: Colors.grey[300],
                      ),
                      const SizedBox(height: 24),
                      const Text(
                        'No Watchlists Yet',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w600,
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Create a watchlist to track stocks',
                        style: TextStyle(
                          fontSize: 15,
                          color: Colors.grey[600],
                        ),
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton.icon(
                        onPressed: () => _showCreateWatchlistDialog(context),
                        icon: const Icon(Icons.add),
                        label: const Text('Create Watchlist'),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              )
            : SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      return Padding(
                        key: ValueKey(watchlists[index].id), 
                        padding: const EdgeInsets.only(bottom: 12),
                        child: WatchlistCard(watchlist: watchlists[index]),
                      );
                    },
                    childCount: watchlists.length,
                  ),
                ),
              ),
      ],
    );
  }

  Widget _buildPortfolioSummary(List holdings, Decimal balance) {
    final marketService = ref.read(marketServiceProvider);
    var totalInvested = Decimal.zero;
    var totalCurrent = Decimal.zero;

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
    final totalValue = balance + totalCurrent;
    
    Decimal pnlPercent = Decimal.zero;
    if (totalInvested > Decimal.zero) {
      final ratio = (totalPnl / totalInvested).toDecimal(scaleOnInfinitePrecision: 10);
      pnlPercent = ratio * Decimal.fromInt(100);
    }
    
    final isProfit = totalPnl >= Decimal.zero;

    return RepaintBoundary( 
      child: Container(
      margin: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
  begin: Alignment.topLeft,
  end: Alignment.bottomRight,
  colors: [
    Color(0xFF4F8EF7),
    Color(0xFF6AA8FF),
  ],
),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
  color: Color(0xFF4F8EF7).withValues(alpha: 0.15),
  blurRadius: 28,
  spreadRadius: 0,
  offset: Offset(0, 10),
)
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 20, 24, 18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Holdings Value',
                  style: AppTheme.body2.copyWith(
                    color: Colors.white70,
                    letterSpacing: 0.3,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '₹${PriceFormatter.formatPrice(totalValue)}',
                  style: AppTheme.heading1.copyWith(
                    color: Colors.white,
                    fontSize: 40,
                    fontWeight: FontWeight.bold,
                    shadows: [
                      const Shadow(
                        color: Colors.black26,
                        blurRadius: 6,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Text(
                      'Total P&L',
                      style: AppTheme.body2.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      '${isProfit ? '' : ''}${PriceFormatter.formatChange(totalPnl)}',
                      style: AppTheme.subtitle1.copyWith(
                        color: isProfit ? const Color(0xFF22C55E) : const Color(0xFFEF4444),
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: isProfit 
                            ? const Color(0xFF22C55E).withValues(alpha: 0.2)
                            : const Color(0xFFEF4444).withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            isProfit ? Icons.trending_up_rounded : Icons.trending_down_rounded,
                            color: isProfit ? const Color(0xFF22C55E) : const Color(0xFFEF4444),
                            size: 14,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            PriceFormatter.formatChangePercent(pnlPercent),
                            style: TextStyle(
                              color: isProfit ? const Color(0xFF22C55E) : const Color(0xFFEF4444),
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Container(
                  height: 1,
                  color: Colors.white24,
                ),
              ],
            ),
          ),
          
          // Bottom info section
          Container(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 18),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.10),
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(24),
                bottomRight: Radius.circular(24),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: _buildSummaryItemPremium(
                    'Invested',
                    '₹${PriceFormatter.formatPrice(totalInvested)}',
                  ),
                ),
                Container(
                  width: 1,
                  height: 36,
                  color: Colors.white24,
                ),
                Expanded(
                  child: _buildSummaryItemPremium(
                    'Current',
                    '₹${PriceFormatter.formatPrice(totalCurrent)}',
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ));
  }

  Widget _buildSummaryItemPremium(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          label,
          style: AppTheme.caption.copyWith(
            color: Colors.white70,
            fontSize: 12,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: AppTheme.subtitle2.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 15,
          ),
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }

  Future<void> _showCreateWatchlistDialog(BuildContext context) async {
    await showDialog(
      context: context,
      builder: (context) => const CreateWatchlistDialog(),
    );
  }
}
