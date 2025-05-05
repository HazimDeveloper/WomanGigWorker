import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';
import 'package:trust_me/services/location_service.dart';
import 'package:trust_me/widgets/map_legend.dart';
import '../../providers/location_provider.dart';
import '../../widgets/location_search.dart';
import '../../widgets/risk_map.dart';
import '../../config/constants.dart';
import '../../models/location_model.dart';
import 'package:uuid/uuid.dart';

class CustomerMapScreen extends StatefulWidget {
  static const String routeName = '/customer/map';

  const CustomerMapScreen({Key? key}) : super(key: key);

  @override
  State<CustomerMapScreen> createState() => _CustomerMapScreenState();
}

class _CustomerMapScreenState extends State<CustomerMapScreen> {
  final GlobalKey<RiskMapState> _mapKey = GlobalKey<RiskMapState>();
  final Uuid _uuid = const Uuid();
  
  List<LocationModel> _searchResults = [];
  bool _isLoading = false;
  bool _showSearch = false;
  bool _isInSelectionMode = false;
  LatLng? _selectedPosition;
  String _newLocationName = "";
  TextEditingController _locationNameController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadLocations();
  }

  @override
  void dispose() {
    _locationNameController.dispose();
    super.dispose();
  }

  void _loadLocations() {
    final locationProvider = Provider.of<LocationProvider>(context, listen: false);
    locationProvider.loadLocations();
    locationProvider.getCurrentLocation();
  }

  Future<void> _searchLocations(String query) async {
    // Existing search implementation...
  }

  void _handleLocationSelected(LocationModel location) {
    final position = LatLng(location.latitude, location.longitude);
    _mapKey.currentState?.animateToPosition(position);
    
    // Show location details bottom sheet
    _showLocationDetailsBottomSheet(location);
  }

  // Add a new method to handle map taps
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

  // Add a method to show a dialog for adding a new location
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
                _isInSelectionMode = false;
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
                _isInSelectionMode = false;
              });
            },
            child: const Text('ADD'),
          ),
        ],
      ),
    );
  }

  // Add a method to create a new location
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
        
        // Show the location details
        _handleLocationSelected(newLocation);
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

  void _showLocationDetailsBottomSheet(LocationModel location) {
    // Existing implementation...
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Consumer<LocationProvider>(
        builder: (context, locationProvider, _) {
          final currentPosition = locationProvider.currentPosition;
          final locations = locationProvider.locations;
          final isLoading = locationProvider.isLoading;

          return Stack(
            children: [
              // Map
              if (isLoading && currentPosition == null)
                const Center(
                  child: CircularProgressIndicator(),
                )
              else
                RiskMap(
                  key: _mapKey,
                  locations: locations,
                  initialPosition: currentPosition != null
                      ? LatLng(currentPosition.latitude, currentPosition.longitude)
                      : null,
                  onLocationSelected: _handleLocationSelected,
                  onMapTapped: _handleMapTapped, // Add this
                ),

              // Search Bar
              Positioned(
                top: MediaQuery.of(context).padding.top + 16,
                left: 16,
                right: 16,
                child: GestureDetector(
                  onTap: () {
                    setState(() {
                      _showSearch = true;
                    });
                  },
                  child: Container(
                    height: 50,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
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
                    child: Row(
                      children: const [
                        Icon(Icons.search, color: Colors.grey),
                        SizedBox(width: 8),
                        Text(
                          'Search location...',
                          style: TextStyle(
                            color: Colors.grey,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
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
                  backgroundColor: _isInSelectionMode ? Colors.orange : AppColors.secondary,
                  onPressed: () {
                    setState(() {
                      _isInSelectionMode = !_isInSelectionMode;
                    });
                    _mapKey.currentState?.setSelectionMode(_isInSelectionMode);
                    
                    if (_isInSelectionMode) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Tap anywhere on the map to add a new location in Jitra area'),
                          duration: Duration(seconds: 3),
                        ),
                      );
                    }
                  },
                  child: Icon(
                    _isInSelectionMode ? Icons.close : Icons.add_location_alt,
                    color: Colors.white,
                  ),
                ),
              ),

              // Search Panel (fullscreen when active)
              if (_showSearch)
                Positioned.fill(
                  child: Container(
                    color: Colors.white,
                    child: Column(
                      children: [
                        AppBar(
                          backgroundColor: Colors.white,
                          elevation: 0,
                          leading: IconButton(
                            icon: const Icon(Icons.arrow_back, color: Colors.black),
                            onPressed: () {
                              setState(() {
                                _showSearch = false;
                                _searchResults = [];
                              });
                            },
                          ),
                          title: const Text(
                            'Search Location',
                            style: TextStyle(
                              color: Colors.black,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        Expanded(
                          child: LocationSearch(
                            onSearch: _searchLocations,
                            onLocationSelected: (location) {
                              setState(() {
                                _showSearch = false;
                              });
                              _handleLocationSelected(location);
                            },
                            searchResults: _searchResults,
                            isLoading: _isLoading,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                
              // Loading indicator
              if (_isLoading)
                Container(
                  color: Colors.black.withOpacity(0.3),
                  child: const Center(
                    child: CircularProgressIndicator(),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}