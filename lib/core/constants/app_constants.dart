class AppConstants {
  static const List<String> availableStocks = [
    'RELIANCE',
    'TCS',
    'INFY',
    'HDFCBANK',
    'ICICIBANK',
    'SBIN',
    'ITC',
    'LT',
    'BHARTIARTL',
    'AXISBANK',
  ];

  static const Map<String, double> initialPrices = {
    'RELIANCE': 2450.50,
    'TCS': 3650.75,
    'INFY': 1580.25,
    'HDFCBANK': 1650.80,
    'ICICIBANK': 985.30,
    'SBIN': 625.45,
    'ITC': 445.60,
    'LT': 3280.90,
    'BHARTIARTL': 1125.35,
    'AXISBANK': 1045.70,
  };

  static const int tickRateMilliseconds = 1000;
  
  static const double initialWalletBalance = 1000000.0;
  
  static const String defaultWatchlistName = 'My Watchlist';
  
  static const Map<String, String> stockSectors = {
    'RELIANCE': 'Energy',
    'TCS': 'IT',
    'INFY': 'IT',
    'HDFCBANK': 'Banking',
    'ICICIBANK': 'Banking',
    'SBIN': 'Banking',
    'ITC': 'FMCG',
    'LT': 'Infra',
    'BHARTIARTL': 'Telecom',
    'AXISBANK': 'Banking',
  };
  
  static String getSector(String symbol) {
    return stockSectors[symbol] ?? 'Other';
  }
}
