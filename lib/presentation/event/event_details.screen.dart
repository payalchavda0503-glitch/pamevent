import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../api/api.client.dart';
import '../../helpers/app_colors.dart';
import '../../helpers/public_url.dart';
import '../shared/widgets/custom_button.widget.dart';

class EventDetailsScreen extends StatefulWidget {
  final int eventId;
  final String title;
  final String imageUrl;
  final String price;

  const EventDetailsScreen({
    super.key,
    this.eventId = 0,
    this.title = '',
    this.imageUrl = '',
    this.price = '',
  });

  @override
  State<EventDetailsScreen> createState() => _EventDetailsScreenState();
}

class _EventDetailsScreenState extends State<EventDetailsScreen> {
  int _selectedTabIndex = 0;
  bool _isLoading = true;
  Map<String, dynamic>? _eventDetail;
  List<dynamic> _performers = [];

  @override
  void initState() {
    super.initState();
    if (widget.eventId != 0) {
      _fetchEventDetail();
    } else {
      _isLoading = false;
    }
  }

  Future<void> _fetchEventDetail() async {
    setState(() => _isLoading = true);
    try {
      final data = await ApiClient.getCustomerEventDetail(widget.eventId);
      print('event detail API Full Response: $data');
      
      if (mounted) {
        setState(() {
          _eventDetail = data;
          // Extract performers directly from event detail response
          _performers = data?['performers'] is List ? data!['performers'] : [];
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error fetching event details: $e');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final data = _eventDetail ?? {};
    final title = data['title'] ?? widget.title;
    final imageUrl = data['event_img'] ?? data['event_thumbnail'] ?? widget.imageUrl;
    final venue = data['venue'] ?? '';
    final address = '${data['city'] ?? ''}, ${data['country'] ?? ''}'.trim();
    final startDate = data['start_date'] ?? '';
    final startTime = data['start_time'] ?? '';
    final description = data['description'] ?? '';
    final refundPolicy = data['refund_policy'] ?? '';

    return Scaffold(
      backgroundColor: AppColors.white,
      body: SafeArea(
        child: Column(
          children: [
            // Custom App Bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: const BoxDecoration(
                        color: AppColors.black,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.arrow_back_ios_new, color: AppColors.white, size: 16),
                    ),
                  ),
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.ios_share, color: AppColors.black),
                        onPressed: () {},
                      ),
                      IconButton(
                        icon: const Icon(Icons.bookmark_border, color: AppColors.black),
                        onPressed: () {},
                      ),
                    ],
                  ),
                ],
              ),
            ),

            Expanded(
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Event Image
                      Stack(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(16),
                            child: CachedNetworkImage(
                              imageUrl: resolvePublicUrl(imageUrl) ?? imageUrl,
                              width: double.infinity,
                              height: 200,
                              fit: BoxFit.cover,
                              placeholder: (context, url) => Container(
                                height: 200,
                                color: AppColors.lightGrey,
                                child: const Center(child: CircularProgressIndicator()),
                              ),
                              errorWidget: (context, url, error) => Container(
                                height: 200,
                                color: AppColors.lightGrey,
                                child: const Icon(Icons.image_not_supported),
                              ),
                            ),
                          ),
                          Positioned(
                            top: 12,
                            right: 12,
                            child: Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: AppColors.white.withValues(alpha: 0.8),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.bookmark_border, size: 18),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Title and Date Row
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Date Box (Dynamic based on start_date)
                          if (startDate.isNotEmpty)
                            Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(8),
                                color: AppColors.scaffold,
                              ),
                              child: Column(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                                    decoration: const BoxDecoration(
                                      color: AppColors.primary,
                                      borderRadius: BorderRadius.vertical(top: Radius.circular(8)),
                                    ),
                                    child: Text(
                                      startDate.split('-').length > 1 
                                          ? _getMonthAbbreviation(int.parse(startDate.split('-')[1]))
                                          : 'Date',
                                      style: const TextStyle(color: AppColors.white, fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.symmetric(vertical: 8),
                                    child: Text(
                                      startDate.split('-').last,
                                      style: const TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.black,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          const SizedBox(width: 12),
                          // Title and Info
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        title,
                                        style: const TextStyle(
                                          fontSize: 22,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: Colors.teal,
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: const Text(
                                        'upcoming',
                                        style: TextStyle(color: AppColors.white, fontSize: 10, fontWeight: FontWeight.bold),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    const Icon(Icons.calendar_today, size: 14, color: AppColors.primary),
                                    const SizedBox(width: 4),
                                    Text(startDate, style: const TextStyle(fontSize: 12, color: AppColors.darkGrey)),
                                    const Padding(
                                      padding: EdgeInsets.symmetric(horizontal: 4),
                                      child: Text('|', style: TextStyle(color: AppColors.grey)),
                                    ),
                                    const Icon(Icons.access_time, size: 14, color: AppColors.primary),
                                    const SizedBox(width: 4),
                                    Text(startTime, style: const TextStyle(fontSize: 12, color: AppColors.darkGrey)),
                                    const Padding(
                                      padding: EdgeInsets.symmetric(horizontal: 4),
                                      child: Text('|', style: TextStyle(color: AppColors.grey)),
                                    ),
                                    const Icon(Icons.location_on, size: 14, color: AppColors.primary),
                                    const SizedBox(width: 4),
                                    Expanded(
                                      child: Text(
                                        venue,
                                        style: const TextStyle(fontSize: 12, color: AppColors.primary, fontWeight: FontWeight.w500),
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
                      const SizedBox(height: 24),

                      // Tabs
                      Row(
                        children: [
                          _buildTab('About', 0),
                          const SizedBox(width: 16),
                          _buildTab('FAQ', 1),
                          const SizedBox(width: 16),
                          _buildTab('Sponsors', 2),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Description
                      if (description.isNotEmpty)
                        Text(
                          description.replaceAll(RegExp(r'<[^>]*>|&nbsp;'), ''),
                          style: const TextStyle(
                            fontSize: 13,
                            color: AppColors.darkGrey,
                            height: 1.4,
                          ),
                        ),
                      const SizedBox(height: 24),

                      // Performers
                      if (_performers.isNotEmpty) ...[
                        const Text(
                          'Performers',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 12),
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: _performers.map((artist) {
                              return Padding(
                                padding: const EdgeInsets.only(right: 12),
                                child: _buildPerformer(
                                  artist['name'] ?? artist['username'] ?? 'Artist',
                                  resolvePublicUrl(artist['photo'] ?? artist['image'] ?? artist['avatar']) ?? 'https://picsum.photos/100/100',
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                        const SizedBox(height: 24),
                      ],

                      // Location
                      const Text(
                        'Location',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Icons.location_on, color: AppColors.primary, size: 20),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  venue,
                                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.primary),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  address,
                                  style: const TextStyle(fontSize: 13, color: AppColors.darkGrey),
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  children: const [
                                    Text(
                                      'Show Map',
                                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                                    ),
                                    Icon(Icons.keyboard_arrow_down, size: 18),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),

                      // Refund Policy
                      const Text(
                        'Refund Policy',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        refundPolicy.isNotEmpty ? refundPolicy : 'No refund policy specified.',
                        style: const TextStyle(fontSize: 13, color: AppColors.darkGrey),
                      ),
                      const SizedBox(height: 32),
                    ],
                  ),
                ),
              ),
            ),

            // Bottom Bar
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.scaffold,
                border: Border(top: BorderSide(color: AppColors.lightGrey.withValues(alpha: 0.5))),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Price', style: TextStyle(fontSize: 12, color: AppColors.darkGrey)),
                        Text(
                          formatPrice(data['payment_info']?['calculate_price'] ?? widget.price),
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    flex: 2,
                    child: CustomButton(
                      title: 'Get Tickets',
                      onTap: () {
                        // Handle ticket purchase
                      },
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getMonthAbbreviation(int month) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    if (month >= 1 && month <= 12) return months[month - 1];
    return 'Month';
  }

  Widget _buildTab(String title, int index) {
    bool isSelected = _selectedTabIndex == index;
    return GestureDetector(
      onTap: () => setState(() => _selectedTabIndex = index),
      child: Column(
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 16,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              color: isSelected ? AppColors.primary : AppColors.darkGrey,
            ),
          ),
          if (isSelected)
            Container(
              margin: const EdgeInsets.only(top: 4),
              height: 2,
              width: 20,
              color: AppColors.primary,
            ),
        ],
      ),
    );
  }

  Widget _buildPerformer(String name, String imageUrl) {
    return Column(
      children: [
        CachedNetworkImage(
          imageUrl: imageUrl,
          imageBuilder: (context, imageProvider) => CircleAvatar(
            radius: 30,
            backgroundImage: imageProvider,
          ),
          placeholder: (context, url) => const CircleAvatar(
            radius: 30,
            backgroundColor: AppColors.lightGrey,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
          errorWidget: (context, url, error) => const CircleAvatar(
            radius: 30,
            backgroundColor: AppColors.lightGrey,
            child: Icon(Icons.person, color: AppColors.grey),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          name,
          style: const TextStyle(fontSize: 12),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }
}
