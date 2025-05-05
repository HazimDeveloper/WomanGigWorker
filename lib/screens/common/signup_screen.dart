import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:trust_me/screens/admin/admin_home_screen.dart';
import 'package:trust_me/screens/buddy/buddy_home_screen.dart';
import 'package:trust_me/screens/customer/customer_home_screen.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/common/custom_button.dart';
import '../../widgets/common/custom_text_field.dart';
import '../../utils/job_categories.dart'; // Import job categories
import '../../config/constants.dart';

class SignupScreen extends StatefulWidget {
  static const String routeName = '/signup';

  const SignupScreen({Key? key}) : super(key: key);

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _phoneController = TextEditingController();
  final _customJobController = TextEditingController();
  final _customCompanyController = TextEditingController();
  String _selectedRole = AppConstants.roleCustomer;
  String? _selectedJob;
  String? _selectedCompany;
  bool _isLoading = false;
  String? _errorMessage;
  bool _customJobSelected = false;
  bool _customCompanySelected = false;

  @override
  void dispose() {
    _usernameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _phoneController.dispose();
    _customJobController.dispose();
    _customCompanyController.dispose();
    super.dispose();
  }

  void _showJobOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(15)),
      ),
      builder: (BuildContext context) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.6,
          padding: const EdgeInsets.symmetric(vertical: 20),
          child: Column(
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Select Your Job',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 10),
              Expanded(
                child: ListView.builder(
                  itemCount: JobCategories.categories.length,
                  itemBuilder: (context, index) {
                    final item = JobCategories.categories[index];
                    return ListTile(
                      title: Text(item),
                      selected: item == _selectedJob,
                      selectedTileColor: AppColors.primary.withOpacity(0.1),
                      onTap: () {
                        setState(() {
                          _selectedJob = item;
                          _customJobSelected = item == JobCategories.otherOption;
                        });
                        Navigator.pop(context);
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showCompanyOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(15)),
      ),
      builder: (BuildContext context) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.6,
          padding: const EdgeInsets.symmetric(vertical: 20),
          child: Column(
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Select Your Company',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 10),
              Expanded(
                child: ListView.builder(
                  itemCount: Companies.list.length,
                  itemBuilder: (context, index) {
                    final item = Companies.list[index];
                    return ListTile(
                      title: Text(item),
                      selected: item == _selectedCompany,
                      selectedTileColor: AppColors.primary.withOpacity(0.1),
                      onTap: () {
                        setState(() {
                          _selectedCompany = item;
                          _customCompanySelected = item == Companies.otherOption;
                        });
                        Navigator.pop(context);
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _signUp() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    // Validate job and company selections
    if (_selectedJob == null) {
      setState(() {
        _errorMessage = "Please select a job";
      });
      return;
    }

    if (_customJobSelected && _customJobController.text.isEmpty) {
      setState(() {
        _errorMessage = "Please specify your job";
      });
      return;
    }

    if (_selectedCompany == null) {
      setState(() {
        _errorMessage = "Please select a company";
      });
      return;
    }

    if (_customCompanySelected && _customCompanyController.text.isEmpty) {
      setState(() {
        _errorMessage = "Please specify your company";
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final success = await Provider.of<AuthProvider>(context, listen: false).signUp(
        email: _emailController.text.trim(),
        password: _passwordController.text,
        username: _usernameController.text.trim(),
        role: _selectedRole,
      );

      if (success && mounted) {
        // Determine job value (custom or selected)
        final String jobValue = _customJobSelected && _customJobController.text.isNotEmpty
            ? _customJobController.text.trim()
            : _selectedJob ?? '';
            
        // Determine company value (custom or selected)
        final String companyValue = _customCompanySelected && _customCompanyController.text.isNotEmpty
            ? _customCompanyController.text.trim()
            : _selectedCompany ?? '';

        // Update additional user info
        await Provider.of<AuthProvider>(context, listen: false).updateUser(
          job: jobValue,
          company: companyValue,
          phoneNumber: _phoneController.text.trim(),
        );
        
        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Account created successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        
        // Navigate to home screen based on role
        if (_selectedRole == AppConstants.roleCustomer) {
          Navigator.of(context).pushReplacementNamed(CustomerHomeScreen.routeName);
        } else if (_selectedRole == AppConstants.roleBuddy) {
          Navigator.of(context).pushReplacementNamed(BuddyHomeScreen.routeName);
        } else if (_selectedRole == AppConstants.roleAdmin) {
          Navigator.of(context).pushReplacementNamed(AdminHomeScreen.routeName);
        }
      } else if (mounted) {
        final authProvider = Provider.of<AuthProvider>(context, listen: false);
        setState(() {
          _errorMessage = authProvider.errorMessage ?? "Sign up failed";
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
      });
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
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        elevation: 0,
        title: const Text(
          'Trust.ME',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
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
              const SizedBox(height: 32),
              // Sign Up Form
              Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Username Field
                    const Text(
                      'USERNAME',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 8),
                    CustomTextField(
                      controller: _usernameController,
                      textInputAction: TextInputAction.next,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter a username';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    
                    // Email Field
                    const Text(
                      'EMAIL',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 8),
                    CustomTextField(
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
                    const Text(
                      'PASSWORD',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 8),
                    CustomTextField(
                      controller: _passwordController,
                      obscureText: true,
                      textInputAction: TextInputAction.next,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter a password';
                        }
                        if (value.length < 6) {
                          return 'Password must be at least 6 characters';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    
                    // Confirm Password Field
                    const Text(
                      'CONFIRM PASSWORD',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 8),
                    CustomTextField(
                      controller: _confirmPasswordController,
                      obscureText: true,
                      textInputAction: TextInputAction.next,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please confirm your password';
                        }
                        if (value != _passwordController.text) {
                          return 'Passwords do not match';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    
                    // Job Field
                    const Text(
                      'JOB',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 8),
                    // Job Selection with BottomSheet
                    GestureDetector(
                      onTap: () => _showJobOptions(context),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                _selectedJob ?? 'Select your job',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: _selectedJob == null ? Colors.grey : Colors.black,
                                ),
                              ),
                            ),
                            const Icon(Icons.arrow_drop_down, color: Colors.grey),
                          ],
                        ),
                      ),
                    ),
                    // Custom Job Input (shows when "Others" is selected)
                    if (_customJobSelected) ...[
                      const SizedBox(height: 16),
                      const Text(
                        'SPECIFY YOUR JOB',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 8),
                      CustomTextField(
                        controller: _customJobController,
                        textInputAction: TextInputAction.next,
                      ),
                    ],
                    const SizedBox(height: 16),
                    
                    // Company Field
                    const Text(
                      'COMPANY',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 8),
                    // Company Selection with BottomSheet
                    GestureDetector(
                      onTap: () => _showCompanyOptions(context),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                _selectedCompany ?? 'Select your company',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: _selectedCompany == null ? Colors.grey : Colors.black,
                                ),
                              ),
                            ),
                            const Icon(Icons.arrow_drop_down, color: Colors.grey),
                          ],
                        ),
                      ),
                    ),
                    // Custom Company Input (shows when "Others" is selected)
                    if (_customCompanySelected) ...[
                      const SizedBox(height: 16),
                      const Text(
                        'SPECIFY YOUR COMPANY',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 8),
                      CustomTextField(
                        controller: _customCompanyController,
                        textInputAction: TextInputAction.next,
                      ),
                    ],
                    const SizedBox(height: 16),
                    
                    // Phone Field
                    const Text(
                      'PHONE NUMBER',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 8),
                    CustomTextField(
                      controller: _phoneController,
                      keyboardType: TextInputType.phone,
                      textInputAction: TextInputAction.done,
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
                    
                    // Sign Up Button
                    Center(
                      child: CustomButton(
                        text: 'SIGN UP',
                        onPressed: _signUp,
                        isLoading: _isLoading,
                        width: 200,
                      ),
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
}