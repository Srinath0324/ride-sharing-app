class RideRequest {
  final String id;
  final String riderId;
  final String? acceptedDriverId;
  final String fromAddress;
  final String toAddress;
  final double fromLat;
  final double fromLng;
  final double toLat;
  final double toLng;
  final double initialFare;
  final double? finalFare;
  final DateTime requestTime;
  final DateTime? scheduledTime;
  final String
  status; // 'pending', 'negotiating', 'accepted', 'cancelled', 'completed'
  final int seats;
  final List<String> counterOfferIds;
  final String? acceptedOfferId;
  final String rideType; // 'shared' or 'private'

  RideRequest({
    required this.id,
    required this.riderId,
    this.acceptedDriverId,
    required this.fromAddress,
    required this.toAddress,
    required this.fromLat,
    required this.fromLng,
    required this.toLat,
    required this.toLng,
    required this.initialFare,
    this.finalFare,
    required this.requestTime,
    this.scheduledTime,
    required this.status,
    required this.seats,
    this.counterOfferIds = const [],
    this.acceptedOfferId,
    this.rideType = 'shared', // Default to shared rides
  });

  // Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'riderId': riderId,
      'acceptedDriverId': acceptedDriverId,
      'fromAddress': fromAddress,
      'toAddress': toAddress,
      'fromLat': fromLat,
      'fromLng': fromLng,
      'toLat': toLat,
      'toLng': toLng,
      'initialFare': initialFare,
      'finalFare': finalFare,
      'requestTime': requestTime.toIso8601String(),
      'scheduledTime': scheduledTime?.toIso8601String(),
      'status': status,
      'seats': seats,
      'counterOfferIds': counterOfferIds,
      'acceptedOfferId': acceptedOfferId,
      'rideType': rideType,
    };
  }

  // Create from JSON
  factory RideRequest.fromJson(Map<String, dynamic> json) {
    return RideRequest(
      id: json['id'] ?? '',
      riderId: json['riderId'] ?? '',
      acceptedDriverId: json['acceptedDriverId'],
      fromAddress: json['fromAddress'] ?? '',
      toAddress: json['toAddress'] ?? '',
      fromLat: (json['fromLat'] ?? 0.0).toDouble(),
      fromLng: (json['fromLng'] ?? 0.0).toDouble(),
      toLat: (json['toLat'] ?? 0.0).toDouble(),
      toLng: (json['toLng'] ?? 0.0).toDouble(),
      initialFare: (json['initialFare'] ?? 0.0).toDouble(),
      finalFare:
          json['finalFare'] != null ? (json['finalFare']).toDouble() : null,
      requestTime:
          json['requestTime'] != null
              ? DateTime.parse(json['requestTime'])
              : DateTime.now(),
      scheduledTime:
          json['scheduledTime'] != null
              ? DateTime.parse(json['scheduledTime'])
              : null,
      status: json['status'] ?? 'pending',
      seats: json['seats'] ?? 1,
      counterOfferIds: List<String>.from(json['counterOfferIds'] ?? []),
      acceptedOfferId: json['acceptedOfferId'],
      rideType: json['rideType'] ?? 'shared',
    );
  }

  // Create a copy with updated values
  RideRequest copyWith({
    String? id,
    String? riderId,
    String? acceptedDriverId,
    String? fromAddress,
    String? toAddress,
    double? fromLat,
    double? fromLng,
    double? toLat,
    double? toLng,
    double? initialFare,
    double? finalFare,
    DateTime? requestTime,
    DateTime? scheduledTime,
    String? status,
    int? seats,
    List<String>? counterOfferIds,
    String? acceptedOfferId,
    String? rideType,
  }) {
    return RideRequest(
      id: id ?? this.id,
      riderId: riderId ?? this.riderId,
      acceptedDriverId: acceptedDriverId ?? this.acceptedDriverId,
      fromAddress: fromAddress ?? this.fromAddress,
      toAddress: toAddress ?? this.toAddress,
      fromLat: fromLat ?? this.fromLat,
      fromLng: fromLng ?? this.fromLng,
      toLat: toLat ?? this.toLat,
      toLng: toLng ?? this.toLng,
      initialFare: initialFare ?? this.initialFare,
      finalFare: finalFare ?? this.finalFare,
      requestTime: requestTime ?? this.requestTime,
      scheduledTime: scheduledTime ?? this.scheduledTime,
      status: status ?? this.status,
      seats: seats ?? this.seats,
      counterOfferIds: counterOfferIds ?? this.counterOfferIds,
      acceptedOfferId: acceptedOfferId ?? this.acceptedOfferId,
      rideType: rideType ?? this.rideType,
    );
  }
}
