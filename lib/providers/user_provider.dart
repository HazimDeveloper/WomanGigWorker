import 'dart:io';
import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';
import '../services/database_service.dart';
import '../services/storage_service.dart';

class UserProvider with ChangeNotifier {
  final AuthService _authService = AuthService();
  final StorageService _storageService = StorageService();
  
  List<UserModel> _users = [];
  bool _isLoading = false;
  String? _errorMessage;

  // Getters
  List<UserModel> get users => _users;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  // Load all users
  Future<void> loadUsers() async {
    _setLoading(true);
    try {
      // Only admin should be able to load all users
      // This would typically be implemented with a security rule in Firestore
      // Here we're just demonstrating the functionality
      
      // Create an instance of DatabaseService to get users
      final DatabaseService databaseService = DatabaseService();
      databaseService.getUsers().listen((usersList) {
        _users = usersList;
        notifyListeners();
      });
    } catch (e) {
      _setError(e.toString());
    } finally {
      _setLoading(false);
    }
  }

  // Update profile picture
  Future<bool> updateProfilePicture(File imageFile, String userId) async {
    _setLoading(true);
    _clearError();
    try {
      // Upload image to Firebase Storage
      final String imageUrl = await _storageService.uploadProfileImage(imageFile, userId);
      
      // Get user
      final UserModel? user = await _authService.getUserData(userId);
      if (user == null) {
        throw Exception('User not found');
      }
      
      // Update user with new photo URL
      final UserModel updatedUser = user.copyWith(photoUrl: imageUrl);
      await _authService.updateUserData(updatedUser);
      
      // Update local users list if this user is in it
      final int index = _users.indexWhere((u) => u.id == userId);
      if (index != -1) {
        _users[index] = updatedUser;
        notifyListeners();
      }
      
      return true;
    } catch (e) {
      _setError(e.toString());
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Update user details
  Future<bool> updateUserDetails({
    required String userId,
    String? username,
    String? job,
    String? company,
    String? phoneNumber,
  }) async {
    _setLoading(true);
    _clearError();
    try {
      // Get user
      final UserModel? user = await _authService.getUserData(userId);
      if (user == null) {
        throw Exception('User not found');
      }
      
      // Update user
      final UserModel updatedUser = user.copyWith(
        username: username,
        job: job,
        company: company,
        phoneNumber: phoneNumber,
      );
      await _authService.updateUserData(updatedUser);
      
      // Update local users list if this user is in it
      final int index = _users.indexWhere((u) => u.id == userId);
      if (index != -1) {
        _users[index] = updatedUser;
        notifyListeners();
      }
      
      return true;
    } catch (e) {
      _setError(e.toString());
      return false;
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
}