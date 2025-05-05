import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:uuid/uuid.dart';
import 'package:path/path.dart' as path;

class StorageService {
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final Uuid _uuid = const Uuid();

  // Upload user profile image with proper error handling
  Future<String> uploadProfileImage(File file, String userId) async {
    try {
      print("Starting profile image upload for userId: $userId");
      
      // Get file extension
      final String extension = path.extension(file.path);
      final String fileName = 'profile$extension';
      
      // Create reference - simplified path structure
      final Reference storageRef = _storage.ref('users/$userId/$fileName');
      
      // Check if file exists locally
      if (!await file.exists()) {
        throw Exception('Selected image file does not exist');
      }
      
      // Upload with metadata
      final UploadTask uploadTask = storageRef.putFile(
        file,
        SettableMetadata(
          contentType: 'image/${extension.replaceAll('.', '')}',
          customMetadata: {'userId': userId},
        ),
      );
      
      // Monitor upload progress (optional)
      uploadTask.snapshotEvents.listen((TaskSnapshot snapshot) {
        print('Upload progress: ${(snapshot.bytesTransferred / snapshot.totalBytes) * 100}%');
      }, onError: (e) {
        print("Upload monitoring error: $e");
      });
      
      // Wait for upload to complete
      final TaskSnapshot taskSnapshot = await uploadTask;
      
      // Get download URL
      final String downloadUrl = await taskSnapshot.ref.getDownloadURL();
      print("Profile image uploaded successfully: $downloadUrl");
      
      return downloadUrl;
    } catch (e) {
      print("Error in uploadProfileImage: $e");
      throw Exception('Error uploading profile image: $e');
    }
  }

  // Upload feedback image with proper error handling
  Future<String> uploadFeedbackImage(File file, String userId) async {
    try {
      print("Starting feedback image upload for userId: $userId");
      
      // Create a unique filename with extension
      final String extension = path.extension(file.path);
      final String imageId = _uuid.v4();
      final String fileName = '$imageId$extension';
      
      // Create reference - simplified path structure
      final Reference storageRef = _storage.ref('feedback/$userId/$fileName');
      
      // Check if file exists locally
      if (!await file.exists()) {
        throw Exception('Selected image file does not exist');
      }
      
      // Get file size for validation
      final fileSize = await file.length();
      if (fileSize > 5 * 1024 * 1024) {
        throw Exception('Image file is too large (max 5MB)');
      }
      
      // Upload with metadata
      final UploadTask uploadTask = storageRef.putFile(
        file,
        SettableMetadata(
          contentType: 'image/${extension.replaceAll('.', '')}',
          customMetadata: {
            'userId': userId,
            'uploadDate': DateTime.now().toIso8601String(),
          },
        ),
      );
      
      // Wait for upload to complete
      final TaskSnapshot taskSnapshot = await uploadTask;
      
      // Get download URL
      final String downloadUrl = await taskSnapshot.ref.getDownloadURL();
      print("Feedback image uploaded successfully: $downloadUrl");
      
      return downloadUrl;
    } catch (e) {
      print("Error in uploadFeedbackImage: $e");
      throw Exception('Error uploading feedback image: $e');
    }
  }

  // Delete image
  Future<void> deleteImage(String imageUrl) async {
    try {
      final Reference storageRef = _storage.refFromURL(imageUrl);
      await storageRef.delete();
      print("Image deleted successfully: $imageUrl");
    } catch (e) {
      print("Error deleting image: $e");
      throw Exception('Error deleting image: $e');
    }
  }
}