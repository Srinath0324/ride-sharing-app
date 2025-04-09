import 'dart:async';
import 'package:flutter/material.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';
import '../services/map_service.dart';

class RydeMapWidget extends StatefulWidget {
  final bool showUserLocation;
  final Function(MapboxMap)? onMapCreated;
  final Function(CameraOptions)? onCameraChanged;
  final CameraOptions? initialCameraPosition;
  final Widget? child;

  const RydeMapWidget({
    super.key,
    this.showUserLocation = true,
    this.onMapCreated,
    this.onCameraChanged,
    this.initialCameraPosition,
    this.child,
  });

  @override
  State<RydeMapWidget> createState() => _RydeMapWidgetState();
}

class _RydeMapWidgetState extends State<RydeMapWidget> {
  MapboxMap? _mapboxMap;
  String? _styleUrl;
  CameraOptions? _initialCameraPosition;
  bool _isMapReady = false;

  @override
  void initState() {
    super.initState();
    _styleUrl = MapService.styleUrl;
    _loadInitialPosition();
  }

  Future<void> _loadInitialPosition() async {
    if (widget.initialCameraPosition != null) {
      _initialCameraPosition = widget.initialCameraPosition;
    } else {
      _initialCameraPosition = await MapService.getInitialCameraOptions();
    }

    if (mounted) {
      setState(() {});
    }
  }

  void _onMapCreated(MapboxMap mapboxMap) {
    _mapboxMap = mapboxMap;

    if (widget.showUserLocation) {
      MapService.setupLocationPuck(mapboxMap);
    }

    setState(() {
      _isMapReady = true;
    });

    if (widget.onMapCreated != null) {
      widget.onMapCreated!(mapboxMap);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_styleUrl == null || _initialCameraPosition == null) {
      return const Center(child: CircularProgressIndicator());
    }

    return Stack(
      children: [
        MapWidget(
          key: const ValueKey('mapWidget'),
          styleUri: _styleUrl!,
          cameraOptions: _initialCameraPosition,
          onMapCreated: _onMapCreated,
        ),
        if (_isMapReady && widget.child != null) widget.child!,
      ],
    );
  }
}
