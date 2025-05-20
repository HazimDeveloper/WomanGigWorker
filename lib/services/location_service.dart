import 'dart:math' as math;
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../config/constants.dart';

class LocationService {
  // Get current position with proper error handling
  Future<Position> getCurrentPosition() async {
    try {
      bool serviceEnabled;
      LocationPermission permission;

      // Check if location services are enabled
      serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        print("Location services are disabled, returning default Jitra position");
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
          print("Location permissions denied, returning default Jitra position");
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
        print("Location permissions permanently denied, returning default Jitra position");
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
      final position = await Geolocator.getCurrentPosition();
      print("Got current position: ${position.latitude}, ${position.longitude}");
      
      // Check if the position is within Jitra area
      if (!isInJitraArea(position.latitude, position.longitude)) {
        print("Current position is outside Jitra area, returning Jitra center");
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
      
      return position;
    } catch (e) {
      print("Error getting current position: $e");
      // Return default position for Jitra in case of any errors
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

  // Calculate distance between two locations in meters using Haversine formula
  double calculateDistance(LatLng point1, LatLng point2) {
    const double earthRadius = 6371000; // in meters
    
    // Convert coordinates from degrees to radians
    final double lat1 = _degreesToRadians(point1.latitude);
    final double lon1 = _degreesToRadians(point1.longitude);
    final double lat2 = _degreesToRadians(point2.latitude);
    final double lon2 = _degreesToRadians(point2.longitude);
    
    // Haversine formula
    final double dLat = lat2 - lat1;
    final double dLon = lon2 - lon1;
    final double a = 
        math.sin(dLat/2) * math.sin(dLat/2) +
        math.cos(lat1) * math.cos(lat2) * 
        math.sin(dLon/2) * math.sin(dLon/2);
    final double c = 2 * math.atan2(math.sqrt(a), math.sqrt(1-a));
    
    final double distance = earthRadius * c;
    return distance;
  }
  
  // Convert degrees to radians
  double _degreesToRadians(double degrees) {
    return degrees * (math.pi / 180);
  }

  // Check if a location is within the Jitra area
  bool isInJitraArea(double latitude, double longitude) {
    // Skip invalid coordinates
    if (latitude == 0 && longitude == 0) {
      print("Invalid coordinates (0,0), not in Jitra area");
      return false;
    }
    
    // Create LatLng for the location and for Jitra
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
    final List<T> validLocations = [];
    int skippedInvalidCoordinates = 0;
    int skippedOutsideJitra = 0;
    
    for (final location in locations) {
      try {
        final LatLng locationLatLng = getLatLng(location);
        
        // Skip invalid coordinates
        if (locationLatLng.latitude == 0 && locationLatLng.longitude == 0) {
          skippedInvalidCoordinates++;
          continue;
        }
        
        // Skip locations outside Jitra
        if (!isInJitraArea(locationLatLng.latitude, locationLatLng.longitude)) {
          skippedOutsideJitra++;
          continue;
        }
        
        // Calculate distance from current location
        final double distance = calculateDistance(currentLocation, locationLatLng);
        
        // Add if within radius
        if (distance <= radius) {
          validLocations.add(location);
        }
      } catch (e) {
        print("Error processing location in getNearbyLocations: $e");
      }
    }
    
    print("Found ${validLocations.length} locations within ${radius/1000}km radius");
    print("Skipped $skippedInvalidCoordinates locations with invalid coordinates");
    print("Skipped $skippedOutsideJitra locations outside Jitra area");
    
    return validLocations;
  }

  // Get distance between two locations in kilometers
  double getDistanceInKm(double lat1, double lon1, double lat2, double lon2) {
    final LatLng point1 = LatLng(lat1, lon1);
    final LatLng point2 = LatLng(lat2, lon2);
    
    return calculateDistance(point1, point2) / 1000;
  }

  // Check if coordinates are valid
  bool areCoordinatesValid(double latitude, double longitude) {
    // Basic validation range (-90 to 90 for latitude, -180 to 180 for longitude)
    if (latitude < -90 || latitude > 90 || longitude < -180 || longitude > 180) {
      return false;
    }
    
    // Check if they're exactly 0,0 (often indicates uninitialized coordinates)
    if (latitude == 0 && longitude == 0) {
      return false;
    }
    
    return true;
  }

  // Get fixed coordinates for invalid ones (defaults to Jitra center)
  LatLng getFixedCoordinates(double latitude, double longitude) {
    if (areCoordinatesValid(latitude, longitude)) {
      return LatLng(latitude, longitude);
    } else {
      print("Invalid coordinates ($latitude, $longitude), fixing to Jitra center");
      return LatLng(AppGeoConstants.jitraLatitude, AppGeoConstants.jitraLongitude);
    }
  }
}