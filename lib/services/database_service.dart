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

  // Get feedback
Stream<List<FeedbackModel>> getFeedback() {
  print("Starting feedback stream from Firestore");
  
  // Add a small delay before starting the stream to ensure Firebase is initialized
  return Stream.fromFuture(Future.delayed(Duration(milliseconds: 500)))
    .asyncExpand((_) {
      return _firestore
        .collection(AppConstants.feedbackCollection)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
          print("Feedback snapshot received with ${snapshot.docs.length} documents");
          // Convert snapshot to list of FeedbackModel objects
          return snapshot.docs
            .map((doc) => FeedbackModel.fromMap(doc.data(), doc.id))
            .toList();
        });
    });
}

 Future<FeedbackModel> addFeedback({
  required UserModel user,
  required String locationId,
  required String locationName,
  required double safetyRating,
  required String feedback,
  String? imageBase64,
}) async {
  try {
    final String feedbackId = _uuid.v4();
    final DateTime now = DateTime.now();

    // Create feedback model with base64 image
    final FeedbackModel feedbackModel = FeedbackModel(
      id: feedbackId,
      userId: user.id,
      username: user.username,
      userPhotoUrl: user.photoUrl,
      locationId: locationId,
      locationName: locationName,
      safetyRating: safetyRating,
      feedback: feedback,
      imageBase64: imageBase64, // Store base64 image
      createdAt: now,
    );

    // Save to Firestore
    await _firestore
        .collection(AppConstants.feedbackCollection)
        .doc(feedbackId)
        .set(feedbackModel.toMap());

    // Update location safety rating
    await _updateLocationSafetyRating(locationId, locationName, safetyRating);

    return feedbackModel;
  } catch (e) {
    print("Error in DatabaseService.addFeedback: $e");
    throw Exception('Error adding feedback: $e');
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
          data['latitude'] = 6.2641; // Jitra center
          data['longitude'] = 100.4214;
        }
        
        return LocationModel.fromMap(data, id);
      }).toList();
      
      // Log all locations to debug
      for (var location in locations) {
        print("Loaded: ${location.name} (${location.latitude}, ${location.longitude})");
      }
      
      return locations;
    });
}

  // Get location by ID
  Future<LocationModel?> getLocationById(String locationId) async {
    try {
      final DocumentSnapshot locationDoc = await _firestore
          .collection(AppConstants.locationsCollection)
          .doc(locationId)
          .get();

      if (!locationDoc.exists) {
        return null;
      }

      return LocationModel.fromMap(
          locationDoc.data() as Map<String, dynamic>, locationId);
    } catch (e) {
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
    
    // Proceed with the existing code...
    // Check if location exists
    final QuerySnapshot existingLocations = await _firestore
        .collection(AppConstants.locationsCollection)
        .where('name', isEqualTo: name)
        .limit(1)
        .get();

    if (existingLocations.docs.isNotEmpty) {
      // Location exists, update it
      final String locationId = existingLocations.docs[0].id;
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

      return updatedLocation;
    } else {
      // Create new location with verified coordinates
      final String locationId = _uuid.v4();
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
      // Get the current location
      LocationModel? location = await getLocationById(locationId);

      if (location == null) {
        // Location not found, create it
        location = await addOrUpdateLocation(
          name: locationName,
          latitude: 0.0, // Default values, will be updated later
          longitude: 0.0,
        );
      }

      // Update safety rating
      final LocationModel updatedLocation = location.updateSafetyRating(newRating);

      // Update in Firestore
      await _firestore
          .collection(AppConstants.locationsCollection)
          .doc(locationId)
          .update(updatedLocation.toMap());
    } catch (e) {
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