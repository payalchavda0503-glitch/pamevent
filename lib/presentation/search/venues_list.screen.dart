import 'dart:async';
import 'package:flutter/material.dart';
import '../../api/api.client.dart';
import '../../helpers/app_colors.dart';
import '../../helpers/public_url.dart';
import '../shared/widgets/custom_image.dart';
import '../shared/widgets/app_drawer.widget.dart';
import 'venue_details.screen.dart';

class VenuesListScreen extends StatefulWidget {
  final VoidCallback? onMenuTap;

  const VenuesListScreen({super.key, this.onMenuTap});

  @override
  State<VenuesListScreen> createState() => _VenuesListScreenState();
}

class _VenuesListScreenState extends State<VenuesListScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  List<dynamic> _venues = [];
  bool _isLoading = true;
  final TextEditingController _searchController = TextEditingController();
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _fetchVenues();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  Future<void> _fetchVenues() async {
    setState(() => _isLoading = true);
    try {
      final response = await ApiClient.getVenues(search: _searchController.text);
      debugPrint("result:$response");
      if (mounted) {
        setState(() {
          // The response has a nested structure: data -> data
          final dynamic dataField = response?['data'];
          if (dataField is Map && dataField['data'] is List) {
            _venues = dataField['data'];
          } else if (dataField is List) {
            _venues = dataField;
          } else {
            _venues = [];
          }
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error fetching venues: $e');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _onSearchChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      _fetchVenues();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: AppColors.white,
      drawer: const AppDrawer(),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1B0C40), // Dark theme header
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.menu, color: AppColors.white),
          onPressed: () {
            if (widget.onMenuTap != null) {
              widget.onMenuTap!();
            } else {
              _scaffoldKey.currentState?.openDrawer();
            }
          },
        ),
        title: const Text(
          'Venue',
          style: TextStyle(color: AppColors.white, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with Search Bar
            Container(
              width: double.infinity,
              padding: const EdgeInsets.only(bottom: 24),
              decoration: const BoxDecoration(
                color: Color(0xFF1B0C40),
              ),
              child: Column(
                children: [
                  const SizedBox(height: 10),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Container(
                      height: 45,
                      decoration: BoxDecoration(
                        color: AppColors.white,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: TextField(
                        controller: _searchController,
                        onChanged: _onSearchChanged,
                        decoration: InputDecoration(
                          hintText: 'Search venues...',
                          hintStyle: const TextStyle(color: AppColors.grey, fontSize: 13),
                          prefixIcon: const Icon(Icons.search, color: AppColors.grey, size: 20),
                          suffixIcon: _searchController.text.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(Icons.close, color: AppColors.grey, size: 18),
                                  onPressed: () {
                                    _searchController.clear();
                                    _onSearchChanged('');
                                  },
                                )
                              : null,
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(vertical: 11),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            
            // Total Venue showing label
            if (!_isLoading && _venues.isNotEmpty)
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 16),
                child: Text(
                  'Total Venue showing: ${_venues.length}',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.black,
                  ),
                ),
              ),

            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _venues.isEmpty
                      ? const Center(
                          child: Text(
                            'Venue not available',
                            style: TextStyle(color: AppColors.grey, fontSize: 16),
                          ),
                        )
                      : GridView.builder(
                           padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                           gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                               crossAxisCount: 2,
                               crossAxisSpacing: 16,
                               mainAxisSpacing: 16,
                               childAspectRatio: 0.95, // Reduced slightly to give more vertical space
                             ),
                          itemCount: _venues.length,
                          itemBuilder: (context, index) {
                            final venue = _venues[index];
                            final eventCount = venue['event_count']?.toString() ?? '0';
                            return _buildVenueItem(
                              name: venue['venue'] ?? venue['name'] ?? 'Venue',
                              address: venue['address'] ?? '${venue['city'] ?? ''}, ${venue['country'] ?? ''}',
                              eventCount: eventCount,
                              venueData: venue,
                            );
                          },
                        ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVenueItem({
    required String name,
    required String address,
    required String eventCount,
    required dynamic venueData,
  }) {
    return GestureDetector(
      onTap: () {
        final slug = venueData['slug'] ?? venueData['venue']?.toString().toLowerCase().replaceAll(' ', '-') ?? name.toLowerCase().replaceAll(' ', '-');
        
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => VenueDetailsScreen(
              slug: slug,
              name: name,
              address: address,
            ),
          ),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(4),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 15,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Flexible(
                child: Text(
                  name,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: AppColors.black,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(height: 6),
              Flexible(
                child: Text(
                  address,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.black,
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                '$eventCount Event',
                style: const TextStyle(
                  fontSize: 11,
                  color: AppColors.grey,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'View',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: AppColors.black,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
