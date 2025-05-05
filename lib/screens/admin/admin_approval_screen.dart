import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:trust_me/screens/admin/admin_feedback_details_screen.dart';
import 'package:trust_me/screens/common/login_screen.dart';
import '../../providers/auth_provider.dart';
import '../../providers/location_provider.dart';
import '../../widgets/common/custom_button.dart';
import '../../models/feedback_model.dart';
import '../../config/constants.dart';

class AdminApprovalScreen extends StatefulWidget {
  static const String routeName = '/admin/approval';

  const AdminApprovalScreen({Key? key}) : super(key: key);

  @override
  State<AdminApprovalScreen> createState() => _AdminApprovalScreenState();
}

class _AdminApprovalScreenState extends State<AdminApprovalScreen> {
  bool _isLoading = false;
  List<FeedbackModel> _pendingFeedback = [];

  @override
  void initState() {
    super.initState();
    _loadPendingFeedback();
  }

 Future<void> _loadPendingFeedback() async {
  setState(() {
    _isLoading = true;
  });

  try {
    // Remove the await since loadFeedback() is void and not an async method
    Provider.of<LocationProvider>(context, listen: false).loadFeedback();
    
    // Add a small delay to allow data to load
    await Future.delayed(const Duration(milliseconds: 500));
    
    // Now get the feedback data
    final allFeedback = Provider.of<LocationProvider>(context, listen: false).feedback;
    
    setState(() {
      _pendingFeedback = allFeedback;
    });
  } catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Error loading pending feedback: ${e.toString()}'),
        backgroundColor: Colors.red,
      ),
    );
  } finally {
    setState(() {
      _isLoading = false;
    });
  }
}

  Future<void> _approveFeedback(FeedbackModel feedback) async {
    // In a real app, you would update the feedback status in the database
    try {
      // Simulate API call
      setState(() {
        _isLoading = true;
      });
      
      await Future.delayed(const Duration(milliseconds: 500));
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Feedback approved successfully'),
          backgroundColor: Colors.green,
        ),
      );
      
      // Remove from pending list
      setState(() {
        _pendingFeedback.removeWhere((item) => item.id == feedback.id);
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error approving feedback: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _rejectFeedback(FeedbackModel feedback) async {
    // In a real app, you would mark the feedback as rejected or delete it
    try {
      // Simulate API call
      setState(() {
        _isLoading = true;
      });
      
      await Future.delayed(const Duration(milliseconds: 500));
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Feedback rejected'),
          backgroundColor: Colors.orange,
        ),
      );
      
      // Remove from pending list
      setState(() {
        _pendingFeedback.removeWhere((item) => item.id == feedback.id);
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error rejecting feedback: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _signOut() async {
    try {
      await Provider.of<AuthProvider>(context, listen: false).signOut();
      if (mounted) {
        Navigator.of(context).pushReplacementNamed(LoginScreen.routeName);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error signing out: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primary,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        elevation: 0,
        title: const Text(
          'APPROVAL',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
        centerTitle: true,
        automaticallyImplyLeading: false,
      ),
      body: Column(
        children: [
          // Header Row
          Container(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            color: AppColors.primary.withOpacity(0.7),
            child: Row(
              children: [
                Expanded(
                  flex: 2,
                  child: Text(
                    'USERNAME',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: Colors.black.withOpacity(0.8),
                    ),
                  ),
                ),
                Expanded(
                  flex: 1,
                  child: Center(
                    child: Text(
                      'POSTS',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: Colors.black.withOpacity(0.8),
                      ),
                    ),
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Center(
                    child: Text(
                      'STATUS',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: Colors.black.withOpacity(0.8),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          // Feedback List
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _pendingFeedback.isEmpty
                    ? const Center(child: Text('No pending feedback to approve'))
                    : ListView.builder(
                        itemCount: _pendingFeedback.length,
                        itemBuilder: (context, index) {
                          final feedback = _pendingFeedback[index];
                          return _buildFeedbackItem(feedback);
                        },
                      ),
          ),
          
          // Logout Button
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: CustomButton(
              text: 'LOG OUT',
              onPressed: _signOut,
              backgroundColor: Colors.black,
              textColor: Colors.white,
              width: 150,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeedbackItem(FeedbackModel feedback) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 16),
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          // Username
          Expanded(
            flex: 2,
            child: Text(
              feedback.username.toUpperCase(),
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ),
          
          // View Button
          Expanded(
            flex: 1,
            child: Center(
              child: IconButton(
                icon: const Icon(Icons.visibility, color: Colors.black),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => AdminFeedbackDetailScreen(feedback: feedback),
                    ),
                  );
                },
              ),
            ),
          ),
          
          // Approval Buttons
          Expanded(
            flex: 2,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Approve Button
                IconButton(
                  icon: const Icon(
                    Icons.check_circle,
                    color: Colors.green,
                    size: 28,
                  ),
                  onPressed: () => _approveFeedback(feedback),
                ),
                
                // Reject Button
                IconButton(
                  icon: const Icon(
                    Icons.cancel,
                    color: Colors.red,
                    size: 28,
                  ),
                  onPressed: () => _rejectFeedback(feedback),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}