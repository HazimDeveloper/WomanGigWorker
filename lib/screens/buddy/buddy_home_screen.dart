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

class BuddyHomeScreen extends StatefulWidget {
  static const String routeName = '/buddy/home';

  const BuddyHomeScreen({Key? key}) : super(key: key);

  @override
  State<BuddyHomeScreen> createState() => _BuddyHomeScreenState();
}

class _BuddyHomeScreenState extends State<BuddyHomeScreen> {
  int _currentIndex = 0;
  final PageController _pageController = PageController();

  @override
  void initState() {
    super.initState();
    // Initialize image cache with higher limits for better performance
    PaintingBinding.instance.imageCache.maximumSize = 200;
    PaintingBinding.instance.imageCache.maximumSizeBytes = 100 << 20; // 100 MB
    
    // Initial data load happens in the _HomeFeedPage now
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
          KeepAlivePage(child: _BuddyHomeFeedPage(userId: user.id)),
          
          // Map Page
          const KeepAlivePage(child: BuddyMapScreen()),
          
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
            icon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
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

// Dedicated widget for the home feed to better control rebuilds
class _BuddyHomeFeedPage extends StatefulWidget {
  final String userId;
  
  const _BuddyHomeFeedPage({Key? key, required this.userId}) : super(key: key);
  
  @override
  _BuddyHomeFeedPageState createState() => _BuddyHomeFeedPageState();
}

class _BuddyHomeFeedPageState extends State<_BuddyHomeFeedPage> {
  @override
  void initState() {
    super.initState();
    // Load feedback data when this page initializes
    Provider.of<LocationProvider>(context, listen: false).loadFeedback();
  }

  Future<void> _handleLikeToggle(FeedbackModel feedback, bool isLiked) async {
    final userId = widget.userId;
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
                    // Notification functionality
                  },
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
                    'You are a Buddy user. You can view and comment on locations but cannot add new feedback.',
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
            child: Selector<LocationProvider, _FeedbackListState>(
              // Only select the specific data we need
              selector: (_, provider) => _FeedbackListState(
                feedback: provider.feedback,
                isLoading: provider.isLoading,
                errorMessage: provider.errorMessage,
              ),
              // Only rebuild if the specific state we care about changed
              shouldRebuild: (previous, next) => 
                previous.isLoading != next.isLoading ||
                previous.errorMessage != next.errorMessage ||
                previous.feedback.length != next.feedback.length,
              builder: (context, state, _) {
                if (state.isLoading && state.feedback.isEmpty) {
                  return const Center(
                    child: CircularProgressIndicator(),
                  );
                }
                
                if (state.feedback.isEmpty) {
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
                  itemCount: state.feedback.length,
                  itemBuilder: (context, index) {
                    final feedback = state.feedback[index];
                    return FeedbackCard(
                      key: ValueKey(feedback.id), // Important for efficient rebuilds
                      feedback: feedback,
                      currentUserId: widget.userId,
                      onTap: () {
                        // View feedback details
                      },
                      onLikeToggle: (isLiked) {
                        _handleLikeToggle(feedback, isLiked);
                      },
                      onAddComment: () {
                        _showCommentDialog(feedback);
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

// State class for the feedback list to optimize rebuilds
class _FeedbackListState {
  final List<FeedbackModel> feedback;
  final bool isLoading;
  final String? errorMessage;
  
  const _FeedbackListState({
    required this.feedback,
    required this.isLoading,
    this.errorMessage,
  });
}