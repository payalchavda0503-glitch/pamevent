import 'dart:developer' as dev show log;
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../api/api.client.dart';
import '../helpers/app_colors.dart';
import '../helpers/public_url.dart';
import '../services/toast.service.dart';
import 'event/event_details.screen.dart';
import 'event/all_events.screen.dart';
import 'search/search_results.screen.dart';
import 'search/artist_details.screen.dart';
import 'shared/widgets/custom_text_field.widget.dart';
import 'shared/widgets/filter_bottom_sheet.widget.dart';

class HomeScreen extends StatefulWidget {
  final VoidCallback? onMenuTap;
  const HomeScreen({super.key, this.onMenuTap});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController _searchController = TextEditingController();
  bool _isLoading = true;
  List<dynamic> _events = [];
  List<dynamic> _categories = [];

  @override
  void initState() {
    super.initState();
    _fetchHomeData();
  }

  Future<void> _fetchHomeData() async {
    print('--- FETCHING HOME DATA START ---');
    setState(() => _isLoading = true);
    try {
      // Fetch only home data as it contains both categories and events
      final homeData = await ApiClient.home();
      print('Home API Full Response: $homeData');

      setState(() {
        // Extracting categories from home API
        _categories = homeData?['categories'] ?? [];
        
        // Extracting events from home API (checking multiple possible keys)
        final eventsList = homeData?['upcoming_events'] ?? homeData?['events'] ?? [];
        _events = eventsList is List ? eventsList : [];
        
        if (_events.isNotEmpty) {
          print('First event data sample: ${_events.first}');
        }
        
        print('Home Data - Categories: ${_categories.length}, Events: ${_events.length}');
        _isLoading = false;
      });
    } catch (e, stack) {
      print('Error fetching home data: $e');
      print('Stack trace: $stack');
      setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
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
                        // Search Bar with Drawer and Filter
                        Row(
                          children: [
                            IconButton(
                              icon: const Icon(Icons.menu, color: AppColors.black),
                              onPressed: widget.onMenuTap,
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: GestureDetector(
                                onTap: () {
                                  // Handle search tap
                                },
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: AppColors.scaffold,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
                                  child: Row(
                                    children: const [
                                      Icon(Icons.search, color: AppColors.grey, size: 20),
                                      SizedBox(width: 8),
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
                            const SizedBox(width: 4),
                            IconButton(
                              icon: const Icon(Icons.filter_list, color: AppColors.black),
                              onPressed: () {
                                showModalBottomSheet(
                                  context: context,
                                  isScrollControlled: true,
                                  backgroundColor: Colors.transparent,
                                  builder: (context) => const FilterBottomSheet(),
                                );
                              },
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),

                        // Events Section Header
                        Row(
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
                                  date: event['event_date'] != null 
                                      ? '${event['event_date']} / ${event['event_start_time'] ?? ''}'
                                      : (event['start_date'] != null 
                                          ? '${event['start_date']} / ${event['start_time'] ?? ''}'
                                          : ''),
                                  price: formatPrice(event['payment_info'] is Map 
                                      ? (event['payment_info']['calculate_price'] ?? event['payment_info']['original_price'])
                                      : (event['price'] ?? event['event_price'] ?? event['ticket_price'] ?? event['min_price'] ?? event['starting_price'])),
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
          CircleAvatar(
            radius: 40,
            backgroundImage: NetworkImage(imageUrl),
            backgroundColor: AppColors.lightGrey,
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
          child: CachedNetworkImage(
            imageUrl: imageUrl,
            width: 120,
            height: 120,
            fit: BoxFit.cover,
            placeholder: (context, url) => Container(
              width: 120,
              height: 120,
              color: AppColors.lightGrey,
              child: const Center(child: CircularProgressIndicator(strokeWidth: 2)),
            ),
            errorWidget: (context, url, error) => Container(
              width: 120,
              height: 120,
              color: AppColors.lightGrey,
              child: const Icon(Icons.image_not_supported, color: AppColors.grey),
            ),
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
              Text(
                price,
                style: const TextStyle(
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

  Widget _buildCategoryItem(String title, String imageUrl) {
    return Container(
      width: 100,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        color: AppColors.lightGrey,
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        fit: StackFit.expand,
        children: [
          CachedNetworkImage(
            imageUrl: imageUrl,
            fit: BoxFit.cover,
            placeholder: (context, url) => Container(
              color: AppColors.lightGrey,
              child: const Center(child: CircularProgressIndicator(strokeWidth: 2)),
            ),
            errorWidget: (context, url, error) => Container(
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
    );
  }
}
