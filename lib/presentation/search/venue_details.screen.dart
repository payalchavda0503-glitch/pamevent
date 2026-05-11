import 'package:flutter/material.dart';
import '../../api/api.client.dart';
import '../../helpers/app_colors.dart';
import '../../helpers/public_url.dart';
import '../../helpers/utils.dart';
import '../shared/widgets/custom_image.dart';
import '../event/event_details.screen.dart';

class VenueDetailsScreen extends StatefulWidget {
  final String slug;
  final String? name;
  final String? imageUrl;
  final String? address;

  const VenueDetailsScreen({
    super.key,
    required this.slug,
    this.name,
    this.imageUrl,
    this.address,
  });

  @override
  State<VenueDetailsScreen> createState() => _VenueDetailsScreenState();
}

class _VenueDetailsScreenState extends State<VenueDetailsScreen> {
  int _selectedTabIndex = 0;
  bool _isLoading = true;
  Map<String, dynamic>? _venueDetail;
  List<dynamic> _upcomingEvents = [];
  List<dynamic> _pastEvents = [];
  List<String> _galleryImages = [];

  @override
  void initState() {
    super.initState();
    _fetchVenueDetail();
  }

  Future<void> _fetchVenueDetail() async {
    debugPrint('Fetching details for venue slug: ${widget.slug}');
    setState(() => _isLoading = true);
    try {
      final data = await ApiClient.getVenueDetail(widget.slug);
      if (mounted) {
        setState(() {
          // The API returns { "venue": { ... }, "upcoming_events": [ ... ] }
          // We extract the inner venue object for _venueDetail
          _venueDetail = data?['venue'] is Map ? data!['venue'] : data;
          
          _upcomingEvents = data?['upcoming_events'] is List ? data!['upcoming_events'] : [];
          _pastEvents = data?['past_events'] is List ? data!['past_events'] : [];
          
          debugPrint('Extracted Venue Name: ${_venueDetail?['venue']}');
          debugPrint('Extracted Upcoming Events Count: ${_upcomingEvents.length}');
          
          if (data?['gallery_images'] is List) {
            _galleryImages = List<String>.from(data!['gallery_images'].map((e) => e.toString().trim()));
          }
          
          String? mainImg = (_venueDetail?['image'] ?? _venueDetail?['photo'] ?? _venueDetail?['thumbnail'])?.toString().trim();
          if (mainImg != null && !_galleryImages.contains(mainImg)) {
            _galleryImages.insert(0, mainImg);
          }
          if (_galleryImages.isEmpty && widget.imageUrl != null) {
            _galleryImages.add(widget.imageUrl!);
          }
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error fetching venue details: $e');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: AppBar(
        backgroundColor: AppColors.white,
        elevation: 0,
        leading: GestureDetector(
          onTap: () => Navigator.pop(context),
          child: Container(
            margin: const EdgeInsets.all(8),
            padding: const EdgeInsets.all(8),
            decoration: const BoxDecoration(
              color: AppColors.black,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.arrow_back_ios_new, color: AppColors.white, size: 16),
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _venueDetail?['venue'] ?? _venueDetail?['name'] ?? widget.name ?? 'Venue',
                            style: const TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              color: AppColors.black,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              const Icon(Icons.location_on, size: 18, color: AppColors.grey),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  _venueDetail?['address'] ?? widget.address ?? 'Location not available',
                                  style: const TextStyle(
                                    fontSize: 14,
                                    color: AppColors.grey,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 24),
                          Row(
                            children: [
                              _buildTab('Upcoming', 0),
                              const SizedBox(width: 16),
                              _buildTab('Past', 1),
                            ],
                          ),
                          const SizedBox(height: 16),
                        ],
                      ),
                    ),
                    _selectedTabIndex == 0
                        ? (_upcomingEvents.isNotEmpty
                            ? ListView.builder(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                                itemCount: _upcomingEvents.length,
                                itemBuilder: (context, index) {
                                  return _buildEventCard(_upcomingEvents[index]);
                                },
                              )
                            : const Padding(
                                padding: EdgeInsets.all(32.0),
                                child: Center(
                                  child: Text(
                                    'No upcoming events',
                                    style: TextStyle(color: AppColors.grey, fontSize: 16),
                                  ),
                                ),
                              ))
                        : (_pastEvents.isNotEmpty
                            ? ListView.builder(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                                itemCount: _pastEvents.length,
                                itemBuilder: (context, index) {
                                  return _buildEventCard(_pastEvents[index]);
                                },
                              )
                            : const Padding(
                                padding: EdgeInsets.all(32.0),
                                child: Center(
                                  child: Text(
                                    'No past events',
                                    style: TextStyle(color: AppColors.grey, fontSize: 16),
                                  ),
                                ),
                              )),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _buildTab(String title, int index) {
    return GestureDetector(
      onTap: () {
        setState(() => _selectedTabIndex = index);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          color: _selectedTabIndex == index ? AppColors.primary : AppColors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: _selectedTabIndex == index ? AppColors.primary : AppColors.lightGrey,
          ),
        ),
        child: Text(
          title,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: _selectedTabIndex == index ? Colors.white : AppColors.black,
          ),
        ),
      ),
    );
  }

  Widget _buildEventCard(dynamic event) {
    final price = event['payment_info'] is Map 
        ? (event['payment_info']['calculate_price'] ?? event['payment_info']['original_price'])
        : (event['final_price'] ?? event['price'] ?? event['event_price'] ?? event['ticket_price'] ?? event['min_price'] ?? event['starting_price'] ?? '0.00');
    
    final eventImageUrl = event['thumbnail'] ?? event['image'] ?? event['photo'] ?? event['event_thumbnail'] ?? event['event_img'];
    
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => EventDetailsScreen(
              eventId: event['id'] ?? 0,
              title: event['title'] ?? event['event_name'] ?? 'Untitled',
              imageUrl: resolvePublicUrl(eventImageUrl) ?? 'https://picsum.photos/200/200',
              price: formatPrice(price),
            ),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: Colors.white,
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
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: CustomImage(
                  resolvePublicUrl(eventImageUrl) ?? 'https://picsum.photos/120/120',
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
                      event['title'] ?? event['event_name'] ?? 'Untitled',
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
                            event['venue_name'] ?? event['event_address'] ?? '${event['city'] ?? ''}, ${event['country'] ?? ''}'.trim().replaceAll(RegExp(r'^, |, $'), '') ?? event['location'] ?? event['venue'] ?? 'Online',
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
                            'By ${event['organizer_name'] ?? event['organizer']?['username'] ?? 'Unknown'}',
                            style: const TextStyle(fontSize: 11, color: AppColors.grey),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      (() {
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
                      style: const TextStyle(fontSize: 12, color: AppColors.darkGrey),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Text(
                          '\$${formatPrice(price)}',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            color: AppColors.black,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
