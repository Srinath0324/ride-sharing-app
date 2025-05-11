import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';
import '../constants/app_routes.dart';
import '../constants/app_theme.dart';
import '../providers/auth_provider.dart';
import '../widgets/bottom_navbar.dart';
import '../widgets/location_button.dart';
import '../widgets/map_widget.dart';
import '../services/map_service.dart';
import '../services/geocoding_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentNavIndex = 0;
  MapboxMap? _mapboxMap;
  bool _isMapInitialized = false;
  String? _currentLocationAddress;
  bool _isLoadingLocation = false;

  // Sample recent rides data
  final Map<String, dynamic> _recentRide = {
    'from': '1901 Thornridge Cir. Shiloh',
    'to': '4140 Parker Rd. Allentown',
    'date': '16 July 2023, 10:30 PM',
    'driver': 'Jane Cooper',
    'seats': 4,
    'status': 'Paid',
  };

  void _onMapCreated(MapboxMap mapboxMap) {
    _mapboxMap = mapboxMap;
    setState(() {
      _isMapInitialized = true;
    });

    // Get current location when map is created
    _updateCurrentLocationAddress();
  }

  Future<void> _updateCurrentLocationAddress() async {
    setState(() {
      _isLoadingLocation = true;
    });

    try {
      // Get current location
      final position = await MapService.getCurrentLocation();

      // Get address from geocoding service
      final result = await GeocodingService.reverseGeocode(
        position.longitude,
        position.latitude,
      );

      setState(() {
        _currentLocationAddress = result['placeName'];
        _isLoadingLocation = false;
      });
    } catch (e) {
      print('Error getting current location address: $e');
      setState(() {
        _currentLocationAddress = 'Location unavailable';
        _isLoadingLocation = false;
      });
    }
  }

  void _handleLocationButtonPress() {
    setState(() {
      _isLoadingLocation = true;
    });

    // This will be called when the location button is pressed
    _updateCurrentLocationAddress();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final authProvider = Provider.of<AuthProvider>(context);
    final userName = authProvider.user?.name?.split(' ')[0] ?? 'John';

    return Scaffold(
      body: Stack(
        children: [
          // Map background
          RydeMapWidget(showUserLocation: true, onMapCreated: _onMapCreated),

          // Content
          SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Welcome text with sign out button
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Welcome $userName',
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                      ),
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(50),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              spreadRadius: 1,
                              blurRadius: 4,
                            ),
                          ],
                        ),
                        child: IconButton(
                          icon: const Icon(Icons.logout, size: 22),
                          onPressed: () async {
                            await authProvider.signOut();
                            if (!context.mounted) return;
                            Navigator.pushReplacementNamed(
                              context,
                              AppRoutes.login,
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),

                // Search bar
                GestureDetector(
                  onTap: () {
                    Navigator.pushNamed(
                      context,
                      AppRoutes.bookRide,
                      arguments: {'currentLocation': _currentLocationAddress},
                    );
                  },
                  child: Container(
                    margin: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(40),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          spreadRadius: 1,
                          blurRadius: 4,
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.search, color: Colors.grey[400]),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            _isLoadingLocation
                                ? 'Getting your location...'
                                : _currentLocationAddress ??
                                    'Where do you want to go?',
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 16,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const Spacer(),

                // Recent rides section
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(24),
                      topRight: Radius.circular(24),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Recent Rides',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Recent ride card
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Column(
                          children: [
                            // Map thumbnail and route details
                            Row(
                              children: [
                                // Small map thumbnail
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(12),
                                  child: Image.asset(
                                    'assets/images/Map.png',
                                    width: 80,
                                    height: 80,
                                    fit: BoxFit.cover,
                                  ),
                                ),
                                const SizedBox(width: 16),

                                // From and To locations
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          const Icon(
                                            Icons.location_on_outlined,
                                            size: 20,
                                            color: Colors.grey,
                                          ),
                                          const SizedBox(width: 8),
                                          Expanded(
                                            child: Text(
                                              _recentRide['from'],
                                              style: const TextStyle(
                                                fontSize: 14,
                                                fontWeight: FontWeight.w500,
                                              ),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 8),
                                      Row(
                                        children: [
                                          const Icon(
                                            Icons.location_on,
                                            size: 20,
                                            color: Colors.grey,
                                          ),
                                          const SizedBox(width: 8),
                                          Expanded(
                                            child: Text(
                                              _recentRide['to'],
                                              style: const TextStyle(
                                                fontSize: 14,
                                                fontWeight: FontWeight.w500,
                                              ),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),

                            const SizedBox(height: 16),
                            const Divider(height: 1),
                            const SizedBox(height: 16),

                            // Ride details (date, driver, seats, status)
                            Row(
                              children: [
                                // Date & Time
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        'Date & Time',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        _recentRide['date'],
                                        style: const TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),

                                // Driver
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        'Driver',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        _recentRide['driver'],
                                        style: const TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),

                                // Seats
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Seats',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      _recentRide['seats'].toString(),
                                      style: const TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),

                                const SizedBox(width: 8),

                                // Status
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.green.withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    _recentRide['status'],
                                    style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.green,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Location button
          if (_isMapInitialized)
            Positioned(
              right: 16,
              bottom: MediaQuery.of(context).size.height * 0.35 + 16,
              child: LocationButton(
                mapboxMap: _mapboxMap,
                onLocationButtonPressed: _handleLocationButtonPress,
              ),
            ),
        ],
      ),
      bottomNavigationBar: BottomNavBar(
        currentIndex: _currentNavIndex,
        onTap: (index) {
          if (index == _currentNavIndex) {
            return; // Already on this tab
          }

          // Navigate to the selected screen
          switch (index) {
            case 0:
              Navigator.pushReplacementNamed(context, AppRoutes.home);
              break;
            case 1:
              Navigator.pushReplacementNamed(context, AppRoutes.rideHistory);
              break;
            case 2:
              Navigator.pushReplacementNamed(context, AppRoutes.wallet);
              break;
            case 3:
              Navigator.pushReplacementNamed(context, AppRoutes.chat);
              break;
            case 4:
              Navigator.pushReplacementNamed(context, AppRoutes.profile);
              break;
          }

          // Update the index after navigation
          setState(() {
            _currentNavIndex = index;
          });
        },
      ),
    );
  }
}
