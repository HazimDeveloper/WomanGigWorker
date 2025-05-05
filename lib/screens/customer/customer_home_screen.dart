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
      // Then reload
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

  void _loadData() {
    // Load feedbacks for the home screen
    Provider.of<LocationProvider>(context, listen: false).loadFeedback();
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
    return Scaffold(
      backgroundColor: AppColors.primary,
      body: PageView(
        controller: _pageController,
        onPageChanged: _onPageChanged,
        children: [
          // Home Feed Page
          _buildHomeFeed(),
          
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
    );
  }

  Widget _buildHomeFeed() {
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
          
          // Feedback List
          Expanded(
            child: Consumer<LocationProvider>(
              builder: (context, locationProvider, _) {
                final feedback = locationProvider.feedback;
                final isLoading = locationProvider.isLoading;
                
                if (isLoading) {
                  return const Center(
                    child: CircularProgressIndicator(),
                  );
                }
                
                if (feedback.isEmpty) {
                  return const Center(
                    child: Text(
                      'No feedback available yet',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.black54,
                      ),
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
        ],
      ),
    );
  }
}