// Create a new file: lib/services/alternative_upload_service.dart

import 'dart:io';
import 'dart:typed_data';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart'; // Add this package
import 'package:uuid/uuid.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart' as path_provider; // Add this package

class AlternativeUploadService {
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final Uuid _uuid = const Uuid();

  // Method 1: Direct Firebase upload with multiple attempts and resize
  Future<String?> uploadImageToFirebaseWithRetry(File file, String userId) async {
    try {
      print("Starting direct Firebase upload for userId: $userId");
      
      // Create a unique ID for the file
      final String imageId = _uuid.v4();
      final String extension = path.extension(file.path);
      final String fileName = '$imageId$extension';
      
      // Reference to Firebase Storage
      final Reference storageRef = _storage.ref('feedback/$userId/$fileName');
      
      // Try with original file first
      try {
        final UploadTask uploadTask = storageRef.putFile(file);
        final TaskSnapshot snapshot = await uploadTask;
        return await snapshot.ref.getDownloadURL();
      } catch (e) {
        print("Initial upload failed, trying with compressed image: $e");
      }
      
      // If original upload fails, try with compressed image
      final Uint8List? compressedData = await _compressImage(file);
      if (compressedData == null) {
        throw Exception("Failed to compress image");
      }
      
      final UploadTask compressedUploadTask = storageRef.putData(compressedData);
      final TaskSnapshot compressedSnapshot = await compressedUploadTask;
      return await compressedSnapshot.ref.getDownloadURL();
    } catch (e) {
      print("All upload attempts failed: $e");
      return null;
    }
  }
  
  // Method 2: Compression utility that uses a different library
  Future<Uint8List?> _compressImage(File file) async {
    try {
      // Get file size
      final int originalSize = await file.length();
      print("Original file size: ${originalSize / 1024} KB");
      
      // Compress with flutter_image_compress 
      final result = await FlutterImageCompress.compressWithFile(
        file.absolute.path,
        minWidth: 500,
        minHeight: 500,
        quality: 70,
      );
      
      if (result != null) {
        print("Compressed file size: ${result.length / 1024} KB");
      }
      
      return result;
    } catch (e) {
      print("Compression error: $e");
      return null;
    }
  }
  
  // Method 3: Save to temporary file then upload
  Future<String?> uploadViaTempFile(File file, String userId) async {
    try {
      // Get temporary directory
      final tempDir = await path_provider.getTemporaryDirectory();
      final String tempPath = tempDir.path;
      final String targetPath = '$tempPath/${_uuid.v4()}.jpg';
      
      // Compress to temporary file
      final File? compressedFile = (await FlutterImageCompress.compressAndGetFile(
        file.absolute.path,
        targetPath,
        quality: 50,
        minWidth: 400,
        minHeight: 400,
      )) as File?;
      
      if (compressedFile == null) {
        throw Exception("Failed to create compressed file");
      }
      
      // Upload the temporary file
      final String imageId = _uuid.v4();
      final Reference storageRef = _storage.ref('feedback/$userId/$imageId.jpg');
      final UploadTask uploadTask = storageRef.putFile(compressedFile);
      final TaskSnapshot snapshot = await uploadTask;
      
      // Clean up the temporary file
      await compressedFile.delete();
      
      return await snapshot.ref.getDownloadURL();
    } catch (e) {
      print("Temp file upload error: $e");
      return null;
    }
  }
}