import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';
import 'package:trust_me/widgets/map_legend.dart';
import '../../providers/location_provider.dart';
import '../../widgets/location_search.dart';
import '../../widgets/risk_map.dart';
import '../../config/constants.dart';
import '../../models/location_model.dart';

class BuddyMapScreen extends StatefulWidget {
  static const String routeName = '/buddy/map';

  const BuddyMapScreen({Key? key}) : super(key: key);

  @override
  State<BuddyMapScreen> createState() => _BuddyMapScreenState();
}

class _BuddyMapScreenState extends State<BuddyMapScreen> with AutomaticKeepAliveClientMixin {
  final GlobalKey<RiskMapState> _mapKey = GlobalKey<RiskMapState>();
  List<LocationModel> _searchResults = [];
  bool _isSearching = false;
  bool _showSearch = false;
  bool _dataLoaded = false;

  // AutomaticKeepAliveClientMixin override
  @override
  bool get wantKeepAlive => true;

@override
void initState() {
  super.initState();
  // Load locations with a small delay to ensure everything is initialized
  Future.delayed(Duration(milliseconds: 300), () {
    if (mounted) {
      _forceLoadLocations();
    }
  });
}

void _forceLoadLocations() {
  final locationProvider = Provider.of<LocationProvider>(context, listen: false);
  
  // First clear any existing data
  locationProvider.clearData();
  
  // Then load fresh data
  print("Force loading locations and current position");
  locationProvider.loadLocations();
  locationProvider.getCurrentLocation();
  
  // After a delay, check if we got data
  Future.delayed(Duration(seconds: 2), () {
    if (mounted) {
      final locations = locationProvider.locations;
      print("After force load: ${locations.length} locations available");
      
      if (locations.isEmpty) {
        // If still empty, try adding a sample location
        print("Still no locations, adding sample");
        _addSampleLocation(locationProvider);
      }
    }
  });
}

Future<void> _addSampleLocation(LocationProvider provider) async {
  try {
    await provider.addLocation(
      name: "Jitra Center",
      latitude: 6.2641,
      longitude: 100.4214,
    );
    print("Added sample location");
  } catch (e) {
    print("Error adding sample location: $e");
  }
}

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_dataLoaded) {
      _loadLocations();
      _dataLoaded = true;
    }
  }

void _loadLocations() {
  try {
    final locationProvider = Provider.of<LocationProvider>(context, listen: false);
    locationProvider.loadLocations();
    locationProvider.getCurrentLocation();
    print("Location provider: loadLocations and getCurrentLocation called");
  } catch (e) {
    print("Error loading locations: $e");
  }
}

 Future<void> _searchLocations(String query) async {
  if (query.isEmpty) {
    setState(() {
      _searchResults = [];
    });
    return;
  }

  setState(() {
    _isSearching = true;
  });

  try {
    final locationProvider = Provider.of<LocationProvider>(context, listen: false);
    
    // Use the new method that directly returns locations with feedback
    final results = await locationProvider.searchLocationsWithFeedback(query);
    
    setState(() {
      _searchResults = results;
      _isSearching = false;
    });
    
    // Show message if no results
    if (results.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No locations with feedback found matching your search'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  } catch (e) {
    print("Search error: $e");
    setState(() {
      _isSearching = false;
    });
  }
}

  void _handleLocationSelected(LocationModel location) {
    final position = LatLng(location.latitude, location.longitude);
    _mapKey.currentState?.animateToPosition(position);
    
    // Show location details bottom sheet
    _showLocationDetailsBottomSheet(location);
  }

  void _showLocationDetailsBottomSheet(LocationModel location) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true, // Allow for larger sheet
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
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

        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.location_on,
                    color: statusColor,
                    size: 24,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      location.name,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(color: statusColor),
                    ),
                    child: Text(
                      location.safetyLevel.replaceAll('_', ' ').toUpperCase(),
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: statusColor,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Icon(
                    Icons.star,
                    color: Colors.amber,
                    size: 20,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${location.averageSafetyRating.toStringAsFixed(1)} (${location.ratingCount} ${location.ratingCount == 1 ? 'review' : 'reviews'})',
                    style: const TextStyle(
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // Information instead of action button
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.secondary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      color: AppColors.secondary,
                    ),
                    const SizedBox(width: 8),
                    const Expanded(
                      child: Text(
                        'As a Buddy user, you can view location safety information but cannot add feedback.',
                        style: TextStyle(fontSize: 13),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // Required for AutomaticKeepAliveClientMixin
    
    return Scaffold(
      body: Consumer<LocationProvider>(
        builder: (context, locationProvider, _) {
          final currentPosition = locationProvider.currentPosition;
          final locations = locationProvider.locations;
          final isLoading = locationProvider.isLoading;

       // Debug print to check locations
        print("Map screen received ${locations.length} locations");
        
        // Check for valid locations
        if (locations.isEmpty && !isLoading) {
          // If no locations and not loading, force a reload
          print("No locations available, triggering reload");
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              locationProvider.loadLocations();
            }
          });
        }

          return Stack(
            children: [
              // Map
              if (isLoading && currentPosition == null && locations.isEmpty)
                const Center(
                  child: CircularProgressIndicator(),
                )
              else
                 Column(
                children: [
                  // Small debug text at top of map (remove in production)
                  Container(
                    color: Colors.white.withOpacity(0.7),
                    padding: const EdgeInsets.all(4),
                    child: Text(
                      "Locations: ${locations.length}",
                      style: TextStyle(fontSize: 10, color: Colors.black),
                    ),
                  ),
                  // The actual map
                  Expanded(
                    child: RiskMap(
                      key: _mapKey,
                      locations: locations,
                      initialPosition: currentPosition != null
                          ? LatLng(currentPosition.latitude, currentPosition.longitude)
                          : null,
                      onLocationSelected: _handleLocationSelected,
                    ),
                  ),
                ],
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

              // Buddy Status Indicator
              Positioned(
                top: MediaQuery.of(context).padding.top + 80,
                left: 16,
                right: 16,
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                  decoration: BoxDecoration(
                    color: AppColors.secondary.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.secondary),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.verified_user,
                        color: AppColors.secondary,
                        size: 16,
                      ),
                      const SizedBox(width: 8),
                      const Expanded(
                        child: Text(
                          'Buddy Mode: View-only access',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                      ),
                    ],
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
                            isLoading: _isSearching,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}