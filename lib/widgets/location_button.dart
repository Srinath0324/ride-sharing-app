import 'package:flutter/material.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';
import '../services/map_service.dart';

class LocationButton extends StatelessWidget {
  final MapboxMap? mapboxMap;
  final double size;
  final double iconSize;
  final EdgeInsetsGeometry? margin;
  final Function()? onLocationButtonPressed;
  final Function(bool)? onLocationPermissionResult;

  const LocationButton({
    Key? key,
    this.mapboxMap,
    this.size = 50.0,
    this.iconSize = 24.0,
    this.margin,
    this.onLocationButtonPressed,
    this.onLocationPermissionResult,
  }) : super(key: key);

  // Handle location button press with permission checks
  Future<void> _handleLocationRequest(BuildContext context) async {
    try {
      // Show loading indicator in button
      if (onLocationButtonPressed != null) {
        onLocationButtonPressed!();
      }

      // Request location
      await MapService.getCurrentLocation();

      // If we have a map instance, animate to current location
      if (mapboxMap != null) {
        await MapService.animateCameraToCurrentLocation(mapboxMap!);
      }

      // Notify about successful permission
      if (onLocationPermissionResult != null) {
        onLocationPermissionResult!(true);
      }
    } catch (e) {
      // Show error message
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not get location: ${e.toString()}'),
            duration: const Duration(seconds: 3),
          ),
        );
      }

      // Notify about failed permission
      if (onLocationPermissionResult != null) {
        onLocationPermissionResult!(false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: margin,
      child: GestureDetector(
        onTap: () => _handleLocationRequest(context),
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: const Color(0xFF0CC25F),
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Center(
            child: Icon(Icons.my_location, color: Colors.white, size: iconSize),
          ),
        ),
      ),
    );
  }
}
