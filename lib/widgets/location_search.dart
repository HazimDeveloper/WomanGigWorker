import 'package:flutter/material.dart';
import '../models/location_model.dart';
import '../config/constants.dart';
import '../providers/location_provider.dart';
import 'package:provider/provider.dart';
import '../services/location_service.dart';

class LocationSearch extends StatefulWidget {
  final Function(String query) onSearch;
  final Function(LocationModel location) onLocationSelected;
  final List<LocationModel> searchResults;
  final bool isLoading; // Use this instead of separate isSearching
  final String emptyMessage;

  const LocationSearch({
    Key? key,
    required this.onSearch,
    required this.onLocationSelected,
    required this.searchResults,
    this.isLoading = false,
    this.emptyMessage = 'No locations found',
  }) : super(key: key);

  @override
  State<LocationSearch> createState() => _LocationSearchState();
}

class _LocationSearchState extends State<LocationSearch> {
  final TextEditingController _searchController = TextEditingController();
  bool _showResults = false;
  List<LocationModel> _feedbackLocations = [];
  bool _loadingLocations = false;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
    _loadFeedbackLocations();
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  // Load locations that have feedback
  Future<void> _loadFeedbackLocations() async {
    setState(() {
      _loadingLocations = true;
    });

    try {
      // Get locations with feedback from LocationProvider
      final locationProvider = Provider.of<LocationProvider>(context, listen: false);
      final locationsWithFeedback = locationProvider.getLocationsWithFeedback();
      
      setState(() {
        _feedbackLocations = locationsWithFeedback;
        _loadingLocations = false;
      });
      
      print("Loaded ${_feedbackLocations.length} locations with feedback for search");
    } catch (e) {
      print("Error loading feedback locations: $e");
      setState(() {
        _loadingLocations = false;
      });
    }
  }

  void _onSearchChanged() {
    final String query = _searchController.text.trim();
    if (query.isEmpty) {
      setState(() {
        _showResults = false;
      });
    } else {
      setState(() {
        _showResults = true;
      });
      widget.onSearch(query);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Search TextField
        Container(
          margin: const EdgeInsets.all(16),
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
          child: TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Search location...',
              prefixIcon: const Icon(Icons.search, color: Colors.grey),
              suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear, color: Colors.grey),
                      onPressed: () {
                        _searchController.clear();
                        setState(() {
                          _showResults = false;
                        });
                      },
                    )
                  : null,
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 14,
              ),
            ),
          ),
        ),

        // Feedback Locations Info
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 16),
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.9),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: Row(
            children: [
              const Icon(Icons.info_outline, color: Colors.blue, size: 16),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'You can only add feedback to locations within Jitra area. Search from ${_feedbackLocations.length} locations with existing feedback, or add a new location on the map.',
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.black87,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),

        // Recently Used Locations
        if (!_showResults && _feedbackLocations.isNotEmpty)
          Expanded(
            child: Container(
              color: Colors.white,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Padding(
                    padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
                    child: Text(
                      'LOCATIONS WITH FEEDBACK',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.black54,
                      ),
                    ),
                  ),
                  Expanded(
                    child: _loadingLocations
                        ? const Center(child: CircularProgressIndicator())
                        : ListView.builder(
                            itemCount: _feedbackLocations.length,
                            itemBuilder: (context, index) {
                              return _buildLocationItem(_feedbackLocations[index]);
                            },
                          ),
                  ),
                ],
              ),
            ),
          ),

        // Search Results
        if (_showResults)
          Expanded(
            child: Container(
              color: Colors.white,
              child: widget.isLoading
                  ? const Center(
                      child: Padding(
                        padding: EdgeInsets.all(16.0),
                        child: CircularProgressIndicator(),
                      ),
                    )
                  : widget.searchResults.isEmpty
                      ? Center(
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.search_off,
                                  color: Colors.grey,
                                  size: 48,
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  widget.emptyMessage,
                                  style: const TextStyle(
                                    color: Colors.grey,
                                    fontSize: 16,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                const Text(
                                  'Try another search term or add a new location on the map',
                                  style: TextStyle(
                                    color: Colors.grey,
                                    fontSize: 14,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          ),
                        )
                      : ListView.builder(
                          shrinkWrap: true,
                          itemCount: widget.searchResults.length,
                          itemBuilder: (context, index) {
                            final location = widget.searchResults[index];
                            return _buildLocationItem(location);
                          },
                        ),
            ),
          ),
      ],
    );
  }

  Widget _buildLocationItem(LocationModel location) {
    // Check if coordinates exist
    bool hasValidCoordinates = location.latitude != 0 && location.longitude != 0;
    
    // Determine status color
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

    // Check if location is in Jitra
    final bool isInJitra = LocationService().isInJitraArea(
      location.latitude, 
      location.longitude
    );

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
          // Show warning icon for invalid locations
          if (!hasValidCoordinates || !isInJitra)
            Tooltip(
              message: !hasValidCoordinates 
                  ? 'Invalid coordinates' 
                  : 'Outside Jitra area',
              child: Icon(
                Icons.warning_amber_rounded,
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
      // Only allow selection for valid locations within Jitra
      onTap: hasValidCoordinates && isInJitra 
        ? () => widget.onLocationSelected(location)
        : () {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  !hasValidCoordinates
                      ? 'This location has invalid coordinates'
                      : 'This location is outside Jitra area',
                  style: const TextStyle(color: Colors.white),
                ),
                backgroundColor: Colors.orange,
              ),
            );
          },
    );
  }
}