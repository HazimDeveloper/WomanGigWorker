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
  final TextEditingController _locationController = TextEditingController();
  final TextEditingController _feedbackController = TextEditingController();
  double _safetyRating = 3.0;
  LocationModel? _selectedLocation;
  File? _imageFile;
  bool _isLoading = false;
  bool _showSearchResults = false;
  List<LocationModel> _searchResults = [];
  
  // Map related variables
  final GlobalKey<RiskMapState> _mapKey = GlobalKey<RiskMapState>();
  bool _showMap = false;
  bool _isMapSelectionMode = false;
  LatLng? _selectedPosition;
  
  // Tab controller for switching between search and map
  late TabController _tabController;

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
    super.dispose();
  }
  
  void _loadMapData() {
    final locationProvider = Provider.of<LocationProvider>(context, listen: false);
    locationProvider.loadLocations();
    locationProvider.getCurrentLocation();
  }

  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? pickedFile = await picker.pickImage(source: ImageSource.gallery);
    
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
      final results = await locationProvider.searchLocations(query);
      print("Search results: ${results.length} locations found");
      
      if (results.isEmpty) {
        // If no exact matches, try to add the entered text as a new location
        final newLocation = await locationProvider.addLocation(
          name: query,
          latitude: AppGeoConstants.jitraLatitude, // Default to Jitra center
          longitude: AppGeoConstants.jitraLongitude,
        );
        
        if (newLocation != null) {
          results.add(newLocation);
          print("Created new location: ${newLocation.name} with Jitra coordinates");
        }
      }
      
      setState(() {
        _searchResults = results;
        _isLoading = false;
      });
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
    // Check if the location has valid coordinates
    if (location.latitude == 0 || location.longitude == 0) {
      print("Location ${location.name} has invalid coordinates, setting to Jitra center");
      
      // Create a copy with valid coordinates
      final fixedLocation = location.copyWith(
        latitude: AppGeoConstants.jitraLatitude,
        longitude: AppGeoConstants.jitraLongitude
      );
      
      setState(() {
        _selectedLocation = fixedLocation;
        _locationController.text = fixedLocation.name;
        _showSearchResults = false;
      });
      
      // Inform the user that default coordinates are being used
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Using default Jitra coordinates for this location'),
          backgroundColor: Colors.orange,
          duration: Duration(seconds: 2),
        ),
      );
    } else {
      // Check if location is within Jitra
      final locationService = LocationService();
      final bool isInJitra = locationService.isInJitraArea(
        location.latitude, 
        location.longitude
      );
      
      if (!isInJitra) {
        // If outside Jitra, use Jitra center coordinates
        final fixedLocation = location.copyWith(
          latitude: AppGeoConstants.jitraLatitude,
          longitude: AppGeoConstants.jitraLongitude
        );
        
        setState(() {
          _selectedLocation = fixedLocation;
          _locationController.text = fixedLocation.name;
          _showSearchResults = false;
        });
        
        // Inform the user
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Location adjusted to Jitra area'),
            backgroundColor: Colors.orange,
            duration: Duration(seconds: 2),
          ),
        );
      } else {
        // Location is valid and in Jitra
        setState(() {
          _selectedLocation = location;
          _locationController.text = location.name;
          _showSearchResults = false;
        });
      }
    }
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
          content: Text('Selected location is outside Jitra area. Please select a location within Jitra.'),
          backgroundColor: Colors.orange,
        ),
      );
    }
  }

  // Show dialog to name a new location
  void _showAddLocationDialog(LatLng position) {
    final TextEditingController nameController = TextEditingController();
    
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
              controller: nameController,
              decoration: const InputDecoration(
                hintText: 'Location name',
                border: OutlineInputBorder(),
              ),
              autofocus: true,
            ),
            const SizedBox(height: 8),
            Text(
              'Coordinates: ${position.latitude.toStringAsFixed(6)}, ${position.longitude.toStringAsFixed(6)}',
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
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
              final name = nameController.text.trim();
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

    // Validate coordinates
    if (_selectedLocation!.latitude == 0 || _selectedLocation!.longitude == 0) {
      // Fix coordinates before uploading
      _selectedLocation = _selectedLocation!.copyWith(
        latitude: AppGeoConstants.jitraLatitude,
        longitude: AppGeoConstants.jitraLongitude
      );
      
      // Inform the user
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Using default Jitra coordinates for this location'),
          backgroundColor: Colors.orange,
          duration: Duration(seconds: 2),
        ),
      );
    }

    // Check if the selected location is in Jitra area
    final locationService = LocationService();
    final bool isInJitra = locationService.isInJitraArea(
      _selectedLocation!.latitude, 
      _selectedLocation!.longitude
    );
    
    if (!isInJitra) {
      // Adjust coordinates to Jitra center
      _selectedLocation = _selectedLocation!.copyWith(
        latitude: AppGeoConstants.jitraLatitude,
        longitude: AppGeoConstants.jitraLongitude
      );
      
      // Inform the user
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Location adjusted to Jitra area'),
          backgroundColor: Colors.orange,
          duration: Duration(seconds: 2),
        ),
      );
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
      
      // Add feedback with the validated location
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
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Feedback uploaded successfully'),
            backgroundColor: Colors.green,
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
    final locationProvider = Provider.of<LocationProvider>(context);
    final locations = locationProvider.locations;

    return Scaffold(
      backgroundColor: AppColors.primary,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        elevation: 0,
        title: const Text(
          'Add Feedback',
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
              text: 'FEEDBACK',
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
          _buildMapSelection(locations),
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
                  labelText: 'WRITE YOUR FEEDBACK',
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
              child: _isLoading
                  ? const Center(
                      child: Padding(
                        padding: EdgeInsets.all(16.0),
                        child: CircularProgressIndicator(),
                      ),
                    )
                  : _searchResults.isEmpty
                      ? const Center(
                          child: Padding(
                            padding: EdgeInsets.all(16.0),
                            child: Text(
                              'No locations found',
                              style: TextStyle(
                                color: Colors.grey,
                                fontSize: 16,
                              ),
                            ),
                          ),
                        )
                      : ListView.builder(
                          shrinkWrap: true,
                          itemCount: _searchResults.length,
                          itemBuilder: (context, index) {
                            final location = _searchResults[index];
                            return _buildLocationItem(location);
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
  Widget _buildMapSelection(List<LocationModel> locations) {
    return Stack(
      children: [
        Consumer<LocationProvider>(
          builder: (context, locationProvider, _) {
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
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              children: [
                const Text(
                  'Choose a location on the map',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _isMapSelectionMode 
                      ? 'Tap anywhere on the map to add a new location'
                      : 'Tap the button below to start selecting a location',
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
  
  // Build a location item for search results
  Widget _buildLocationItem(LocationModel location) {
    Color statusColor;
    switch (location.safetyLevel) {
      case AppConstants.safeLevelSafe:
        statusColor = AppColors.safeGreen;
        break;
      case AppConstants.safeLevelModerate:
        statusColor = AppColors.moderateYellow;
        break;
      case AppConstants.safeLevelHighRisk:
        statusColor = AppColors.highRiskRed;
        break;
      default:
        statusColor = Colors.grey;
    }

    bool hasValidCoordinates = location.latitude != 0 && location.longitude != 0;

    return ListTile(
      leading: Icon(
        Icons.location_on,
        color: statusColor,
      ),
      title: Row(
        children: [
          Expanded(
            child: Text(
              location.name,
              style: const TextStyle(
                fontWeight: FontWeight.w500,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (!hasValidCoordinates)
            Tooltip(
              message: 'Using Jitra coordinates',
              child: Icon(
                Icons.info_outline,
                color: Colors.orange,
                size: 16,
              ),
            ),
        ],
      ),
      subtitle: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 8,
              vertical: 2,
            ),
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              location.safetyLevel.replaceAll('_', ' ').toUpperCase(),
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: statusColor,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Rating: ${location.averageSafetyRating.toStringAsFixed(1)} (${location.ratingCount})',
              style: const TextStyle(
                fontSize: 12,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
      onTap: () => _selectLocation(location),
    );
  }
}