import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:trust_me/screens/admin/admin_home_screen.dart';
import 'package:trust_me/screens/buddy/buddy_home_screen.dart';
import 'package:trust_me/screens/customer/customer_home_screen.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/common/custom_button.dart';
import '../../widgets/common/custom_text_field.dart';
import '../../config/constants.dart';
import 'signup_screen.dart';

class LoginScreen extends StatefulWidget {
  static const String routeName = '/login';

  const LoginScreen({Key? key}) : super(key: key);

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _fillBuddyCredentials() {
    setState(() {
      _emailController.text = 'nini@buddy.gmail.com';
      _passwordController.text = 'password123';
    });
  }

  void _fillAdminCredentials() {
    setState(() {
      _emailController.text = 'nini@admin.gmail.com';
      _passwordController.text = 'password123';
    });
  }

  void _fillCustomerCredentials() {
    setState(() {
      _emailController.text = 'nini@gmail.com';
      _passwordController.text = 'password123';
    });
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Debug print
      print("Starting login process...");
      
      final success = await Provider.of<AuthProvider>(context, listen: false).signIn(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );

      // Debug print
      print("Login result: $success");

      if (success && mounted) {
        final authProvider = Provider.of<AuthProvider>(context, listen: false);
        
        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Login successful!'),
            backgroundColor: Colors.green,
          ),
        );
        
        // Explicitly navigate based on user role
        if (authProvider.isAdmin) {
          Navigator.of(context).pushReplacementNamed(AdminHomeScreen.routeName);
        } else if (authProvider.isBuddy) {
          Navigator.of(context).pushReplacementNamed(BuddyHomeScreen.routeName);
        } else {
          Navigator.of(context).pushReplacementNamed(CustomerHomeScreen.routeName);
        }
      } else if (mounted) {
        final authProvider = Provider.of<AuthProvider>(context, listen: false);
        setState(() {
          _errorMessage = authProvider.errorMessage ?? "Login failed";
        });
        
        // Debug print
        print("Error during login: $_errorMessage");
      }
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
      });
      
      // Debug print
      print("Exception during login: $e");
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primary,
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              SizedBox(height: MediaQuery.of(context).size.height * 0.1),
              // App Logo or Title
              const Center(
                child: Text(
                  'Trust.ME',
                  style: TextStyle(
                    fontSize: 36,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              const Center(
                child: Text(
                  'EMPOWERING WOMEN',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: Colors.black87,
                    letterSpacing: 1.5,
                  ),
                ),
              ),
              const SizedBox(height: 48),
              // Login Form
              Form(
                key: _formKey,
                child: Column(
                  children: [
                    // Email Field
                    CustomTextField(
                      labelText: 'EMAIL',
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      textInputAction: TextInputAction.next,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter your email';
                        }
                        if (!value.contains('@') || !value.contains('.')) {
                          return 'Please enter a valid email';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    // Password Field
                    CustomTextField(
                      labelText: 'PASSWORD',
                      controller: _passwordController,
                      obscureText: true,
                      textInputAction: TextInputAction.done,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter your password';
                        }
                        if (value.length < 6) {
                          return 'Password must be at least 6 characters';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 24),
                    // Error Message
                    if (_errorMessage != null)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.red.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.red),
                        ),
                        child: Text(
                          _errorMessage!,
                          style: const TextStyle(
                            fontSize: 14,
                            color: Colors.red,
                          ),
                        ),
                      ),
                    if (_errorMessage != null) const SizedBox(height: 16),
                    // Login Button
                    CustomButton(
                      text: 'LOG IN',
                      onPressed: _login,
                      isLoading: _isLoading,
                      width: 200,
                    ),
                    const SizedBox(height: 24),
                    // Sign Up Link
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text(
                          "DON'T HAVE AN ACCOUNT?",
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(width: 8),
                        TextButton(
                          onPressed: () {
                            Navigator.pushNamed(context, SignupScreen.routeName);
                          },
                          child: const Text(
                            'SIGN UP',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: AppColors.secondary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuickLoginButton(String role, Color color, VoidCallback onPressed) {
    return InkWell(
      onTap: onPressed,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: color.withOpacity(0.2),
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: color),
        ),
        child: Text(
          role,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ),
    );
  }
}