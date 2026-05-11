import 'package:flutter/material.dart';
import '../../api/api.client.dart';
import '../../helpers/app_colors.dart';
import '../../helpers/public_url.dart';
import '../../helpers/utils.dart';
import '../shared/widgets/custom_image.dart';
import '../shared/widgets/filter_bottom_sheet.widget.dart';
import '../shared/widgets/price_display.widget.dart';
import 'event_details.screen.dart';
import '../../helpers/app_state.dart';

class AllEventsScreen extends StatefulWidget {
  final String? initialCategory;
  final String? initialVenue;
  const AllEventsScreen({super.key, this.initialCategory, this.initialVenue});

  @override
  State<AllEventsScreen> createState() => _AllEventsScreenState();
}

class _AllEventsScreenState extends State<AllEventsScreen> {
  final ScrollController _scrollController = ScrollController();
  List<dynamic> _events = [];
  bool _isLoading = true;
  int _currentPage = 1;
  bool _hasMore = true;
  Map<String, dynamic>? _activeFilters;

  @override
  void initState() {
    super.initState();
    _activeFilters = {};
    if (widget.initialCategory != null) {
      _activeFilters!['category'] = widget.initialCategory;
    }
    if (widget.initialVenue != null) {
      _activeFilters!['venue'] = widget.initialVenue;
    }
    if (_activeFilters!.isEmpty) {
      _activeFilters = null;
    }
    _fetchEvents();
    _scrollController.addListener(() {
      if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent * 0.8 &&
          !_isLoading &&
          _hasMore) {
        _fetchEvents();
      }
    });
  }

  Future<void> _fetchEvents() async {
    if (!_hasMore) return;
    setState(() => _isLoading = true);

    try {
      final data = await ApiClient.getCustomerEvents(
        page: _currentPage,
        category: _activeFilters?['category'],
        eventType: _activeFilters?['event'],
        dates: _activeFilters?['dates'],
        minPrice: _activeFilters?['min'],
        maxPrice: _activeFilters?['max'],
        filterVenue:  AppState.selectedLocation.value,
      );
      if (data != null && data['events'] != null) {
        final newEvents = data['events']['data'] as List;
        setState(() {
          _events.addAll(newEvents);
          _currentPage++;
          _hasMore = data['events']['next_page_url'] != null;
          _isLoading = false;
        });
      } else {
        setState(() {
          _hasMore = false;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error fetching all events: $e');
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
      if (mounted) {
        setState(() {
          _activeFilters = filters.isEmpty ? null : filters;
          _events = [];
          _currentPage = 1;
          _hasMore = true;
        });
        _fetchEvents();
      }
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
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
          icon: const Icon(Icons.arrow_back_ios_new, color: AppColors.black, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'All Events',
          style: TextStyle(color: AppColors.black, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Stack(
              clipBehavior: Clip.none,
              children: [
                const Icon(Icons.filter_list, color: AppColors.black),
                if (_activeFilters != null && _activeFilters!.isNotEmpty)
                  Positioned(
                    top: -2,
                    right: -2,
                    child: Container(
                      width: 10,
                      height: 10,
                      decoration: const BoxDecoration(
                        color: AppColors.primary,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
              ],
            ),
            onPressed: _showFilterSheet,
          ),
        ],
      ),
      body: SafeArea(
        child: _events.isEmpty
            ? _isLoading
                ? const Center(child: CircularProgressIndicator())
                : Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.event_busy, size: 64, color: AppColors.grey),
                        const SizedBox(height: 16),
                        const Text(
                          'No events found',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppColors.black,
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Please try a different category or search term.',
                          style: TextStyle(color: AppColors.grey),
                        ),
                        const SizedBox(height: 24),
                        TextButton(
                          onPressed: () {
                            setState(() {
                              _activeFilters = null;
                              _events = [];
                              _currentPage = 1;
                              _hasMore = true;
                            });
                            _fetchEvents();
                          },
                          child: const Text('Clear Filters'),
                        ),
                      ],
                    ),
                  )
            : RefreshIndicator(
                onRefresh: () async {
                  setState(() {
                    _events = [];
                    _currentPage = 1;
                    _hasMore = true;
                  });
                  await _fetchEvents();
                },
                child: ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.all(16),
                  itemCount: _events.length + (_hasMore ? 1 : 0),
                  itemBuilder: (context, index) {
                    if (index == _events.length) {
                      return const Center(
                        child: Padding(
                          padding: EdgeInsets.symmetric(vertical: 16),
                          child: CircularProgressIndicator(),
                        ),
                      );
                    }

                    final event = _events[index];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: _buildEventItem(event),
                    );
                  },
                ),
              ),
      ),
    );
  }

  Widget _buildEventItem(dynamic event) {
    int eventId = 0;
    if (event['id'] != null) {
      eventId = int.tryParse(event['id'].toString()) ?? 0;
    } else if (event['event_id'] != null) {
      eventId = int.tryParse(event['event_id'].toString()) ?? 0;
    }
    
    final title = event['title'] ?? 'Untitled Event';
    final imageUrl = event['event_thumbnail_url'] ?? 
                    resolvePublicUrl(event['event_thumbnail'] ?? event['image'] ?? event['event_img']) ?? 
                    'https://picsum.photos/200/200';
    
    final location = event['event_address'] ?? 
                    '${event['city'] ?? ''}, ${event['country'] ?? ''}'.trim().replaceAll(RegExp(r'^, |, $'), '') ?? 
                    event['venue'] ?? 
                    'Online';
    
    final organizer = event['organizer'] is Map 
        ? (event['organizer']['username'] ?? 'Unknown')
        : (event['organizer_name'] ?? 'Unknown');
    
    final date = (() {
      String d = event['event_date']?.toString() ?? event['start_date']?.toString() ?? '';
      String t = event['event_start_time']?.toString() ?? event['start_time']?.toString() ?? '';
      
      if (d.isEmpty && event['date_type'] == 'multiple' && event['multiple_dates'] is List && (event['multiple_dates'] as List).isNotEmpty) {
        final firstDate = (event['multiple_dates'] as List).first;
        d = firstDate['event_date']?.toString() ?? firstDate['start_date']?.toString() ?? '';
        t = firstDate['event_start_time']?.toString() ?? firstDate['start_time']?.toString() ?? '';
      }
      String formattedDate = formatShortEventDate(d);
      return formattedDate.isNotEmpty ? '$formattedDate / $t' : '';
    })();
            
    final priceRaw = event['payment_info'] is Map 
        ? (event['payment_info']['calculate_price'] ?? event['payment_info']['original_price'])
        : (event['final_price'] ?? event['price'] ?? event['event_price'] ?? event['ticket_price'] ?? event['min_price'] ?? event['starting_price']);
        
    final status = event['status_label'];
    final statusColor = event['status_color'] != null
        ? Color(int.parse(event['status_color'].replaceAll('#', '0xFF')))
        : null;

    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => EventDetailsScreen(
              eventId: eventId,
              title: title,
              imageUrl: imageUrl,
              price: formatPrice(priceRaw),
            ),
          ),
        );
      },
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
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
                whenEmpty: Container(
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
                  Text(
                    title,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
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
                    price: priceRaw,
                    originalPrice: (event is Map && event['payment_info'] is Map) 
                        ? (event['payment_info']['original_price'] ?? event['payment_info']['calculate_price']) 
                        : (event['price'] ?? event['original_price'] ?? event['event_price']),
                    isDiscounted: (event is Map && event['payment_info'] is Map && event['payment_info']['early_bird_discount'] == 'enable') || 
                                 (event is Map && event['early_bird_discount'] == 'enable'),
                    priceStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
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
      ),
    );
  }
}
