import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';
import '../config/constants.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Get current user
  User? get currentUser => _auth.currentUser;

  // User stream
  Stream<User?> get userStream => _auth.authStateChanges();

  // Sign up with email and password
  Future<UserModel> signUpWithEmailAndPassword({
    required String email,
    required String password,
    required String username,
    required String role,
  }) async {
    try {
      // Create user in Firebase Auth
      final UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (userCredential.user == null) {
        throw Exception('Failed to create user');
      }

      final User user = userCredential.user!;

      // Create user model
      final UserModel userModel = UserModel(
        id: user.uid,
        username: username,
        email: email,
        role: role,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      // Save user in Firestore
      await _firestore.collection(AppConstants.usersCollection).doc(user.uid).set(userModel.toMap());

      return userModel;
    } on FirebaseAuthException catch (e) {
      if (e.code == 'weak-password') {
        throw Exception('The password provided is too weak.');
      } else if (e.code == 'email-already-in-use') {
        throw Exception('The account already exists for that email.');
      } else {
        throw Exception('Error during sign up: ${e.message}');
      }
    } catch (e) {
      throw Exception('Error during sign up: $e');
    }
  }

  // Sign in with email and password
  Future<UserModel> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    try {
      // Check for predefined role emails for testing
      String role = AppConstants.roleCustomer; // Default role

      if (email == 'nini@buddy.gmail.com') {
        // Special handling for buddy test account
        print("Buddy test account detected");
        
        // Check if user exists in Firebase
        try {
          final userCredential = await _auth.signInWithEmailAndPassword(
            email: email,
            password: password,
          );
          
          if (userCredential.user == null) {
            // Create buddy test account if it doesn't exist
            return await signUpWithEmailAndPassword(
              email: email,
              password: password,
              username: 'Buddy Test',
              role: AppConstants.roleBuddy,
            );
          }
          
          // User exists, check if role is correct
          final user = userCredential.user!;
          final docSnapshot = await _firestore.collection(AppConstants.usersCollection).doc(user.uid).get();
          
          if (docSnapshot.exists) {
            final userData = docSnapshot.data();
            if (userData != null && userData['role'] == AppConstants.roleBuddy) {
              // Role is correct, return user model
              return UserModel.fromMap(userData, user.uid);
            } else {
              // Update role to buddy
              await _firestore.collection(AppConstants.usersCollection).doc(user.uid).update({
                'role': AppConstants.roleBuddy,
              });
              
              // Get updated user data
              final updatedDoc = await _firestore.collection(AppConstants.usersCollection).doc(user.uid).get();
              return UserModel.fromMap(updatedDoc.data()!, user.uid);
            }
          } else {
            // Create user document if it doesn't exist
            final userModel = UserModel(
              id: user.uid,
              username: 'Buddy Test',
              email: email,
              role: AppConstants.roleBuddy,
              createdAt: DateTime.now(),
              updatedAt: DateTime.now(),
            );
            
            await _firestore.collection(AppConstants.usersCollection).doc(user.uid).set(userModel.toMap());
            return userModel;
          }
        } catch (e) {
          print("Error with buddy test account: $e");
          // Create buddy test account if sign in fails
          return await signUpWithEmailAndPassword(
            email: email,
            password: password,
            username: 'Buddy Test',
            role: AppConstants.roleBuddy,
          );
        }
      } else if (email == 'nini@admin.gmail.com') {
        // Special handling for admin test account
        print("Admin test account detected");
        
        // Check if user exists in Firebase
        try {
          final userCredential = await _auth.signInWithEmailAndPassword(
            email: email,
            password: password,
          );
          
          if (userCredential.user == null) {
            // Create admin test account if it doesn't exist
            return await signUpWithEmailAndPassword(
              email: email,
              password: password,
              username: 'Admin Test',
              role: AppConstants.roleAdmin,
            );
          }
          
          // User exists, check if role is correct
          final user = userCredential.user!;
          final docSnapshot = await _firestore.collection(AppConstants.usersCollection).doc(user.uid).get();
          
          if (docSnapshot.exists) {
            final userData = docSnapshot.data();
            if (userData != null && userData['role'] == AppConstants.roleAdmin) {
              // Role is correct, return user model
              return UserModel.fromMap(userData, user.uid);
            } else {
              // Update role to admin
              await _firestore.collection(AppConstants.usersCollection).doc(user.uid).update({
                'role': AppConstants.roleAdmin,
              });
              
              // Get updated user data
              final updatedDoc = await _firestore.collection(AppConstants.usersCollection).doc(user.uid).get();
              return UserModel.fromMap(updatedDoc.data()!, user.uid);
            }
          } else {
            // Create user document if it doesn't exist
            final userModel = UserModel(
              id: user.uid,
              username: 'Admin Test',
              email: email,
              role: AppConstants.roleAdmin,
              createdAt: DateTime.now(),
              updatedAt: DateTime.now(),
            );
            
            await _firestore.collection(AppConstants.usersCollection).doc(user.uid).set(userModel.toMap());
            return userModel;
          }
        } catch (e) {
          print("Error with admin test account: $e");
          // Create admin test account if sign in fails
          return await signUpWithEmailAndPassword(
            email: email,
            password: password,
            username: 'Admin Test',
            role: AppConstants.roleAdmin,
          );
        }
      } else {
        // Regular sign in
        final UserCredential userCredential = await _auth.signInWithEmailAndPassword(
          email: email,
          password: password,
        );

        if (userCredential.user == null) {
          throw Exception('Failed to sign in');
        }

        final User user = userCredential.user!;

        // Get user from Firestore
        final DocumentSnapshot userDoc = await _firestore
            .collection(AppConstants.usersCollection)
            .doc(user.uid)
            .get();

        if (!userDoc.exists) {
          throw Exception('User data not found');
        }

        return UserModel.fromMap(userDoc.data() as Map<String, dynamic>, user.uid);
      }
    } on FirebaseAuthException catch (e) {
      if (e.code == 'user-not-found') {
        throw Exception('No user found for that email.');
      } else if (e.code == 'wrong-password') {
        throw Exception('Wrong password provided.');
      } else {
        throw Exception('Error during sign in: ${e.message}');
      }
    } catch (e) {
      throw Exception('Error during sign in: $e');
    }
  }

  // Sign out
  Future<void> signOut() async {
    try {
      await _auth.signOut();
    } catch (e) {
      throw Exception('Error during sign out: $e');
    }
  }

  // Get user data
  Future<UserModel?> getUserData(String userId) async {
      if (_auth.currentUser == null) {
    return null; // Don't try to access Firestore if not signed in
  }

    try {
      final DocumentSnapshot userDoc = await _firestore
          .collection(AppConstants.usersCollection)
          .doc(userId)
          .get();

      if (!userDoc.exists) {
        return null;
      }

      return UserModel.fromMap(userDoc.data() as Map<String, dynamic>, userId);
    } catch (e) {
        print('Error getting user data: $e');
    return null;
    }
  }

  // Update user data
  Future<void> updateUserData(UserModel userModel) async {
    try {
      await _firestore
          .collection(AppConstants.usersCollection)
          .doc(userModel.id)
          .update(userModel.toMap());
    } catch (e) {
      throw Exception('Error updating user data: $e');
    }
  }

  // Reset password
  Future<void> resetPassword(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } on FirebaseAuthException catch (e) {
      throw Exception('Error sending password reset email: ${e.message}');
    } catch (e) {
      throw Exception('Error sending password reset email: $e');
    }
  }
}