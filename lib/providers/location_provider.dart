import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../models/location_model.dart';
import '../models/feedback_model.dart';
import '../models/user_model.dart';
import '../services/database_service.dart';
import '../services/location_service.dart';
import '../services/storage_service.dart';
import '../config/constants.dart';
import 'dart:convert';

class LocationProvider with ChangeNotifier {
  final DatabaseService _databaseService = DatabaseService();
  final LocationService _locationService = LocationService();
  final StorageService _storageService = StorageService();
  
  List<LocationModel> _locations = [];
  List<FeedbackModel> _feedback = [];
  List<FeedbackModel> _pendingFeedback = []; // New list for pending feedback
  LocationModel? _selectedLocation;
  Position? _currentPosition;
  bool _isLoading = false;
  String? _errorMessage;
  bool _initialized = false;

  // Getters
  List<LocationModel> get locations => _locations;
  List<FeedbackModel> get feedback => _feedback;
  List<FeedbackModel> get pendingFeedback => _pendingFeedback;
  LocationModel? get selectedLocation => _selectedLocation;
  Position? get currentPosition => _currentPosition;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get initialized => _initialized;

  StreamSubscription<List<LocationModel>>? _locationsSubscription;
  StreamSubscription<List<FeedbackModel>>? _feedbackSubscription;
  StreamSubscription<List<FeedbackModel>>? _pendingFeedbackSubscription;

  // Constructor
  LocationProvider() {
    // Initialize with a small delay to ensure Firebase is ready
    Future.delayed(Duration(milliseconds: 100), () {
      if (!_initialized) {
        print("Auto-initializing LocationProvider");
        loadLocations();
        loadFeedback();
        loadPendingFeedback(); // Load pending feedback
        getCurrentLocation();
        _initialized = true;
      }
    });
  }

  // Get feedback for a specific location
  List<FeedbackModel> getFeedbackForLocation(String locationId) {
    return _feedback.where((feedback) => 
        feedback.locationId == locationId).toList();
  }

  // Check if a location has feedback
  bool hasLocationFeedback(String locationId) {
    return _feedback.any((feedback) => feedback.locationId == locationId);
  }

  void loadLocations() {
    _setLoading(true);
    try {
      print("Starting to load locations data...");
      
      // Cancel existing subscription if any
      _locationsSubscription?.cancel();
      
      // Create new subscription
      _locationsSubscription = _databaseService.getLocations().listen((locationsList) {
        print("Received ${locationsList.length} locations from database");
        
        // Log all locations for debugging
        for (var location in locationsList) {
          print("Location: ${location.name}, ID: ${location.id}");
          print("  Coordinates: ${location.latitude}, ${location.longitude}");
          print("  Safety: ${location.safetyLevel}, Rating: ${location.averageSafetyRating}");
        }
        
        _locations = locationsList;
        _setLoading(false);
        notifyListeners();
        
        // If no locations, add a sample one in Jitra
        if (locationsList.isEmpty) {
          print("No locations found, adding a sample location");
          _addSampleLocation();
        }
      }, onError: (e) {
        print("Error in locations listener: $e");
        _setError(e.toString());
        _setLoading(false);
      });
    } catch (e) {
      print("Error in loadLocations: $e");
      _setError(e.toString());
      _setLoading(false);
    }
  }

  Future<void> _addSampleLocation() async {
    try {
      await addLocation(
        name: "Jitra Town Center",
        latitude: 6.2641, // Jitra coordinates
        longitude: 100.4214,
      );
      print("Added sample location in Jitra");
    } catch (e) {
      print("Error adding sample location: $e");
    }
  }

  // Load feedback - now only loads approved feedback
  void loadFeedback() {
    _setLoading(true);
    try {
      print("Loading approved feedback data...");
      
      // Cancel existing subscription if any
      _feedbackSubscription?.cancel();
      
      // Create new subscription with detailed error handling
      _feedbackSubscription = _databaseService.getApprovedFeedback().listen(
        (feedbackList) {
          print("Received ${feedbackList.length} approved feedback items from database");
          _feedback = feedbackList;
          _setLoading(false);
          notifyListeners();
        }, 
        onError: (e) {
          print("Error in feedback listener: $e");
          _setError(e.toString());
          _setLoading(false);
        }
      );
    } catch (e) {
      print("Exception in loadFeedback: $e");
      _setError(e.toString());
      _setLoading(false);
    }
  }

  // Load pending feedback (for admin)
  void loadPendingFeedback() {
    _setLoading(true);
    try {
      print("Loading pending feedback data...");
      
      // Cancel existing subscription if any
      _pendingFeedbackSubscription?.cancel();
      
      // Create new subscription with detailed error handling
      _pendingFeedbackSubscription = _databaseService.getPendingFeedback().listen(
        (feedbackList) {
          print("Received ${feedbackList.length} pending feedback items from database");
          _pendingFeedback = feedbackList;
          _setLoading(false);
          notifyListeners();
        }, 
        onError: (e) {
          print("Error in pending feedback listener: $e");
          _setError(e.toString());
          _setLoading(false);
        }
      );
    } catch (e) {
      print("Exception in loadPendingFeedback: $e");
      _setError(e.toString());
      _setLoading(false);
    }
  }

  // Method to cancel all active listeners
  void cancelListeners() {
    print("Cancelling all LocationProvider listeners");
    
    _locationsSubscription?.cancel();
    _feedbackSubscription?.cancel();
    _pendingFeedbackSubscription?.cancel();
    
    _locationsSubscription = null;
    _feedbackSubscription = null;
    _pendingFeedbackSubscription = null;
    
    // Clear cached data to prevent stale data display
    print("Clearing cached location data");
  }

  // Clear all data - useful for refresh operations
  void clearData() {
    print("Clearing all location data");
    _locations = [];
    _feedback = [];
    _pendingFeedback = [];
    _selectedLocation = null;
    _currentPosition = null;
    _setLoading(false);
    _errorMessage = null;
    notifyListeners();
  }

  // Select location
  void selectLocation(LocationModel location) {
    print("Selected location: ${location.name}");
    _selectedLocation = location;
    notifyListeners();
  }

  // Get current location with better error handling
  Future<void> getCurrentLocation() async {
    _setLoading(true);
    try {
      print("Getting current position...");
      final position = await _locationService.getCurrentPosition();
      print("Current position obtained: ${position.latitude}, ${position.longitude}");
      _currentPosition = position;
      notifyListeners();
    } catch (e) {
      print("Error getting current position: $e");
      _setError("Location error: ${e.toString()}");
      
      // Set a default position for Malaysia
      _currentPosition = Position(
        longitude: 100.4214, // Default to Jitra
        latitude: 6.2641,
        timestamp: DateTime.now(),
        accuracy: 0,
        altitude: 0,
        heading: 0,
        speed: 0,
        speedAccuracy: 0, headingAccuracy: 0, altitudeAccuracy: 0,
      );
      notifyListeners();
    } finally {
      _setLoading(false);
    }
  }

  Future<List<LocationModel>> searchLocationsWithFeedback(String query) async {
    if (query.isEmpty) return [];
    
    _setLoading(true);
    try {
      print("Searching locations with feedback for query: $query");
      
      // Get all location IDs that have feedback
      final Set<String> locationIdsWithFeedback = _feedback
          .map((feedback) => feedback.locationId)
          .toSet();
      
      // Search all locations first
      final results = await _databaseService.searchLocations(query);
      
      // Filter to only include locations with feedback
      final filteredResults = results.where((location) => 
          locationIdsWithFeedback.contains(location.id)).toList();
      
      print("Filtered from ${results.length} to ${filteredResults.length} results with feedback");
      return filteredResults;
    } catch (e) {
      print("Error searching locations with feedback: $e");
      _setError(e.toString());
      return [];
    } finally {
      _setLoading(false);
    }
  }

  // Search locations
  Future<List<LocationModel>> searchLocations(String query) async {
    if (query.isEmpty) return [];
    
    _setLoading(true);
    try {
      print("Searching locations with query: $query");
      final results = await _databaseService.searchLocations(query);
      print("Search returned ${results.length} results");
      return results;
    } catch (e) {
      print("Error searching locations: $e");
      _setError(e.toString());
      return [];
    } finally {
      _setLoading(false);
    }
  }

  // Add location
  Future<LocationModel?> addLocation({
    required String name,
    required double latitude,
    required double longitude,
  }) async {
    _setLoading(true);
    try {
      print("Adding new location: $name");
      final location = await _databaseService.addOrUpdateLocation(
        name: name,
        latitude: latitude,
        longitude: longitude,
      );
      return location;
    } catch (e) {
      print("Error adding location: $e");
      _setError(e.toString());
      return null;
    } finally {
      _setLoading(false);
    }
  }

  // Get all locations that have feedback
  List<LocationModel> getLocationsWithFeedback() {
    // Create a set of location IDs that have feedback
    final Set<String> locationIdsWithFeedback = _feedback
        .map((feedback) => feedback.locationId)
        .toSet();
    
    // Filter locations to only include those with feedback
    return _locations.where((location) => 
        locationIdsWithFeedback.contains(location.id)).toList();
  }

  // Add feedback with improved error handling
  Future<bool> addFeedback({
    required UserModel user,
    required String locationId,
    required String locationName,
    required double safetyRating,
    required String feedback,
    String? imageBase64,
    File? imageFile,
  }) async {
    _setLoading(true);
    try {
      print("Adding feedback for location: $locationName");
      
      // Debug info
      if (imageBase64 != null) {
        print("Image data included (length: ${imageBase64.length})");
      } else if (imageFile != null) {
        print("Image file included: ${imageFile.path}");
      } else {
        print("No image included with feedback");
      }
      
      // Try to get base64 data from file if we have a file but no base64
      if (imageBase64 == null && imageFile != null) {
        try {
          final bytes = await imageFile.readAsBytes();
          imageBase64 = base64Encode(bytes);
          print("Converted image file to base64 (length: ${imageBase64.length})");
        } catch (e) {
          print("Error converting image file to base64: $e");
        }
      }
      
      // Add the feedback
      await _databaseService.addFeedback(
        user: user,
        locationId: locationId,
        locationName: locationName,
        safetyRating: safetyRating,
        feedback: feedback,
        imageBase64: imageBase64,
      );
      
      print("Feedback added successfully");
      
      // Refresh the feedback lists
      if (user.role == AppConstants.roleBuddy) {
        // If buddy, refresh pending feedback
        loadPendingFeedback();
      } else {
        // Otherwise refresh approved feedback
        loadFeedback();
      }
      
      return true;
    } catch (e) {
      print("Error in LocationProvider.addFeedback: $e");
      _setError(e.toString());
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Approve feedback (for admin)
  Future<bool> approveFeedback(String feedbackId) async {
    _setLoading(true);
    try {
      print("Approving feedback: $feedbackId");
      await _databaseService.updateFeedbackStatus(
        feedbackId: feedbackId,
        status: AppConstants.feedbackStatusApproved,
      );
      
      // Refresh both pending and approved feedback
      loadPendingFeedback();
      loadFeedback();
      
      return true;
    } catch (e) {
      print("Error approving feedback: $e");
      _setError(e.toString());
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Reject feedback (for admin)
  Future<bool> rejectFeedback(String feedbackId) async {
    _setLoading(true);
    try {
      print("Rejecting feedback: $feedbackId");
      await _databaseService.updateFeedbackStatus(
        feedbackId: feedbackId,
        status: AppConstants.feedbackStatusRejected,
      );
      
      // Refresh pending feedback list
      loadPendingFeedback();
      
      return true;
    } catch (e) {
      print("Error rejecting feedback: $e");
      _setError(e.toString());
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<FeedbackModel> addComment({
    required String feedbackId,
    required UserModel user,
    required String comment,
  }) async {
    _setLoading(true);
    try {
      print("Adding comment to feedback: $feedbackId");
      final updatedFeedback = await _databaseService.addComment(
        feedbackId: feedbackId,
        user: user,
        comment: comment,
      );
      
      // Refresh feedback lists
      loadFeedback();
      
      return updatedFeedback;
    } catch (e) {
      print("Error in LocationProvider.addComment: $e");
      _setError(e.toString());
      throw Exception('Error adding comment: $e');
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> toggleLike({
    required String feedbackId,
    required String userId,
  }) async {
    _setLoading(true);
    try {
      print("Toggling like for feedback: $feedbackId, user: $userId");
      await _databaseService.toggleLike(
        feedbackId: feedbackId,
        userId: userId,
      );
      
      // Refresh feedback list
      loadFeedback();
      
      return true;
    } catch (e) {
      print("Error in LocationProvider.toggleLike: $e");
      _setError(e.toString());
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Get nearby locations
  List<LocationModel> getNearbyLocations({
    required LatLng currentLocation,
    required double radius,
  }) {
    try {
      print("Getting nearby locations within ${radius}m of ${currentLocation.latitude}, ${currentLocation.longitude}");
      final nearbyLocations = _locationService.getNearbyLocations<LocationModel>(
        locations: _locations,
        currentLocation: currentLocation,
        radius: radius,
        getLatLng: (location) => LatLng(location.latitude, location.longitude),
      );
      print("Found ${nearbyLocations.length} nearby locations");
      return nearbyLocations;
    } catch (e) {
      print("Error getting nearby locations: $e");
      _setError(e.toString());
      return [];
    }
  }

  // Force refresh all data
  Future<void> refreshAllData() async {
    print("Forcing refresh of all location data");
    cancelListeners();
    clearData();
    _setLoading(true);
    
    try {
      await Future.delayed(Duration(milliseconds: 300));
      loadLocations();
      loadFeedback();
      loadPendingFeedback();
      await getCurrentLocation();
    } catch (e) {
      print("Error refreshing all data: $e");
      _setError(e.toString());
    } finally {
      _setLoading(false);
    }
  }

  // Helper methods
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(String error) {
    _errorMessage = error;
    notifyListeners();
  }

  void _clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  @override
  void dispose() {
    cancelListeners();
    super.dispose();
  }
}