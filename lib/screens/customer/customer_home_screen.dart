import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/location_provider.dart';
import '../../widgets/feedback_card.dart';
import '../../config/constants.dart';
import '../../models/feedback_model.dart';
import 'customer_map_screen.dart';
import 'customer_profile_screen.dart';
import 'customer_upload_screen.dart';

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
        children: [
          // Home Feed Page
          _buildHomeFeed(isWorker),
          
          // Map Page
          const CustomerMapScreen(),
          
          // Upload Feedback Page
          const CustomerUploadScreen(),
          
          // Profile Page
          const CustomerProfileScreen(),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: _onItemTapped,
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.white,
        selectedItemColor: isWorker ? Colors.teal : AppColors.secondary,
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
          
          // Role-specific header
          Container(
            margin: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: _getRoleColor(isWorker).withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: _getRoleColor(isWorker)),
            ),
            child: Row(
              children: [
                Icon(
                  _getRoleIcon(isWorker),
                  color: _getRoleColor(isWorker),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _getRoleMessage(isWorker),
                    style: const TextStyle(
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
                        children: [
                          const Icon(
                            Icons.feedback_outlined,
                            size: 64,
                            color: Colors.grey,
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            'No feedback available yet',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.black54,
                            ),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Pull down to refresh',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey,
                            ),
                          ),
                          const SizedBox(height: 24),
                          ElevatedButton.icon(
                            onPressed: () {
                              _pageController.jumpToPage(2); // Go to upload screen
                            },
                            icon: const Icon(Icons.add),
                            label: const Text('Add your feedback'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: isWorker ? Colors.teal : AppColors.secondary,
                              foregroundColor: Colors.white,
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
                          // TODO: Implement feedback details screen
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

  // Helper methods for role-specific UI
  Color _getRoleColor(bool isWorker) {
    return isWorker ? Colors.teal : AppColors.secondary;
  }

  IconData _getRoleIcon(bool isWorker) {
    return isWorker ? Icons.work : Icons.person;
  }

  String _getRoleMessage(bool isWorker) {
    if (isWorker) {
      return 'Worker Mode: Your feedback will automatically be approved to help other women in your community.';
    } else {
      return 'Customer Mode: You can view and add safety information to help other women.';
    }
  }
}