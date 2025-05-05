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
                      ? CachedNetworkImageProvider(feedback.userPhotoUrl!)
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
              
              // Feedback Image (if available)
              if (feedback.imageUrl != null)
                Container(
                  width: double.infinity,
                  height: 200,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    image: DecorationImage(
                      image: CachedNetworkImageProvider(feedback.imageUrl!),
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                
              // Placeholder image for demo
              if (feedback.imageUrl == null)
                Container(
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
                ),
            ],
          ),
        ),
      ),
    );
  }
}