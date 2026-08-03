import 'package:go_router/go_router.dart';
import '../../screens/home_screen.dart';
import '../../screens/market_screen.dart';
import '../../screens/holdings_screen.dart';
import '../../screens/watchlist_detail_screen.dart';
import '../../screens/trade_ticket_screen.dart';
import '../../screens/order_confirmation_screen.dart';

final appRouter = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(
      path: '/',
      builder: (context, state) => const HomeScreen(),
    ),
    GoRoute(
      path: '/market',
      builder: (context, state) => const MarketScreen(),
    ),
    GoRoute(
      path: '/holdings',
      builder: (context, state) => const HoldingsScreen(),
    ),
    GoRoute(
      path: '/watchlist/:id',
      builder: (context, state) {
        final id = state.pathParameters['id']!;
        return WatchlistDetailScreen(watchlistId: id);
      },
    ),
    GoRoute(
      path: '/trade',
      builder: (context, state) {
        final symbol = state.uri.queryParameters['symbol'] ?? '';
        return TradeTicketScreen(symbol: symbol);
      },
    ),
    GoRoute(
      path: '/order-confirmation',
      builder: (context, state) {
        final symbol = state.uri.queryParameters['symbol'] ?? '';
        final type = state.uri.queryParameters['type'] ?? '';
        final quantity = state.uri.queryParameters['quantity'] ?? '0';
        final price = state.uri.queryParameters['price'] ?? '0';
        final total = state.uri.queryParameters['total'] ?? '0';
        
        return OrderConfirmationScreen(
          symbol: symbol,
          type: type,
          quantity: int.parse(quantity),
          price: price,
          total: total,
        );
      },
    ),
  ],
);
