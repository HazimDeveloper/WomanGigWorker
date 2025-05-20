import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../models/feedback_model.dart';
import '../../config/constants.dart';
import '../../widgets/safety_rating.dart';

class AdminFeedbackDetailScreen extends StatelessWidget {
  final FeedbackModel feedback;

  const AdminFeedbackDetailScreen({
    Key? key,
    required this.feedback,
  }) : super(key: key);

  // Helper method to build image from base64 string
  Widget _buildImageContent() {
    // Check for base64 image first
    if (feedback.imageBase64 != null && feedback.imageBase64!.isNotEmpty) {
      try {
        // Convert base64 to image
        return Container(
          width: double.infinity,
          height: 200,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            image: DecorationImage(
              image: MemoryImage(base64Decode(feedback.imageBase64!)),
              fit: BoxFit.cover,
            ),
          ),
        );
      } catch (e) {
        print("Error decoding base64 image: $e");
        // Fallback to URL or placeholder if base64 fails
      }
    }
    
    // Check for URL image
    if (feedback.imageUrl != null && feedback.imageUrl!.isNotEmpty) {
      return Container(
        width: double.infinity,
        height: 200,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: CachedNetworkImage(
            imageUrl: feedback.imageUrl!,
            fit: BoxFit.cover,
            placeholder: (context, url) => const Center(
              child: CircularProgressIndicator(),
            ),
            errorWidget: (context, url, error) => Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error, color: Colors.red, size: 32),
                  const SizedBox(height: 8),
                  Text(
                    'Image failed to load',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                ],
              ),
            ),
            // Performance optimizations
            memCacheWidth: 800,
            memCacheHeight: 800,
            cacheKey: "${feedback.id}_feedback_image",
            fadeOutDuration: Duration.zero,
            fadeInDuration: const Duration(milliseconds: 300),
          ),
        ),
      );
    }

    // Fallback placeholder
    return Container(
      width: double.infinity,
      height: 200,
      decoration: BoxDecoration(
        color: Colors.grey.shade300,
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Center(
        child: Icon(
          Icons.image,
          size: 40,
          color: Colors.grey,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primary,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          feedback.username.toUpperCase(),
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // User Profile Picture (placeholder in this case)
              Center(
                child: CircleAvatar(
                  radius: 40,
                  backgroundColor: Colors.grey.shade300,
                  backgroundImage: feedback.userPhotoUrl != null
                      ? CachedNetworkImageProvider(
                          feedback.userPhotoUrl!,
                          cacheKey: "profile_${feedback.userId}",
                        )
                      : null,
                  child: feedback.userPhotoUrl == null
                      ? Text(
                          feedback.username.isNotEmpty
                              ? feedback.username[0].toUpperCase()
                              : '?',
                          style: const TextStyle(
                            fontSize: 30,
                            fontWeight: FontWeight.bold,
                            color: Colors.black54,
                          ),
                        )
                      : null,
                ),
              ),
              const SizedBox(height: 24),
              
              // Location Name
              Row(
                children: [
                  const Icon(Icons.location_on, size: 20, color: Colors.black),
                  const SizedBox(width: 8),
                  Text(
                    feedback.locationName.toUpperCase(),
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              
              // Safety Rating
              const Text(
                'SAFETY RATE',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
              const SizedBox(height: 8),
              SafetyRating(
                rating: feedback.safetyRating,
                allowUpdate: false,
                itemSize: 28,
              ),
              const SizedBox(height: 24),
              
              // Feedback Text
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  feedback.feedback.toUpperCase(),
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.black,
                  ),
                ),
              ),
              const SizedBox(height: 24),
              
              // Feedback Image
              _buildImageContent(),
                
              // Status badge for pending feedback
              if (feedback.status == AppConstants.feedbackStatusPending)
                Container(
                  margin: const EdgeInsets.only(top: 24),
                  padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                  decoration: BoxDecoration(
                    color: Colors.orange.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.orange),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: const [
                      Icon(Icons.warning_amber_rounded, color: Colors.orange),
                      SizedBox(width: 8),
                      Text(
                        'PENDING APPROVAL',
                        style: TextStyle(
                          color: Colors.orange,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}