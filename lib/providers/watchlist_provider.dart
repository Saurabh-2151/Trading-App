import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/watchlist.dart';
import '../repositories/watchlist_repository.dart';

final watchlistRepositoryProvider = Provider<WatchlistRepository>((ref) {
  return WatchlistRepository();
});

final watchlistsProvider = StateNotifierProvider<WatchlistsNotifier, List<Watchlist>>((ref) {
  final repository = ref.watch(watchlistRepositoryProvider);
  return WatchlistsNotifier(repository);
});

class WatchlistsNotifier extends StateNotifier<List<Watchlist>> {
  final WatchlistRepository _repository;

  WatchlistsNotifier(this._repository) : super([]) {
    _loadWatchlists();
  }

  void _loadWatchlists() {
    state = _repository.getAllWatchlists();
  }

  Future<void> createWatchlist(String name) async {
    await _repository.createWatchlist(name);
    _loadWatchlists();
  }

  Future<void> updateWatchlist(Watchlist watchlist) async {
    await _repository.updateWatchlist(watchlist);
    _loadWatchlists();
  }

  Future<void> deleteWatchlist(String id) async {
    await _repository.deleteWatchlist(id);
    _loadWatchlists();
  }

  Future<void> addStock(String watchlistId, String symbol) async {
    await _repository.addStockToWatchlist(watchlistId, symbol);
    _loadWatchlists();
  }

  Future<void> removeStock(String watchlistId, String symbol) async {
    await _repository.removeStockFromWatchlist(watchlistId, symbol);
    _loadWatchlists();
  }

  Future<void> reorderStocks(String watchlistId, List<String> newOrder) async {
    await _repository.reorderStocks(watchlistId, newOrder);
    _loadWatchlists();
  }
}
