import 'package:flutter/foundation.dart';
import '../services/wallet_service.dart';
import '../models/wallet_model.dart';
import '../main.dart'; // Import to access the useFirebase flag

class WalletProvider with ChangeNotifier {
  final WalletService _walletService = WalletService();

  int _balance = 0;
  List<WalletTransaction> _transactions = [];
  bool _isLoading = false;
  String? _errorMessage;

  // Getters
  int get balance => _balance;
  List<WalletTransaction> get transactions => List.unmodifiable(_transactions);
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  // Constructor - Initialize wallet data
  WalletProvider() {
    loadWalletData();
  }

  // Load wallet data from Firestore
  Future<void> loadWalletData() async {
    if (!useFirebase) {
      return; // Skip Firebase operations when not using Firebase
    }

    _setLoading(true);
    _clearError();

    try {
      // Load wallet information
      final wallet = await _walletService.getWallet();
      if (wallet != null) {
        _balance = wallet.balance;
      }

      // Load transactions
      _transactions = await _walletService.getTransactions();
      notifyListeners();
    } catch (e) {
      _setError(e.toString());
    } finally {
      _setLoading(false);
    }
  }

  // Set loading state
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  // Set error message
  void _setError(String message) {
    _errorMessage = message;
    notifyListeners();
  }

  // Clear error message
  void _clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  // Add money to wallet
  Future<void> addMoney(int amount) async {
    if (amount <= 0) return;

    _setLoading(true);
    _clearError();

    try {
      if (useFirebase) {
        // Use Firebase service to add money
        await _walletService.addMoney(amount);

        // Reload wallet data to get updated balance and transactions
        await loadWalletData();
      } else {
        // Local implementation for non-Firebase mode
        _balance += amount;

        _transactions.add(
          WalletTransaction(
            userId: 'local-user',
            title: 'Added to wallet',
            amount: amount,
            date: DateTime.now(),
            isCredit: true,
          ),
        );
        notifyListeners();
      }
    } catch (e) {
      _setError(e.toString());
    } finally {
      _setLoading(false);
    }
  }

  // Deduct money from wallet
  Future<bool> deductMoney(int amount, String reason) async {
    if (amount <= 0) return false;
    if (_balance < amount) return false;

    _setLoading(true);
    _clearError();

    try {
      if (useFirebase) {
        // Use Firebase service to deduct money
        final success = await _walletService.deductMoney(amount, reason);

        if (success) {
          // Reload wallet data to get updated balance and transactions
          await loadWalletData();
        }

        return success;
      } else {
        // Local implementation for non-Firebase mode
        _balance -= amount;

        _transactions.add(
          WalletTransaction(
            userId: 'local-user',
            title: reason,
            amount: amount,
            date: DateTime.now(),
            isCredit: false,
          ),
        );
        notifyListeners();
        return true;
      }
    } catch (e) {
      _setError(e.toString());
      return false;
    } finally {
      _setLoading(false);
    }
  }
}
