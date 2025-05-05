import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:trust_me/models/user_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/user_provider.dart';
import '../../widgets/common/custom_button.dart';
import '../../widgets/common/custom_text_field.dart';
import '../../widgets/common/custom_dropdown.dart';
import '../../utils/job_categories.dart';
import '../../config/constants.dart';
import '../../screens/common/login_screen.dart';
import '../../utils/image_util.dart';

class BuddyProfileScreen extends StatefulWidget {
  static const String routeName = '/buddy/profile';

  const BuddyProfileScreen({Key? key}) : super(key: key);

  @override
  State<BuddyProfileScreen> createState() => _BuddyProfileScreenState();
}

class _BuddyProfileScreenState extends State<BuddyProfileScreen> with AutomaticKeepAliveClientMixin {
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
  bool _dataLoaded = false;
  Uint8List? _imagePreview; // For showing the selected image before upload

  // AutomaticKeepAliveClientMixin override
  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    // Use Future.microtask to prevent build-time issues
    Future.microtask(() {
      if (mounted) {
        _loadUserData();
      }
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_dataLoaded) {
      _loadUserData();
      _dataLoaded = true;
    }
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
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 80,
      );
      
      if (pickedFile != null) {
        setState(() {
          _imageFile = File(pickedFile.path);
        });
        
        // Create a preview of the image
        final bytes = await _imageFile!.readAsBytes();
        setState(() {
          _imagePreview = bytes;
        });
      }
    } catch (e) {
      print("Error picking image: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error selecting image: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
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
          throw Exception('Failed to process image');
        }
      }
      
      // Determine job value (custom or selected)
      final String jobValue = _customJobSelected && _customJobController.text.isNotEmpty
          ? _customJobController.text.trim()
          : _selectedJob ?? '';
          
      // Determine company value (custom or selected)
      final String companyValue = _customCompanySelected && _customCompanyController.text.isNotEmpty
          ? _customCompanyController.text.trim()
          : _selectedCompany ?? '';
      
      // Update user details with the new photo URL if available
      final success = await Provider.of<AuthProvider>(context, listen: false).updateUser(
        job: jobValue,
        company: companyValue,
        phoneNumber: _phoneController.text.trim(),
        photoBase64: photoBase64,
      );
      
      if (success && mounted) {
        setState(() {
          _isEditing = false;
          _imageFile = null; // Reset the image file after successful upload
          _imagePreview = null;
        });
        
        // Refresh user data
        Provider.of<AuthProvider>(context, listen: false).refreshUserData();
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profile updated successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      print("Error updating profile: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error updating profile: ${e.toString()}'),
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
    super.build(context); // Required for AutomaticKeepAliveClientMixin
    
    return Selector<AuthProvider, UserModel?>(
      selector: (_, authProvider) => authProvider.user,
      builder: (context, user, _) {
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
              'MY PROFILE',
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
                      _imagePreview = null;
                    });
                  },
                ),
            ],
          ),
          body: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
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
                                      color: AppColors.secondary.withOpacity(0.5),
                                      width: 3,
                                    ),
                                  ),
                                  child: _buildProfileImage(user),
                                ),
                                if (_isEditing)
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: AppColors.secondary,
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
                          ),
                          const SizedBox(height: 8),
                          
                          // Email
                          Text(
                            user.email,
                            style: const TextStyle(
                              fontSize: 16,
                              color: Colors.black54,
                            ),
                          ),
                          const SizedBox(height: 16),
                          
                          // Buddy Badge
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            decoration: BoxDecoration(
                              color: AppColors.secondary.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: AppColors.secondary),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.verified_user,
                                  color: AppColors.secondary,
                                  size: 18,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Buddy User',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.secondary,
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
                      _buildEditForm(),
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
          ),
        );
      },
    );
  }

  Widget _buildProfileImage(UserModel user) {
    // Display image preview if available (for newly selected images)
    if (_imagePreview != null) {
      return CircleAvatar(
        radius: 56,
        backgroundColor: Colors.grey.shade200,
        backgroundImage: MemoryImage(_imagePreview!),
      );
    }
    // Display already uploaded base64 image
    else if (user.photoBase64 != null && user.photoBase64!.isNotEmpty) {
      try {
        return CircleAvatar(
          radius: 56,
          backgroundColor: Colors.grey.shade200,
          backgroundImage: MemoryImage(base64Decode(user.photoBase64!)),
        );
      } catch (e) {
        print("Error decoding base64 image: $e");
      }
    }
    // Display network image if available
    else if (user.photoUrl != null && user.photoUrl!.isNotEmpty) {
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

  Widget _buildInfoSection(UserModel user) {
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
            _buildInfoItem(Icons.work, 'Job', user.job!),
            const SizedBox(height: 16),
          ],
          
          // Display company info
          if (user.company != null && user.company!.isNotEmpty) ...[
            _buildInfoItem(Icons.business, 'Company', user.company!),
            const SizedBox(height: 16),
          ],
          
          // Display phone info
          if (user.phoneNumber != null && user.phoneNumber!.isNotEmpty)
            _buildInfoItem(Icons.phone, 'Phone', user.phoneNumber!),
        ],
      ),
    );
  }

  Widget _buildInfoItem(IconData icon, String label, String value) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColors.secondary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            color: AppColors.secondary,
            size: 20,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.grey,
                ),
              ),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: Colors.black,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildEditForm() {
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
            ),
          ),
        ],
      ),
    );
  }
}