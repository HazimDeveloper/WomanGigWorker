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
  final Function(LatLng position)? onMapTapped; // This will be null for workers

  const RiskMap({
    Key? key,
    required this.locations,
    this.initialPosition,
    this.initialZoom = 14.0,
    this.onLocationSelected,
    this.onMapTapped, // Will be null for view-only mode
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
  
  // Variables for restricting map movement
  final LatLng _jitraCenterPosition = LatLng(
    AppGeoConstants.jitraLatitude,
    AppGeoConstants.jitraLongitude
  );
  
  // Set bounds for Jitra area - slightly larger than the maxDistance to allow smoother UX
  final double _maxBoundsDistance = AppGeoConstants.maxDistanceFromJitraKm * 1.2; // 20% larger than the actual limit

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

  // Add a helper method to check if a position is within Jitra area
  bool _isInJitraArea(LatLng position) {
    final locationService = LocationService();
    return locationService.isInJitraArea(position.latitude, position.longitude);
  }

  // Method to enforce camera bounds
  Future<void> _enforceJitraBounds(GoogleMapController controller) async {
    LatLngBounds visibleRegion = await controller.getVisibleRegion();
    
    // Calculate the center of the visible region
    LatLng visibleCenter = LatLng(
      (visibleRegion.northeast.latitude + visibleRegion.southwest.latitude) / 2,
      (visibleRegion.northeast.longitude + visibleRegion.southwest.longitude) / 2
    );
    
    // Calculate distance from Jitra center to visible center
    final locationService = LocationService();
    double distanceInMeters = locationService.calculateDistance(
      _jitraCenterPosition, 
      visibleCenter
    );
    
    // Convert to km
    double distanceInKm = distanceInMeters / 1000;
    
    // If too far, animate back to Jitra center
    if (distanceInKm > _maxBoundsDistance) {
      print("Map dragged too far ($distanceInKm km). Restricting to Jitra area.");
      controller.animateCamera(
        CameraUpdate.newLatLngZoom(_jitraCenterPosition, widget.initialZoom)
      );
    }
  }

  void _updateMarkersAndCircles() {
    final Set<Marker> markers = {};
    final Set<Circle> circles = {};

    int validLocations = 0;
    int skippedLocations = 0;

    for (final location in widget.locations) {
      // Skip locations with invalid coordinates
      if (location.latitude == 0 && location.longitude == 0) {
        print("Skipping location with invalid coordinates: ${location.name} (ID: ${location.id})");
        skippedLocations++;
        continue;
      }
      
      // Skip locations outside Jitra area
      if (!_isInJitraArea(LatLng(location.latitude, location.longitude))) {
        print("Skipping location outside Jitra area: ${location.name}");
        skippedLocations++;
        continue;
      }
      
      validLocations++;

      // Create marker WITHOUT infoWindow to remove text bubbles
      final marker = Marker(
        markerId: MarkerId(location.id),
        position: LatLng(location.latitude, location.longitude),
        // Remove infoWindow or set it to empty to remove text
        // infoWindow: InfoWindow(), // Can use empty InfoWindow if needed
        icon: BitmapDescriptor.defaultMarker, // You can customize the marker icon here
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

    // Add Jitra boundary circle
    final jitraBoundaryCircle = Circle(
      circleId: const CircleId('jitra_boundary'),
      center: _jitraCenterPosition,
      radius: AppGeoConstants.maxDistanceFromJitraKm * 1000, // Convert km to meters
      fillColor: Colors.blue.withOpacity(0.05),
      strokeColor: Colors.blue,
      strokeWidth: 1,
    );
    circles.add(jitraBoundaryCircle);

    // If we have a selected position marker, add it back to the markers
    if (_selectedPositionMarker != null) {
      markers.add(_selectedPositionMarker!);
    }

    print("Map updated with $validLocations valid locations. Skipped $skippedLocations invalid locations.");

    setState(() {
      _markers = markers;
      _circles = circles;
    });
  }

  // Handle map taps
  void _onMapTap(LatLng position) {
    if (_inSelectionMode) {
      // Check if the position is within Jitra area
      if (_isInJitraArea(position)) {
        // Create a new marker for the selected position
        final newMarker = Marker(
          markerId: const MarkerId('selected_position'),
          position: position,
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueViolet),
          // Remove infoWindow to remove text
          // infoWindow: const InfoWindow(
          //   title: 'Selected Location',
          //   snippet: 'Tap to confirm this location',
          // ),
        );
        
        setState(() {
          _selectedPositionMarker = newMarker;
          // Update markers
          _markers = {..._markers.where((m) => m.markerId.value != 'selected_position'), newMarker};
        });
        
        // Call the callback
        widget.onMapTapped?.call(position);
      } else {
        // Show a message that this is outside Jitra
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Selected location is outside Jitra area. Please select a location within the blue circle.'),
            backgroundColor: Colors.orange,
          ),
        );
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

  // Add a method to refresh the map markers
  void refreshMap() {
    _updateMarkersAndCircles();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        GoogleMap(
          mapType: MapType.normal,
          initialCameraPosition: CameraPosition(
            target: widget.initialPosition ?? _jitraCenterPosition, // Default to Jitra
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
          onCameraMove: (CameraPosition position) {
            // Check if the camera is being moved too far from Jitra
            if (!_isInJitraArea(position.target)) {
              // Let it move a bit beyond before restricting for better UX
              if (position.zoom < 12) {
                // If zoomed out too far, we'll handle in onCameraIdle
                return;
              }
            }
          },
          onCameraIdle: () async {
            // When camera stops moving, check if we need to enforce boundaries
            final controller = await _controller.future;
            _enforceJitraBounds(controller);
          },
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
                'Tap on the map to select a location in Jitra area (within blue circle)',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
            ),
          ),
        
        // Jitra area explanation
        Positioned(
          top: 80,
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
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Row(
                  children: [
                    Container(
                      height: 12,
                      width: 12,
                      decoration: BoxDecoration(
                        color: Colors.blue.withOpacity(0.4),
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.blue, width: 1),
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      'Jitra Area',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
              ],
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