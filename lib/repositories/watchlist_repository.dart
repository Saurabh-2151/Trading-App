import 'package:uuid/uuid.dart';
import '../models/watchlist.dart';
import '../storage/hive_storage.dart';
import '../core/constants/app_constants.dart';

class WatchlistRepository {
  final _uuid = const Uuid();

  List<Watchlist> getAllWatchlists() {
    return HiveStorage.watchlistsBoxInstance.values.toList();
  }

  Watchlist? getWatchlist(String id) {
    return HiveStorage.watchlistsBoxInstance.values
        .where((w) => w.id == id)
        .firstOrNull;
  }

  Future<void> createWatchlist(String name) async {
    final watchlist = Watchlist(
      id: _uuid.v4(),
      name: name,
      symbols: [],
    );
    await HiveStorage.watchlistsBoxInstance.add(watchlist);
  }

  Future<void> updateWatchlist(Watchlist watchlist) async {
    final index = HiveStorage.watchlistsBoxInstance.values
        .toList()
        .indexWhere((w) => w.id == watchlist.id);
    if (index != -1) {
      await HiveStorage.watchlistsBoxInstance.putAt(index, watchlist);
    }
  }

  Future<void> deleteWatchlist(String id) async {
    final watchlist = HiveStorage.watchlistsBoxInstance.values
        .where((w) => w.id == id)
        .firstOrNull;
    if (watchlist != null) {
      await watchlist.delete();
    }
  }

  Future<void> addStockToWatchlist(String watchlistId, String symbol) async {
    final watchlist = getWatchlist(watchlistId);
    if (watchlist != null && !watchlist.symbols.contains(symbol)) {
      watchlist.symbols.add(symbol);
      await updateWatchlist(watchlist);
    }
  }

  Future<void> removeStockFromWatchlist(String watchlistId, String symbol) async {
    final watchlist = getWatchlist(watchlistId);
    if (watchlist != null) {
      watchlist.symbols.remove(symbol);
      await updateWatchlist(watchlist);
    }
  }

  Future<void> reorderStocks(String watchlistId, List<String> newOrder) async {
    final watchlist = getWatchlist(watchlistId);
    if (watchlist != null) {
      final updated = watchlist.copyWith(symbols: newOrder);
      await updateWatchlist(updated);
    }
  }

  Future<void> initializeDefaultWatchlist() async {
    if (HiveStorage.watchlistsBoxInstance.isEmpty) {
      await createWatchlist(AppConstants.defaultWatchlistName);
    }
  }
}
