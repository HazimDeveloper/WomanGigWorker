import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../models/location_model.dart';
import '../config/constants.dart';
import '../services/location_service.dart';

class RiskMap extends StatefulWidget {
  final List<LocationModel> locations;
  final LatLng? initialPosition;
  final double initialZoom;
  final Function(LocationModel location)? onLocationSelected;
  final Function(LatLng position)? onMapTapped; // Add this new callback

  const RiskMap({
    Key? key,
    required this.locations,
    this.initialPosition,
    this.initialZoom = 14.0,
    this.onLocationSelected,
    this.onMapTapped, // Add this parameter
  }) : super(key: key);

  @override
  RiskMapState createState() => RiskMapState();
}

class RiskMapState extends State<RiskMap> {
  final Completer<GoogleMapController> _controller = Completer();
  Set<Marker> _markers = {};
  Set<Circle> _circles = {};
  Marker? _selectedPositionMarker; // New marker for tapped position
  
  // Add a variable to track if we're in location selection mode
  bool _inSelectionMode = false;

  @override
  void initState() {
    super.initState();
    _updateMarkersAndCircles();
  }

  @override
  void didUpdateWidget(RiskMap oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.locations != widget.locations) {
      _updateMarkersAndCircles();
    }
  }

  void _updateMarkersAndCircles() {
    final Set<Marker> markers = {};
    final Set<Circle> circles = {};

    for (final location in widget.locations) {
      // Skip locations with invalid coordinates
      if (location.latitude == 0 && location.longitude == 0) {
        continue;
      }

      // Create marker
      final marker = Marker(
        markerId: MarkerId(location.id),
        position: LatLng(location.latitude, location.longitude),
        infoWindow: InfoWindow(
          title: location.name,
          snippet: 'Safety: ${location.safetyLevel}',
        ),
        onTap: () {
          widget.onLocationSelected?.call(location);
        },
      );
      markers.add(marker);

      // Create circle for safety rating visualization
      Color circleColor;
      switch (location.safetyLevel) {
        case AppConstants.safeLevelSafe:
          circleColor = AppColors.safeGreen;
          break;
        case AppConstants.safeLevelModerate:
          circleColor = AppColors.moderateYellow;
          break;
        case AppConstants.safeLevelHighRisk:
          circleColor = AppColors.highRiskRed;
          break;
        default:
          circleColor = Colors.grey;
      }

      final circle = Circle(
        circleId: CircleId(location.id),
        center: LatLng(location.latitude, location.longitude),
        radius: 100, // 100 meters
        fillColor: circleColor.withOpacity(0.3),
        strokeColor: circleColor,
        strokeWidth: 1,
      );
      circles.add(circle);
    }

    // If we have a selected position marker, add it back to the markers
    if (_selectedPositionMarker != null) {
      markers.add(_selectedPositionMarker!);
    }

    setState(() {
      _markers = markers;
      _circles = circles;
    });
  }

  // Add this method to handle map taps
  void _onMapTap(LatLng position) {
    if (_inSelectionMode) {
      // Check if the position is within Jitra area
      final locationService = LocationService();
      final bool isInJitra = locationService.isInJitraArea(
        position.latitude, 
        position.longitude
      );
      
      if (isInJitra) {
        // Create a new marker for the selected position
        final newMarker = Marker(
          markerId: const MarkerId('selected_position'),
          position: position,
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueViolet),
          infoWindow: const InfoWindow(
            title: 'Selected Location',
            snippet: 'Tap to confirm this location',
          ),
        );
        
        setState(() {
          _selectedPositionMarker = newMarker;
          // Update markers
          _markers = {..._markers.where((m) => m.markerId.value != 'selected_position'), newMarker};
        });
        
        // Call the callback
        widget.onMapTapped?.call(position);
      } else {
        // Show a message via callback that this is outside Jitra
        final jitraPosition = LatLng(
          AppGeoConstants.jitraLatitude,
          AppGeoConstants.jitraLongitude
        );
        widget.onMapTapped?.call(jitraPosition);
      }
    }
  }

  // Add a method to enable/disable selection mode
  void setSelectionMode(bool enabled) {
    setState(() {
      _inSelectionMode = enabled;
      if (!enabled) {
        // Clear selected position marker when disabling selection mode
        _selectedPositionMarker = null;
        _updateMarkersAndCircles();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        GoogleMap(
          mapType: MapType.normal,
          initialCameraPosition: CameraPosition(
            target: widget.initialPosition ?? const LatLng(6.2641, 100.4214), // Default to Jitra
            zoom: widget.initialZoom,
          ),
          markers: _markers,
          circles: _circles,
          myLocationEnabled: true,
          myLocationButtonEnabled: true,
          zoomControlsEnabled: true,
          onMapCreated: (GoogleMapController controller) {
            _controller.complete(controller);
          },
          onTap: _onMapTap, // Add the tap handler
        ),
        
        // Selection mode indicator
        if (_inSelectionMode)
          Positioned(
            top: 16,
            left: 16,
            right: 16,
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: const Text(
                'Tap on the map to select a location in Jitra area',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
            ),
          ),
      ],
    );
  }

  Future<void> animateToPosition(LatLng position) async {
    final GoogleMapController controller = await _controller.future;
    controller.animateCamera(CameraUpdate.newLatLngZoom(position, 15));
  }
}