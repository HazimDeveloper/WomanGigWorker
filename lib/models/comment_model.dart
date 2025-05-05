import 'package:cloud_firestore/cloud_firestore.dart';

class CommentModel {
  final String id;
  final String userId;
  final String username;
  final String? userPhotoUrl;
  final String text;
  final DateTime createdAt;

  CommentModel({
    required this.id,
    required this.userId,
    required this.username,
    this.userPhotoUrl,
    required this.text,
    required this.createdAt,
  });

  // Create from map
  factory CommentModel.fromMap(Map<String, dynamic> map) {
    return CommentModel(
      id: map['id'] ?? '',
      userId: map['userId'] ?? '',
      username: map['username'] ?? '',
      userPhotoUrl: map['userPhotoUrl'],
      text: map['text'] ?? '',
      createdAt: map['createdAt'] != null
          ? (map['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
    );
  }

  // Convert to map
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'username': username,
      'userPhotoUrl': userPhotoUrl,
      'text': text,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  // Create a copy with updated fields
  CommentModel copyWith({
    String? id,
    String? userId,
    String? username,
    String? userPhotoUrl,
    String? text,
    DateTime? createdAt,
  }) {
    return CommentModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      username: username ?? this.username,
      userPhotoUrl: userPhotoUrl ?? this.userPhotoUrl,
      text: text ?? this.text,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  String toString() {
    return 'CommentModel(id: $id, userId: $userId, username: $username, text: $text, createdAt: $createdAt)';
  }
}