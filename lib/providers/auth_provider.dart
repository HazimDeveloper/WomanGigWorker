import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import 'package:trust_me/providers/location_provider.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';
import '../config/constants.dart';
import '../main.dart'; // Import to access navigatorKey
class AuthProvider with ChangeNotifier {
  final AuthService _authService = AuthService();
  
  UserModel? _user;
  bool _isLoading = false;
  String? _errorMessage;

  // Getters
  UserModel? get user => _user;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isAuthenticated => _user != null;
  bool get isCustomer => _user?.role == AppConstants.roleCustomer;
  bool get isBuddy => _user?.role == AppConstants.roleBuddy;
  bool get isAdmin => _user?.role == AppConstants.roleAdmin;

  // Constructor - initialize user from current Firebase user
  AuthProvider() {
    _initializeUser();
  }

  // Initialize user
  Future<void> _initializeUser() async {
    _setLoading(true);
    try {
      final User? currentUser = _authService.currentUser;
      if (currentUser != null) {
        _user = await _authService.getUserData(currentUser.uid);
      }
    } catch (e) {
      _setError(e.toString());
    } finally {
      _setLoading(false);
    }
  }

Future<void> refreshUserData() async {
  _setLoading(true);
  _clearError();
  try {
    if (_user != null) {
      _user = await _authService.getUserData(_user!.id);
      notifyListeners();
    }
  } catch (e) {
    _setError(e.toString());
  } finally {
    _setLoading(false);
  }
}

  // Sign up
  Future<bool> signUp({
    required String email,
    required String password,
    required String username,
    required String role,
  }) async {
    _setLoading(true);
    _clearError();
    try {
      _user = await _authService.signUpWithEmailAndPassword(
        email: email,
        password: password,
        username: username,
        role: role,
      );
      notifyListeners();
      return true;
    } catch (e) {
      _setError(e.toString());
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Sign in
  Future<bool> signIn({
    required String email,
    required String password,
  }) async {
    _setLoading(true);
    _clearError();
    try {
      _user = await _authService.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      notifyListeners();
      return true;
    } catch (e) {
      _setError(e.toString());
      return false;
    } finally {
      _setLoading(false);
    }
  }

// Add this method to your AuthProvider class
Future<bool> updateUserWithMap(Map<String, dynamic> data) async {
  if (_user == null) return false;
  
  _setLoading(true);
  _clearError();
  try {
    final UserModel updatedUser = _user!.copyWith(
      username: data['username'] ?? _user!.username,
      photoUrl: data['photoUrl'] ?? _user!.photoUrl,
      job: data['job'] ?? _user!.job,
      company: data['company'] ?? _user!.company,
      phoneNumber: data['phoneNumber'] ?? _user!.phoneNumber,
      updatedAt: DateTime.now(),
    );
    
    await _authService.updateUserData(updatedUser);
    _user = updatedUser;
    notifyListeners();
    return true;
  } catch (e) {
    _setError(e.toString());
    return false;
  } finally {
    _setLoading(false);
  }
}

Future<void> signOut() async {
  _setLoading(true);
  _clearError();
  try {
    // First, clear the user data
    _user = null;
    
    // Then cancel any active listeners
    if (navigatorKey.currentContext != null) {
      try {
        Provider.of<LocationProvider>(
          navigatorKey.currentContext!,
          listen: false
        ).cancelListeners();
      } catch (e) {
        print("Error cancelling location listeners: $e");
      }
    }
    
    // Finally, sign out from Firebase
    await _authService.signOut();
    
    // Notify about the change
    notifyListeners();
  } catch (e) {
    _setError(e.toString());
  } finally {
    _setLoading(false);
  }
}

void _cancelAllListeners() {
  try {
    // Cancel LocationProvider listeners
    if (navigatorKey.currentContext != null) {
      final locationProvider = Provider.of<LocationProvider>(
        navigatorKey.currentContext!,
        listen: false
      );
      locationProvider.cancelListeners();
    }
    
 
    
    print("All Firestore listeners cancelled successfully");
  } catch (e) {
    print("Error cancelling listeners: $e");
  }
}

  // Update user
 Future<bool> updateUser({
  String? username,
  String? photoUrl,
  String? photoBase64,
  String? job,
  String? company,
  String? phoneNumber,
}) async {
  if (_user == null) return false;
  
  _setLoading(true);
  _clearError();
  try {
    final UserModel updatedUser = _user!.copyWith(
      username: username,
      photoUrl: photoUrl ,
         photoBase64: photoBase64,
      job: job,
      company: company,
      phoneNumber: phoneNumber,
      updatedAt: DateTime.now(),
    );
    
    await _authService.updateUserData(updatedUser);
    _user = updatedUser; // Update local user object
    notifyListeners();
    return true;
  } catch (e) {
    _setError(e.toString());
    return false;
  } finally {
    _setLoading(false);
  }
}

  // Reset password
  Future<bool> resetPassword(String email) async {
    _setLoading(true);
    _clearError();
    try {
      await _authService.resetPassword(email);
      return true;
    } catch (e) {
      _setError(e.toString());
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Listen to auth state changes
 void listenToAuthChanges(BuildContext context) {
  _authService.userStream.listen((User? firebaseUser) async {
    try {
      if (firebaseUser == null) {
        // User signed out - set _user to null FIRST before any other operations
        _user = null;
        notifyListeners();
        
      } else {
        // User is signed in, fetch their data
        try {
          _user = await _authService.getUserData(firebaseUser.uid);
          notifyListeners();
        } catch (e) {
          print("Error fetching user data: $e");
          // Handle error but don't crash
        }
      }
    } catch (e) {
      print("Auth state change error: $e");
      // Don't crash the app, just log the error
    }
  });
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