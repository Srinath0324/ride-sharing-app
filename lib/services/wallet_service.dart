import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/wallet_model.dart';
import '../constants/app_constants.dart';
import 'package:uuid/uuid.dart';

class WalletService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final _uuid = const Uuid();

  // Get current user ID
  String? get currentUserId => _auth.currentUser?.uid;

  // Initialize wallet for a new user
  Future<void> initializeWallet(String userId) async {
    try {
      // Check if wallet already exists
      final walletDoc =
          await _firestore
              .collection(AppConstants.usersCollection)
              .doc(userId)
              .collection('wallet')
              .doc('wallet_info')
              .get();

      if (!walletDoc.exists) {
        // Create new wallet with zero balance
        final wallet = Wallet(
          userId: userId,
          balance: 0,
          lastUpdated: DateTime.now(),
        );

        // Save to Firestore
        await _firestore
            .collection(AppConstants.usersCollection)
            .doc(userId)
            .collection('wallet')
            .doc('wallet_info')
            .set(wallet.toJson());
      }
    } catch (e) {
      rethrow;
    }
  }

  // Get wallet for current user
  Future<Wallet?> getWallet() async {
    try {
      if (currentUserId == null) {
        throw Exception('User not authenticated');
      }

      final docSnapshot =
          await _firestore
              .collection(AppConstants.usersCollection)
              .doc(currentUserId)
              .collection('wallet')
              .doc('wallet_info')
              .get();

      if (docSnapshot.exists) {
        return Wallet.fromJson(docSnapshot.data()!);
      } else {
        // Initialize wallet if it doesn't exist
        await initializeWallet(currentUserId!);

        // Return default wallet
        return Wallet(
          userId: currentUserId!,
          balance: 0,
          lastUpdated: DateTime.now(),
        );
      }
    } catch (e) {
      rethrow;
    }
  }

  // Update wallet balance
  Future<void> updateWalletBalance(int newBalance) async {
    try {
      if (currentUserId == null) {
        throw Exception('User not authenticated');
      }

      await _firestore
          .collection(AppConstants.usersCollection)
          .doc(currentUserId)
          .collection('wallet')
          .doc('wallet_info')
          .update({
            'balance': newBalance,
            'lastUpdated': DateTime.now().toIso8601String(),
          });
    } catch (e) {
      rethrow;
    }
  }

  // Add transaction
  Future<void> addTransaction(WalletTransaction transaction) async {
    try {
      if (currentUserId == null) {
        throw Exception('User not authenticated');
      }

      await _firestore
          .collection(AppConstants.usersCollection)
          .doc(currentUserId)
          .collection('wallet')
          .doc('transactions')
          .collection('history')
          .doc(transaction.id)
          .set(transaction.toJson());
    } catch (e) {
      rethrow;
    }
  }

  // Get all transactions for current user
  Future<List<WalletTransaction>> getTransactions() async {
    try {
      if (currentUserId == null) {
        throw Exception('User not authenticated');
      }

      final querySnapshot =
          await _firestore
              .collection(AppConstants.usersCollection)
              .doc(currentUserId)
              .collection('wallet')
              .doc('transactions')
              .collection('history')
              .orderBy('date', descending: true)
              .get();

      return querySnapshot.docs
          .map((doc) => WalletTransaction.fromJson(doc.data()))
          .toList();
    } catch (e) {
      rethrow;
    }
  }

  // Add money to wallet
  Future<void> addMoney(int amount) async {
    try {
      if (currentUserId == null) {
        throw Exception('User not authenticated');
      }

      // Get current wallet
      final wallet = await getWallet();
      if (wallet == null) {
        throw Exception('Wallet not found');
      }

      // Update balance
      final newBalance = wallet.balance + amount;
      await updateWalletBalance(newBalance);

      // Add transaction record
      final transaction = WalletTransaction(
        id: _uuid.v4(),
        userId: currentUserId!,
        title: 'Added to wallet',
        amount: amount,
        date: DateTime.now(),
        isCredit: true,
      );

      await addTransaction(transaction);
    } catch (e) {
      rethrow;
    }
  }

  // Deduct money from wallet
  Future<bool> deductMoney(int amount, String reason) async {
    try {
      if (currentUserId == null) {
        throw Exception('User not authenticated');
      }

      // Get current wallet
      final wallet = await getWallet();
      if (wallet == null) {
        throw Exception('Wallet not found');
      }

      // Check if sufficient balance
      if (wallet.balance < amount) {
        return false;
      }

      // Update balance
      final newBalance = wallet.balance - amount;
      await updateWalletBalance(newBalance);

      // Add transaction record
      final transaction = WalletTransaction(
        id: _uuid.v4(),
        userId: currentUserId!,
        title: reason,
        amount: amount,
        date: DateTime.now(),
        isCredit: false,
      );

      await addTransaction(transaction);
      return true;
    } catch (e) {
      rethrow;
    }
  }
}
