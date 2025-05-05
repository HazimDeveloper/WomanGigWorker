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
import '../../widgets/common/custom_dropdown.dart'; // Import the new dropdown widget
import '../../utils/job_categories.dart'; // Import job categories
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
  final TextEditingController _customCompanyController = TextEditingController();
  bool _isEditing = false;
  bool _isLoading = false;
  File? _imageFile;
  final ImagePicker _picker = ImagePicker();
  String? _selectedJob;
  String? _selectedCompany;
  bool _customJobSelected = false;
  bool _customCompanySelected = false;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  @override
  void dispose() {
    _phoneController.dispose();
    _customJobController.dispose();
    _customCompanyController.dispose();
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
      
      // Handle company selection
      String userCompany = user.company ?? '';
      if (Companies.list.contains(userCompany)) {
        _selectedCompany = userCompany;
        _customCompanySelected = false;
      } else if (userCompany.isNotEmpty) {
        _selectedCompany = Companies.otherOption;
        _customCompanyController.text = userCompany;
        _customCompanySelected = true;
      }
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
        
    final String companyValue = _customCompanySelected && _customCompanyController.text.isNotEmpty
        ? _customCompanyController.text.trim()
        : _selectedCompany ?? '';
    
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

    return Scaffold(
      backgroundColor: AppColors.primary,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
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
              // Profile Image
              GestureDetector(
                onTap: _isEditing ? _pickImage : null,
                child: Stack(
                  alignment: Alignment.bottomRight,
                  children: [
                    CircleAvatar(
  radius: 60,
  backgroundColor: Colors.grey.shade200,
  backgroundImage: _imageFile != null
      ? FileImage(_imageFile!) as ImageProvider
      : (user.photoBase64 != null 
          ? MemoryImage(base64Decode(user.photoBase64!)) as ImageProvider
          : (user.photoUrl != null
              ? CachedNetworkImageProvider(user.photoUrl!) as ImageProvider
              : null)),
  child: (_imageFile == null && user.photoBase64 == null && user.photoUrl == null)
      ? Text(
          user.username.isNotEmpty
              ? user.username[0].toUpperCase()
              : '?',
          style: const TextStyle(
            fontSize: 40,
            fontWeight: FontWeight.bold,
            color: Colors.black54,
          ),
        )
      : null,
),
                    if (_isEditing)
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.secondary,
                          shape: BoxShape.circle,
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
              const SizedBox(height: 32),
              
              // Profile Form
              if (_isEditing) ...[
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
                const SizedBox(height: 16),
                
                // Company Dropdown
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
                    CustomDropdown(
                      hintText: 'Select your company',
                      value: _selectedCompany,
                      items: Companies.list,
                      isSearchable: true,
                      onChanged: (String? value) {
                        setState(() {
                          _selectedCompany = value;
                          _customCompanySelected = value == Companies.otherOption;
                        });
                      },
                    ),
                    if (_customCompanySelected) ...[
                      const SizedBox(height: 8),
                      CustomTextField(
                        labelText: 'SPECIFY YOUR COMPANY',
                        controller: _customCompanyController,
                        textInputAction: TextInputAction.next,
                        validator: (value) {
                          if (_customCompanySelected && (value == null || value.isEmpty)) {
                            return 'Please specify your company';
                          }
                          return null;
                        },
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 16),
                
                // Phone Field
                CustomTextField(
                  labelText: 'PHONE NUMBER',
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  textInputAction: TextInputAction.done,
                ),
                const SizedBox(height: 32),
                
                // Update Button
                CustomButton(
                  text: 'SAVE',
                  onPressed: _updateProfile,
                  isLoading: _isLoading,
                  width: 200,
                ),
              ] else ...[
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
                if (user.phoneNumber != null && user.phoneNumber!.isNotEmpty) ...[
                  _buildInfoItem('Phone', user.phoneNumber!),
                  const SizedBox(height: 32),
                ],
              ],
              
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

 Widget _buildInfoItem(String label, String value) {
  return Row(
    mainAxisAlignment: MainAxisAlignment.center, // Keep this
    children: [
      Text(
        '$label: ',
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: Colors.black54,
        ),
      ),
      // Add Expanded widget to handle text overflow
      Expanded(
        child: Text(
          value,
          style: const TextStyle(
            fontSize: 16,
            color: Colors.black,
          ),
          // Add overflow handling
          overflow: TextOverflow.ellipsis,
          maxLines: 2,
        ),
      ),
    ],
  );
}
}