import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'dart:async';
import '../core/constants/app_constants.dart';
import '../core/theme/app_theme.dart';
import '../widgets/market_stock_row.dart';

class MarketScreen extends ConsumerStatefulWidget {
  const MarketScreen({super.key});

  @override
  ConsumerState<MarketScreen> createState() => _MarketScreenState();
}

class _MarketScreenState extends ConsumerState<MarketScreen> {
  final _searchController = TextEditingController();
  String _searchQuery = '';
  Timer? _debounceTimer; // OPTIMIZATION: Debounce search

  @override
  void dispose() {
    _searchController.dispose();
    _debounceTimer?.cancel(); // OPTIMIZATION: Clean up timer
    super.dispose();
  }

  // OPTIMIZATION: Debounce search to prevent rebuild on every keystroke
  void _onSearchChanged(String value) {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 300), () {
      if (mounted) {
        setState(() {
          _searchQuery = value;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final filteredStocks = AppConstants.availableStocks
        .where((symbol) => symbol.toLowerCase().contains(_searchQuery.toLowerCase()))
        .toList();
        
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text('Market'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search stocks...',
                prefixIcon: Icon(Icons.search, color: AppTheme.textSecondary),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _debounceTimer?.cancel(); // OPTIMIZATION: Cancel pending debounce
                          setState(() {
                            _searchController.clear();
                            _searchQuery = '';
                          });
                        },
                      )
                    : null,
              ),
              onChanged: (value) {
                // OPTIMIZATION: Immediate update for clear button visibility, debounced for filtering
                if (value.isEmpty) {
                  _debounceTimer?.cancel();
                  setState(() {
                    _searchQuery = '';
                  });
                } else {
                  _onSearchChanged(value);
                }
              },
            ),
          ),
          Expanded(
            child: filteredStocks.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.search_off_rounded,
                          size: 64,
                          color: AppTheme.textTertiary,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No stocks found',
                          style: AppTheme.subtitle1.copyWith(
                            color: AppTheme.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
                    itemCount: filteredStocks.length,
                    cacheExtent: 500, // OPTIMIZATION: Cache off-screen items for smoother scrolling
                    itemBuilder: (context, index) {
                      final symbol = filteredStocks[index];
                      return Padding(
                        key: ValueKey(symbol), // OPTIMIZATION: Stable keys for better diff performance
                        padding: const EdgeInsets.only(bottom: 8),
                        child: MarketStockRow(
                          symbol: symbol,
                          onTap: () => context.push('/trade?symbol=$symbol'),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
