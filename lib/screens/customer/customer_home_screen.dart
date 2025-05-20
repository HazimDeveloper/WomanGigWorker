// lib/screens/customer/customer_home_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/location_provider.dart';
import '../../widgets/feedback_card.dart';
import '../../config/constants.dart';
import '../../models/feedback_model.dart';
import 'customer_map_screen.dart';
import 'customer_profile_screen.dart';

class CustomerHomeScreen extends StatefulWidget {
  static const String routeName = '/customer/home';

  const CustomerHomeScreen({Key? key}) : super(key: key);

  @override
  State<CustomerHomeScreen> createState() => _CustomerHomeScreenState();
}

class _CustomerHomeScreenState extends State<CustomerHomeScreen> {
  int _currentIndex = 0;
  final PageController _pageController = PageController();

  @override
  void initState() {
    super.initState();
    
    // Force data loading
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        final locationProvider = Provider.of<LocationProvider>(context, listen: false);
        // Clear existing data first
        locationProvider.clearData();
        // Then reload approved feedback only
        locationProvider.loadFeedback();
        locationProvider.loadLocations();
      }
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onPageChanged(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  void _onItemTapped(int index) {
    _pageController.jumpToPage(index);
  }

  Future<void> _handleLikeToggle(FeedbackModel feedback, bool isLiked) async {
    try {
      final userId = Provider.of<AuthProvider>(context, listen: false).user!.id;
      await Provider.of<LocationProvider>(context, listen: false).toggleLike(
        feedbackId: feedback.id,
        userId: userId,
      );
      
      // Show visual feedback
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(isLiked ? 'Liked!' : 'Unliked'),
            duration: const Duration(seconds: 1),
            backgroundColor: isLiked ? Colors.pink : Colors.grey,
          ),
        );
      }
    } catch (e) {
      print("Error toggling like: $e");
      // Show error message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showCommentDialog(FeedbackModel feedback) {
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
                  final userId = Provider.of<AuthProvider>(context, listen: false).user!;
                  await Provider.of<LocationProvider>(context, listen: false).addComment(
                    feedbackId: feedback.id,
                    user: userId,
                    comment: commentController.text.trim(),
                  );
                  Navigator.of(context).pop();
                  
                  // Show success message
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Comment added successfully'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  }
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
  
  // Add method to view all comments for a feedback item
  void _viewAllComments(FeedbackModel feedback) {
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
  }

  @override
  Widget build(BuildContext context) {
    final user = Provider.of<AuthProvider>(context).user;
    
    if (user == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.pushReplacementNamed(context, '/login');
      });
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    
    // Determine if user is a worker for styling
    final bool isWorker = user.role == AppConstants.roleWorker;

    return Scaffold(
      backgroundColor: AppColors.primary,
      body: PageView(
        controller: _pageController,
        onPageChanged: _onPageChanged,
        // Remove the swipe gesture if needed
        physics: const ClampingScrollPhysics(),
        children: [
          // Home Feed Page
          _buildHomeFeed(isWorker),
          
          // Map Page
          const CustomerMapScreen(),
          
          // Profile Page - remove the upload page
          const CustomerProfileScreen(),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: _onItemTapped,
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.white,
        selectedItemColor: Colors.teal, // Worker color
        unselectedItemColor: Colors.grey,
        showSelectedLabels: false,
        showUnselectedLabels: false,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.map),
            label: 'Map',
          ),
          // No upload tab for workers
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }

  Widget _buildHomeFeed(bool isWorker) {
    return SafeArea(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: Row(
              children: [
                const Text(
                  'Trust.ME',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.notifications_none),
                  onPressed: () {
                    // TODO: Implement notifications
                  },
                ),
              ],
            ),
          ),
          
          // Welcome message for all users
          Container(
            margin: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.teal.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.teal),
            ),
            child: Row(
              children: const [
                Icon(
                  Icons.info_outline,
                  color: Colors.teal,
                ),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'You can view, like, and comment on all safety information to help other women',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.black87,
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          // Feedback List with optimized rebuild strategy
          Expanded(
            child: RefreshIndicator(
              onRefresh: () async {
                 Provider.of<LocationProvider>(context, listen: false).loadFeedback();
              },
              child: Consumer<LocationProvider>(
                builder: (context, locationProvider, _) {
                  final feedback = locationProvider.feedback;
                  final isLoading = locationProvider.isLoading;
                  
                  if (isLoading && feedback.isEmpty) {
                    return const Center(
                      child: CircularProgressIndicator(),
                    );
                  }
                  
                  if (feedback.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: const [
                          Icon(
                            Icons.feedback_outlined,
                            size: 64,
                            color: Colors.grey,
                          ),
                          SizedBox(height: 16),
                          Text(
                            'No feedback available yet',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.black54,
                            ),
                          ),
                          SizedBox(height: 8),
                          Text(
                            'Pull down to refresh',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    );
                  }
                  
                  return ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: feedback.length,
                    itemBuilder: (context, index) {
                      final userId = Provider.of<AuthProvider>(context).user!.id;
                      return FeedbackCard(
                        feedback: feedback[index],
                        currentUserId: userId,
                        onTap: () {
                          // View feedback details (optional enhancement)
                          if (feedback[index].comments.isNotEmpty) {
                            _viewAllComments(feedback[index]);
                          }
                        },
                        onLikeToggle: (isLiked) {
                          _handleLikeToggle(feedback[index], isLiked);
                        },
                        onAddComment: () {
                          _showCommentDialog(feedback[index]);
                        },
                      );
                    },
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}