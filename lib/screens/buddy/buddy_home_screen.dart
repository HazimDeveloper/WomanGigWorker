
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:trust_me/screens/common/login_screen.dart';
import '../../providers/auth_provider.dart';
import '../../providers/location_provider.dart';
import '../../widgets/feedback_card.dart';
import '../../models/feedback_model.dart';
import '../../config/constants.dart';
import 'buddy_map_screen.dart';
import 'buddy_profile_screen.dart';
import '../../screens/customer/customer_upload_screen.dart'; // Import the upload screen

class BuddyHomeScreen extends StatefulWidget {
  static const String routeName = '/buddy/home';

  const BuddyHomeScreen({Key? key}) : super(key: key);

  @override
  State<BuddyHomeScreen> createState() => _BuddyHomeScreenState();
}

class _BuddyHomeScreenState extends State<BuddyHomeScreen> {
  int _currentIndex = 0;
  final PageController _pageController = PageController();
  bool _showApprovedFeedback = true; // Toggle between approved and pending

  @override
  void initState() {
    super.initState();
    // Initialize image cache with higher limits for better performance
    PaintingBinding.instance.imageCache.maximumSize = 200;
    PaintingBinding.instance.imageCache.maximumSizeBytes = 100 << 20; // 100 MB
    
    // Initial data load
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        final locationProvider = Provider.of<LocationProvider>(context, listen: false);
        // Clear existing data first
        locationProvider.clearData();
        // Load both approved and pending feedback
        locationProvider.loadFeedback();
        locationProvider.loadPendingFeedback();
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
    final userId = Provider.of<AuthProvider>(context, listen: false).user!.id;
    await Provider.of<LocationProvider>(context, listen: false).toggleLike(
      feedbackId: feedback.id,
      userId: userId,
    );
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
                final userId = Provider.of<AuthProvider>(context, listen: false).user!;
                await Provider.of<LocationProvider>(context, listen: false).addComment(
                  feedbackId: feedback.id,
                  user: userId,
                  comment: commentController.text.trim(),
                );
                Navigator.of(context).pop();
              }
            },
            child: const Text('POST'),
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
        Navigator.pushReplacementNamed(context, LoginScreen.routeName);
      });
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    
    return Scaffold(
      backgroundColor: AppColors.primary,
      body: PageView(
        controller: _pageController,
        onPageChanged: _onPageChanged,
        children: [
          // Home Feed Page - wrapped in KeepAlivePage to prevent rebuilds
          _buildBuddyHomeFeed(),
          
          // Map Page
          const KeepAlivePage(child: BuddyMapScreen()),
          
          // Add Upload Page for buddies
          const KeepAlivePage(child: CustomerUploadScreen()),
          
          // Profile Page
          const KeepAlivePage(child: BuddyProfileScreen()),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: _onItemTapped,
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.white,
        selectedItemColor: AppColors.secondary,
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
          BottomNavigationBarItem(
            icon: Icon(Icons.add_circle_outline),
            label: 'Upload',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
      // Add a floating action button for quick upload access
      floatingActionButton: _currentIndex == 0 ? FloatingActionButton(
        backgroundColor: AppColors.secondary,
        onPressed: () {
          _pageController.jumpToPage(2); // Jump to upload page
        },
        child: const Icon(Icons.add, color: Colors.white),
      ) : null,
    );
  }

  // Build buddy home feed
  Widget _buildBuddyHomeFeed() {
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
                // Toggle button
                TextButton.icon(
                  onPressed: () {
                    setState(() {
                      _showApprovedFeedback = !_showApprovedFeedback;
                    });
                  },
                  icon: Icon(
                    _showApprovedFeedback ? Icons.visibility : Icons.hourglass_top,
                    color: _showApprovedFeedback ? Colors.green : Colors.orange,
                  ),
                  label: Text(
                    _showApprovedFeedback ? 'Approved' : 'My Pending',
                    style: TextStyle(
                      color: _showApprovedFeedback ? Colors.green : Colors.orange,
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          // Buddy Status Banner
          Container(
            margin: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.secondary.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.secondary),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.verified_user,
                  color: AppColors.secondary,
                ),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    'You are a Buddy user. Your safety information will need admin approval before showing to others.',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.black87,
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          // Feedback List
          Expanded(
            child: _showApprovedFeedback
                ? _buildApprovedFeedbackList()
                : _buildMyPendingFeedbackList(),
          ),
        ],
      ),
    );
  }

  // Show approved feedback from everyone
  Widget _buildApprovedFeedbackList() {
    return RefreshIndicator(
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
                children: [
                  const Icon(
                    Icons.feedback_outlined,
                    size: 64,
                    color: Colors.grey,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'No approved feedback available yet',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.black54,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      ElevatedButton.icon(
                        onPressed: () => setState(() {
                          _showApprovedFeedback = false;
                        }),
                        icon: const Icon(Icons.hourglass_top),
                        label: const Text('View my pending'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orange,
                          foregroundColor: Colors.white,
                        ),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton.icon(
                        onPressed: () {
                          _pageController.jumpToPage(2); // Jump to upload page
                        },
                        icon: const Icon(Icons.add),
                        label: const Text('Add feedback'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.secondary,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ],
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
                key: ValueKey(feedback[index].id),
                feedback: feedback[index],
                currentUserId: userId,
                onTap: () {
                  // View feedback details
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
    );
  }

  // Show only this buddy's pending feedback
  Widget _buildMyPendingFeedbackList() {
    final userId = Provider.of<AuthProvider>(context).user!.id;
    
    return RefreshIndicator(
      onRefresh: () async {
         Provider.of<LocationProvider>(context, listen: false).loadPendingFeedback();
      },
      child: Consumer<LocationProvider>(
        builder: (context, locationProvider, _) {
          final allPendingFeedback = locationProvider.pendingFeedback;
          // Filter to only show this buddy's pending feedback
          final myPendingFeedback = allPendingFeedback
              .where((feedback) => feedback.userId == userId)
              .toList();
          
          final isLoading = locationProvider.isLoading;
          
          if (isLoading && myPendingFeedback.isEmpty) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }
          
          if (myPendingFeedback.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.check_circle_outline,
                    size: 64,
                    color: Colors.green,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'You have no pending feedback',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.black54,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'All your feedback has been processed',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      ElevatedButton.icon(
                        onPressed: () => setState(() {
                          _showApprovedFeedback = true;
                        }),
                        icon: const Icon(Icons.visibility),
                        label: const Text('View approved'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                        ),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton.icon(
                        onPressed: () {
                          _pageController.jumpToPage(2); // Jump to upload page
                        },
                        icon: const Icon(Icons.add),
                        label: const Text('Add new'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.secondary,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          }
          
          return Stack(
            children: [
              ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: myPendingFeedback.length,
                itemBuilder: (context, index) {
                  final feedback = myPendingFeedback[index];
                  return _buildPendingFeedbackCard(feedback);
                },
              ),
              // Add floating action button to add more feedback even when there's pending feedback
              Positioned(
                bottom: 16,
                right: 16,
                child: FloatingActionButton(
                  heroTag: "addMoreFeedback",
                  backgroundColor: AppColors.secondary,
                  onPressed: () {
                    _pageController.jumpToPage(2); // Jump to upload page
                  },
                  child: const Icon(Icons.add, color: Colors.white),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  // Custom card for pending feedback
  Widget _buildPendingFeedbackCard(FeedbackModel feedback) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: Colors.orange.withOpacity(0.5),
          width: 2,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Pending status banner
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
            decoration: BoxDecoration(
              color: Colors.orange.withOpacity(0.2),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(10),
                topRight: Radius.circular(10),
              ),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.hourglass_top,
                  color: Colors.orange,
                  size: 18,
                ),
                const SizedBox(width: 8),
                const Text(
                  'Waiting for Admin Approval',
                  style: TextStyle(
                    color: Colors.orange,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                const Spacer(),
                Text(
                  'Submitted: ${_formatDate(feedback.createdAt)}',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          
          // Location header
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Row(
              children: [
                const Icon(Icons.location_on, color: Colors.grey),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    feedback.locationName,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
                // Safety rating
                Row(
                  children: [
                    const Icon(Icons.star, color: Colors.amber, size: 18),
                    const SizedBox(width: 4),
                    Text(
                      feedback.safetyRating.toStringAsFixed(1),
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          
          // Feedback content
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Text(
              feedback.feedback,
              style: const TextStyle(fontSize: 14),
            ),
          ),
          
          // Image if available
          if (feedback.imageBase64 != null && feedback.imageBase64!.isNotEmpty)
            Container(
              width: double.infinity,
              height: 150,
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                image: DecorationImage(
                  image: MemoryImage(base64Decode(feedback.imageBase64!)),
                  fit: BoxFit.cover,
                ),
              ),
            ),
          
          // Footer
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              'Admin will review this safety information soon. Approved safety information will be visible to everyone.',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
        ],
      ),
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
      return '${difference.inDays} days ago';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }
}

// KeepAlivePage wrapper to prevent PageView from rebuilding pages
class KeepAlivePage extends StatefulWidget {
  final Widget child;
  
  const KeepAlivePage({Key? key, required this.child}) : super(key: key);
  
  @override
  _KeepAlivePageState createState() => _KeepAlivePageState();
}

class _KeepAlivePageState extends State<KeepAlivePage> with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;
  
  @override
  Widget build(BuildContext context) {
    super.build(context);
    return widget.child;
  }
}