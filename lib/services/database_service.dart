import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:trust_me/models/comment_model.dart';
import 'package:trust_me/services/location_service.dart';
import 'package:uuid/uuid.dart';
import '../models/feedback_model.dart';
import '../models/location_model.dart';
import '../models/user_model.dart';
import '../config/constants.dart';

class DatabaseService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final Uuid _uuid = const Uuid();

  // Get all users
  Stream<List<UserModel>> getUsers() {
    return _firestore
        .collection(AppConstants.usersCollection)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => UserModel.fromMap(doc.data(), doc.id))
            .toList());
  }

  Stream<List<FeedbackModel>> getFeedback({String? status}) {
    print("Starting feedback stream from Firestore" + (status != null ? " with status: $status" : ""));
    
    // Add a small delay before starting the stream to ensure Firebase is initialized
    return Stream.fromFuture(Future.delayed(Duration(milliseconds: 500)))
      .asyncExpand((_) {
        Query query = _firestore
          .collection(AppConstants.feedbackCollection)
          .orderBy('createdAt', descending: true);
        
        // Add status filter if specified
        if (status != null) {
          query = query.where('status', isEqualTo: status);
        }
        
        return query.snapshots().map((snapshot) {
          print("Feedback snapshot received with ${snapshot.docs.length} documents");
          // Convert snapshot to list of FeedbackModel objects
          return snapshot.docs
            .map((doc) => FeedbackModel.fromMap(doc.data() as Map<String, dynamic>, doc.id))
            .toList();
        });
      });
  }

  // Get pending feedback (for admin approval)
  Stream<List<FeedbackModel>> getPendingFeedback() {
    return getFeedback(status: AppConstants.feedbackStatusPending);
  }

  // Get approved feedback (for displaying in home screens)
  Stream<List<FeedbackModel>> getApprovedFeedback() {
    return getFeedback(status: AppConstants.feedbackStatusApproved);
  }

  // Get feedback by user role
  Stream<List<FeedbackModel>> getFeedbackByUserRole(String userRole, {String? status}) {
    print("Starting feedback stream for role: $userRole" + (status != null ? " with status: $status" : ""));
    
    return Stream.fromFuture(Future.delayed(Duration(milliseconds: 500)))
      .asyncExpand((_) {
        Query query = _firestore
          .collection(AppConstants.feedbackCollection)
          .where('userRole', isEqualTo: userRole)
          .orderBy('createdAt', descending: true);
        
        // Add status filter if specified
        if (status != null) {
          query = query.where('status', isEqualTo: status);
        }
        
        return query.snapshots().map((snapshot) {
          print("Feedback snapshot received with ${snapshot.docs.length} documents for role: $userRole");
          return snapshot.docs
            .map((doc) => FeedbackModel.fromMap(doc.data() as Map<String, dynamic>, doc.id))
            .toList();
        });
      });
  }

  // Add feedback with status and userRole
  Future<FeedbackModel> addFeedback({
    required UserModel user,
    required String locationId,
    required String locationName,
    required double safetyRating,
    required String feedback,
    String? imageBase64,
  }) async {
    try {
      print("Starting addFeedback process for location: $locationName (ID: $locationId)");
      final String feedbackId = _uuid.v4();
      final DateTime now = DateTime.now();

      // Determine initial status based on user role
      // For Buddy users, feedback starts as pending
      // For Customer/Worker users, feedback is automatically approved
      String initialStatus = user.role == AppConstants.roleBuddy 
        ? AppConstants.feedbackStatusPending 
        : AppConstants.feedbackStatusApproved;

      // Create feedback model with base64 image, status and userRole
      final FeedbackModel feedbackModel = FeedbackModel(
        id: feedbackId,
        userId: user.id,
        username: user.username,
        userPhotoUrl: user.photoUrl,
        locationId: locationId,
        locationName: locationName,
        safetyRating: safetyRating,
        feedback: feedback,
        imageBase64: imageBase64,
        createdAt: now,
        status: initialStatus,
        userRole: user.role,
      );

      print("Saving feedback with ID: $feedbackId, status: $initialStatus");
      // Save to Firestore
      await _firestore
          .collection(AppConstants.feedbackCollection)
          .doc(feedbackId)
          .set(feedbackModel.toMap());

      // Update location safety rating (only if feedback is approved)
      if (initialStatus == AppConstants.feedbackStatusApproved) {
        print("Feedback is approved, updating location safety rating");
        await _updateLocationSafetyRating(locationId, locationName, safetyRating);
        
        // Add a small delay to ensure Firestore updates propagate
        await Future.delayed(const Duration(milliseconds: 500));
      } else {
        print("Feedback is pending approval, not updating location safety rating yet");
      }

      return feedbackModel;
    } catch (e) {
      print("Error in DatabaseService.addFeedback: $e");
      throw Exception('Error adding feedback: $e');
    }
  }

  // Update feedback status
  Future<FeedbackModel> updateFeedbackStatus({
    required String feedbackId,
    required String status,
  }) async {
    try {
      print("Updating feedback status: $feedbackId to $status");
      // Get the current feedback
      final DocumentSnapshot feedbackDoc = await _firestore
          .collection(AppConstants.feedbackCollection)
          .doc(feedbackId)
          .get();

      if (!feedbackDoc.exists) {
        throw Exception('Feedback not found');
      }

      final FeedbackModel feedbackModel = FeedbackModel.fromMap(
          feedbackDoc.data() as Map<String, dynamic>, feedbackId);

      // Update status
      final FeedbackModel updatedFeedback = feedbackModel.copyWith(status: status);

      // Update feedback in Firestore
      await _firestore
          .collection(AppConstants.feedbackCollection)
          .doc(feedbackId)
          .update({'status': status});

      // If feedback is being approved, update location safety rating
      if (status == AppConstants.feedbackStatusApproved && 
          feedbackModel.status != AppConstants.feedbackStatusApproved) {
        print("Feedback is now approved, updating location safety rating");
        await _updateLocationSafetyRating(
          feedbackModel.locationId, 
          feedbackModel.locationName, 
          feedbackModel.safetyRating
        );
        
        // Add a small delay to ensure Firestore updates propagate
        await Future.delayed(const Duration(milliseconds: 500));
      }

      return updatedFeedback;
    } catch (e) {
      print("Error updating feedback status: $e");
      throw Exception('Error updating feedback status: $e');
    }
  }

  Future<FeedbackModel> addComment({
    required String feedbackId,
    required UserModel user,
    required String comment,
  }) async {
    try {
      final String commentId = _uuid.v4();
      final CommentModel commentModel = CommentModel(
        id: commentId,
        userId: user.id,
        username: user.username,
        userPhotoUrl: user.photoUrl,
        text: comment,
        createdAt: DateTime.now(),
      );

      // Get the current feedback
      final DocumentSnapshot feedbackDoc = await _firestore
          .collection(AppConstants.feedbackCollection)
          .doc(feedbackId)
          .get();

      if (!feedbackDoc.exists) {
        throw Exception('Feedback not found');
      }

      final FeedbackModel feedbackModel = FeedbackModel.fromMap(
          feedbackDoc.data() as Map<String, dynamic>, feedbackId);

      // Add comment
      final FeedbackModel updatedFeedback = feedbackModel.addComment(commentModel);

      // Update feedback in Firestore
      await _firestore
          .collection(AppConstants.feedbackCollection)
          .doc(feedbackId)
          .update({
        'comments': updatedFeedback.comments.map((c) => c.toMap()).toList(),
      });

      return updatedFeedback;
    } catch (e) {
      print("Error adding comment: $e");
      throw Exception('Error adding comment: $e');
    }
  }

  Future<FeedbackModel> toggleLike({
    required String feedbackId,
    required String userId,
  }) async {
    try {
      // Get the current feedback
      final DocumentSnapshot feedbackDoc = await _firestore
          .collection(AppConstants.feedbackCollection)
          .doc(feedbackId)
          .get();

      if (!feedbackDoc.exists) {
        throw Exception('Feedback not found');
      }

      final FeedbackModel feedbackModel = FeedbackModel.fromMap(
          feedbackDoc.data() as Map<String, dynamic>, feedbackId);

      // Check if user already liked
      FeedbackModel updatedFeedback;
      if (feedbackModel.likedBy.contains(userId)) {
        updatedFeedback = feedbackModel.removeLike(userId);
      } else {
        updatedFeedback = feedbackModel.addLike(userId);
      }

      // Update feedback in Firestore
      await _firestore
          .collection(AppConstants.feedbackCollection)
          .doc(feedbackId)
          .update({
        'likedBy': updatedFeedback.likedBy,
      });

      return updatedFeedback;
    } catch (e) {
      print("Error toggling like: $e");
      throw Exception('Error toggling like: $e');
    }
  }

  // Get locations
  Stream<List<LocationModel>> getLocations() {
    print("Starting locations stream from Firestore");
    
    return _firestore
      .collection(AppConstants.locationsCollection)
      .snapshots()
      .map((snapshot) {
        print("Location snapshot received with ${snapshot.docs.length} documents");
        
        // Convert to location models and ensure each has valid coordinates
        List<LocationModel> locations = snapshot.docs.map((doc) {
          var data = doc.data();
          var id = doc.id;
          
          // Handle potential missing data
          if (!data.containsKey('latitude') || !data.containsKey('longitude')) {
            print("Location ${data['name'] ?? id} missing coordinates, adding defaults");
            data['latitude'] = AppGeoConstants.jitraLatitude; // Jitra center
            data['longitude'] = AppGeoConstants.jitraLongitude;
          }
          
          return LocationModel.fromMap(data, id);
        }).toList();
        
        // Log all locations to debug
        for (var location in locations) {
          print("Loaded: ${location.name} (${location.latitude}, ${location.longitude}) - Safety level: ${location.safetyLevel}");
        }
        
        return locations;
      });
  }

  // Get location by ID
  Future<LocationModel?> getLocationById(String locationId) async {
    try {
      print("Fetching location with ID: $locationId");
      final DocumentSnapshot locationDoc = await _firestore
          .collection(AppConstants.locationsCollection)
          .doc(locationId)
          .get();

      if (!locationDoc.exists) {
        print("Location not found with ID: $locationId");
        return null;
      }

      final locationData = locationDoc.data() as Map<String, dynamic>;
      print("Found location: ${locationData['name']} (${locationData['latitude']}, ${locationData['longitude']})");
      return LocationModel.fromMap(locationData, locationId);
    } catch (e) {
      print("Error getting location: $e");
      throw Exception('Error getting location: $e');
    }
  }

  // Add or update location
  Future<LocationModel> addOrUpdateLocation({
    required String name,
    required double latitude,
    required double longitude,
  }) async {
    try {
      print("Adding or updating location: $name at ($latitude, $longitude)");
      // Validate coordinates - if 0,0 or null, use Jitra coordinates
      if (latitude == 0 || longitude == 0) {
        print("Invalid coordinates (0,0) for location: $name. Using Jitra center coordinates.");
        latitude = AppGeoConstants.jitraLatitude;
        longitude = AppGeoConstants.jitraLongitude;
      }
      
      // Check if the location is in Jitra area
      final locationService = LocationService();
      final bool isInJitra = locationService.isInJitraArea(latitude, longitude);
      
      if (!isInJitra) {
        print("Warning: Location is outside Jitra area. Adjusting to Jitra center.");
        // Use Jitra coordinates
        latitude = AppGeoConstants.jitraLatitude;
        longitude = AppGeoConstants.jitraLongitude;
      }
      
      // Check if location exists
      print("Checking if location '$name' already exists");
      final QuerySnapshot existingLocations = await _firestore
          .collection(AppConstants.locationsCollection)
          .where('name', isEqualTo: name)
          .limit(1)
          .get();

      if (existingLocations.docs.isNotEmpty) {
        // Location exists, update it
        final String locationId = existingLocations.docs[0].id;
        print("Location exists with ID: $locationId, updating coordinates");
        final LocationModel existingLocation = LocationModel.fromMap(
            existingLocations.docs[0].data() as Map<String, dynamic>, locationId);

        // Only update coordinates if they're valid
        final LocationModel updatedLocation = existingLocation.copyWith(
          latitude: latitude,
          longitude: longitude,
        );

        await _firestore
            .collection(AppConstants.locationsCollection)
            .doc(locationId)
            .update(updatedLocation.toMap());

        print("Location updated: ${updatedLocation.name} (${updatedLocation.latitude}, ${updatedLocation.longitude}) - Safety level: ${updatedLocation.safetyLevel}");
        return updatedLocation;
      } else {
        // Create new location with verified coordinates
        final String locationId = _uuid.v4();
        print("Creating new location with ID: $locationId");
        final LocationModel newLocation = LocationModel(
          id: locationId,
          name: name,
          latitude: latitude,
          longitude: longitude,
          averageSafetyRating: 0.0,
          ratingCount: 0,
          safetyLevel: AppConstants.safeLevelModerate, // Default to moderate
          updatedAt: DateTime.now(),
        );

        await _firestore
            .collection(AppConstants.locationsCollection)
            .doc(locationId)
            .set(newLocation.toMap());

        print("New location created: ${newLocation.name} (${newLocation.latitude}, ${newLocation.longitude}) - Safety level: ${newLocation.safetyLevel}");
        return newLocation;
      }
    } catch (e) {
      print("Error in addOrUpdateLocation: $e");
      throw Exception('Error adding/updating location: $e');
    }
  }

  // Update location safety rating
  Future<void> _updateLocationSafetyRating(
    String locationId,
    String locationName,
    double newRating,
  ) async {
    try {
      print("Updating safety rating for location: $locationName (ID: $locationId) - New rating: $newRating");
      // Get the current location
      LocationModel? location = await getLocationById(locationId);

      if (location == null) {
        // Location not found, create it
        print("Location not found, creating new location");
        location = await addOrUpdateLocation(
          name: locationName,
          latitude: AppGeoConstants.jitraLatitude, // Use Jitra coordinates instead of 0,0
          longitude: AppGeoConstants.jitraLongitude,
        );
      }

      // Update safety rating
      print("Current rating: ${location.averageSafetyRating} (${location.ratingCount} ratings)");
      final LocationModel updatedLocation = location.updateSafetyRating(newRating);
      print("Updated rating: ${updatedLocation.averageSafetyRating} (${updatedLocation.ratingCount} ratings)");
      print("New safety level: ${updatedLocation.safetyLevel}");

      // Update in Firestore
      await _firestore
          .collection(AppConstants.locationsCollection)
          .doc(locationId)
          .update(updatedLocation.toMap());
          
      print("Location safety rating updated successfully");
    } catch (e) {
      print("Error updating location safety rating: $e");
      throw Exception('Error updating location safety rating: $e');
    }
  }

  Future<List<LocationModel>> searchLocations(String query) async {
    try {
      print("Searching for locations with query: $query");
      
      // Try to find existing locations
      final QuerySnapshot locationsSnapshot = await _firestore
          .collection(AppConstants.locationsCollection)
          .where('name', isGreaterThanOrEqualTo: query.toLowerCase())
          .where('name', isLessThanOrEqualTo: query.toLowerCase() + '\uf8ff')
          .get();

      List<LocationModel> results = locationsSnapshot.docs
          .map((doc) => LocationModel.fromMap(doc.data() as Map<String, dynamic>, doc.id))
          .toList();
      
      print("Found ${results.length} locations for query: $query");
      
      // Check and fix coordinates for all results
      results = results.map((location) {
        // If coordinates are missing or 0, use Jitra coordinates
        if (location.latitude == 0 || location.longitude == 0) {
          print("Fixing coordinates for location: ${location.name}");
          return location.copyWith(
            latitude: AppGeoConstants.jitraLatitude,
            longitude: AppGeoConstants.jitraLongitude
          );
        }
        return location;
      }).toList();
      
      return results;
    } catch (e) {
      print("Error searching locations: $e");
      throw Exception('Error searching locations: $e');
    }
  }
}