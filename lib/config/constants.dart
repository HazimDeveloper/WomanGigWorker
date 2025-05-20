// Modified constants.dart file to ensure proper Jitra boundaries

import 'package:flutter/material.dart';

class AppColors {
  // Using the pink color from the design
  static const primary = Color(0xFFFFC0CB); // Pink color
  static const secondary = Color(0xFFB347B3); // Purple color for buttons
  static const background = Color(0xFFFFC0CB); // Pink background
  static const safeGreen = Color(0xFF4CAF50); // Green for safe areas
  static const moderateYellow = Color(0xFFFFEB3B); // Yellow for moderate risk
  static const highRiskRed = Color(0xFFE53935); // Red for high-risk areas
  static const textDark = Color(0xFF212121);
  static const textLight = Color(0xFF757575);
  static const cardBg = Color(0xFFAF35AF); // Darker pink for cards
}

class AppConstants {
  // Firebase collections
  static const String usersCollection = 'users';
  static const String feedbackCollection = 'feedback';
  static const String locationsCollection = 'locations';
  
  // User roles
  static const String roleCustomer = 'customer';
  static const String roleWorker = 'worker'; // Added worker role
  static const String roleBuddy = 'buddy';
  static const String roleAdmin = 'admin';
  
  // Safety levels
  static const String safeLevelSafe = 'safe';
  static const String safeLevelModerate = 'moderate';
  static const String safeLevelHighRisk = 'high_risk';
  
  // Feedback status
  static const String feedbackStatusPending = 'pending'; // New feedback status
  static const String feedbackStatusApproved = 'approved'; // New feedback status
  static const String feedbackStatusRejected = 'rejected'; // New feedback status
}

class AppAssets {
  // Image paths
  static const String logoPath = 'assets/images/logo.png';
  static const String placeholderPath = 'assets/images/placeholder.png';
  static const String mapMarkerPath = 'assets/icons/map_marker.png';
  
  // Icon paths
  static const String homeIconPath = 'assets/icons/home.svg';
  static const String mapIconPath = 'assets/icons/map.svg';
  static const String addIconPath = 'assets/icons/add.svg';
  static const String profileIconPath = 'assets/icons/profile.svg';
}

class ApiKeys {
  static const String googleMapsApiKey = 'AIzaSyAwwgmqAxzQmdmjNQ-vklZnvVdZjkWLcTY';
}

class AppGeoConstants {
  // Jitra, Kedah coordinates
  static const double jitraLatitude = 6.2641;
  static const double jitraLongitude = 100.4214;
  
  // Maximum allowed distance from Jitra in kilometers
  // Reduced from 15km to 10km for tighter area restriction
  static const double maxDistanceFromJitraKm = 10.0;
  
  // Kedah state boundary coordinates (approximate)
  static const double kedahNorth = 6.5167; // Northern boundary
  static const double kedahSouth = 5.4586; // Southern boundary
  static const double kedahEast = 101.1532; // Eastern boundary
  static const double kedahWest = 99.6445; // Western boundary
  
  // Map zoom levels
  static const double defaultZoom = 14.0;
  static const double closeZoom = 16.0;
  static const double farZoom = 12.0;
  static const double maxZoom = 18.0;
  static const double minZoom = 10.0;
  
  // Map movement thresholds
  static const double bounceThresholdKm = 12.0; // When to bounce back to Jitra
}