import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:trust_me/screens/admin/admin_approval_screen.dart';
import 'package:trust_me/screens/buddy/buddy_map_screen.dart';
import 'package:trust_me/screens/buddy/buddy_profile_screen.dart';
import 'package:trust_me/screens/common/login_screen.dart';
import 'package:trust_me/screens/common/signup_screen.dart';
import 'package:trust_me/screens/common/splash_screen.dart';
import 'config/theme.dart';
import 'providers/auth_provider.dart';
import 'screens/customer/customer_home_screen.dart';
import 'screens/customer/customer_map_screen.dart';
import 'screens/customer/customer_profile_screen.dart';
import 'screens/customer/customer_upload_screen.dart';
import 'screens/buddy/buddy_home_screen.dart';
import 'screens/admin/admin_home_screen.dart';
import 'main.dart'; // Import to access the global navigatorKey

class TrustMeApp extends StatelessWidget {
  const TrustMeApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, _) {
        // Listen for auth state changes
        try {
          // Only listen if user is signed in
          if (authProvider.isAuthenticated) {
            authProvider.listenToAuthChanges(context);
          }
        } catch (e) {
          print("Error in auth listener: $e");
        }
        
        return MaterialApp(
          navigatorKey: navigatorKey, // Use the global navigatorKey
          debugShowCheckedModeBanner: false,
          title: 'Trust.ME',
          theme: AppTheme.light,
          initialRoute: SplashScreen.routeName,
          routes: {
            // Common routes
            SplashScreen.routeName: (_) => const SplashScreen(),
            LoginScreen.routeName: (_) => const LoginScreen(),
            SignupScreen.routeName: (_) => const SignupScreen(),
            
            // Customer/Worker routes
            CustomerHomeScreen.routeName: (_) => const CustomerHomeScreen(),
            CustomerMapScreen.routeName: (_) => const CustomerMapScreen(),
            CustomerProfileScreen.routeName: (_) => const CustomerProfileScreen(),
            CustomerUploadScreen.routeName: (_) => const CustomerUploadScreen(),
            
            // Buddy routes
            BuddyHomeScreen.routeName: (_) => const BuddyHomeScreen(),
            BuddyMapScreen.routeName: (context) => const BuddyMapScreen(),
            BuddyProfileScreen.routeName: (context) => const BuddyProfileScreen(),
            
            // Admin routes
            AdminHomeScreen.routeName: (_) => const AdminHomeScreen(),
            AdminApprovalScreen.routeName: (context) => const AdminApprovalScreen(),
          },
        );
      },
    );
  }
}