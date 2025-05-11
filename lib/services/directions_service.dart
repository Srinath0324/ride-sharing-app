import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';
import 'package:flutter/material.dart';

class DirectionsService {
  static final String? _accessToken = dotenv.env['MAPBOX_PUBLIC_TOKEN'];
  static const String _endpoint =
      'https://api.mapbox.com/directions/v5/mapbox/driving';

  /// Get a route between coordinates
  static Future<Map<String, dynamic>> getRoute(
    Position origin,
    Position destination,
  ) async {
    if (_accessToken == null) {
      throw Exception('Mapbox access token not found');
    }

    final coordinates =
        '${origin.lng},${origin.lat};${destination.lng},${destination.lat}';
    final url =
        '$_endpoint/$coordinates?geometries=geojson&overview=full&access_token=$_accessToken';

    final response = await http.get(Uri.parse(url));
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);

      if (data['routes'] != null && data['routes'].length > 0) {
        final route = data['routes'][0];

        return {
          'routes': data['routes'],
          'geometry': route['geometry'],
          'duration': route['duration'],
          'distance': route['distance'],
        };
      } else {
        throw Exception('No route found between the coordinates');
      }
    } else {
      throw Exception('Failed to get directions: ${response.statusCode}');
    }
  }

  /// Get directions between coordinates with detailed response
  static Future<Map<String, dynamic>> getDirections(
    num startLng,
    num startLat,
    num endLng,
    num endLat,
  ) async {
    if (_accessToken == null) {
      throw Exception('Mapbox access token not found');
    }

    final coordinates = '$startLng,$startLat;$endLng,$endLat';
    final url =
        '$_endpoint/$coordinates?geometries=geojson&overview=full&access_token=$_accessToken';

    final response = await http.get(Uri.parse(url));
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);

      if (data['routes'] != null && data['routes'].isNotEmpty) {
        final route = data['routes'][0];

        return {
          'routes': data['routes'],
          'geometry': route['geometry'],
          'duration': route['duration'], // in seconds
          'distance': route['distance'], // in meters
        };
      } else {
        throw Exception('No route found between the coordinates');
      }
    } else {
      throw Exception('Failed to get directions: ${response.statusCode}');
    }
  }

  /// Draw a route on the map
  static Future<String> drawRoute(
    MapboxMap mapboxMap,
    Map<String, dynamic> geometry,
  ) async {
    // Generate unique source and layer IDs
    final String sourceId =
        'route-source-${DateTime.now().millisecondsSinceEpoch}';
    final String routeLayerId = '$sourceId-route';
    final String casingLayerId = '$sourceId-casing';

    // Create a GeoJSON source with the route geometry
    final geojson = {'type': 'Feature', 'properties': {}, 'geometry': geometry};

    try {
      // Remove old route layers if they exist
      try {
        // We're simplifying by just attempting to remove common layer IDs
        // This approach avoids the need to iterate through arrays that might have null issues
        await mapboxMap.style.removeStyleLayer('route-layer');
        await mapboxMap.style.removeStyleLayer('casing-layer');
        await mapboxMap.style.removeStyleSource('route-source');
      } catch (e) {
        // Ignore errors if layers don't exist
      }

      // Add source
      await mapboxMap.style.addSource(
        GeoJsonSource(id: sourceId, data: jsonEncode(geojson)),
      );

      // Add casing layer first (this creates the outline/border of the route)
      await mapboxMap.style.addLayer(
        LineLayer(
          id: casingLayerId,
          sourceId: sourceId,
          lineColor: Colors.blue.shade800.value,
          lineWidth: 8.0,
          lineOpacity: 0.7,
        ),
      );

      // Add main route layer on top
      await mapboxMap.style.addLayer(
        LineLayer(
          id: routeLayerId,
          sourceId: sourceId,
          lineColor: Colors.blue.value,
          lineWidth: 4.0,
          lineOpacity: 0.9,
        ),
      );

      return sourceId;
    } catch (e) {
      print('Error drawing route: $e');
      return '';
    }
  }

  /// Add marker for a location point
  static Future<String> addMarker(
    MapboxMap mapboxMap,
    Position position,
    Color color, {
    String? markerId,
  }) async {
    final pointId =
        markerId ?? 'point-${DateTime.now().millisecondsSinceEpoch}';

    // Create GeoJSON for point
    final pointGeoJson = {
      'type': 'Feature',
      'properties': {},
      'geometry': {
        'type': 'Point',
        'coordinates': [position.lng, position.lat],
      },
    };

    try {
      // Add source for point
      await mapboxMap.style.addSource(
        GeoJsonSource(id: pointId, data: jsonEncode(pointGeoJson)),
      );

      // Add circle layer for point
      await mapboxMap.style.addLayer(
        CircleLayer(
          id: '${pointId}-circle',
          sourceId: pointId,
          circleColor: color.value,
          circleRadius: 10.0,
          circleStrokeColor: Colors.white.value,
          circleStrokeWidth: 2.0,
        ),
      );

      return pointId;
    } catch (e) {
      print('Error adding marker: $e');
      return '';
    }
  }

  /// Remove source and layer from map
  static Future<void> removeSource(MapboxMap mapboxMap, String sourceId) async {
    try {
      final layerId = '${sourceId}-circle';
      if (await mapboxMap.style.styleLayerExists(layerId)) {
        await mapboxMap.style.removeStyleLayer(layerId);
      }
      if (await mapboxMap.style.styleSourceExists(sourceId)) {
        await mapboxMap.style.removeStyleSource(sourceId);
      }
    } catch (e) {
      print('Error removing source: $e');
    }
  }
}
