import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/watchlist_provider.dart';
import '../core/theme/app_theme.dart';
import '../widgets/stock_picker_dialog.dart';
import '../widgets/watchlist_stock_row.dart';
import '../widgets/rename_watchlist_dialog.dart';

class WatchlistDetailScreen extends ConsumerWidget {
  final String watchlistId;

  const WatchlistDetailScreen({
    super.key,
    required this.watchlistId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final watchlists = ref.watch(watchlistsProvider);
    final watchlist = watchlists.where((w) => w.id == watchlistId).firstOrNull;

    if (watchlist == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Watchlist')),
        body: const Center(child: Text('Watchlist not found')),
      );
    }

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: Text(watchlist.name),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_rounded),
            onPressed: () => _showRenameDialog(context, ref, watchlist.id, watchlist.name),
            tooltip: 'Rename',
          ),
          IconButton(
            icon: const Icon(Icons.delete_rounded),
            onPressed: () => _deleteWatchlist(context, ref, watchlist.id),
            tooltip: 'Delete',
          ),
        ],
      ),
      body: watchlist.symbols.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.show_chart,
                    size: 80,
                    color: Colors.grey[300],
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'No Stocks Yet',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w600,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Add your first stock to this watchlist',
                    style: TextStyle(
                      fontSize: 15,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: () => _showStockPicker(context, ref, watchlist.id),
                    icon: const Icon(Icons.add),
                    label: const Text('Add Stock'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ],
              ),
            )
          : ReorderableListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: watchlist.symbols.length,
              buildDefaultDragHandles: true, // OPTIMIZATION: Use built-in drag handles
              onReorder: (oldIndex, newIndex) {
                _reorderStocks(ref, watchlist.id, watchlist.symbols, oldIndex, newIndex);
              },
              itemBuilder: (context, index) {
                final symbol = watchlist.symbols[index];
                return Padding(
                  key: ValueKey(symbol), // OPTIMIZATION: Stable keys for efficient reordering
                  padding: const EdgeInsets.only(bottom: 8),
                  child: WatchlistStockRow(
                    symbol: symbol,
                    watchlistId: watchlist.id,
                    onTap: () => context.push('/trade?symbol=$symbol'),
                    onDelete: () => _removeStock(ref, watchlist.id, symbol),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showStockPicker(context, ref, watchlist.id),
        icon: const Icon(Icons.add_rounded),
        label: const Text('Add Stock'),
        elevation: 4,
      ),
    );
  }

  Future<void> _showStockPicker(BuildContext context, WidgetRef ref, String watchlistId) async {
    final symbol = await showDialog<String>(
      context: context,
      builder: (context) => StockPickerDialog(watchlistId: watchlistId),
    );

    if (symbol != null) {
      await ref.read(watchlistsProvider.notifier).addStock(watchlistId, symbol);
    }
  }

  Future<void> _showRenameDialog(BuildContext context, WidgetRef ref, String id, String currentName) async {
    await showDialog(
      context: context,
      builder: (context) => RenameWatchlistDialog(
        watchlistId: id,
        currentName: currentName,
      ),
    );
  }

  Future<void> _deleteWatchlist(BuildContext context, WidgetRef ref, String id) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Watchlist'),
        content: const Text('Are you sure you want to delete this watchlist?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await ref.read(watchlistsProvider.notifier).deleteWatchlist(id);
      if (context.mounted) {
        context.pop();
      }
    }
  }

  void _removeStock(WidgetRef ref, String watchlistId, String symbol) {
    ref.read(watchlistsProvider.notifier).removeStock(watchlistId, symbol);
  }

  void _reorderStocks(WidgetRef ref, String watchlistId, List<String> symbols, int oldIndex, int newIndex) {
    final newOrder = List<String>.from(symbols);
    if (oldIndex < newIndex) {
      newIndex -= 1;
    }
    final item = newOrder.removeAt(oldIndex);
    newOrder.insert(newIndex, item);
    ref.read(watchlistsProvider.notifier).reorderStocks(watchlistId, newOrder);
  }
}
