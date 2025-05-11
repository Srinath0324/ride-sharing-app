import 'package:flutter/foundation.dart';

class WalletTransaction {
  final String title;
  final int amount;
  final DateTime date;
  final bool isCredit;

  WalletTransaction({
    required this.title,
    required this.amount,
    required this.date,
    this.isCredit = true,
  });
}

class WalletProvider with ChangeNotifier {
  int _balance = 0;
  final List<WalletTransaction> _transactions = [];

  int get balance => _balance;
  List<WalletTransaction> get transactions => List.unmodifiable(_transactions);

  void addMoney(int amount) {
    if (amount <= 0) return;

    _balance += amount;

    _transactions.add(
      WalletTransaction(
        title: 'Added to wallet',
        amount: amount,
        date: DateTime.now(),
        isCredit: true,
      ),
    );

    notifyListeners();
  }

  bool deductMoney(int amount, String reason) {
    if (amount <= 0) return false;
    if (_balance < amount) return false;

    _balance -= amount;

    _transactions.add(
      WalletTransaction(
        title: reason,
        amount: amount,
        date: DateTime.now(),
        isCredit: false,
      ),
    );

    notifyListeners();
    return true;
  }
}
