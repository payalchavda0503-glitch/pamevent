import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../api/api.client.dart';
import '../../helpers/app_colors.dart';
import '../../helpers/public_url.dart';
import 'event_details.screen.dart';

class AllEventsScreen extends StatefulWidget {
  const AllEventsScreen({super.key});

  @override
  State<AllEventsScreen> createState() => _AllEventsScreenState();
}

class _AllEventsScreenState extends State<AllEventsScreen> {
  final ScrollController _scrollController = ScrollController();
  List<dynamic> _events = [];
  bool _isLoading = true;
  int _currentPage = 1;
  bool _hasMore = true;

  @override
  void initState() {
    super.initState();
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
      final data = await ApiClient.getCustomerEvents(page: _currentPage);
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
      ),
      body: SafeArea(
        child: _events.isEmpty && _isLoading
            ? const Center(child: CircularProgressIndicator())
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
    final eventId = event['id'] ?? event['event_id'] ?? 0;
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
    
    final date = event['event_date'] != null 
        ? '${event['event_date']} / ${event['event_start_time'] ?? ''}'
        : (event['start_date'] != null 
            ? '${event['start_date']} / ${event['start_time'] ?? ''}'
            : '');
            
    final priceRaw = event['payment_info'] is Map 
        ? (event['payment_info']['calculate_price'] ?? event['payment_info']['original_price'])
        : (event['price'] ?? event['event_price'] ?? event['ticket_price'] ?? event['min_price'] ?? event['starting_price']);
        
    final price = formatPrice(priceRaw);
    
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
              price: price,
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
                  Text(
                    price,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
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
