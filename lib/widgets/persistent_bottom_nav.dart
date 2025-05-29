import 'package:flutter/material.dart';
import '../screens/home_screen.dart';
import '../screens/profile_screen.dart';
import '../screens/ride_history_screen.dart';
import '../screens/wallet_screen.dart';
import '../screens/chat_screen.dart';
import 'bottom_navbar.dart';

class PersistentBottomNav extends StatefulWidget {
  const PersistentBottomNav({Key? key}) : super(key: key);

  @override
  State<PersistentBottomNav> createState() => _PersistentBottomNavState();
}

class _PersistentBottomNavState extends State<PersistentBottomNav> {
  int _currentIndex = 0;

  // List of screens to be shown in the bottom navigation
  final List<Widget> _screens = [
    const HomeScreen(),
    const RideHistoryScreen(),
    const WalletScreen(),
    const ChatScreen(),
    const ProfileScreen(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _currentIndex, children: _screens),
      bottomNavigationBar: BottomNavBar(
        currentIndex: _currentIndex,
        onTap: _onItemTapped,
      ),
    );
  }
}
