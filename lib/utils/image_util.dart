// lib/utils/image_util.dart

import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image/image.dart' as img;

class ImageUtil {

static Future<String?> isolatedFileToBase64(String filePath) async {
  try {
    // Create file from path
    final file = File(filePath);
    if (!await file.exists()) {
      return null;
    }
    
    // Read file bytes
    final bytes = await file.readAsBytes();
    
    // Process the image to reduce size
    final image = img.decodeImage(bytes);
    if (image == null) return null;
    
    // Calculate new dimensions (max 800px width)
    int targetWidth = 800;
    int targetHeight = (image.height * targetWidth / image.width).round();
    
    // Resize
    final resized = img.copyResize(
      image,
      width: targetWidth,
      height: targetHeight,
    );
    
    // Compress to jpg
    final compressed = img.encodeJpg(resized, quality: 70);
    
    // Convert to base64
    final base64String = base64Encode(compressed);
    return base64String;
  } catch (e) {
    print('Error in isolatedFileToBase64: $e');
    return null;
  }
}

 // In image_util.dart - enhance the fileToBase64 method
static Future<String?> fileToBase64(File file) async {
  try {
    // Check file size before processing
    final int fileSize = await file.length();
    if (fileSize > 5 * 1024 * 1024) {
      print('File too large: ${fileSize / 1024 / 1024} MB');
      // Implement more aggressive compression for large files
    }
    
    // Read the file as bytes
    final bytes = await file.readAsBytes();
    
    // More robust image decoding with error handling
    final image = img.decodeImage(bytes);
    if (image == null) {
      print('Failed to decode image');
      return null;
    }
    
    // Resize to a smaller size (reducing from 500 to 300)
    final resized = img.copyResize(
      image, 
      width: 300,
      maintainAspect: true,
    );
    
    // Use higher compression (reduce quality from 70 to 50)
    final compressed = img.encodeJpg(resized, quality: 50);
    
    // Convert to base64
    final base64String = base64Encode(compressed);
    print('Successful base64 conversion: ${base64String.length} chars');
    return base64String;
  } catch (e) {
    print('Error converting image to base64: $e');
    return null;
  }
}
  static Future<String?> compressMoreAggressively(File file) async {
  try {
    final bytes = await file.readAsBytes();
    final image = img.decodeImage(bytes);
    if (image == null) return null;
    
    // Very small size and high compression
    final resized = img.copyResize(
      image, 
      width: 200,
    );
    
    // Much higher compression
    final compressed = img.encodeJpg(resized, quality: 30);
    
    return base64Encode(compressed);
  } catch (e) {
    print('Error in aggressive compression: $e');
    return null;
  }
}
  // Convert base64 to Image widget
  static Image base64ToImage(String base64String) {
    return Image.memory(
      base64Decode(base64String),
      fit: BoxFit.cover,
    );
  }
  
  // Pick image and convert to base64
  static Future<String?> pickImageAsBase64() async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? pickedFile = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 70,
      );
      
      if (pickedFile == null) return null;
      
      final file = File(pickedFile.path);
      return await fileToBase64(file);
    } catch (e) {
      print('Error picking image: $e');
      return null;
    }
  }
}