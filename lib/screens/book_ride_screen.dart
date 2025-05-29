import 'package:flutter/material.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';
import 'package:provider/provider.dart';
import 'dart:async';

import 'package:intl/intl.dart';
import '../constants/app_routes.dart';
import '../constants/app_theme.dart';
import '../widgets/location_button.dart';
import '../widgets/map_widget.dart';
import '../widgets/location_search_sheet.dart';
import '../widgets/seat_selection_modal.dart';
import '../widgets/schedule_ride_sheet.dart';
import '../providers/location_provider.dart';
import '../providers/ride_provider.dart';
import '../providers/auth_provider.dart';
import '../services/map_service.dart';
import '../services/map_markers.dart';
import '../services/geocoding_service.dart';
import '../services/places_service.dart';
import '../services/directions_service.dart';
import 'package:flutter/services.dart';

class BookRideScreen extends StatefulWidget {
  const BookRideScreen({Key? key}) : super(key: key);

  @override
  State<BookRideScreen> createState() => _BookRideScreenState();
}

class _BookRideScreenState extends State<BookRideScreen>
    with SingleTickerProviderStateMixin {
  final TextEditingController _fromController = TextEditingController();
  final TextEditingController _toController = TextEditingController();
  MapboxMap? _mapboxMap;
  bool _isMapInitialized = false;
  String? _originMarkerId;
  String? _destinationMarkerId;
  String? _routeId;
  bool _isLoadingRoute = false;
  CircleAnnotationManager? _originCircleManager;
  CircleAnnotationManager? _destinationCircleManager;

  // Tab controller for Shared Cab / Private Cab
  late TabController _tabController;
  String _rideType = 'shared'; // 'shared' or 'private'

  // Seat selection
  int _selectedSeats = 1;

  // Schedule ride
  DateTime? _scheduledDate;

  // Location data
  Position? _originPosition;
  Position? _destinationPosition;
  Position? _currentUserPosition;

  // Add a field for the estimated fare
  double _estimatedFare = 0.0;
  TextEditingController _fareController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);

    // Listen to tab changes
    _tabController.addListener(() {
      setState(() {
        _rideType = _tabController.index == 0 ? 'shared' : 'private';
      });
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Get arguments from navigator
    final Map<String, dynamic>? args =
        ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;

    if (args != null && args.containsKey('currentLocation')) {
      final currentLocation = args['currentLocation'];
      if (currentLocation != null && _fromController.text.isEmpty) {
        setState(() {
          _fromController.text = currentLocation;
        });
      }
    }

    // Use current location from provider if available
    _getCurrentLocationFromProvider();
  }

  Future<void> _getCurrentLocationFromProvider() async {
    final locationProvider = Provider.of<LocationProvider>(
      context,
      listen: false,
    );

    if (locationProvider.currentPosition != null &&
        locationProvider.currentAddress != null) {
      _currentUserPosition = Position(
        locationProvider.currentPosition!.longitude,
        locationProvider.currentPosition!.latitude,
      );

      // If from field is empty, use current location
      if (_fromController.text.isEmpty) {
        setState(() {
          _fromController.text = locationProvider.currentAddress!;
          _originPosition = _currentUserPosition;
        });
      }
    }
  }

  @override
  void dispose() {
    _fromController.dispose();
    _toController.dispose();
    _tabController.dispose();
    _fareController.dispose();
    super.dispose();
  }

  void _onMapCreated(MapboxMap mapboxMap) {
    _mapboxMap = mapboxMap;
    setState(() {
      _isMapInitialized = true;
    });

    // If we already have positions, add markers
    _updateMarkersAfterMapInitialized();
  }

  void _updateMarkersAfterMapInitialized() {
    if (_isMapInitialized && _mapboxMap != null) {
      // Add origin marker if we have the position
      if (_originPosition != null) {
        _addOriginMarker(_originPosition!);
      }

      // Add destination marker if we have the position
      if (_destinationPosition != null) {
        _addDestinationMarker(_destinationPosition!);
      }

      // Draw route if we have both positions
      if (_originPosition != null && _destinationPosition != null) {
        _drawRoute();
      }
    }
  }

  Future<void> _setCurrentLocationAsFrom() async {
    try {
      final locationProvider = Provider.of<LocationProvider>(
        context,
        listen: false,
      );

      // Try to get location from provider first
      if (locationProvider.currentPosition != null &&
          locationProvider.currentAddress != null) {
        setState(() {
          _fromController.text = locationProvider.currentAddress!;
          _originPosition = Position(
            locationProvider.currentPosition!.longitude,
            locationProvider.currentPosition!.latitude,
          );
        });

        // Add marker if map is initialized
        if (_isMapInitialized && _mapboxMap != null) {
          await _addOriginMarker(_originPosition!);

          // If we have destination, draw route
          if (_destinationPosition != null) {
            await _drawRoute();
          }
        }

        return;
      }

      // If not available in provider, get current location directly
      final position = await MapService.getCurrentLocation();

      // Get address from geocoding service
      final result = await GeocodingService.reverseGeocode(
        position.longitude,
        position.latitude,
      );

      // Update text field and position
      setState(() {
        _fromController.text = result['placeName'];
        _originPosition = Position(position.longitude, position.latitude);
      });

      // Add marker if map is initialized
      if (_isMapInitialized && _mapboxMap != null) {
        await _addOriginMarker(_originPosition!);

        // If we have destination, draw route
        if (_destinationPosition != null) {
          await _drawRoute();
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not get location: ${e.toString()}')),
        );
      }
    }
  }

  // Add origin marker to the map
  Future<void> _addOriginMarker(Position position) async {
    if (_mapboxMap == null) return;

    // Create circle annotation manager if not exists
    _originCircleManager ??=
        await _mapboxMap!.annotations.createCircleAnnotationManager();

    // Create circle annotation options
    final options = CircleAnnotationOptions(
      geometry: Point(coordinates: position),
      circleColor: Colors.green.value,
      circleRadius: 10.0,
      circleStrokeWidth: 2.0,
      circleStrokeColor: Colors.white.value,
    );

    // Add the annotation and store the ID
    final annotation = await _originCircleManager!.create(options);
    _originMarkerId = annotation.id;
  }

  // Add destination marker to the map
  Future<void> _addDestinationMarker(Position position) async {
    if (_mapboxMap == null) return;

    // Create circle annotation manager if not exists
    _destinationCircleManager ??=
        await _mapboxMap!.annotations.createCircleAnnotationManager();

    // Create circle annotation options
    final options = CircleAnnotationOptions(
      geometry: Point(coordinates: position),
      circleColor: Colors.red.value,
      circleRadius: 10.0,
      circleStrokeWidth: 2.0,
      circleStrokeColor: Colors.white.value,
    );

    // Add the annotation and store the ID
    final annotation = await _destinationCircleManager!.create(options);
    _destinationMarkerId = annotation.id;
  }

  // Add method to calculate estimated fare based on route distance
  void _calculateEstimatedFare(double distanceInKm) {
    // Base fare + per km rate
    final baseFare = 50.0; // Base fare in INR
    final perKmRate = 15.0; // Per KM rate in INR

    // Calculate fare with minimum fare of ₹50
    final calculatedFare = baseFare + (distanceInKm * perKmRate);
    setState(() {
      _estimatedFare = calculatedFare;
      // Format fare with Indian number system
      final indianFareFormat = NumberFormat.currency(
        locale: 'en_IN',
        symbol: '₹',
        decimalDigits: 0,
      );
      _fareController.text = indianFareFormat.format(calculatedFare).trim();
    });
  }

  // Update the _drawRoute method to calculate fare
  Future<void> _drawRoute() async {
    if (_mapboxMap == null ||
        _originPosition == null ||
        _destinationPosition == null) {
      return;
    }

    setState(() {
      _isLoadingRoute = true;
    });

    try {
      // Get directions from the API
      final response = await DirectionsService.getDirections(
        _originPosition!.lng,
        _originPosition!.lat,
        _destinationPosition!.lng,
        _destinationPosition!.lat,
      );

      if (response != null && response.containsKey('geometry')) {
        final List<dynamic> coordinates =
            response['geometry']['coordinates'] as List<dynamic>;
        final List<Position> routeCoordinates =
            coordinates
                .map(
                  (coord) => Position(coord[0] as double, coord[1] as double),
                )
                .toList();

        // Clear any existing route
        if (_routeId != null && _mapboxMap != null) {
          await MapMarkers.removeRoute(_mapboxMap!, _routeId!);
          _routeId = null;
        }

        // Draw the new route
        _routeId = await MapMarkers.addRoute(_mapboxMap!, routeCoordinates);

        // Update camera to show the entire route
        await _mapboxMap!.flyTo(
          CameraOptions(
            center: Point(
              coordinates: Position(
                (_originPosition!.lng + _destinationPosition!.lng) / 2,
                (_originPosition!.lat + _destinationPosition!.lat) / 2,
              ),
            ),
            zoom: 12.0,
            padding: MbxEdgeInsets(
              top: 100,
              left: 100,
              bottom: 300,
              right: 100,
            ),
          ),
          MapAnimationOptions(duration: 500, startDelay: 0),
        );

        // Calculate and update estimated fare based on distance
        final double distanceInMeters = response['distance'] as double;
        final double distanceInKm = distanceInMeters / 1000;
        _calculateEstimatedFare(distanceInKm);
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error drawing route: ${e.toString()}')),
        );
      }
    } finally {
      setState(() {
        _isLoadingRoute = false;
      });
    }
  }

  void _handleLocationButtonPress() async {
    if (_mapboxMap == null) return;

    if (_originPosition != null && _destinationPosition != null) {
      // If both origin and destination are set, first zoom to see both locations
      await MapMarkers.fitMapToShowRoute(
        mapboxMap: _mapboxMap!,
        origin: _originPosition!,
        destination: _destinationPosition!,
      );
    } else if (_currentUserPosition != null) {
      // Zoom to current user position
      await _mapboxMap!.setCamera(
        CameraOptions(
          center: Point(coordinates: _currentUserPosition!),
          zoom: 15.0,
        ),
      );

      if (_fromController.text.isEmpty) {
        // Set current location as origin if from field is empty
        _setCurrentLocationAsFrom();
      }
    } else {
      // Try to get current location
      _setCurrentLocationAsFrom();
    }
  }

  // Show the search location sheet
  void _showFromLocationSearchSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder:
          (context) => LocationSearchSheet(
            title: 'Choose start location',
            initialLocation:
                _fromController.text.isNotEmpty ? _fromController.text : null,
            currentUserPosition: _currentUserPosition,
            onLocationSelected: (location) {
              setState(() {
                _fromController.text = location['placeName'] ?? '';
                _originPosition = location['coordinates'];
              });

              // Add marker and draw route if needed
              if (_isMapInitialized && _mapboxMap != null) {
                _addOriginMarker(_originPosition!);
                if (_destinationPosition != null) {
                  _drawRoute();
                }
              }
            },
          ),
    );
  }

  // Show the search location sheet for destination
  void _showToLocationSearchSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder:
          (context) => LocationSearchSheet(
            title: 'Choose destination',
            initialLocation:
                _toController.text.isNotEmpty ? _toController.text : null,
            currentUserPosition: _currentUserPosition,
            onLocationSelected: (location) {
              setState(() {
                _toController.text = location['placeName'] ?? '';
                _destinationPosition = location['coordinates'];
              });

              // Add marker and draw route if needed
              if (_isMapInitialized && _mapboxMap != null) {
                _addDestinationMarker(_destinationPosition!);
                if (_originPosition != null) {
                  _drawRoute();
                }
              }
            },
          ),
    );
  }

  // Show seat selection modal
  void _showSeatSelectionModal() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder:
          (context) => SeatSelectionModal(
            initialSeats: _selectedSeats,
            onSeatSelected: (seats) {
              setState(() {
                _selectedSeats = seats;
              });
            },
          ),
    );
  }

  // Show schedule ride sheet
  void _showScheduleRideSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder:
          (context) => ScheduleRideSheet(
            initialDate: _scheduledDate,
            onDateSelected: (date) {
              setState(() {
                _scheduledDate = date;
              });
            },
          ),
    );
  }

  // Format the scheduled date for display
  String _formatScheduledDate() {
    if (_scheduledDate == null) {
      return 'now';
    }

    return DateFormat('dd MMM, h:mm a').format(_scheduledDate!);
  }

  // Create a new ride request with fare negotiation
  void _createRideRequest() {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final rideProvider = Provider.of<RideProvider>(context, listen: false);

    if (_originPosition == null || _destinationPosition == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please set both pickup and destination locations'),
        ),
      );
      return;
    }

    if (_fareController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter your proposed fare')),
      );
      return;
    }

    // Parse fare amount
    final String fareText =
        _fareController.text.replaceAll('₹', '').replaceAll(',', '').trim();
    final double initialFare = double.tryParse(fareText) ?? _estimatedFare;

    // Create ride request through provider
    try {
      final rideRequest = rideProvider.createRideRequest(
        riderId: authProvider.currentUser!.id,
        fromAddress: _fromController.text,
        toAddress: _toController.text,
        fromLat: _originPosition!.lat,
        fromLng: _originPosition!.lng,
        toLat: _destinationPosition!.lat,
        toLng: _destinationPosition!.lng,
        initialFare: initialFare,
        scheduledTime: _scheduledDate,
        seats: _selectedSeats,
        rideType: _rideType, // Add ride type parameter
      );

      // Navigate to fare negotiation screen
      Navigator.pushNamed(context, AppRoutes.fareNegotiation);
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error creating ride request: ${e.toString()}'),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Map background
          RydeMapWidget(
            showUserLocation: false, // We'll use custom markers instead
            onMapCreated: _onMapCreated,
            onMapClick: null, // We want full map interactivity
          ),

          // Content
          SafeArea(
            child: Column(
              children: [
                // App bar with back button
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                  child: Row(
                    children: [
                      GestureDetector(
                        onTap: () {
                          Navigator.pop(context);
                        },
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(8),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.1),
                                spreadRadius: 1,
                                blurRadius: 4,
                              ),
                            ],
                          ),
                          child: const Icon(Icons.arrow_back),
                        ),
                      ),
                      const Expanded(
                        child: Center(
                          child: Text(
                            'Book Ride',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                      // Empty space to center title
                      const SizedBox(width: 40),
                    ],
                  ),
                ),

                const Spacer(),

                // Bottom sheet with ride options
                Container(
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(24),
                      topRight: Radius.circular(24),
                    ),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Tabs for Find Pool / Offer Pool
                      Padding(
                        padding: const EdgeInsets.only(top: 8.0),
                        child: TabBar(
  controller: _tabController,
  tabs: const [
    Tab(text: 'Shared Cab'),
    Tab(text: 'Private Cab'),
  ],
  indicatorColor: _tabController.index == 0
      ? Colors.green
      : Colors.deepPurpleAccent,
  labelColor: _tabController.index == 0
      ? Colors.green
      : Colors.deepPurpleAccent,
  unselectedLabelColor: Colors.grey,
  indicatorWeight: 3,
)

                      ),

                      // Main content
                      Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          children: [
                            // From field
                            GestureDetector(
                              onTap: _showFromLocationSearchSheet,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 12,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.grey[100],
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.circle,
                                      color: Colors.green,
                                      size: 12,
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: Text(
                                        _fromController.text.isNotEmpty
                                            ? _fromController.text
                                            : 'Choose start location',
                                        style: TextStyle(
                                          color:
                                              _fromController.text.isNotEmpty
                                                  ? Colors.black
                                                  : Colors.grey,
                                          fontSize: 14,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),

                            const SizedBox(height: 12),

                            // To field
                            GestureDetector(
                              onTap: _showToLocationSearchSheet,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 12,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.grey[100],
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.location_on,
                                      color: Colors.red,
                                      size: 18,
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Text(
                                        _toController.text.isNotEmpty
                                            ? _toController.text
                                            : 'Choose destination',
                                        style: TextStyle(
                                          color:
                                              _toController.text.isNotEmpty
                                                  ? Colors.black
                                                  : Colors.grey,
                                          fontSize: 14,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),

                            const SizedBox(height: 16),

                            // Schedule time and seats row
                            Row(
                              children: [
                                // Schedule time button
                                Expanded(
                                  child: GestureDetector(
                                    onTap: _showScheduleRideSheet,
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 12,
                                        vertical: 8,
                                      ),
                                      decoration: BoxDecoration(
                                        border: Border.all(
                                          color: Colors.grey.shade200,
                                        ),
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: Row(
                                        children: [
                                          const Icon(
                                            Icons.access_time,
                                            size: 16,
                                            color: Colors.grey,
                                          ),
                                          const SizedBox(width: 8),
                                          Expanded(
                                            child: Text(
                                              _formatScheduledDate(),
                                              style: const TextStyle(
                                                fontSize: 13,
                                              ),
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),

                                const SizedBox(width: 12),

                                // Number of seats button - only show for shared cab
                                if (_rideType == 'shared')
                                  GestureDetector(
                                    onTap: _showSeatSelectionModal,
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 12,
                                        vertical: 8,
                                      ),
                                      decoration: BoxDecoration(
                                        border: Border.all(
                                          color: Colors.grey.shade200,
                                        ),
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: Row(
                                        children: [
                                          const Icon(
                                            Icons.airline_seat_recline_normal,
                                            size: 16,
                                            color: Colors.grey,
                                          ),
                                          const SizedBox(width: 8),
                                          Text(
                                            '$_selectedSeats Seat',
                                            style: const TextStyle(
                                              fontSize: 13,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                              ],
                            ),

                            const SizedBox(height: 24),

                            // Find Pool button
                            SizedBox(
                              width: double.infinity,
                              height: 50,
                              child: ElevatedButton(
                                onPressed:
                                    _isLoadingRoute
                                        ? null
                                        : () {
                                          if (_fromController.text.isNotEmpty &&
                                              _toController.text.isNotEmpty) {
                                            if (_estimatedFare > 0) {
                                              // Show fare negotiation dialog
                                              showModalBottomSheet(
                                                context: context,
                                                isScrollControlled: true,
                                                backgroundColor:
                                                    Colors.transparent,
                                                builder:
                                                    (context) =>
                                                        _buildFareNegotiationSheet(
                                                          context,
                                                        ),
                                              );
                                            } else {
                                              ScaffoldMessenger.of(
                                                context,
                                              ).showSnackBar(
                                                const SnackBar(
                                                  content: Text(
                                                    'Please calculate route first',
                                                  ),
                                                ),
                                              );
                                            }
                                          } else {
                                            ScaffoldMessenger.of(
                                              context,
                                            ).showSnackBar(
                                              const SnackBar(
                                                content: Text(
                                                  'Please enter both locations',
                                                ),
                                              ),
                                            );
                                          }
                                        },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppTheme.primaryColor,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(50),
                                  ),
                                ),
                                child:
                                    _isLoadingRoute
                                        ? const SizedBox(
                                          width: 24,
                                          height: 24,
                                          child: CircularProgressIndicator(
                                            color: Colors.white,
                                            strokeWidth: 2,
                                          ),
                                        )
                                        : const Text(
                                          'FIND CAB',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                              ),
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
              bottom: MediaQuery.of(context).size.height * 0.37,
              child: LocationButton(
                mapboxMap: _mapboxMap,
                onLocationButtonPressed: _handleLocationButtonPress,
              ),
            ),
        ],
      ),
    );
  }

  // Add a method to build the fare negotiation bottom sheet
  Widget _buildFareNegotiationSheet(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Propose Your Fare',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'Drivers will see your proposed fare and might accept or counter',
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 24),

            // Route info
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.location_on,
                        color: Colors.blue,
                        size: 16,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _fromController.text,
                          style: const TextStyle(fontSize: 14),
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
                        color: Colors.red,
                        size: 16,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _toController.text,
                          style: const TextStyle(fontSize: 14),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Estimated fare info
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Estimated Fare',
                        style: TextStyle(fontSize: 14, color: Colors.grey),
                      ),
                      Text(
                        _fareController.text,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.info_outline, color: Colors.grey, size: 20),
              ],
            ),
            const SizedBox(height: 20),

            // Your proposed fare input
            TextField(
              controller: _fareController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'Your Proposed Fare',
                prefixText: '₹ ',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 16,
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Submit button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(context); // Close the bottom sheet
                  _createRideRequest();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text(
                  'Find Drivers',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
