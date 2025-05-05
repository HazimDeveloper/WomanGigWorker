import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../config/constants.dart';
import '../customer/customer_home_screen.dart';
import '../buddy/buddy_home_screen.dart';
import '../admin/admin_home_screen.dart';
import 'login_screen.dart';

class SplashScreen extends StatefulWidget {
  static const String routeName = '/splash';

  const SplashScreen({Key? key}) : super(key: key);

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _opacityAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );

    _opacityAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.5, curve: Curves.easeIn),
      ),
    );

    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.5, 1.0, curve: Curves.easeOut),
      ),
    );

    _controller.forward();

    // Navigate after animation
    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _checkAuthState();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _checkAuthState() {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    
    Future.delayed(const Duration(milliseconds: 500), () {
      if (authProvider.isAuthenticated) {
        // User is authenticated, navigate to appropriate home screen
        if (authProvider.isAdmin) {
          Navigator.of(context).pushReplacementNamed(AdminHomeScreen.routeName);
        } else if (authProvider.isBuddy) {
          Navigator.of(context).pushReplacementNamed(BuddyHomeScreen.routeName);
        } else {
          // Default to Customer
          Navigator.of(context).pushReplacementNamed(CustomerHomeScreen.routeName);
        }
      } else {
        // User is not authenticated, navigate to login screen
        Navigator.of(context).pushReplacementNamed(LoginScreen.routeName);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primary,
      body: Center(
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            return Opacity(
              opacity: _opacityAnimation.value,
              child: Transform.scale(
                scale: _scaleAnimation.value,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Logo or App Name
                    const Text(
                      'Trust.ME',
                      style: TextStyle(
                        fontSize: 48,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'EMPOWERING WOMEN',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: Colors.black87,
                        letterSpacing: 1.5,
                      ),
                    ),
                    const SizedBox(height: 48),
                    SizedBox(
                      width: 40,
                      height: 40,
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(
                          AppColors.secondary,
                        ),
                        strokeWidth: 3,
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}