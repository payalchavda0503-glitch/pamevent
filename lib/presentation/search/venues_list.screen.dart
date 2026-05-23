import 'dart:async';
import 'package:flutter/material.dart';
import '../../api/api.client.dart';
import '../../helpers/app_colors.dart';
import '../../helpers/public_url.dart';
import '../shared/widgets/custom_image.dart';
import 'venue_details.screen.dart';

class VenuesListScreen extends StatefulWidget {
  final VoidCallback? onMenuTap;

  const VenuesListScreen({super.key, this.onMenuTap});

  @override
  State<VenuesListScreen> createState() => _VenuesListScreenState();
}

class _VenuesListScreenState extends State<VenuesListScreen> {
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
      backgroundColor: AppColors.white,
      appBar: AppBar(
        backgroundColor: AppColors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.menu, color: AppColors.black),
          onPressed: widget.onMenuTap,
        ),
        title: const Text(
          'Venues',
          style: TextStyle(color: AppColors.black, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Search Bar
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Container(
                decoration: BoxDecoration(
                  color: const Color(0xFFF5F5F5),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.lightGrey),
                ),
                child: TextField(
                  controller: _searchController,
                  onChanged: _onSearchChanged,
                  decoration: InputDecoration(
                    hintText: 'Search venues...',
                    hintStyle: const TextStyle(color: AppColors.grey, fontSize: 14),
                    prefixIcon: const Icon(Icons.search, color: AppColors.grey),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.close, color: AppColors.grey, size: 20),
                            onPressed: () {
                              _searchController.clear();
                              _onSearchChanged('');
                            },
                          )
                        : null,
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(vertical: 12),
                  ),
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
                           padding: const EdgeInsets.only(left: 16, right: 16, bottom: 16),
                           gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                               crossAxisCount: 2,
                               crossAxisSpacing: 16,
                               mainAxisSpacing: 16,
                               childAspectRatio: 1.5, // Increased from 1.3 to reduce card height/bottom space
                             ),
                          itemCount: _venues.length,
                          itemBuilder: (context, index) {
                            final venue = _venues[index];
                            return _buildVenueItem(
                              name: venue['venue'] ?? venue['name'] ?? 'Venue',
                              address: venue['address'] ?? '${venue['city'] ?? ''}, ${venue['country'] ?? ''}',
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
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.lightGrey.withOpacity(0.5)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.start, // Align to top to be safer against overflows
            children: [
              Text(
                name,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 6),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.location_on, size: 12, color: AppColors.grey),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      address,
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.grey,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
