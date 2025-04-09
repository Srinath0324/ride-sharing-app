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

  /// Draw a route on the map
  static Future<String> drawRoute(
    MapboxMap mapboxMap,
    Map<String, dynamic> geometry,
  ) async {
    // Generate unique source and layer IDs
    final String sourceId =
        'route-source-${DateTime.now().millisecondsSinceEpoch}';
    final String layerId =
        'route-layer-${DateTime.now().millisecondsSinceEpoch}';

    // Create a GeoJSON source with the route geometry
    final geojson = {'type': 'Feature', 'properties': {}, 'geometry': geometry};

    try {
      // Add source
      await mapboxMap.style.addSource(
        GeoJsonSource(id: sourceId, data: jsonEncode(geojson)),
      );

      // Add line layer
      await mapboxMap.style.addLayer(
        LineLayer(
          id: layerId,
          sourceId: sourceId,
          lineColor: Colors.blue.value,
          lineWidth: 5.0,
          lineOpacity: 0.7,
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
