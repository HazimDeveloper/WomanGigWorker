import 'package:flutter/material.dart';
import '../models/location_model.dart';
import '../config/constants.dart';

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

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
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
                            child: Text(
                              widget.emptyMessage,
                              style: const TextStyle(
                                color: Colors.grey,
                                fontSize: 16,
                              ),
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
          // Show coordinate status icon
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
      onTap: () {
        // Before returning the location, ensure it has valid coordinates
        LocationModel locationToReturn = location;
        
        // If no valid coordinates, fix them with Jitra coordinates
        if (!hasValidCoordinates) {
          locationToReturn = location.copyWith(
            latitude: AppGeoConstants.jitraLatitude,
            longitude: AppGeoConstants.jitraLongitude
          );
        }
        
        widget.onLocationSelected(locationToReturn);
      },
    );
  }
}