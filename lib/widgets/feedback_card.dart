import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart';
import '../models/feedback_model.dart';
import '../config/constants.dart';
import 'safety_rating.dart';

class FeedbackCard extends StatelessWidget {
  final FeedbackModel feedback;
  final String currentUserId;
  final VoidCallback? onTap;
  final Function(bool isLiked)? onLikeToggle;
  final VoidCallback? onAddComment;

  const FeedbackCard({
    Key? key,
    required this.feedback,
    required this.currentUserId,
    this.onTap,
    this.onLikeToggle,
    this.onAddComment,
  }) : super(key: key);

Widget _buildBase64Image(String base64String) {
  // Use a static cache for decoded images
  final Map<String, Uint8List> _decodedImageCache = {};
  
  // Generate a short hash of the base64 string as the cache key
  final String cacheKey = base64String.length.toString() + 
                         base64String.substring(0, 10) + 
                         base64String.substring(base64String.length - 10);
  
  // Check if we already decoded this image
  if (!_decodedImageCache.containsKey(cacheKey)) {
    try {
      // Decode only if not in cache
      _decodedImageCache[cacheKey] = base64Decode(base64String);
    } catch (e) {
      print("Error decoding base64 image: $e");
      return const Center(
        child: Icon(Icons.broken_image, color: Colors.red, size: 40)
      );
    }
  }
  
  // Use the cached decoded data
  return Image.memory(
    _decodedImageCache[cacheKey]!,
    fit: BoxFit.cover,
    gaplessPlayback: true, // Important to prevent flicker
  );
}

  @override
  Widget build(BuildContext context) {
    final bool isLiked = feedback.likedBy.contains(currentUserId);
    final DateFormat formatter = DateFormat('MMM dd, yyyy • h:mm a');
    final String formattedDate = formatter.format(feedback.createdAt);

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 0),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      color: AppColors.cardBg,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Row(
                children: [
                  // User avatar
                  CircleAvatar(
                    radius: 20,
                    backgroundColor: Colors.grey.shade200,
                    backgroundImage: feedback.userPhotoUrl != null
                        ? CachedNetworkImageProvider(feedback.userPhotoUrl!)
                        : null,
                    child: feedback.userPhotoUrl == null
                        ? Text(
                            feedback.username.isNotEmpty
                                ? feedback.username[0].toUpperCase()
                                : '?',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.black54,
                            ),
                          )
                        : null,
                  ),
                  const SizedBox(width: 12),
                  // User info and date
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          feedback.username,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        Text(
                          formattedDate,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.white.withOpacity(0.7),
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Location information
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Row(
                        children: [
                          const Icon(
                            Icons.location_on,
                            size: 16,
                            color: Colors.white70,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            feedback.locationName,
                            style: const TextStyle(
                              fontSize: 14,
                              color: Colors.white,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      SafetyRating(
                        rating: feedback.safetyRating,
                        allowUpdate: false,
                        itemSize: 16,
                        activeColor: Colors.amber,
                        inactiveColor: Colors.white24,
                      ),
                    ],
                  ),
                ],
              ),
            ),
            
            // Feedback content
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
              child: Text(
                feedback.feedback,
                style: const TextStyle(
                  fontSize: 16,
                  color: Colors.white,
                ),
              ),
            ),
            
 if (feedback.imageBase64 != null && feedback.imageBase64!.isNotEmpty)
  Container(
    width: double.infinity,
    constraints: const BoxConstraints(
      maxHeight: 250,
    ),
    child: _buildBase64Image(feedback.imageBase64!),
  )
else if (feedback.imageUrl != null)
  Container(
    width: double.infinity,
    constraints: const BoxConstraints(
      maxHeight: 250,
    ),
    child: CachedNetworkImage(
      imageUrl: feedback.imageUrl!,
      fit: BoxFit.cover,
      placeholder: (context, url) => const Center(
        child: SizedBox(
          height: 30,
          width: 30,
          child: CircularProgressIndicator(),
        ),
      ),
      errorWidget: (context, url, error) => const Icon(
        Icons.error,
        color: Colors.red,
      ),
       memCacheWidth: 800, // Limit memory cache size
  memCacheHeight: 800,
  cacheKey: "${feedback.id}_image", // Use a stable cache key
  fadeOutDuration: Duration.zero, // Remove fade animations that might cause flicker
  fadeInDuration: const Duration(milliseconds: 300),
    ),
  ),
            
            // Actions
            Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  // Like button
                  InkWell(
                    onTap: () => onLikeToggle?.call(!isLiked),
                    child: Row(
                      children: [
                        Icon(
                          isLiked ? Icons.favorite : Icons.favorite_border,
                          color: isLiked ? Colors.red : Colors.white,
                          size: 20,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          feedback.likedBy.length.toString(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  // Comment button
                  InkWell(
                    onTap: onAddComment,
                    child: Row(
                      children: [
                        const Icon(
                          Icons.comment_outlined,
                          color: Colors.white,
                          size: 20,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          feedback.comments.length.toString(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            
            // Comments preview (show only last comment if any)
            if (feedback.comments.isNotEmpty)
              Container(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Divider(
                      color: Colors.white24,
                      height: 16,
                    ),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        CircleAvatar(
                          radius: 12,
                          backgroundColor: Colors.grey.shade200,
                          backgroundImage: feedback.comments.last.userPhotoUrl != null
                              ? CachedNetworkImageProvider(feedback.comments.last.userPhotoUrl!)
                              : null,
                          child: feedback.comments.last.userPhotoUrl == null
                              ? Text(
                                  feedback.comments.last.username.isNotEmpty
                                      ? feedback.comments.last.username[0].toUpperCase()
                                      : '?',
                                  style: const TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black54,
                                  ),
                                )
                              : null,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: RichText(
                            text: TextSpan(
                              children: [
                                TextSpan(
                                  text: feedback.comments.last.username,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                                const TextSpan(text: ' '),
                                TextSpan(
                                  text: feedback.comments.last.text,
                                  style: const TextStyle(
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (feedback.comments.length > 1)
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Text(
                          'View all ${feedback.comments.length} comments',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.white.withOpacity(0.7),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  
}