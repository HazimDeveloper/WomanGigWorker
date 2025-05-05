
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/comment_model.dart';

class FeedbackModel {
  final String id;
  final String userId;
  final String username;
  final String? userPhotoUrl;
  final String locationId;
  final String locationName;
  final double safetyRating;
  final String feedback;
  final String? imageUrl; // Keep for backward compatibility
  final String? imageBase64; // Add this field
  final List<String> likedBy;
  final List<CommentModel> comments;
  final DateTime createdAt;

  FeedbackModel({
    required this.id,
    required this.userId,
    required this.username,
    this.userPhotoUrl,
    required this.locationId,
    required this.locationName,
    required this.safetyRating,
    required this.feedback,
    this.imageUrl,
    this.imageBase64, // New field
    this.likedBy = const [],
    this.comments = const [],
    required this.createdAt,
  });

  // Update fromMap
  factory FeedbackModel.fromMap(Map<String, dynamic> map, String id) {
    return FeedbackModel(
      id: id,
      userId: map['userId'] ?? '',
      username: map['username'] ?? '',
      userPhotoUrl: map['userPhotoUrl'],
      locationId: map['locationId'] ?? '',
      locationName: map['locationName'] ?? '',
      safetyRating: (map['safetyRating'] ?? 0.0).toDouble(),
      feedback: map['feedback'] ?? '',
      imageUrl: map['imageUrl'],
      imageBase64: map['imageBase64'], // Add this
      likedBy: List<String>.from(map['likedBy'] ?? []),
      comments: map['comments'] != null
          ? List<CommentModel>.from(
              (map['comments'] as List).map(
                (x) => CommentModel.fromMap(x),
              ),
            )
          : [],
      createdAt: map['createdAt'] != null
          ? (map['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
    );
  }

  // Update toMap
  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'username': username,
      'userPhotoUrl': userPhotoUrl,
      'locationId': locationId,
      'locationName': locationName,
      'safetyRating': safetyRating,
      'feedback': feedback,
      'imageUrl': imageUrl,
      'imageBase64': imageBase64, // Add this
      'likedBy': likedBy,
      'comments': comments.map((comment) => comment.toMap()).toList(),
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  // Update copyWith
  FeedbackModel copyWith({
    String? userId,
    String? username,
    String? userPhotoUrl,
    String? locationId,
    String? locationName,
    double? safetyRating,
    String? feedback,
    String? imageUrl,
    String? imageBase64, // Add this
    List<String>? likedBy,
    List<CommentModel>? comments,
  }) {
    return FeedbackModel(
      id: this.id,
      userId: userId ?? this.userId,
      username: username ?? this.username,
      userPhotoUrl: userPhotoUrl ?? this.userPhotoUrl,
      locationId: locationId ?? this.locationId,
      locationName: locationName ?? this.locationName,
      safetyRating: safetyRating ?? this.safetyRating,
      feedback: feedback ?? this.feedback,
      imageUrl: imageUrl ?? this.imageUrl,
      imageBase64: imageBase64 ?? this.imageBase64, // Add this
      likedBy: likedBy ?? this.likedBy,
      comments: comments ?? this.comments,
      createdAt: this.createdAt,
    );
  }

  FeedbackModel addLike(String userId) {
  if (likedBy.contains(userId)) return this;
  
  List<String> updatedLikes = List.from(likedBy);
  updatedLikes.add(userId);
  
  return copyWith(likedBy: updatedLikes);
}

// Remove a like
FeedbackModel removeLike(String userId) {
  if (!likedBy.contains(userId)) return this;
  
  List<String> updatedLikes = List.from(likedBy);
  updatedLikes.remove(userId);
  
  return copyWith(likedBy: updatedLikes);
}

// Add a comment
FeedbackModel addComment(CommentModel comment) {
  List<CommentModel> updatedComments = List.from(comments);
  updatedComments.add(comment);
  
  return copyWith(comments: updatedComments);
}
}