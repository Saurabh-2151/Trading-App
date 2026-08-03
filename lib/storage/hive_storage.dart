import 'package:hive_flutter/hive_flutter.dart';
import '../models/watchlist.dart';
import '../models/holding.dart';
import '../models/order.dart';
import '../models/wallet.dart';

class HiveStorage {
  static const String watchlistsBox = 'watchlists';
  static const String holdingsBox = 'holdings';
  static const String ordersBox = 'orders';
  static const String walletBox = 'wallet';

  static Future<void> init() async {
    await Hive.initFlutter();
    
    Hive.registerAdapter(WatchlistAdapter());
    Hive.registerAdapter(HoldingAdapter());
    Hive.registerAdapter(OrderAdapter());
    Hive.registerAdapter(WalletAdapter());
    
    await Hive.openBox<Watchlist>(watchlistsBox);
    await Hive.openBox<Holding>(holdingsBox);
    await Hive.openBox<Order>(ordersBox);
    await Hive.openBox<Wallet>(walletBox);
  }

  static Box<Watchlist> get watchlistsBoxInstance => 
      Hive.box<Watchlist>(watchlistsBox);

  static Box<Holding> get holdingsBoxInstance => 
      Hive.box<Holding>(holdingsBox);

  static Box<Order> get ordersBoxInstance => 
      Hive.box<Order>(ordersBox);

  static Box<Wallet> get walletBoxInstance => 
      Hive.box<Wallet>(walletBox);
}
