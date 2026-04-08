import 'dart:async';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import '../../api/api.client.dart';
import '../../helpers/app_colors.dart';
import '../../helpers/public_url.dart';
import '../event/event_details.screen.dart';
import '../shared/widgets/custom_image.dart';
import '../shared/widgets/filter_bottom_sheet.widget.dart';
import 'artist_details.screen.dart';

class SearchResultsScreen extends StatefulWidget {
  final String initialQuery;
  final Map<String, dynamic>? initialFilters;
  final VoidCallback? onMenuTap;

  const SearchResultsScreen({
    super.key,
    this.initialQuery = '',
    this.initialFilters,
    this.onMenuTap,
  });

  @override
  State<SearchResultsScreen> createState() => _SearchResultsScreenState();
}

class _SearchResultsScreenState extends State<SearchResultsScreen> {
  late TextEditingController _searchController;
  List<dynamic> _events = [];
  List<dynamic> _artists = [];
  List<dynamic> _venues = [];
  bool _isLoading = false;
  Timer? _debounce;
  Map<String, dynamic>? _activeFilters;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController(text: widget.initialQuery);
    _activeFilters = widget.initialFilters;
    
    if (_activeFilters != null) {
      _performFilter();
    } else if (widget.initialQuery.isNotEmpty) {
      _performSearch(widget.initialQuery);
    }
  }

  void _onSearchChanged(String query) {
    setState(() {}); // Update to show/hide clear icon
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      if (query.isNotEmpty) {
        _activeFilters = null; // Clear filters when typing a new search
        _performSearch(query);
      } else {
        setState(() {
          _events = [];
          _artists = [];
          _venues = [];
        });
      }
    });
  }

  Future<void> _performSearch(String query) async {
    setState(() => _isLoading = true);
    try {
      final results = await ApiClient.customerSearch(query);
      if (results != null) {
        setState(() {
          _events = results['events'] is List ? results['events'] : [];
          _artists = results['artists'] is List ? results['artists'] : [];
          _venues = results['venues'] is List ? results['venues'] : [];
          _isLoading = false;
        });
      } else {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      debugPrint('Error searching: $e');
      setState(() => _isLoading = false);
    }
  }

  Future<void> _performFilter() async {
    if (_activeFilters == null) return;
    
    setState(() => _isLoading = true);
    try {
      final results = await ApiClient.getCustomerEvents(
        category: _activeFilters!['category'],
        eventType: _activeFilters!['event'],
        searchInput: _searchController.text.isNotEmpty ? _searchController.text : null,
        dates: _activeFilters!['dates'],
        minPrice: _activeFilters!['min'],
        maxPrice: _activeFilters!['max'],
      );
      
      if (results != null) {
        setState(() {
          if (results['events'] != null && results['events']['data'] is List) {
            _events = results['events']['data'];
          } else if (results['data'] is List) {
            _events = results['data'];
          } else {
            _events = [];
          }
          _artists = []; // Filter API usually only returns events
          _venues = [];
          _isLoading = false;
        });
      } else {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      debugPrint('Error filtering: $e');
      setState(() => _isLoading = false);
    }
  }

  void _showFilterSheet() async {
    final filters = await showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => FilterBottomSheet(initialFilters: _activeFilters),
    );

    if (filters != null) {
      setState(() {
        _activeFilters = filters;
      });
      _performFilter();
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _debounce?.cancel();
    super.dispose();
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
          'Search',
          style: TextStyle(color: AppColors.black, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Search Bar Header
            Padding(
              padding: const EdgeInsets.only(left: 16.0, right: 16.0, bottom: 8.0),
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      height: 50, // Fixed height to prevent cutting
                      decoration: BoxDecoration(
                        color: const Color(0xFFF5F5F5),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.lightGrey),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: TextField(
                          controller: _searchController,
                          autofocus: false,
                          onChanged: _onSearchChanged,
                          textAlignVertical: TextAlignVertical.center, // Center text vertically
                          decoration: InputDecoration(
                            hintText: 'Find events, artist & venues',
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
                            enabledBorder: InputBorder.none,
                            focusedBorder: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 12), // Adjust horizontal padding
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            if (_isLoading)
              const Expanded(
                child: Center(child: CircularProgressIndicator()),
              )
            else
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Popular Section (Events)
                      if (_events.isNotEmpty) ...[
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16.0),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: const [
                              Text(
                                'Events',
                                style: TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.black,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16.0),
                          child: Column(
                            children: _events.map((event) {
                              final price = event['payment_info'] is Map 
                                  ? (event['payment_info']['calculate_price'] ?? event['payment_info']['original_price'])
                                  : (event['price'] ?? event['event_price'] ?? event['ticket_price'] ?? event['min_price'] ?? event['starting_price'] ?? '0.00');
                              
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 16),
                                child: _buildEventItem(
                                  eventId: event['id'] ?? 0,
                                  imageUrl: resolvePublicUrl(event['thumbnail'] ?? event['image'] ?? event['photo'] ?? event['event_thumbnail']) ?? 'https://picsum.photos/200/200',
                                  title: event['title'] ?? event['event_name'] ?? 'Untitled',
                                  location: event['venue_name'] ?? 
                                           event['event_address'] ?? 
                                           '${event['city'] ?? ''}, ${event['country'] ?? ''}'.trim().replaceAll(RegExp(r'^, |, $'), '') ?? 
                                           event['location'] ?? 
                                           event['venue'] ?? 
                                           'Online',
                                  organizer: event['organizer_name'] ?? event['organizer']?['username'] ?? 'Unknown',
                                  date: '${event['start_date'] ?? ''} / ${event['start_time'] ?? ''}',
                                  price: formatPrice(price),
                                  status: event['status_label'],
                                  statusColor: event['status_color'] != null
                                      ? Color(int.parse(event['status_color'].replaceAll('#', '0xFF')))
                                      : null,
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                        const Divider(height: 48, thickness: 1, color: AppColors.lightGrey),
                      ],

                      // Artists Section
                      if (_artists.isNotEmpty) ...[
                        const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 16.0),
                          child: Text(
                            'Artists',
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: AppColors.black,
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16.0),
                          child: SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: Row(
                              children: _artists.map((artist) {
                                return Padding(
                                  padding: const EdgeInsets.only(right: 16),
                                  child: _buildArtistItem(
                                    artist['name'] ?? artist['username'] ?? 'Artist',
                                    resolvePublicUrl(artist['photo'] ?? artist['image'] ?? artist['avatar']) ?? 'https://picsum.photos/100/100',
                                    artist['slug'] ?? artist['username'] ?? '',
                                  ),
                                );
                              }).toList(),
                            ),
                          ),
                        ),
                        const Divider(height: 48, thickness: 1, color: AppColors.lightGrey),
                      ],

                      // Venue Section
                      if (_venues.isNotEmpty) ...[
                        const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 16.0),
                          child: Text(
                            'Venue',
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: AppColors.black,
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16.0),
                          child: SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: Row(
                              children: _venues.map((venue) {
                                return Padding(
                                  padding: const EdgeInsets.only(right: 16),
                                  child: _buildVenueItem(
                                    name: venue['venue'] ?? venue['name'] ?? 'Venue',
                                    imageUrl: resolvePublicUrl(venue['image'] ?? venue['photo'] ?? venue['thumbnail']),
                                    address: venue['address'] ?? '${venue['city'] ?? ''}, ${venue['country'] ?? ''}',
                                  ),
                                );
                              }).toList(),
                            ),
                          ),
                        ),
                        const SizedBox(height: 32),
                      ],
                      
                      if (!_isLoading && _events.isEmpty && _artists.isEmpty && _venues.isEmpty)
                        const Padding(
                          padding: EdgeInsets.all(32.0),
                          child: Center(
                            child: Text(
                              'No results found',
                              style: TextStyle(color: AppColors.grey, fontSize: 16),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildVenueItem({
    required String name,
    required String? imageUrl,
    required String address,
  }) {
    return Container(
      width: 160,
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            child: CustomImage(
              imageUrl,
              height: 100,
              fit: BoxFit.cover,
              whenEmpty: Container(
                height: 100,
                color: AppColors.lightGrey.withOpacity(0.3),
                child: const Center(
                  child: Icon(Icons.business, size: 40, color: AppColors.grey),
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Row(
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
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEventItem({
    required int eventId,
    required String imageUrl,
    required String title,
    required String location,
    required String organizer,
    required String date,
    required String price,
    String? status,
    Color? statusColor,
  }) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => EventDetailsScreen(
              eventId: eventId,
              title: title,
              imageUrl: imageUrl,
              price: price,
            ),
          ),
        );
      },
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: CustomImage(
              imageUrl,
              width: 120,
              height: 120,
              fit: BoxFit.cover,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.location_on, size: 13, color: AppColors.darkGrey),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        location,
                        style: const TextStyle(fontSize: 12, color: AppColors.darkGrey),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    const Icon(Icons.person, size: 13, color: AppColors.darkGrey),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        'By $organizer',
                        style: const TextStyle(fontSize: 11, color: AppColors.grey),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  date,
                  style: const TextStyle(fontSize: 12, color: AppColors.darkGrey),
                ),
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                       price,
                       style: const TextStyle(
                         fontWeight: FontWeight.bold,
                         fontSize: 14,
                         color: AppColors.black,
                       ),
                     ),
                    if (status != null)
                      Text(
                        status,
                        style: TextStyle(
                          color: statusColor ?? AppColors.primary,
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildArtistItem(String name, String imageUrl, String slug) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ArtistDetailsScreen(
              name: name,
              imageUrl: imageUrl,
              artistSlug: slug,
            ),
          ),
        );
      },
      child: Column(
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.lightGrey),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: CustomImage(
                imageUrl,
                width: 80,
                height: 80,
                fit: BoxFit.cover,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              border: Border.all(color: AppColors.lightGrey),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              name,
              style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }
}
