import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../constants/app_routes.dart';
import '../constants/app_constants.dart';
import '../providers/auth_provider.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    Timer(const Duration(seconds: 2), () {
      _checkAuthAndOnboardingStatus();
    });
  }

  Future<void> _checkAuthAndOnboardingStatus() async {
    final prefs = await SharedPreferences.getInstance();
    final isFirstTime = prefs.getBool(AppConstants.isFirstTimeKey) ?? true;

    if (!mounted) return;

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    await authProvider.reloadUser();

    if (authProvider.isAuthenticated) {
      // User is already authenticated, go to home
      Navigator.pushReplacementNamed(context, AppRoutes.home);
    } else if (isFirstTime) {
      // First time user, show onboarding
      Navigator.pushReplacementNamed(context, AppRoutes.onboarding);
    } else {
      // Not first time, but not logged in
      Navigator.pushReplacementNamed(context, AppRoutes.login);
    }
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Color(0xFF2F80ED), // from app.json
      body: Center(
        child: Image(
          image: AssetImage('assets/images/splash.png'),
          fit: BoxFit.contain,
        ),
      ),
    );
  }
}
