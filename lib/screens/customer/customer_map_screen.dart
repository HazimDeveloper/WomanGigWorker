import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';
import 'package:trust_me/providers/auth_provider.dart';
import 'package:trust_me/services/location_service.dart';
import 'package:trust_me/widgets/map_legend.dart';
import '../../providers/location_provider.dart';
import '../../widgets/location_search.dart';
import '../../widgets/risk_map.dart';
import '../../config/constants.dart';
import '../../models/location_model.dart';
import '../../models/feedback_model.dart';
import '../../models/comment_model.dart';
import 'package:uuid/uuid.dart';

class CustomerMapScreen extends StatefulWidget {
  static const String routeName = '/customer/map';

  const CustomerMapScreen({Key? key}) : super(key: key);

  @override
  State<CustomerMapScreen> createState() => _CustomerMapScreenState();
}

class _CustomerMapScreenState extends State<CustomerMapScreen> {
  final GlobalKey<RiskMapState> _mapKey = GlobalKey<RiskMapState>();
  final Uuid _uuid = const Uuid();
  
  List<LocationModel> _searchResults = [];
  bool _isLoading = false;
  bool _showSearch = false;
  bool _isInSelectionMode = false;
  LatLng? _selectedPosition;
  TextEditingController _locationNameController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadLocations();
  }

  @override
  void dispose() {
    _locationNameController.dispose();
    super.dispose();
  }

  void _loadLocations() {
    final locationProvider = Provider.of<LocationProvider>(context, listen: false);
    locationProvider.loadLocations();
    locationProvider.getCurrentLocation();
  }

  Future<void> _searchLocations(String query) async {
    if (query.isEmpty) {
      setState(() {
        _searchResults = [];
      });
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final locationProvider = Provider.of<LocationProvider>(context, listen: false);
      
      // Use searchLocationsWithFeedback to find locations with existing feedback
      final results = await locationProvider.searchLocationsWithFeedback(query);
      
      setState(() {
        _searchResults = results;
        _isLoading = false;
      });
      
      // Show message if no results
      if (results.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No locations with Safety Information found matching your search'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      print("Search error: $e");
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _handleLocationSelected(LocationModel location) {
    final position = LatLng(location.latitude, location.longitude);
    _mapKey.currentState?.animateToPosition(position);
    
    // Show location details bottom sheet
    _showLocationDetailsBottomSheet(location);
  }

  // Method for toggling likes on feedback
  Future<void> _handleLikeToggle(String feedbackId, bool isLiked) async {
    final userId = Provider.of<AuthProvider>(context, listen: false).user!.id;
    await Provider.of<LocationProvider>(context, listen: false).toggleLike(
      feedbackId: feedbackId,
      userId: userId,
    );
  }

  // Method for adding comments to feedback
  void _showCommentDialog(String feedbackId) {
    final TextEditingController commentController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Comment'),
        content: TextField(
          controller: commentController,
          decoration: const InputDecoration(
            hintText: 'Write your comment...',
          ),
          maxLines: 3,
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: const Text('CANCEL'),
          ),
          TextButton(
            onPressed: () async {
              if (commentController.text.trim().isNotEmpty) {
                try {
                  final user = Provider.of<AuthProvider>(context, listen: false).user!;
                  await Provider.of<LocationProvider>(context, listen: false).addComment(
                    feedbackId: feedbackId,
                    user: user,
                    comment: commentController.text.trim(),
                  );
                  Navigator.of(context).pop();
                  
                  // Show success message
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Comment added successfully'),
                      backgroundColor: Colors.green,
                    ),
                  );
                } catch (e) {
                  print("Error adding comment: $e");
                  // Show error message
                  Navigator.of(context).pop();
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Error: ${e.toString()}'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                }
              } else {
                // Show validation error
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Please enter a comment'),
                    backgroundColor: Colors.orange,
                  ),
                );
              }
            },
            child: const Text('POST'),
          ),
        ],
      ),
    );
  }

  void _showLocationDetailsBottomSheet(LocationModel location) {
    // Get user for role-based colors
    final user = Provider.of<AuthProvider>(context, listen: false).user!;
    final backgroundColor = AppColors.getBackgroundForRole(user.role);
    final secondaryColor = AppColors.getSecondaryForRole(user.role);
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true, // Allow for larger sheet
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        // Get location safety information
        final locationProvider = Provider.of<LocationProvider>(context, listen: false);
        final feedbackList = locationProvider.getFeedbackForLocation(location.id);
        final userId = Provider.of<AuthProvider>(context, listen: false).user!.id;
        
        Color statusColor;
        switch (location.safetyLevel) {
          case AppConstants.safeLevelSafe:
            statusColor = AppColors.safeGreen;
            break;
          case AppConstants.safeLevelModerate:
            statusColor = AppColors.moderateYellow;
            break;
          case AppConstants.safeLevelHighRisk:
            statusColor = AppColors.highRiskRed;
            break;
          default:
            statusColor = Colors.grey;
        }

        return DraggableScrollableSheet(
          initialChildSize: 0.6,
          minChildSize: 0.3,
          maxChildSize: 0.9,
          expand: false,
          builder: (context, scrollController) {
            return Container(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              color: Colors.white,
              child: ListView(
                controller: scrollController,
                children: [
                  // Handle for draggable sheet
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // Location name and safety rating
                  Row(
                    children: [
                      Icon(
                        Icons.location_on,
                        color: statusColor,
                        size: 24,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          location.name,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  
                  // Rating information
                  Row(
                    children: [
                      Icon(
                        Icons.star,
                        color: Colors.amber,
                        size: 20,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${location.averageSafetyRating.toStringAsFixed(1)} (${location.ratingCount} ${location.ratingCount == 1 ? 'review' : 'reviews'})',
                        style: const TextStyle(
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  
                  // Feedback list header
                  Row(
                    children: [
                      const Text(
                        'SAFETY INFORMATION',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: statusColor.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: statusColor),
                        ),
                        child: Text(
                          location.safetyLevel.replaceAll('_', ' ').toUpperCase(),
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: statusColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Divider(),
                  
                  // Feedback list
                  if (feedbackList.isEmpty)
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24.0),
                        child: Column(
                          children: const [
                            Icon(Icons.info_outline, size: 48, color: Colors.grey),
                            SizedBox(height: 16),
                            Text(
                              'No detailed safety information available for this location yet.',
                              textAlign: TextAlign.center,
                              style: TextStyle(color: Colors.grey),
                            ),
                          ],
                        ),
                      ),
                    )
                  else
                    ...feedbackList.map((feedback) {
                      // Calculate if the current user has liked this feedback
                      final bool isLiked = feedback.likedBy.contains(userId);
                      
                      return Card(
                        margin: const EdgeInsets.only(bottom: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(12.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // User info and rating
                              Row(
                                children: [
                                  CircleAvatar(
                                    radius: 16,
                                    backgroundColor: Colors.grey.shade300,
                                    child: Text(
                                      feedback.username.isNotEmpty ? feedback.username[0].toUpperCase() : '?',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: Colors.black54,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Text(
                                              feedback.username,
                                              style: const TextStyle(
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                              decoration: BoxDecoration(
                                                color: feedback.userRole == AppConstants.roleBuddy 
                                                    ? Colors.purple.withOpacity(0.2)
                                                    : secondaryColor.withOpacity(0.2),
                                                borderRadius: BorderRadius.circular(8),
                                              ),
                                              child: Text(
                                                feedback.userRole == AppConstants.roleBuddy ? 'Buddy' : 'User',
                                                style: TextStyle(
                                                  fontSize: 10,
                                                  fontWeight: FontWeight.bold,
                                                  color: feedback.userRole == AppConstants.roleBuddy 
                                                      ? Colors.purple
                                                      : secondaryColor,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 4),
                                        Row(
                                          children: [
                                            ...List.generate(
                                              5,
                                              (index) => Icon(
                                                index < feedback.safetyRating.floor()
                                                    ? Icons.star
                                                    : (index < feedback.safetyRating)
                                                        ? Icons.star_half
                                                        : Icons.star_border,
                                                color: Colors.amber,
                                                size: 14,
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            Text(
                                              feedback.safetyRating.toStringAsFixed(1),
                                              style: const TextStyle(
                                                fontSize: 12,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                  // Date
                                  Text(
                                    _formatDate(feedback.createdAt),
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              
                              // Feedback text
                              Text(
                                feedback.feedback,
                                style: const TextStyle(fontSize: 14),
                              ),
                              
                              // Show image if available
                              if (feedback.imageBase64 != null && feedback.imageBase64!.isNotEmpty) ...[
                                const SizedBox(height: 12),
                                Container(
                                  width: double.infinity,
                                  height: 120,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(8),
                                    image: DecorationImage(
                                      image: MemoryImage(
                                        base64Decode(feedback.imageBase64!)
                                      ),
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                ),
                              ],
                              
                              const SizedBox(height: 12),
                              
                              // Like and comment actions
                              Row(
                                children: [
                                  // Like button
                                  InkWell(
                                    onTap: () => _handleLikeToggle(feedback.id, !isLiked),
                                    borderRadius: BorderRadius.circular(20),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                      decoration: BoxDecoration(
                                        color: isLiked ? Colors.red.withOpacity(0.1) : Colors.grey.withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(
                                            isLiked ? Icons.favorite : Icons.favorite_border,
                                            color: isLiked ? Colors.red : Colors.grey,
                                            size: 18,
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            '${feedback.likedBy.length}',
                                            style: TextStyle(
                                              color: isLiked ? Colors.red : Colors.grey,
                                              fontSize: 14,
                                              fontWeight: isLiked ? FontWeight.bold : FontWeight.normal,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  
                                  // Comment button
                                  InkWell(
                                    onTap: () => _showCommentDialog(feedback.id),
                                    borderRadius: BorderRadius.circular(20),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                      decoration: BoxDecoration(
                                        color: Colors.grey.withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          const Icon(
                                            Icons.comment_outlined,
                                            color: Colors.grey,
                                            size: 18,
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            '${feedback.comments.length}',
                                            style: const TextStyle(
                                              color: Colors.grey,
                                              fontSize: 14,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              
                              // Show comments if any
                              if (feedback.comments.isNotEmpty) ...[
                                const SizedBox(height: 12),
                                const Divider(),
                                const SizedBox(height: 8),
                                ...feedback.comments.take(2).map((comment) => Padding(
                                  padding: const EdgeInsets.only(bottom: 8),
                                  child: Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      CircleAvatar(
                                        radius: 12,
                                        backgroundColor: Colors.grey.shade200,
                                        child: Text(
                                          comment.username.isNotEmpty ? comment.username[0].toUpperCase() : '?',
                                          style: const TextStyle(
                                            fontSize: 10,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.black54,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              comment.username,
                                              style: const TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 12,
                                              ),
                                            ),
                                            Text(
                                              comment.text,
                                              style: const TextStyle(fontSize: 12),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                )),
                                
                                // Show "View more comments" if there are more than 2
                                if (feedback.comments.length > 2)
                                  TextButton(
                                    onPressed: () {
                                      // Show all comments in a dialog
                                      showDialog(
                                        context: context,
                                        builder: (context) => AlertDialog(
                                          title: Text('${feedback.comments.length} Comments'),
                                          content: Container(
                                            width: double.maxFinite,
                                            height: 300,
                                            child: ListView.builder(
                                              itemCount: feedback.comments.length,
                                              itemBuilder: (context, index) {
                                                final comment = feedback.comments[index];
                                                return ListTile(
                                                  leading: CircleAvatar(
                                                    radius: 12,
                                                    backgroundColor: Colors.grey.shade200,
                                                    child: Text(
                                                      comment.username.isNotEmpty ? comment.username[0].toUpperCase() : '?',
                                                      style: const TextStyle(
                                                        fontSize: 10,
                                                        fontWeight: FontWeight.bold,
                                                        color: Colors.black54,
                                                      ),
                                                    ),
                                                  ),
                                                  title: Text(
                                                    comment.username,
                                                    style: const TextStyle(
                                                      fontWeight: FontWeight.bold,
                                                      fontSize: 14,
                                                    ),
                                                  ),
                                                  subtitle: Text(comment.text),
                                                );
                                              },
                                            ),
                                          ),
                                          actions: [
                                            TextButton(
                                              onPressed: () => Navigator.pop(context),
                                              child: const Text('CLOSE'),
                                            ),
                                          ],
                                        ),
                                      );
                                    },
                                    child: Text(
                                      'View all ${feedback.comments.length} comments',
                                      style: TextStyle(color: secondaryColor, fontSize: 12),
                                    ),
                                  ),
                              ],
                            ],
                          ),
                        ),
                      );
                    }),
                ],
              ),
            );
          },
        );
      },
    );
  }

  // Format date for display
  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);
    
    if (difference.inDays == 0) {
      return 'Today';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return '${date.day}/${date.month}';
    }
  }

  // Add map tap handling - DISABLE FOR CUSTOMERS
  void _handleMapTapped(LatLng position) {
    // For customers, we don't allow adding locations, so this is disabled
    // This maintains view-only functionality for customer/worker users
  }

  @override
  Widget build(BuildContext context) {
    // Get user for role-based colors
    final user = Provider.of<AuthProvider>(context, listen: false).user;
    final backgroundColor = user != null ? AppColors.getBackgroundForRole(user.role) : AppColors.background;
    final secondaryColor = user != null ? AppColors.getSecondaryForRole(user.role) : AppColors.secondary;
    
    return Scaffold(
      backgroundColor: backgroundColor, // Use role-based background
      body: Consumer<LocationProvider>(
        builder: (context, locationProvider, _) {
          final currentPosition = locationProvider.currentPosition;
          final locations = locationProvider.locations;
          final isLoading = locationProvider.isLoading;

          return Stack(
            children: [
              // Map
              if (isLoading && currentPosition == null)
                const Center(
                  child: CircularProgressIndicator(),
                )
              else
                RiskMap(
                  key: _mapKey,
                  locations: locations,
                  initialPosition: currentPosition != null
                      ? LatLng(currentPosition.latitude, currentPosition.longitude)
                      : null,
                  onLocationSelected: _handleLocationSelected,
                  onMapTapped: _handleMapTapped, // View-only for customers
                ),

              // Search Bar
              Positioned(
                top: MediaQuery.of(context).padding.top + 16,
                left: 16,
                right: 16,
                child: GestureDetector(
                  onTap: () {
                    setState(() {
                      _showSearch = true;
                    });
                  },
                  child: Container(
                    height: 50,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.search, color: secondaryColor),
                        const SizedBox(width: 8),
                        const Text(
                          'Search location...',
                          style: TextStyle(
                            color: Colors.grey,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // Map Legend
              const Positioned(
                bottom: 16,
                right: 16,
                child: MapLegend(),
              ),
              
              // User type indicator (top right)
              if (user != null)
                Positioned(
                  top: MediaQuery.of(context).padding.top + 80,
                  right: 16,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: secondaryColor.withOpacity(0.9),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          user.role == AppConstants.roleWorker ? Icons.work : Icons.person,
                          color: Colors.white,
                          size: 14,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          user.role == AppConstants.roleWorker ? 'Gig Worker' : 'Gig Worker',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

              // Search Panel (fullscreen when active)
              if (_showSearch)
                Positioned.fill(
                  child: Container(
                    color: Colors.white,
                    child: Column(
                      children: [
                        AppBar(
                          backgroundColor: Colors.white,
                          elevation: 0,
                          leading: IconButton(
                            icon: const Icon(Icons.arrow_back, color: Colors.black),
                            onPressed: () {
                              setState(() {
                                _showSearch = false;
                                _searchResults = [];
                              });
                            },
                          ),
                          title: const Text(
                            'Search Location',
                            style: TextStyle(
                              color: Colors.black,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        Expanded(
                          child: LocationSearch(
                            onSearch: _searchLocations,
                            onLocationSelected: (location) {
                              setState(() {
                                _showSearch = false;
                              });
                              _handleLocationSelected(location);
                            },
                            searchResults: _searchResults,
                            isLoading: _isLoading,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                
              // Loading indicator
              if (_isLoading)
                Container(
                  color: Colors.black.withOpacity(0.3),
                  child: const Center(
                    child: CircularProgressIndicator(),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}