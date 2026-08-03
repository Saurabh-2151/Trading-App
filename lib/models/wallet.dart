import 'package:hive/hive.dart';

part 'wallet.g.dart';

@HiveType(typeId: 3)
class Wallet extends HiveObject {
  @HiveField(0)
  String balance;

  Wallet({
    required this.balance,
  });
}
