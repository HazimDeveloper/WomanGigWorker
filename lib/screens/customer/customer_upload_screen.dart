import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:trust_me/widgets/map_legend.dart';
import '../../providers/auth_provider.dart';
import '../../providers/location_provider.dart';
import '../../widgets/common/custom_button.dart';
import '../../widgets/common/custom_text_field.dart';
import '../../widgets/location_search.dart';
import '../../widgets/risk_map.dart';
import '../../config/constants.dart';
import '../../models/location_model.dart';
import '../../services/storage_service.dart';
import '../../utils/image_util.dart';
import '../../services/location_service.dart';

class CustomerUploadScreen extends StatefulWidget {
  static const String routeName = '/customer/upload';

  const CustomerUploadScreen({Key? key}) : super(key: key);

  @override
  State<CustomerUploadScreen> createState() => _CustomerUploadScreenState();
}

class _CustomerUploadScreenState extends State<CustomerUploadScreen> with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final GlobalKey<RiskMapState> _mapKey = GlobalKey<RiskMapState>();
  final TextEditingController _locationController = TextEditingController();
  final TextEditingController _feedbackController = TextEditingController();
  double _safetyRating = 3.0;
  LocationModel? _selectedLocation;
  File? _imageFile;
  bool _isLoading = false;
  bool _showSearchResults = false;
  List<LocationModel> _searchResults = [];
  
  // Map related variables
  bool _showMap = false;
  bool _isMapSelectionMode = false;
  LatLng? _selectedPosition;
  
  // Tab controller for switching between search and map
  late TabController _tabController;
  final TextEditingController _locationNameController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      if (_tabController.index == 1) {
        // When switching to map tab, ensure map is loaded
        _loadMapData();
      }
    });
  }

  @override
  void dispose() {
    _locationController.dispose();
    _feedbackController.dispose();
    _tabController.dispose();
    _locationNameController.dispose();
    super.dispose();
  }
  
  void _loadMapData() {
    final locationProvider = Provider.of<LocationProvider>(context, listen: false);
    locationProvider.loadLocations();
    locationProvider.getCurrentLocation();
  }

  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? pickedFile = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 800, // Optimize image size
      maxHeight: 800,
      imageQuality: 70,
    );
    
    if (pickedFile != null) {
      setState(() {
        _imageFile = File(pickedFile.path);
      });
    }
  }

  Future<void> _searchLocations(String query) async {
    if (query.isEmpty) {
      setState(() {
        _searchResults = [];
        _showSearchResults = false;
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _showSearchResults = true;
    });

    try {
      print("Searching for locations with query: $query");
      
      final locationProvider = Provider.of<LocationProvider>(context, listen: false);
      
      // Use the method that specifically searches for locations with feedback
      final results = await locationProvider.searchLocationsWithFeedback(query);
      
      // Filter to only include locations within Jitra
      final locationService = LocationService();
      final filteredResults = results.where((location) {
        // Skip invalid coordinates and locations outside Jitra
        if (location.latitude == 0 || location.longitude == 0) {
          return false;
        }
        return locationService.isInJitraArea(location.latitude, location.longitude);
      }).toList();
      
      setState(() {
        _searchResults = filteredResults;
        _isLoading = false;
      });
      
      print("Filtered to ${filteredResults.length} locations in Jitra with feedback");
      
    } catch (e) {
      print("Error searching locations: $e");
      setState(() {
        _isLoading = false;
      });
      
      // Show error message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error searching locations: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _selectLocation(LocationModel location) {
    // Check if the location has valid coordinates and is in Jitra
    final locationService = LocationService();
    final bool isInJitra = locationService.isInJitraArea(
      location.latitude, 
      location.longitude
    );
    
    if (location.latitude == 0 || location.longitude == 0 || !isInJitra) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Cannot select location outside Jitra area or with invalid coordinates'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() {
      _selectedLocation = location;
      _locationController.text = location.name;
      _showSearchResults = false;
    });
    
    // Switch back to form tab
    _tabController.animateTo(0);
    
    // Show confirmation
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Selected location: ${location.name}'),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  // Handle map tap for selecting a location
  void _handleMapTapped(LatLng position) {
    setState(() {
      _selectedPosition = position;
    });
    
    // Check if position is in Jitra
    final locationService = LocationService();
    final bool isInJitra = locationService.isInJitraArea(
      position.latitude, 
      position.longitude
    );
    
    if (isInJitra) {
      // Show dialog to add new location
      _showAddLocationDialog(position);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Selected location is outside Jitra area. Please select a location within the blue boundary.'),
          backgroundColor: Colors.orange,
        ),
      );
    }
  }

  // Show dialog to name a new location
  void _showAddLocationDialog(LatLng position) {
    _locationNameController.text = ""; // Clear previous input
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add New Location'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Enter a name for this location:'),
            const SizedBox(height: 12),
            TextField(
              controller: _locationNameController,
              decoration: const InputDecoration(
                hintText: 'Location name',
                border: OutlineInputBorder(),
              ),
              autofocus: true,
              textCapitalization: TextCapitalization.words,
            ),
            const SizedBox(height: 8),
            Text(
              'Coordinates: ${position.latitude.toStringAsFixed(6)}, ${position.longitude.toStringAsFixed(6)}',
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
            const SizedBox(height: 8),
            const Text(
              'This location will be added to the map if approved.',
              style: TextStyle(fontSize: 12, color: Colors.blue),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              // Exit selection mode
              _mapKey.currentState?.setSelectionMode(false);
              setState(() {
                _isMapSelectionMode = false;
              });
            },
            child: const Text('CANCEL'),
          ),
          ElevatedButton(
            onPressed: () async {
              final name = _locationNameController.text.trim();
              if (name.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Please enter a location name'),
                    backgroundColor: Colors.red,
                  ),
                );
                return;
              }
              
              // Close dialog
              Navigator.of(context).pop();
              
              // Add the new location
              await _addNewLocation(name, position);
              
              // Exit selection mode
              _mapKey.currentState?.setSelectionMode(false);
              setState(() {
                _isMapSelectionMode = false;
              });
            },
            child: const Text('ADD'),
          ),
        ],
      ),
    );
  }

  // Add a new location from map selection
  Future<void> _addNewLocation(String name, LatLng position) async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      final locationProvider = Provider.of<LocationProvider>(context, listen: false);
      
      // Create a new location
      final newLocation = await locationProvider.addLocation(
        name: name,
        latitude: position.latitude,
        longitude: position.longitude,
      );
      
      if (newLocation != null) {
        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Location "$name" added successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        
        // Select the new location
        _selectLocation(newLocation);
        
        // Switch back to form tab
        _tabController.animateTo(0);
        
        // Force map data refresh
        locationProvider.loadLocations();
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error adding location: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _uploadFeedback() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_selectedLocation == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a location'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Validate coordinates and location
    final locationService = LocationService();
    final bool isInJitra = locationService.isInJitraArea(
      _selectedLocation!.latitude, 
      _selectedLocation!.longitude
    );
    
    if (_selectedLocation!.latitude == 0 || _selectedLocation!.longitude == 0 || !isInJitra) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Selected location is invalid or outside Jitra area. Please select a different location.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final user = Provider.of<AuthProvider>(context, listen: false).user!;
      
      // Process image if available
      String? imageBase64;
      
      if (_imageFile != null) {
        imageBase64 = await ImageUtil.fileToBase64(_imageFile!);
        if (imageBase64 == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Could not process image. Continuing without image.'),
              backgroundColor: Colors.orange,
            ),
          );
        }
      }
      
      // Add feedback
      final success = await Provider.of<LocationProvider>(context, listen: false).addFeedback(
        user: user,
        locationId: _selectedLocation!.id,
        locationName: _selectedLocation!.name,
        safetyRating: _safetyRating,
        feedback: _feedbackController.text.trim(),
        imageBase64: imageBase64,
      );
      
      if (success && mounted) {
        // Reset form and show success message
        _locationController.clear();
        _feedbackController.clear();
        setState(() {
          _safetyRating = 3.0;
          _selectedLocation = null;
          _imageFile = null;
        });
        
        // Force refresh map data
        final locationProvider = Provider.of<LocationProvider>(context, listen: false);
        locationProvider.loadLocations();
        locationProvider.loadFeedback();
        
        // Switch to the map tab to show the updated information
        _tabController.animateTo(1);
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Feedback uploaded successfully! Check the map to see updated safety information.'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 4),
          ),
        );
      }
    } catch (e) {
      print("Error uploading feedback: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error uploading feedback. Please try again.'),
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
    return Scaffold(
      backgroundColor: AppColors.primary,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        elevation: 0,
        title: const Text(
          'ADD SAFETY INFORMATION',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
        centerTitle: true,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppColors.secondary,
          labelColor: Colors.black,
          tabs: const [
            Tab(
              text: 'SAFETY INFORMATION',
              icon: Icon(Icons.feedback),
            ),
            Tab(
              text: 'MAP',
              icon: Icon(Icons.map),
            ),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // Tab 1: Feedback Form
          _buildFeedbackForm(),
          
          // Tab 2: Map Selection
          _buildMapSelection(),
        ],
      ),
    );
  }

  // Build the feedback form tab
  Widget _buildFeedbackForm() {
    return Stack(
      children: [
        SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Location Search
                const Text(
                  'LOCATION',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 8),
                GestureDetector(
                  onTap: () {
                    FocusScope.of(context).unfocus();
                    setState(() {
                      _showSearchResults = _locationController.text.isNotEmpty;
                    });
                  },
                  child: Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _locationController,
                          decoration: InputDecoration(
                            hintText: 'Search location...',
                            prefixIcon: const Icon(Icons.location_on, color: Colors.grey),
                            filled: true,
                            fillColor: Colors.white,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 16,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide.none,
                            ),
                          ),
                          onChanged: _searchLocations,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please select a location';
                            }
                            return null;
                          },
                          readOnly: true, // Make it read-only to enforce selection from search
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        icon: const Icon(Icons.map),
                        color: AppColors.secondary,
                        tooltip: 'Select on Map',
                        onPressed: () {
                          // Switch to map tab
                          _tabController.animateTo(1);
                        },
                      ),
                    ],
                  ),
                ),
                if (_selectedLocation != null) ...[
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.5),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.location_on, size: 16, color: Colors.black54),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            'Coordinates: ${_selectedLocation!.latitude.toStringAsFixed(6)}, ${_selectedLocation!.longitude.toStringAsFixed(6)}',
                            style: const TextStyle(fontSize: 12, color: Colors.black54),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 24),
                
                // Safety Rating
                const Text(
                  'SAFETY RATE',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 8),
                Center(
                  child: RatingBar.builder(
                    initialRating: _safetyRating,
                    minRating: 1,
                    direction: Axis.horizontal,
                    allowHalfRating: true,
                    itemCount: 5,
                    itemSize: 36,
                    itemPadding: const EdgeInsets.symmetric(horizontal: 4.0),
                    itemBuilder: (context, _) => const Icon(
                      Icons.star,
                      color: Colors.amber,
                    ),
                    onRatingUpdate: (rating) {
                      setState(() {
                        _safetyRating = rating;
                      });
                    },
                  ),
                ),
                const SizedBox(height: 24),
                
                // Feedback Text
                CustomTextField(
                  labelText: 'WRITE YOUR CAPTION',
                  hintText: 'Share your experience at this location...',
                  controller: _feedbackController,
                  keyboardType: TextInputType.multiline,
                  textInputAction: TextInputAction.newline,
                  maxLines: 5,
                  minLines: 3,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your feedback';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 24),
                
                // Image Upload
                const Text(
                  'ADD IMAGE',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 8),
                GestureDetector(
                  onTap: _pickImage,
                  child: Container(
                    height: 150,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: Colors.grey.shade300,
                        width: 1,
                      ),
                    ),
                    child: _imageFile != null
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.file(
                              _imageFile!,
                              fit: BoxFit.cover,
                            ),
                          )
                        : Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: const [
                              Icon(
                                Icons.add_photo_alternate,
                                size: 48,
                                color: Colors.grey,
                              ),
                              SizedBox(height: 8),
                              Text(
                                'Tap to add an image',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey,
                                ),
                              ),
                            ],
                          ),
                  ),
                ),
                const SizedBox(height: 32),
                
                // Submit Button
                Center(
                  child: CustomButton(
                    text: 'POST',
                    onPressed: _uploadFeedback,
                    isLoading: _isLoading,
                    width: 200,
                  ),
                ),
              ],
            ),
          ),
        ),
        
        // Location Search Results
        if (_showSearchResults)
          Positioned(
            top: 80, // Below the location search field
            left: 16,
            right: 16,
            child: Container(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.4,
              ),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Consumer<LocationProvider>(
                builder: (context, locationProvider, _) {
                  return LocationSearch(
                    onSearch: _searchLocations,
                    onLocationSelected: _selectLocation,
                    searchResults: _searchResults,
                    isLoading: _isLoading,
                    emptyMessage: 'No locations found with feedback',
                  );
                },
              ),
            ),
          ),
        
        // Loading overlay
        if (_isLoading)
          Container(
            color: Colors.black.withOpacity(0.3),
            child: const Center(
              child: CircularProgressIndicator(),
            ),
          ),
      ],
    );
  }

  // Build the map selection tab
  Widget _buildMapSelection() {
    return Stack(
      children: [
        Consumer<LocationProvider>(
          builder: (context, locationProvider, _) {
            final List<LocationModel> locations = locationProvider.locations;
            final currentPosition = locationProvider.currentPosition;
            
            return RiskMap(
              key: _mapKey,
              locations: locations,
              initialPosition: currentPosition != null
                  ? LatLng(currentPosition.latitude, currentPosition.longitude)
                  : null,
              onLocationSelected: _selectLocation,
              onMapTapped: _handleMapTapped, // Handle map taps
            );
          },
        ),
        
        // Map Legend
        const Positioned(
          bottom: 16,
          right: 16,
          child: MapLegend(),
        ),
        
        // Add Location Button
        Positioned(
          bottom: 80,
          right: 16,
          child: FloatingActionButton(
            backgroundColor: _isMapSelectionMode ? Colors.orange : AppColors.secondary,
            onPressed: () {
              setState(() {
                _isMapSelectionMode = !_isMapSelectionMode;
              });
              _mapKey.currentState?.setSelectionMode(_isMapSelectionMode);
              
              if (_isMapSelectionMode) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Tap anywhere on the map to add a new location in Jitra area'),
                    duration: Duration(seconds: 3),
                  ),
                );
              }
            },
            child: Icon(
              _isMapSelectionMode ? Icons.close : Icons.add_location_alt,
              color: Colors.white,
            ),
          ),
        ),
        
        // Help Text
        Positioned(
          top: 16,
          left: 16,
          right: 16,
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              children: [
                Row(
                  children: const [
                    Icon(Icons.info_outline, color: Colors.blue, size: 16),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'You can only add feedback for locations within Jitra area (blue circle)',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  _isMapSelectionMode 
                      ? 'Tap anywhere on the map to add a new location'
                      : 'Tap on existing locations or use the + button to add a new one',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[700],
                  ),
                ),
              ],
            ),
          ),
        ),
        
        // Loading overlay
        if (_isLoading)
          Container(
            color: Colors.black.withOpacity(0.3),
            child: const Center(
              child: CircularProgressIndicator(),
            ),
          ),
      ],
    );
  }
}