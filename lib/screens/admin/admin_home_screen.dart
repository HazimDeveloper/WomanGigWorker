import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:trust_me/screens/common/login_screen.dart';
import '../../providers/auth_provider.dart';
import '../../config/constants.dart';
import 'admin_approval_screen.dart';

class AdminHomeScreen extends StatelessWidget {
  static const String routeName = '/admin/home';

  const AdminHomeScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final user = Provider.of<AuthProvider>(context).user;
    
    return Scaffold(
      backgroundColor: AppColors.primary,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        elevation: 0,
        title: const Text(
          'Trust.ME Admin',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.black),
            onPressed: () async {
              await Provider.of<AuthProvider>(context, listen: false).signOut();
              if (context.mounted) {
                Navigator.of(context).pushReplacementNamed(LoginScreen.routeName);
              }
            },
          ),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'Admin Dashboard',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Welcome, ${user?.username ?? "Admin"}!',
              style: const TextStyle(
                fontSize: 18,
              ),
            ),
            const SizedBox(height: 48),
            
            // Admin Menu Options
            _buildAdminMenuButton(
              context,
              'Feedback Approval',
              Icons.approval,
              () {
                Navigator.pushNamed(context, AdminApprovalScreen.routeName);
              },
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildAdminMenuButton(
    BuildContext context,
    String title,
    IconData icon,
    VoidCallback onPressed,
  ) {
    return SizedBox(
      width: 250,
      child: ElevatedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, color: Colors.white),
        label: Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.secondary,
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),
    );
  }
}