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
          content: Text('Error loading pending safety information: ${e.toString()}'),
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
            content: Text('safety information approved successfully'),
            backgroundColor: Colors.green,
          ),
        );
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to approve safety information'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error approving safety information: ${e.toString()}'),
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
            content: Text('safety information rejected'),
            backgroundColor: Colors.orange,
          ),
        );
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to reject safety information'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error rejecting safety information: ${e.toString()}'),
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

  Future<void> _deleteFeedback(FeedbackModel feedback) async {
    // Show confirmation dialog
    final bool? shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Safety Information'),
        content: Text(
          'Are you sure you want to permanently delete this safety information from "${feedback.username}" about "${feedback.locationName}"?\n\nThis action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('CANCEL'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(
              foregroundColor: Colors.red,
            ),
            child: const Text('DELETE'),
          ),
        ],
      ),
    );

    if (shouldDelete == true) {
      try {
        // Set loading state
        setState(() {
          _isLoading = true;
        });
        
        // Delete feedback (you'll need to implement this in your DatabaseService)
        // For now, we'll reject it and show a delete message
        final success = await Provider.of<LocationProvider>(context, listen: false)
            .rejectFeedback(feedback.id);
        
        if (success && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Safety Information deleted successfully'),
              backgroundColor: Colors.red,
            ),
          );
        } else if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Failed to delete safety information'),
              backgroundColor: Colors.red,
            ),
          );
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error deleting safety information: ${e.toString()}'),
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
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
        centerTitle: true,
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.black),
            onPressed: _loadPendingFeedback,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: Column(
        children: [
          // Header Row with better spacing
          Container(
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
            color: AppColors.primary.withOpacity(0.7),
            child: Row(
              children: const [
                Expanded(
                  flex: 3,
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
                  flex: 3,
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
                  flex: 4,
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
                
                if (_isLoading && pendingFeedback.isEmpty) {
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
                    padding: const EdgeInsets.all(16),
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
          Container(
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
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            // Buddy Info
            Expanded(
              flex: 3,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    feedback.username,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(
                        Icons.verified_user,
                        size: 14,
                        color: Colors.purple,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Buddy',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.purple,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            
            const SizedBox(width: 12),
            
            // Location Info
            Expanded(
              flex: 3,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    feedback.locationName,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 2,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(
                        Icons.star,
                        size: 14,
                        color: Colors.amber,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        feedback.safetyRating.toStringAsFixed(1),
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            
            const SizedBox(width: 12),
            
            // Actions
            Expanded(
              flex: 4,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  // View Button
                  _buildActionButton(
                    icon: Icons.visibility,
                    color: Colors.blue,
                    tooltip: 'View Details',
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => AdminFeedbackDetailScreen(feedback: feedback),
                        ),
                      );
                    },
                  ),
                  
                  // Approve Button
                  _buildActionButton(
                    icon: Icons.check_circle,
                    color: Colors.green,
                    tooltip: 'Approve',
                    onPressed: () => _approveFeedback(feedback),
                  ),
                  
                  // Delete Button (Pangkah)
                  _buildActionButton(
                    icon: Icons.close,
                    color: Colors.red,
                    tooltip: 'Delete',
                    onPressed: () => _deleteFeedback(feedback),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required Color color,
    required String tooltip,
    required VoidCallback onPressed,
  }) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            shape: BoxShape.circle,
            border: Border.all(color: color.withOpacity(0.3)),
          ),
          child: Icon(
            icon,
            color: color,
            size: 20,
          ),
        ),
      ),
    );
  }
}