import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'dart:math';
import 'package:uuid/uuid.dart';
import '../models/ride_request_model.dart';
import '../models/fare_offer_model.dart';
import '../models/driver_model.dart';

class RideProvider with ChangeNotifier {
  // Mock data for now, to be replaced with API calls
  final List<RideRequest> _rideRequests = [];
  final List<FareOffer> _fareOffers = [];
  final List<DriverModel> _nearbyDrivers = [];

  // Current ride request being negotiated
  RideRequest? _currentRideRequest;

  // Generate UUID for new records
  final _uuid = const Uuid();

  // Getters
  List<RideRequest> get rideRequests => _rideRequests;
  List<FareOffer> get fareOffers => _fareOffers;
  List<DriverModel> get nearbyDrivers => _nearbyDrivers;
  RideRequest? get currentRideRequest => _currentRideRequest;

  // Initialize with mock data
  RideProvider() {
    _initMockData();
  }

  void _initMockData() {
    // Mock nearby drivers
    _nearbyDrivers.addAll([
      DriverModel(
        id: 'driver1',
        name: 'Jane Cooper',
        phoneNumber: '+91 98765 43210',
        rating: 4.9,
        totalRides: 235,
        carModel: 'Honda City',
        carColor: 'Silver',
        carNumber: 'KA 01 AB 1234',
        totalSeats: 4,
        latitude: 12.9716,
        longitude: 77.5946,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        cabTypes: const ['shared', 'private'], // Both types
      ),
      DriverModel(
        id: 'driver2',
        name: 'Esther Howard',
        phoneNumber: '+91 98765 43211',
        rating: 4.8,
        totalRides: 178,
        carModel: 'Toyota Innova',
        carColor: 'White',
        carNumber: 'KA 01 CD 5678',
        totalSeats: 6,
        latitude: 12.9719,
        longitude: 77.5942,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        cabTypes: const ['shared'], // Only shared
      ),
      DriverModel(
        id: 'driver3',
        name: 'Leslie Alexander',
        phoneNumber: '+91 98765 43212',
        rating: 5.0,
        totalRides: 342,
        carModel: 'Hyundai Verna',
        carColor: 'Blue',
        carNumber: 'KA 01 EF 9012',
        totalSeats: 4,
        latitude: 12.9712,
        longitude: 77.5952,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        cabTypes: const ['private'], // Only private
      ),
      DriverModel(
        id: 'driver4',
        name: 'Robert Fox',
        phoneNumber: '+91 98765 43213',
        rating: 4.7,
        totalRides: 128,
        carModel: 'Maruti Swift',
        carColor: 'Red',
        carNumber: 'KA 01 GH 3456',
        totalSeats: 4,
        latitude: 12.9722,
        longitude: 77.5939,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        cabTypes: const ['shared', 'private'], // Both types
      ),
      DriverModel(
        id: 'driver5',
        name: 'Dianne Russell',
        phoneNumber: '+91 98765 43214',
        rating: 4.6,
        totalRides: 215,
        carModel: 'Mahindra XUV',
        carColor: 'Black',
        carNumber: 'KA 02 IJ 7890',
        totalSeats: 6,
        latitude: 12.9725,
        longitude: 77.5935,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        cabTypes: const ['shared'], // Only shared - larger vehicle
      ),
      DriverModel(
        id: 'driver6',
        name: 'Kathryn Murphy',
        phoneNumber: '+91 98765 43215',
        rating: 4.9,
        totalRides: 310,
        carModel: 'Mercedes E-Class',
        carColor: 'Silver',
        carNumber: 'KA 05 KL 1234',
        totalSeats: 3,
        latitude: 12.9730,
        longitude: 77.5930,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        cabTypes: const ['private'], // Only private - luxury vehicle
      ),
    ]);
  }

  // Create a new ride request with a proposed fare
  RideRequest createRideRequest({
    required String riderId,
    required String fromAddress,
    required String toAddress,
    required num fromLat,
    required num fromLng,
    required num toLat,
    required num toLng,
    required double initialFare,
    DateTime? scheduledTime,
    required int seats,
    required String rideType,
  }) {
    final id = _uuid.v4();

    final request = RideRequest(
      id: id,
      riderId: riderId,
      fromAddress: fromAddress,
      toAddress: toAddress,
      fromLat: fromLat.toDouble(),
      fromLng: fromLng.toDouble(),
      toLat: toLat.toDouble(),
      toLng: toLng.toDouble(),
      initialFare: initialFare,
      requestTime: DateTime.now(),
      scheduledTime: scheduledTime,
      status: 'pending',
      seats: seats,
      rideType: rideType,
    );

    _rideRequests.add(request);
    _currentRideRequest = request;
    notifyListeners();

    // In a real app, this would send the request to nearby drivers
    // For now, simulate drivers sending counter offers after a delay
    _simulateDriverOffers(request);

    return request;
  }

  // Simulate drivers sending counter offers
  void _simulateDriverOffers(RideRequest request) {
    // Update the request status
    final updatedRequest = request.copyWith(status: 'negotiating');
    _updateRideRequest(updatedRequest);

    // Filter drivers based on ride requirements
    final filteredDrivers =
        _nearbyDrivers.where((driver) {
          // Check if driver supports the requested cab type
          bool supportsRequestedCabType = driver.cabTypes.contains(
            request.rideType,
          );

          // For shared rides, make sure driver has enough seats
          bool hasEnoughSeats =
              request.rideType == 'private' ||
              driver.totalSeats >= request.seats;

          // In a real app, we would also check driver availability, location, etc.
          return supportsRequestedCabType &&
              hasEnoughSeats &&
              driver.isAvailable;
        }).toList();

    // Create counter offers from drivers with random amounts
    final random = Random();

    for (var driver in filteredDrivers) {
      // Random variation of the original fare (between 90% and 120%)
      final variation = 0.9 + (random.nextDouble() * 0.3);
      final counterAmount = request.initialFare * variation;

      // Create the counter offer
      final counterOffer = FareOffer(
        id: _uuid.v4(),
        riderId: request.riderId,
        driverId: driver.id,
        amount: double.parse(counterAmount.toStringAsFixed(2)),
        timestamp: DateTime.now(),
        status: 'pending',
        message: 'I can take you for ₹${counterAmount.toInt()}',
      );

      _fareOffers.add(counterOffer);

      // Add counter offer ID to the request
      final updatedCounterIds = [
        ...updatedRequest.counterOfferIds,
        counterOffer.id,
      ];
      final requestWithCounters = updatedRequest.copyWith(
        counterOfferIds: updatedCounterIds,
      );

      _updateRideRequest(requestWithCounters);
    }

    notifyListeners();
  }

  // Get counter offers for a specific ride request
  List<FareOffer> getCounterOffersForRide(String rideRequestId) {
    final request = _rideRequests.firstWhere(
      (req) => req.id == rideRequestId,
      orElse: () => throw Exception('Ride request not found'),
    );

    return _fareOffers
        .where((offer) => request.counterOfferIds.contains(offer.id))
        .toList();
  }

  // Get driver details for a fare offer
  DriverModel getDriverForOffer(String driverId) {
    return _nearbyDrivers.firstWhere(
      (driver) => driver.id == driverId,
      orElse: () => throw Exception('Driver not found'),
    );
  }

  // Accept a counter offer from a driver
  void acceptCounterOffer(String offerId, String rideRequestId) {
    // Find the offer
    final offerIndex = _fareOffers.indexWhere((offer) => offer.id == offerId);
    if (offerIndex == -1) {
      throw Exception('Offer not found');
    }

    // Update the offer status
    final offer = _fareOffers[offerIndex];
    final updatedOffer = offer.copyWith(status: 'accepted');
    _fareOffers[offerIndex] = updatedOffer;

    // Update the ride request
    final requestIndex = _rideRequests.indexWhere(
      (req) => req.id == rideRequestId,
    );
    if (requestIndex == -1) {
      throw Exception('Ride request not found');
    }

    final request = _rideRequests[requestIndex];
    final updatedRequest = request.copyWith(
      status: 'accepted',
      acceptedOfferId: offerId,
      acceptedDriverId: offer.driverId,
      finalFare: offer.amount,
    );

    _rideRequests[requestIndex] = updatedRequest;
    _currentRideRequest = updatedRequest;

    // Reject all other offers for this ride
    for (int i = 0; i < _fareOffers.length; i++) {
      final currentOffer = _fareOffers[i];
      if (currentOffer.id != offerId &&
          request.counterOfferIds.contains(currentOffer.id)) {
        _fareOffers[i] = currentOffer.copyWith(status: 'rejected');
      }
    }

    notifyListeners();
  }

  // Counter offer from rider to a specific driver
  FareOffer createRiderCounterOffer({
    required String rideRequestId,
    required String driverId,
    required double amount,
    String? message,
    bool ensureResponse = false,
  }) {
    // Find the ride request
    final requestIndex = _rideRequests.indexWhere(
      (req) => req.id == rideRequestId,
    );
    if (requestIndex == -1) {
      throw Exception('Ride request not found');
    }

    // Create a new counter offer
    final counterOffer = FareOffer(
      id: _uuid.v4(),
      riderId: _rideRequests[requestIndex].riderId,
      driverId: driverId,
      amount: amount,
      timestamp: DateTime.now(),
      status: 'pending',
      message: message,
    );

    _fareOffers.add(counterOffer);

    // Update the ride request with the new counter offer ID
    final request = _rideRequests[requestIndex];
    final updatedCounterIds = [...request.counterOfferIds, counterOffer.id];
    final updatedRequest = request.copyWith(counterOfferIds: updatedCounterIds);

    _rideRequests[requestIndex] = updatedRequest;
    _currentRideRequest = updatedRequest;

    notifyListeners();

    // In a real app, this would send the counter to the driver
    // For demo purposes, automatically simulate driver response
    _simulateDriverResponseToCounter(
      counterOffer,
      rideRequestId,
      ensureResponse: ensureResponse,
    );

    return counterOffer;
  }

  // Simulate driver response to rider's counter offer
  void _simulateDriverResponseToCounter(
    FareOffer counterOffer,
    String rideRequestId, {
    bool ensureResponse = false,
  }) {
    // Random decision to accept or counter again
    final random = Random();
    final decision = ensureResponse ? 0.4 : random.nextDouble();

    if (decision > 0.5) {
      // Driver accepts the counter offer
      final updatedOffer = counterOffer.copyWith(status: 'accepted');
      final offerIndex = _fareOffers.indexWhere((o) => o.id == counterOffer.id);
      _fareOffers[offerIndex] = updatedOffer;

      // Update the ride request
      final requestIndex = _rideRequests.indexWhere(
        (req) => req.id == rideRequestId,
      );
      final request = _rideRequests[requestIndex];
      final updatedRequest = request.copyWith(
        status: 'accepted',
        acceptedOfferId: counterOffer.id,
        acceptedDriverId: counterOffer.driverId,
        finalFare: counterOffer.amount,
      );

      _rideRequests[requestIndex] = updatedRequest;
      _currentRideRequest = updatedRequest;
    } else {
      // Driver counters back
      final variation = 0.95 + (random.nextDouble() * 0.1);
      final newAmount = counterOffer.amount / variation;

      // Create new counter offer
      final newCounterOffer = FareOffer(
        id: _uuid.v4(),
        riderId: counterOffer.riderId,
        driverId: counterOffer.driverId,
        amount: double.parse(newAmount.toStringAsFixed(2)),
        timestamp: DateTime.now(),
        status: 'pending',
        message: 'My final offer is ₹${newAmount.toInt()}',
      );

      _fareOffers.add(newCounterOffer);

      // Update original counter offer status
      final offerIndex = _fareOffers.indexWhere((o) => o.id == counterOffer.id);
      _fareOffers[offerIndex] = counterOffer.copyWith(status: 'countered');

      // Update the ride request with the new counter offer ID
      final requestIndex = _rideRequests.indexWhere(
        (req) => req.id == rideRequestId,
      );
      final request = _rideRequests[requestIndex];
      final updatedCounterIds = [
        ...request.counterOfferIds,
        newCounterOffer.id,
      ];
      final updatedRequest = request.copyWith(
        counterOfferIds: updatedCounterIds,
      );

      _rideRequests[requestIndex] = updatedRequest;
      _currentRideRequest = updatedRequest;
    }

    notifyListeners();
  }

  // Update a ride request in the list
  void _updateRideRequest(RideRequest updatedRequest) {
    final index = _rideRequests.indexWhere(
      (req) => req.id == updatedRequest.id,
    );
    if (index != -1) {
      _rideRequests[index] = updatedRequest;
      _currentRideRequest = updatedRequest;
    }
  }

  // Cancel a ride request
  void cancelRideRequest(String rideRequestId) {
    final index = _rideRequests.indexWhere((req) => req.id == rideRequestId);
    if (index != -1) {
      final request = _rideRequests[index];
      final updatedRequest = request.copyWith(status: 'cancelled');
      _rideRequests[index] = updatedRequest;

      if (_currentRideRequest?.id == rideRequestId) {
        _currentRideRequest = updatedRequest;
      }

      notifyListeners();
    }
  }

  // Complete a ride
  void completeRide(String rideRequestId) {
    final index = _rideRequests.indexWhere((req) => req.id == rideRequestId);
    if (index != -1) {
      final request = _rideRequests[index];
      final updatedRequest = request.copyWith(status: 'completed');
      _rideRequests[index] = updatedRequest;

      if (_currentRideRequest?.id == rideRequestId) {
        _currentRideRequest = updatedRequest;
      }

      notifyListeners();
    }
  }

  // Reset current ride request
  void resetCurrentRideRequest() {
    _currentRideRequest = null;
    notifyListeners();
  }
}
