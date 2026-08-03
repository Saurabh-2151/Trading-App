import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:decimal/decimal.dart';
import '../repositories/wallet_repository.dart';

final walletRepositoryProvider = Provider<WalletRepository>((ref) {
  return WalletRepository();
});

final walletBalanceProvider = StateNotifierProvider<WalletBalanceNotifier, Decimal>((ref) {
  final repository = ref.watch(walletRepositoryProvider);
  return WalletBalanceNotifier(repository);
});

class WalletBalanceNotifier extends StateNotifier<Decimal> {
  final WalletRepository _repository;

  WalletBalanceNotifier(this._repository) : super(Decimal.zero) {
    _loadBalance();
  }

  void _loadBalance() {
    state = _repository.getBalance();
  }

  Future<void> deduct(Decimal amount) async {
    await _repository.deductBalance(amount);
    _loadBalance();
  }

  Future<void> add(Decimal amount) async {
    await _repository.addBalance(amount);
    _loadBalance();
  }

  bool hasSufficientBalance(Decimal amount) {
    return state >= amount;
  }
}
