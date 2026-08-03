import 'package:decimal/decimal.dart';
import '../models/wallet.dart';
import '../storage/hive_storage.dart';
import '../core/constants/app_constants.dart';

class WalletRepository {
  Wallet getWallet() {
    if (HiveStorage.walletBoxInstance.isEmpty) {
      final wallet = Wallet(
        balance: Decimal.parse(AppConstants.initialWalletBalance.toString()).toString(),
      );
      HiveStorage.walletBoxInstance.put('wallet', wallet);
      return wallet;
    }
    return HiveStorage.walletBoxInstance.get('wallet')!;
  }

  Decimal getBalance() {
    final wallet = getWallet();
    return Decimal.parse(wallet.balance);
  }

  Future<void> updateBalance(Decimal newBalance) async {
    final wallet = Wallet(balance: newBalance.toString());
    await HiveStorage.walletBoxInstance.put('wallet', wallet);
  }

  Future<void> deductBalance(Decimal amount) async {
    final currentBalance = getBalance();
    final newBalance = currentBalance - amount;
    await updateBalance(newBalance);
  }

  Future<void> addBalance(Decimal amount) async {
    final currentBalance = getBalance();
    final newBalance = currentBalance + amount;
    await updateBalance(newBalance);
  }

  bool hasSufficientBalance(Decimal amount) {
    return getBalance() >= amount;
  }
}
