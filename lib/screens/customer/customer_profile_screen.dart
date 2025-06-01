import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../providers/auth_provider.dart';
import '../../providers/user_provider.dart';
import '../../widgets/common/custom_button.dart';
import '../../widgets/common/custom_text_field.dart';
import '../../widgets/common/custom_dropdown.dart';
import '../../utils/job_categories.dart';
import '../../config/constants.dart';
import '../../screens/common/login_screen.dart';
import '../../services/storage_service.dart';
import '../../utils/image_util.dart';

class CustomerProfileScreen extends StatefulWidget {
  static const String routeName = '/customer/profile';

  const CustomerProfileScreen({Key? key}) : super(key: key);

  @override
  State<CustomerProfileScreen> createState() => _CustomerProfileScreenState();
}

class _CustomerProfileScreenState extends State<CustomerProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _customJobController = TextEditingController();
  final TextEditingController _companyController = TextEditingController(); // Changed to direct controller
  bool _isEditing = false;
  bool _isLoading = false;
  File? _imageFile;
  final ImagePicker _picker = ImagePicker();
  String? _selectedJob;
  bool _customJobSelected = false;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  @override
  void dispose() {
    _phoneController.dispose();
    _customJobController.dispose();
    _companyController.dispose(); // Dispose the controller
    super.dispose();
  }

  void _loadUserData() {
    final user = Provider.of<AuthProvider>(context, listen: false).user;
    if (user != null) {
      _phoneController.text = user.phoneNumber ?? '';
      
      // Handle job selection
      String userJob = user.job ?? '';
      if (JobCategories.categories.contains(userJob)) {
        _selectedJob = userJob;
        _customJobSelected = false;
      } else if (userJob.isNotEmpty) {
        _selectedJob = JobCategories.otherOption;
        _customJobController.text = userJob;
        _customJobSelected = true;
      }
      
      // Set company text directly
      _companyController.text = user.company ?? '';
    }
  }

  Future<void> _pickImage() async {
    final XFile? pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _imageFile = File(pickedFile.path);
      });
    }
  }

  Future<void> _updateProfile() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Convert image to base64 if selected
      String? photoBase64;
      if (_imageFile != null) {
        photoBase64 = await ImageUtil.fileToBase64(_imageFile!);
        if (photoBase64 == null) {
          throw Exception('Failed to convert image');
        }
      }
      
      // Other profile data
      final String jobValue = _customJobSelected && _customJobController.text.isNotEmpty
          ? _customJobController.text.trim()
          : _selectedJob ?? '';
          
      // Get company value directly
      final String companyValue = _companyController.text.trim();
      
      // Update user with base64 image
      final success = await Provider.of<AuthProvider>(context, listen: false).updateUser(
        job: jobValue,
        company: companyValue,
        phoneNumber: _phoneController.text.trim(),
        photoBase64: photoBase64, // Use base64 instead of URL
      );
      
      if (success && mounted) {
        setState(() {
          _isEditing = false;
          _imageFile = null;
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profile updated successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      print('Error updating profile: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error updating profile. Please try again.'),
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
    setState(() {
      _isLoading = true;
    });
    
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
    final user = Provider.of<AuthProvider>(context).user;
    
    if (user == null) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    // Get role-based colors
    final backgroundColor = AppColors.getBackgroundForRole(user.role);
    final secondaryColor = AppColors.getSecondaryForRole(user.role);
    
    // Determine user type label
    String userTypeLabel = user.role == AppConstants.roleWorker ? 'Gig Worker' : 'Gig Worker';

    return Scaffold(
      backgroundColor: backgroundColor, // Use role-based background
      appBar: AppBar(
        backgroundColor: backgroundColor,
        elevation: 0,
        title: const Text(
          'PROFILE',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
        centerTitle: true,
        actions: [
          if (!_isEditing)
            IconButton(
              icon: const Icon(Icons.edit, color: Colors.black),
              onPressed: () {
                setState(() {
                  _isEditing = true;
                });
              },
            )
          else
            IconButton(
              icon: const Icon(Icons.close, color: Colors.black),
              onPressed: () {
                setState(() {
                  _isEditing = false;
                  _loadUserData(); // Reset form
                  _imageFile = null;
                });
              },
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Profile Card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    // Profile Image
                    GestureDetector(
                      onTap: _isEditing ? _pickImage : null,
                      child: Stack(
                        alignment: Alignment.bottomRight,
                        children: [
                          Container(
                            height: 120,
                            width: 120,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: secondaryColor.withOpacity(0.5),
                                width: 3,
                              ),
                            ),
                            child: _buildProfileImage(user),
                          ),
                          if (_isEditing)
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: secondaryColor,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: Colors.white,
                                  width: 2,
                                ),
                              ),
                              child: const Icon(
                                Icons.camera_alt,
                                color: Colors.white,
                                size: 20,
                              ),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    // Username
                    Text(
                      user.username,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    
                    // Email
                    Text(
                      user.email,
                      style: const TextStyle(
                        fontSize: 16,
                        color: Colors.black54,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 16),
                    
                    // User Type Badge
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: secondaryColor.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: secondaryColor),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            user.role == AppConstants.roleWorker ? Icons.work : Icons.person,
                            color: secondaryColor,
                            size: 18,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            userTypeLabel,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: secondaryColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 24),
              
              // Profile Information Section
              if (!_isEditing) ...[
                _buildInfoSection(user),
              ] else ...[
                _buildEditForm(secondaryColor),
              ],
              
              const SizedBox(height: 32),
              
              // Sign Out Button
              if (!_isEditing)
                CustomButton(
                  text: 'SIGN OUT',
                  onPressed: _signOut,
                  isLoading: _isLoading,
                  isPrimary: false,
                  width: 200,
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProfileImage(dynamic user) {
    if (_imageFile != null) {
      return CircleAvatar(
        radius: 56,
        backgroundColor: Colors.grey.shade200,
        backgroundImage: FileImage(_imageFile!),
      );
    } else if (user.photoBase64 != null && user.photoBase64!.isNotEmpty) {
      try {
        return CircleAvatar(
          radius: 56,
          backgroundColor: Colors.grey.shade200,
          backgroundImage: MemoryImage(base64Decode(user.photoBase64!)),
        );
      } catch (e) {
        print("Error decoding base64 image: $e");
      }
    } else if (user.photoUrl != null && user.photoUrl!.isNotEmpty) {
      return CircleAvatar(
        radius: 56,
        backgroundColor: Colors.grey.shade200,
        backgroundImage: CachedNetworkImageProvider(
          user.photoUrl!,
          cacheKey: "profile_${user.id}",
        ),
      );
    }
    
    // Fallback to initials
    return CircleAvatar(
      radius: 56,
      backgroundColor: Colors.grey.shade200,
      child: Text(
        user.username.isNotEmpty ? user.username[0].toUpperCase() : '?',
        style: const TextStyle(
          fontSize: 40,
          fontWeight: FontWeight.bold,
          color: Colors.black54,
        ),
      ),
    );
  }

  Widget _buildInfoSection(dynamic user) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'PERSONAL INFORMATION',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 16),
          const Divider(),
          const SizedBox(height: 16),
          
          // Display job info
          if (user.job != null && user.job!.isNotEmpty) ...[
            _buildInfoItem('Job', user.job!),
            const SizedBox(height: 16),
          ],
          
          // Display company info
          if (user.company != null && user.company!.isNotEmpty) ...[
            _buildInfoItem('Company', user.company!),
            const SizedBox(height: 16),
          ],
          
          // Display phone info
          if (user.phoneNumber != null && user.phoneNumber!.isNotEmpty)
            _buildInfoItem('Phone', user.phoneNumber!),
        ],
      ),
    );
  }

  Widget _buildInfoItem(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 80,
          child: Text(
            '$label:',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.black54,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              fontSize: 16,
              color: Colors.black,
            ),
            overflow: TextOverflow.visible,
          ),
        ),
      ],
    );
  }

  Widget _buildEditForm(Color secondaryColor) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'EDIT PROFILE',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 16),
          const Divider(),
          const SizedBox(height: 16),
          
          // Job Dropdown
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'JOB',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 8),
              CustomDropdown(
                hintText: 'Select your job',
                value: _selectedJob,
                items: JobCategories.categories,
                isSearchable: true,
                onChanged: (String? value) {
                  setState(() {
                    _selectedJob = value;
                    _customJobSelected = value == JobCategories.otherOption;
                  });
                },
              ),
              if (_customJobSelected) ...[
                const SizedBox(height: 8),
                CustomTextField(
                  labelText: 'SPECIFY YOUR JOB',
                  controller: _customJobController,
                  textInputAction: TextInputAction.next,
                  validator: (value) {
                    if (_customJobSelected && (value == null || value.isEmpty)) {
                      return 'Please specify your job';
                    }
                    return null;
                  },
                ),
              ],
            ],
          ),
          const SizedBox(height: 20),
          
          // Company Input Field
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'COMPANY',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 8),
              CustomTextField(
                controller: _companyController,
                textInputAction: TextInputAction.next,
                hintText: 'Enter your company name',
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your company name';
                  }
                  return null;
                },
              ),
            ],
          ),
          const SizedBox(height: 20),
          
          // Phone Field
          CustomTextField(
            labelText: 'PHONE NUMBER',
            controller: _phoneController,
            keyboardType: TextInputType.phone,
            textInputAction: TextInputAction.done,
          ),
          const SizedBox(height: 24),
          
          // Update Button
          Center(
            child: CustomButton(
              text: 'SAVE CHANGES',
              onPressed: _updateProfile,
              isLoading: _isLoading,
              width: 200,
              backgroundColor: secondaryColor,
            ),
          ),
        ],
      ),
    );
  }
}