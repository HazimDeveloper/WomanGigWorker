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
      // Load pending feedback
      Provider.of<LocationProvider>(context, listen: false).loadPendingFeedback();
      
      // Add a small delay to allow data to load
      await Future.delayed(const Duration(milliseconds: 500));
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
    try {
      // Set loading state
      setState(() {
        _isLoading = true;
      });
      
      // Approve feedback
      final success = await Provider.of<LocationProvider>(context, listen: false)
          .approveFeedback(feedback.id);
      
      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Feedback approved successfully'),
            backgroundColor: Colors.green,
          ),
        );
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to approve feedback'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error approving feedback: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _rejectFeedback(FeedbackModel feedback) async {
    try {
      // Set loading state
      setState(() {
        _isLoading = true;
      });
      
      // Reject feedback
      final success = await Provider.of<LocationProvider>(context, listen: false)
          .rejectFeedback(feedback.id);
      
      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Feedback rejected'),
            backgroundColor: Colors.orange,
          ),
        );
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to reject feedback'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error rejecting feedback: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
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
          'BUDDY SAFETY INFORMATION APPROVAL',
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
            child: const Row(
              children: [
                Expanded(
                  flex: 2,
                  child: Text(
                    'BUDDY',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: Colors.black87,
                    ),
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Text(
                    'LOCATION',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: Colors.black87,
                    ),
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Text(
                    'ACTIONS',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: Colors.black87,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
          ),
          
          // Pending Feedback List
          Expanded(
            child: Consumer<LocationProvider>(
              builder: (context, locationProvider, _) {
                final pendingFeedback = locationProvider.pendingFeedback;
                
                if (_isLoading) {
                  return const Center(child: CircularProgressIndicator());
                }
                
                if (pendingFeedback.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.check_circle_outline,
                          size: 64,
                          color: Colors.grey,
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'No pending feedback to approve',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey,
                          ),
                        ),
                        const SizedBox(height: 24),
                        ElevatedButton.icon(
                          onPressed: _loadPendingFeedback,
                          icon: const Icon(Icons.refresh),
                          label: const Text('Refresh'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.secondary,
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  );
                }
                
                return RefreshIndicator(
                  onRefresh: _loadPendingFeedback,
                  child: ListView.builder(
                    itemCount: pendingFeedback.length,
                    itemBuilder: (context, index) {
                      final feedback = pendingFeedback[index];
                      return _buildFeedbackItem(feedback);
                    },
                  ),
                );
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
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Username
          Expanded(
            flex: 2,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  feedback.username,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(
                      Icons.person,
                      size: 12,
                      color: Colors.grey,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Buddy',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          
          // Location
          Expanded(
            flex: 2,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  feedback.locationName,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(
                      Icons.star,
                      size: 12,
                      color: Colors.amber,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      feedback.safetyRating.toStringAsFixed(1),
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          
          // Actions
          Expanded(
            flex: 2,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // View Button
                IconButton(
                  icon: const Icon(
                    Icons.visibility,
                    color: Colors.blue,
                    size: 24,
                  ),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => AdminFeedbackDetailScreen(feedback: feedback),
                      ),
                    );
                  },
                  tooltip: 'View Details',
                ),
                
                // Approve Button
                IconButton(
                  icon: const Icon(
                    Icons.check_circle,
                    color: Colors.green,
                    size: 24,
                  ),
                  onPressed: () => _approveFeedback(feedback),
                  tooltip: 'Approve',
                ),
                
                // Reject Button
                IconButton(
                  icon: const Icon(
                    Icons.cancel,
                    color: Colors.red,
                    size: 24,
                  ),
                  onPressed: () => _rejectFeedback(feedback),
                  tooltip: 'Reject',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}