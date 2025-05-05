class UserModel {
  final String id;
  final String username;
  final String email;
  final String role;
  final String? photoUrl;
  final String? job;
  final String? company;
  final String? phoneNumber;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? photoBase64;
  
  UserModel({
    required this.id,
    required this.username,
    required this.email,
    required this.role,
    this.photoUrl,
    this.job,
    this.company,
    this.phoneNumber,
    this.isActive = true,
    required this.createdAt,
    required this.updatedAt,
    this.photoBase64,
  });

  // Helper getters for role-based checks
  bool get isCustomer => role == 'customer';
  bool get isWorker => role == 'worker';
  bool get isBuddy => role == 'buddy';
  bool get isAdmin => role == 'admin';

  // Create from Firebase
  factory UserModel.fromMap(Map<String, dynamic> map, String id) {
    return UserModel(
      id: id,
      username: map['username'] ?? '',
      email: map['email'] ?? '',
      role: map['role'] ?? 'customer',
      photoUrl: map['photoUrl'],
      photoBase64: map['photoBase64'],
      job: map['job'],
      company: map['company'],
      phoneNumber: map['phoneNumber'],
      isActive: map['isActive'] ?? true,
      createdAt: map['createdAt'] != null
          ? (map['createdAt'] as dynamic).toDate()
          : DateTime.now(),
      updatedAt: map['updatedAt'] != null
          ? (map['updatedAt'] as dynamic).toDate()
          : DateTime.now(),
    );
  }

  // Convert to map for Firebase
  Map<String, dynamic> toMap() {
    return {
      'username': username,
      'email': email,
      'role': role,
      'photoUrl': photoUrl,
      'job': job,
      'company': company,
      'phoneNumber': phoneNumber,
      'isActive': isActive,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
      'photoBase64': photoBase64,
    };
  }

  // Create a copy with updated fields
  UserModel copyWith({
    String? username,
    String? email,
    String? role,
    String? photoUrl,
    String? job,
    String? company,
    String? phoneNumber,
    bool? isActive,
    DateTime? updatedAt,
    String? photoBase64,
  }) {
    return UserModel(
      id: this.id,
      username: username ?? this.username,
      email: email ?? this.email,
      role: role ?? this.role,
      photoUrl: photoUrl ?? this.photoUrl,
      job: job ?? this.job,
      company: company ?? this.company,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      isActive: isActive ?? this.isActive,
      createdAt: this.createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
      photoBase64: photoBase64 ?? this.photoBase64,
    );
  }
}