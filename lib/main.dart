import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'constants/app_routes.dart';
import 'constants/app_theme.dart';
import 'providers/auth_provider.dart';
import 'providers/location_provider.dart';
import 'providers/wallet_provider.dart';
import 'providers/ride_provider.dart';
import 'services/map_service.dart';
import 'screens/splash_screen.dart';
import 'screens/onboarding_screen.dart';
import 'screens/login_screen.dart';
import 'screens/signup_screen.dart';
import 'screens/home_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/ride_history_screen.dart';
import 'screens/chat_screen.dart';
import 'screens/book_ride_screen.dart';
import 'screens/ride_available_cars_screen.dart';
import 'screens/ride_information_screen.dart';
import 'screens/booking_success_screen.dart';
import 'screens/tracking_screen.dart';
import 'screens/wallet_screen.dart';
import 'screens/fare_negotiation_screen.dart';

// Flag to control Firebase initialization
bool useFirebase = false;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Load environment variables
  await dotenv.load(fileName: ".env");

  // Initialize MapBox SDK
  await MapService.initialize();

  // Initialize Firebase if needed
  if (useFirebase) {
    try {
      // For this demo, we're not initializing Firebase since we don't have the config
      // In a real app, you would add the Firebase configuration here
      await Firebase.initializeApp(
        // options: DefaultFirebaseOptions.currentPlatform,
      );
      print('Firebase initialized successfully');
    } catch (e) {
      print('Failed to initialize Firebase: $e');
    }
  }

  runApp(const RydeApp());
}

class RydeApp extends StatelessWidget {
  const RydeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => LocationProvider()),
        ChangeNotifierProvider(create: (_) => WalletProvider()),
        ChangeNotifierProvider(create: (_) => RideProvider()),
      ],
      child: MaterialApp(
        title: 'Ryde',
        theme: AppTheme.getTheme(),
        debugShowCheckedModeBanner: false,
        initialRoute: AppRoutes.splash,
        routes: {
          AppRoutes.splash: (context) => const SplashScreen(),
          AppRoutes.onboarding: (context) => const OnboardingScreen(),
          AppRoutes.login: (context) => const LoginScreen(),
          AppRoutes.signup: (context) => const SignupScreen(),
          AppRoutes.home: (context) => const HomeScreen(),
          AppRoutes.profile: (context) => const ProfileScreen(),
          AppRoutes.rideHistory: (context) => const RideHistoryScreen(),
          AppRoutes.chat: (context) => const ChatScreen(),
          AppRoutes.bookRide: (context) => const BookRideScreen(),
          AppRoutes.rideAvailableCars:
              (context) => const RideAvailableCarsScreen(),
          AppRoutes.rideInformation: (context) => const RideInformationScreen(),
          AppRoutes.bookingSuccess: (context) => const BookingSuccessScreen(),
          AppRoutes.tracking: (context) => const TrackingScreen(),
          AppRoutes.wallet: (context) => const WalletScreen(),
          AppRoutes.fareNegotiation: (context) => const FareNegotiationScreen(),
        },
      ),
    );
  }
}
