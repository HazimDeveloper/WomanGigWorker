// Create this as lib/utils/emergency_upload.dart

import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image/image.dart' as img;
import 'package:uuid/uuid.dart';
import 'package:path_provider/path_provider.dart';

class EmergencyUpload {
  static Future<String?> uploadAnyImage(File imageFile, String userId) async {
    try {
      // Create minimal image (very small)
      final bytes = await imageFile.readAsBytes();
      final image = img.decodeImage(bytes);
      
      if (image == null) {
        print("Failed to decode image");
        return null;
      }
      
      // Extreme resize - make it very small
      final smallImage = img.copyResize(image, width: 100);
      final jpg = img.encodeJpg(smallImage, quality: 10);
      
      // Save to a temporary file
      final tempDir = await getTemporaryDirectory();
      final tempFile = File('${tempDir.path}/${Uuid().v4()}.jpg');
      await tempFile.writeAsBytes(jpg);
      
      // Upload directly to Firebase with minimal settings
      final storageRef = FirebaseStorage.instance
          .ref()
          .child('emergency_uploads')
          .child(userId)
          .child('${DateTime.now().millisecondsSinceEpoch}.jpg');
      
      // Set minimal metadata and retry settings
      final SettableMetadata metadata = SettableMetadata(
        contentType: 'image/jpeg',
        customMetadata: {'userId': userId},
      );
      
      // Set minimal timeout
      final uploadTask = storageRef.putFile(tempFile, metadata);
      
      // Monitor progress
      uploadTask.snapshotEvents.listen((event) {
        print('Emergency upload progress: ${event.bytesTransferred}/${event.totalBytes}');
      });
      
      // Wait for completion
      final snapshot = await uploadTask;
      final downloadUrl = await snapshot.ref.getDownloadURL();
      
      // Clean up
      await tempFile.delete();
      
      return downloadUrl;
    } catch (e) {
      print("Emergency upload failed: $e");
      return null;
    }
  }
  
  static Future<bool> tryEmergencyUpload(
      BuildContext context, File imageFile, String userId) async {
    try {
      // Show progress dialog
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          title: Text("Emergency Upload"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text("Trying emergency upload method..."),
            ],
          ),
        ),
      );
      
      // Try upload
      final url = await uploadAnyImage(imageFile, userId);
      
      // Close dialog
      Navigator.of(context, rootNavigator: true).pop();
      
      if (url != null) {
        // Show success
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text("Emergency upload successful!"),
          backgroundColor: Colors.green,
        ));
        return true;
      } else {
        // Show failure
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text("Emergency upload failed. Please try a different image."),
          backgroundColor: Colors.red,
        ));
        return false;
      }
    } catch (e) {
      // Close dialog and show error
      Navigator.of(context, rootNavigator: true).pop();
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text("Error: ${e.toString()}"),
        backgroundColor: Colors.red,
      ));
      return false;
    }
  }
}