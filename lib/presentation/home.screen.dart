import 'dart:developer' as dev show log;
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../api/api.client.dart';
import '../helpers/app_colors.dart';
import '../helpers/app_state.dart';
import '../helpers/public_url.dart';
import '../helpers/utils.dart';
import '../services/toast.service.dart';
import 'shared/widgets/price_display.widget.dart';
import 'event/event_details.screen.dart';
import 'event/all_events.screen.dart';
import 'search/search_results.screen.dart';
import 'search/artist_details.screen.dart';
import 'shared/widgets/custom_image.dart';
import 'shared/widgets/custom_text_field.widget.dart';
import 'shared/widgets/filter_bottom_sheet.widget.dart';
import 'location/select_location.screen.dart';

class HomeScreen extends StatefulWidget {
  final VoidCallback? onMenuTap;
  final VoidCallback? onSearchTap;
  const HomeScreen({super.key, this.onMenuTap, this.onSearchTap});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController _searchController = TextEditingController();
  bool _isLoading = true;
  List<dynamic> _events = [];
  List<dynamic> _categories = [];
  Map<String, dynamic>? _activeFilters;

  String? _lastKnownLocation;

  @override
  void initState() {
    super.initState();
    print('=== HOMESCREEN: initState() called ===');
    _lastKnownLocation = AppState.selectedLocation.value;
    print('=== HOMESCREEN: _lastKnownLocation initialized to: $_lastKnownLocation ===');
    print('=== HOMESCREEN: AppState.selectedLocation.value: ${AppState.selectedLocation.value} ===');
    
    // Fetch home data right away if we already have a location
    if (_lastKnownLocation != null) {
      print('=== HOMESCREEN: Fetching home data with location ===');
      _fetchHomeData();
    } else {
      // Fetch home data without location filter first
      print('=== HOMESCREEN: Fetching home data without location ===');
      _fetchHomeData();
    }
    
    print('=== HOMESCREEN: Adding listener to AppState.selectedLocation ===');
    AppState.selectedLocation.addListener(() {
      print('=== HOMESCREEN: selectedLocation listener triggered ===');
      print('=== HOMESCREEN: New value: ${AppState.selectedLocation.value}, Old value: $_lastKnownLocation ===');
      if (mounted && AppState.selectedLocation.value != _lastKnownLocation) {
        print('=== HOMESCREEN: Updating _lastKnownLocation and fetching data ===');
        setState(() {
          _lastKnownLocation = AppState.selectedLocation.value;
        });
        _fetchHomeData();
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchHomeData() async {
    print('--- FETCHING HOME DATA START ---');
    setState(() => _isLoading = true);
    try {
      if (_activeFilters != null) {
        final results = await ApiClient.getCustomerEvents(
          category: _activeFilters?['category'],
          eventType: _activeFilters?['event'],
          dates: _activeFilters?['dates'],
          minPrice: _activeFilters?['min'],
          maxPrice: _activeFilters?['max'],
          filterVenue: AppState.selectedLocation.value,
        );
        
        final homeData = await ApiClient.home(filterVenue: AppState.selectedLocation.value);
        print("homedata----$homeData");
        setState(() {
          _categories = homeData?['categories'] ?? [];
          if (results != null) {
            if (results['events'] != null && results['events']['data'] is List) {
              _events = results['events']['data'];
            } else if (results['data'] is List) {
              _events = results['data'];
            } else {
              _events = [];
            }
          }
          _isLoading = false;
        });
      } else {
        final homeData = await ApiClient.home(filterVenue: AppState.selectedLocation.value);
       print("homedata----$homeData");
        setState(() {
          _categories = homeData?['categories'] ?? [];
          final eventsList = homeData?['upcoming_events'] ?? homeData?['events'] ?? [];
          _events = eventsList is List ? eventsList : [];
          _isLoading = false;
        });
      }
    } catch (e, stack) {
      print('Error fetching home data: $e');
      print('Stack trace: $stack');
      setState(() => _isLoading = false);
    }
  }

  Future<void> _applyFilters(Map<String, dynamic> filters) async {
    setState(() {
      _isLoading = true;
      _activeFilters = filters;
    });
    
    try {
      final results = await ApiClient.getCustomerEvents(
        category: filters['category'],
        eventType: filters['event'],
        dates: filters['dates'],
        minPrice: filters['min'],
        maxPrice: filters['max'],
        filterVenue: AppState.selectedLocation.value,
      );
      
      setState(() {
        if (results != null) {
          if (results['events'] != null && results['events']['data'] is List) {
            _events = results['events']['data'];
          } else if (results['data'] is List) {
            _events = results['data'];
          } else {
            _events = [];
          }
        }
        _isLoading = false;
      });
    } catch (e) {
      print('Error applying filters on home: $e');
      setState(() => _isLoading = false);
    }
  }

  void _resetFilters() {
    setState(() {
      _activeFilters = null;
      AppState.selectedLocation.value = null;
    });
    _fetchHomeData();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : RefreshIndicator(
                onRefresh: _fetchHomeData,
                child: SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Top Header Row: Location + Filters
                        Row(
                          children: [
                            IconButton(
                              icon: const Icon(Icons.menu, color: AppColors.black),
                              onPressed: widget.onMenuTap,
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: GestureDetector(
                                onTap: () async {
                                  final selected = await Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => SelectLocationScreen(
                                        initialLocation: AppState.selectedLocation.value,
                                      ),
                                    ),
                                  );
                                  if (selected != null) {
                                    setState(() {
                                      AppState.selectedLocation.value = selected;
                                    });
                                    _fetchHomeData();
                                  }
                                },
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: AppColors.white,
                                    borderRadius: BorderRadius.circular(24),
                                    border: Border.all(color: AppColors.lightGrey),
                                  ),
                                  padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
                                  child: ValueListenableBuilder<String?>(
                                    valueListenable: AppState.selectedLocation,
                                    builder: (context, location, child) {
                                      print('=== HOMESCREEN ValueListenableBuilder: location = $location ===');
                                      return Row(
                                        children: [
                                          const Icon(Icons.location_on, color: AppColors.grey, size: 20),
                                          const SizedBox(width: 8),
                                          Expanded(
                                            child: Text(
                                              location ?? 'Select Location',
                                              style: TextStyle(
                                                color: location != null ? AppColors.black : AppColors.grey,
                                                fontSize: 14,
                                                fontWeight: location != null ? FontWeight.w500 : FontWeight.normal,
                                              ),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                          if (location != null) ...[
                                            const SizedBox(width: 8),
                                            GestureDetector(
                                              onTap: () {
                                                setState(() {
                                                  AppState.selectedLocation.value = null;
                                                });
                                                _fetchHomeData();
                                              },
                                              child: const Icon(Icons.close, color: AppColors.grey, size: 20),
                                            ),
                                          ],
                                        ],
                                      );
                                    },
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            IconButton(
                              icon: Icon(
                                Icons.filter_list,
                                color: _activeFilters != null ? AppColors.primary : AppColors.black,
                              ),
                              onPressed: () async {
                                final filters = await showModalBottomSheet<Map<String, dynamic>>(
                                  context: context,
                                  isScrollControlled: true,
                                  backgroundColor: Colors.transparent,
                                  builder: (context) => FilterBottomSheet(initialFilters: _activeFilters),
                                );
                                
                                if (filters != null && mounted) {
                                  _applyFilters(filters);
                                }
                              },
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        // Search Bar
                        Row(
                          children: [
                            Expanded(
                              child: GestureDetector(
                                onTap: widget.onSearchTap,
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFF5F5F5),
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                                  child: Row(
                                    children: const [
                                      Icon(Icons.search, color: AppColors.grey, size: 20),
                                      SizedBox(width: 10),
                                      Expanded(
                                        child: Text(
                                          'Find events, artist & venues',
                                          style: TextStyle(color: AppColors.grey, fontSize: 14),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),

                        // Events Section Header
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              _activeFilters != null ? 'Filtered Events' : 'Events',
                              style: const TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: AppColors.black,
                              ),
                            ),
                            if (_activeFilters != null)
                              TextButton(
                                onPressed: _resetFilters,
                                child: const Text(
                                  'Reset Filters',
                                  style: TextStyle(color: AppColors.primary),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 16),

                        // Event List
                        if (_events.isEmpty)
                          Center(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 48),
                              child: Column(
                                children: [
                                  const Text(
                                    'No events found for this month.',
                                    style: TextStyle(color: AppColors.grey),
                                  ),
                                  const SizedBox(height: 16),
                                  ElevatedButton(
                                    onPressed: _fetchHomeData,
                                    child: const Text('Retry Fetch Data'),
                                  ),
                                ],
                              ),
                            ),
                          )
                        else
                          ..._events.map((event) => Padding(
                                padding: const EdgeInsets.only(bottom: 16),
                                child: _buildEventItem(
                                  eventId: event['id'] ?? event['event_id'] ?? 0,
                                  imageUrl: event['event_thumbnail_url'] ?? 
                                           resolvePublicUrl(event['event_thumbnail'] ?? event['image'] ?? event['event_img']) ?? 
                                           'https://picsum.photos/200/200',
                                  title: event['title'] ?? 'Untitled Event',
                                  location: event['event_address'] ?? 
                                           '${event['city'] ?? ''}, ${event['country'] ?? ''}'.trim().replaceAll(RegExp(r'^, |, $'), '') ?? 
                                           event['venue'] ?? 
                                           'Online',
                                  organizer: event['organizer'] is Map 
                                      ? (event['organizer']['username'] ?? 'Unknown')
                                      : (event['organizer_name'] ?? 'Unknown'),
                                  date: (() {
                                    String d = event['event_date']?.toString() ?? event['start_date']?.toString() ?? '';
                                    String t = event['event_start_time']?.toString() ?? event['start_time']?.toString() ?? '';
                                    
                                    if (d.isEmpty && event['date_type'] == 'multiple' && event['multiple_dates'] is List && (event['multiple_dates'] as List).isNotEmpty) {
                                      final firstDate = (event['multiple_dates'] as List).first;
                                      d = firstDate['event_date']?.toString() ?? firstDate['start_date']?.toString() ?? '';
                                      t = firstDate['event_start_time']?.toString() ?? firstDate['start_time']?.toString() ?? '';
                                    }
                                    String formattedDate = formatShortEventDate(d);
                                    return formattedDate.isNotEmpty ? '$formattedDate / $t' : '';
                                  })(),
                                  price: event['payment_info'] is Map 
                                      ? (event['payment_info']['calculate_price'] ?? event['payment_info']['original_price'])
                                      : (event['final_price'] ?? event['price'] ?? event['event_price'] ?? event['ticket_price'] ?? event['min_price'] ?? event['starting_price']),
                                  originalPrice: event['payment_info'] is Map 
                                      ? (event['payment_info']['original_price'] ?? event['payment_info']['calculate_price']) 
                                      : (event['price'] ?? event['original_price'] ?? event['event_price']),
                                  isDiscounted: (event['payment_info'] is Map && event['payment_info']['early_bird_discount'] == 'enable') || 
                                               (event['early_bird_discount'] == 'enable'),
                                  status: event['status_label'],
                                  statusColor: event['status_color'] != null
                                      ? Color(int.parse(event['status_color'].replaceAll('#', '0xFF')))
                                      : null,
                                ),
                              )),

                        const SizedBox(height: 24),
                        Center(
                          child: TextButton(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (context) => const AllEventsScreen()),
                              );
                            },
                            child: const Text(
                              'See all',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: AppColors.black,
                              ),
                            ),
                          ),
                        ),

                      
                        const SizedBox(height: 24),
                        // Categories Section
                        const Text(
                          'Categories',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: AppColors.black,
                          ),
                        ),
                        const SizedBox(height: 16),
                        if (_categories.isEmpty)
                          const Text('No categories available.')
                        else
                          SizedBox(
                            height: 140,
                            child: ListView.builder(
                              scrollDirection: Axis.horizontal,
                              itemCount: _categories.length,
                              itemBuilder: (context, index) {
                                final category = _categories[index];
                                return Padding(
                                  padding: const EdgeInsets.only(right: 12),
                                  child: _buildCategoryItem(
                                    category['name'] ?? 'Category',
                                    resolvePublicUrl(category['image_url'] ?? category['image']) ?? 'https://picsum.photos/200/300',
                                    () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) => AllEventsScreen(
                                            initialCategory: category['name'],
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                );
                              },
                            ),
                          ),
                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
                ),
              ),
      ),
    );
  }

  Widget _buildArtistItem(String name, String imageUrl, String slug) {
    return GestureDetector(
      onTap: () {
        if (slug.isNotEmpty) {
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
        }
      },
      child: Column(
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.lightGrey),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(40),
              child: CustomImage(
                imageUrl,
                width: 80,
                height: 80,
                fit: BoxFit.cover,
                whenEmpty: Container(
                  width: 80,
                  height: 80,
                  color: AppColors.lightGrey,
                  child: const Icon(Icons.person, color: AppColors.grey),
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              border: Border.all(color: AppColors.lightGrey),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              name,
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.black,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
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
    required dynamic price,
    dynamic originalPrice,
    bool? isDiscounted,
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
              price: formatPrice(price),
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
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      title,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  const Icon(Icons.location_on, size: 14, color: AppColors.darkGrey),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      location,
                      style: const TextStyle(fontSize: 13, color: AppColors.darkGrey),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 2),
              Row(
                children: [
                  const Icon(Icons.person, size: 14, color: AppColors.darkGrey),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      'By $organizer',
                      style: const TextStyle(fontSize: 12, color: AppColors.grey),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                date,
                style: const TextStyle(fontSize: 13, color: AppColors.darkGrey),
              ),
              const SizedBox(height: 4),
              PriceDisplay(
                price: price,
                originalPrice: originalPrice,
                isDiscounted: isDiscounted,
                priceStyle: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
              if (status != null) ...[
                const SizedBox(height: 2),
                Text(
                  status,
                  style: TextStyle(
                    color: statusColor ?? AppColors.primary,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ]
            ],
          ),
        ),
      ],
    ),
    );
  }

  Widget _buildCategoryItem(String title, String imageUrl, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 100,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          color: AppColors.lightGrey,
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          fit: StackFit.expand,
          children: [
            CustomImage(
              imageUrl,
              fit: BoxFit.cover,
              whenEmpty: Container(
                color: AppColors.lightGrey,
                child: const Center(
                  child: Icon(
                    Icons.image_outlined,
                    color: AppColors.grey,
                    size: 30,
                  ),
                ),
              ),
            ),
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.black.withValues(alpha: 0.7),
                  ],
                ),
              ),
            ),
            Positioned(
              bottom: 8,
              left: 8,
              right: 8,
              child: Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
