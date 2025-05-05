import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../config/constants.dart';

class LocationService {
  // Get current position
  Future<Position> getCurrentPosition() async {
    bool serviceEnabled;
    LocationPermission permission;

    // Check if location services are enabled
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      // Return a default position instead of throwing exception
      return Position(
        longitude: AppGeoConstants.jitraLongitude, // Default to Jitra
        latitude: AppGeoConstants.jitraLatitude,
        timestamp: DateTime.now(),
        accuracy: 0,
        altitude: 0,
        heading: 0,
        speed: 0,
        speedAccuracy: 0,
        altitudeAccuracy: 0,
        headingAccuracy: 0,
      );
    }

    // Check location permission
    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        // Return default position
        return Position(
          longitude: AppGeoConstants.jitraLongitude, // Default to Jitra
          latitude: AppGeoConstants.jitraLatitude,
          timestamp: DateTime.now(),
          accuracy: 0,
          altitude: 0,
          heading: 0,
          speed: 0,
          speedAccuracy: 0,
          altitudeAccuracy: 0,
          headingAccuracy: 0,
        );
      }
    }

    if (permission == LocationPermission.deniedForever) {
      // Return default position
      return Position(
        longitude: AppGeoConstants.jitraLongitude, // Default to Jitra
        latitude: AppGeoConstants.jitraLatitude,
        timestamp: DateTime.now(),
        accuracy: 0,
        altitude: 0,
        heading: 0,
        speed: 0,
        speedAccuracy: 0,
        altitudeAccuracy: 0,
        headingAccuracy: 0,
      );
    }

    // Get current position
    return await Geolocator.getCurrentPosition();
  }

  // Calculate distance between two locations in meters
  double calculateDistance(LatLng point1, LatLng point2) {
    return Geolocator.distanceBetween(
      point1.latitude,
      point1.longitude,
      point2.latitude,
      point2.longitude,
    );
  }

  // Check if a location is within the Jitra area
  bool isInJitraArea(double latitude, double longitude) {
    // Create a LatLng for the location and for Jitra
    final LatLng locationLatLng = LatLng(latitude, longitude);
    final LatLng jitraLatLng = LatLng(
      AppGeoConstants.jitraLatitude, 
      AppGeoConstants.jitraLongitude
    );
    
    // Calculate distance in meters
    final double distanceInMeters = calculateDistance(locationLatLng, jitraLatLng);
    
    // Convert to kilometers and check against max distance
    final double distanceInKm = distanceInMeters / 1000;
    final bool isInRange = distanceInKm <= AppGeoConstants.maxDistanceFromJitraKm;
    
    print("Location distance from Jitra: ${distanceInKm.toStringAsFixed(2)}km (in range: $isInRange)");
    
    return isInRange;
  }

  // Get nearby locations within a radius (in meters)
  List<T> getNearbyLocations<T>({
    required List<T> locations,
    required LatLng currentLocation,
    required double radius,
    required LatLng Function(T) getLatLng,
  }) {
    return locations.where((location) {
      final LatLng locationLatLng = getLatLng(location);
      final double distance = calculateDistance(currentLocation, locationLatLng);
      return distance <= radius;
    }).toList();
  }
}