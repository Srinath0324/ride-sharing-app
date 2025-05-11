import 'dart:async';
import 'package:flutter/material.dart';
import '../constants/app_routes.dart';

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
      Navigator.pushReplacementNamed(context, AppRoutes.onboarding);
    });
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
