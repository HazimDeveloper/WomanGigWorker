import 'package:cloud_firestore/cloud_firestore.dart';
import '../config/constants.dart';

class LocationModel {
  final String id;
  final String name;
  final double latitude;
  final double longitude;
  final double averageSafetyRating;
  final int ratingCount;
  final String safetyLevel;
  final DateTime updatedAt;

  LocationModel({
    required this.id,
    required this.name,
    required this.latitude,
    required this.longitude,
    required this.averageSafetyRating,
    required this.ratingCount,
    required this.safetyLevel,
    required this.updatedAt,
  });

  // Create from Firebase
 factory LocationModel.fromMap(Map<String, dynamic> map, String id) {
  // Calculate safety level based on average rating
  final double rating = (map['averageSafetyRating'] ?? 0.0).toDouble();
  String safetyLevel;
  
  // Debug print to see what's happening with ratings
  print("Location: ${map['name']}, Rating: $rating");
  
  if (rating >= 4) {
    safetyLevel = AppConstants.safeLevelSafe;
    print("Assigned as SAFE");
  } else if (rating >= 2.5) {
    safetyLevel = AppConstants.safeLevelModerate;
    print("Assigned as MODERATE");
  } else {
    safetyLevel = AppConstants.safeLevelHighRisk;
    print("Assigned as HIGH RISK");
  }

  // Always use the calculated safety level, not the one from the database
  // to ensure consistency
  return LocationModel(
    id: id,
    name: map['name'] ?? '',
    latitude: (map['latitude'] ?? 0.0).toDouble(),
    longitude: (map['longitude'] ?? 0.0).toDouble(),
    averageSafetyRating: (map['averageSafetyRating'] ?? 0.0).toDouble(),
    ratingCount: map['ratingCount'] ?? 0,
    safetyLevel: safetyLevel, // Always use the calculated safety level
    updatedAt: map['updatedAt'] != null
        ? (map['updatedAt'] as Timestamp).toDate()
        : DateTime.now(),
  );
}

  // Convert to map for Firebase
  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'latitude': latitude,
      'longitude': longitude,
      'averageSafetyRating': averageSafetyRating,
      'ratingCount': ratingCount,
      'safetyLevel': safetyLevel,
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  // Update safety rating
  LocationModel updateSafetyRating(double newRating) {
    final int newCount = ratingCount + 1;
    final double newAverage =
        ((averageSafetyRating * ratingCount) + newRating) / newCount;

    // Determine new safety level
    String newSafetyLevel;
    if (newAverage >= 4) {
      newSafetyLevel = AppConstants.safeLevelSafe;
    } else if (newAverage >= 2.5) {
      newSafetyLevel = AppConstants.safeLevelModerate;
    } else {
      newSafetyLevel = AppConstants.safeLevelHighRisk;
    }

    return LocationModel(
      id: id,
      name: name,
      latitude: latitude,
      longitude: longitude,
      averageSafetyRating: newAverage,
      ratingCount: newCount,
      safetyLevel: newSafetyLevel,
      updatedAt: DateTime.now(),
    );
  }

  // Create a copy with updated fields
  LocationModel copyWith({
    String? name,
    double? latitude,
    double? longitude,
    double? averageSafetyRating,
    int? ratingCount,
    String? safetyLevel,
  }) {
    return LocationModel(
      id: this.id,
      name: name ?? this.name,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      averageSafetyRating: averageSafetyRating ?? this.averageSafetyRating,
      ratingCount: ratingCount ?? this.ratingCount,
      safetyLevel: safetyLevel ?? this.safetyLevel,
      updatedAt: DateTime.now(),
    );
  }
}
