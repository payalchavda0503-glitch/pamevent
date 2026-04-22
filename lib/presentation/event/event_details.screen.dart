import 'dart:async';
import 'dart:developer' as dev;
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '../../api/api.client.dart';
import '../../helpers/app_colors.dart';
import '../../helpers/public_url.dart';
import '../../helpers/utils.dart';
import '../shared/widgets/custom_button.widget.dart';
import '../shared/widgets/custom_image.dart';
import '../search/artist_details.screen.dart';
import '../tickets/select_tickets.screen.dart';

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
  bool _showMap = false;
  Map<String, dynamic>? _eventDetail;
  List<dynamic> _performers = [];
  List<String> _galleryImages = [];
  int _currentImageIndex = 0;
  Timer? _sliderTimer;
  final PageController _pageController = PageController();
  WebViewController? _mapController;

  @override
  void initState() {
    super.initState();
    if (widget.eventId != 0) {
      _fetchEventDetail();
    } else {
      _isLoading = false;
    }
  }

  @override
  void dispose() {
    _sliderTimer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _fetchEventDetail() async {
    debugPrint('Fetching details for eventId: ${widget.eventId}');
    setState(() => _isLoading = true);
    try {
      final data = await ApiClient.getCustomerEventDetail(widget.eventId);
      debugPrint('Event detail API response received for eventId: ${widget.eventId}');
      
      // Printing in chunks so it shows in any console (Terminal or Debug Console)
      String dataStr = 'FULL API DATA: $data';
      for (int i = 0; i < dataStr.length; i += 1000) {
        int end = (i + 1000 < dataStr.length) ? i + 1000 : dataStr.length;
        print(dataStr.substring(i, end));
      }
      
      if (mounted) {
        if (data == null) {
          setState(() {
            _isLoading = false;
          });
          // Show error toast or handle null data
          return;
        }
        setState(() {
          _eventDetail = data;
          // Extract performers directly from event detail response
          _performers = data['performers'] is List ? data['performers'] : [];
          
          // Extract gallery images
          if (data['gallery_images'] is List) {
            _galleryImages = List<String>.from(data['gallery_images'].map((e) {
              String url = e.toString().trim();
              if (url.endsWith(',')) {
                url = url.substring(0, url.length - 1);
              }
              return url;
            }));
          }
          
          // Add the main event image to the gallery if it's not already there
          String? mainImg = (data['event_img'] ?? data['event_thumbnail'])?.toString().trim();
          if (mainImg != null && mainImg.endsWith(',')) {
            mainImg = mainImg.substring(0, mainImg.length - 1);
          }

          if (mainImg != null && !_galleryImages.contains(mainImg)) {
             _galleryImages.insert(0, mainImg);
          }
          
          if (_galleryImages.isEmpty && widget.imageUrl.isNotEmpty) {
            _galleryImages.add(widget.imageUrl);
          }

          _isLoading = false;
        });
        _startSliderTimer();
      }
    } catch (e) {
      debugPrint('Error fetching event details: $e');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _startSliderTimer() {
    _sliderTimer?.cancel();
    if (_galleryImages.length > 1) {
      _sliderTimer = Timer.periodic(const Duration(seconds: 4), (timer) {
        if (_pageController.hasClients) {
          _currentImageIndex = (_currentImageIndex + 1) % _galleryImages.length;
          _pageController.animateToPage(
            _currentImageIndex,
            duration: const Duration(milliseconds: 800),
            curve: Curves.easeInOut,
          );
        }
      });
    }
  }

  void _openImagePreview(int initialIndex) {
    showDialog(
      context: context,
      builder: (context) => _ImagePreviewModal(
        images: _galleryImages,
        initialIndex: initialIndex,
      ),
    );
  }

  void _toggleMap({String? address, String? fullUrl}) {
    setState(() {
      _showMap = !_showMap;
      if (_showMap && _mapController == null) {
        String mapUrl = '';
        
        if (fullUrl != null && fullUrl.isNotEmpty) {
          // If fullUrl starts with //, prepend https:
          mapUrl = fullUrl.startsWith('//') ? 'https:$fullUrl' : fullUrl;
          // Unescape &amp; to &
          mapUrl = mapUrl.replaceAll('&amp;', '&');
        } else if (address != null && address.isNotEmpty) {
          final encodedAddress = Uri.encodeComponent(address);
          mapUrl = 'https://maps.google.com/maps?q=$encodedAddress&output=embed';
        }

        if (mapUrl.isNotEmpty) {
          final htmlContent = '''
            <!DOCTYPE html>
            <html>
              <head>
                <meta name="viewport" content="width=device-width, initial-scale=1.0">
                <style>
                  body { margin: 0; padding: 0; overflow: hidden; }
                  iframe { width: 100%; height: 100vh; border: 0; }
                </style>
              </head>
              <body>
                <iframe src="$mapUrl" allowfullscreen></iframe>
              </body>
            </html>
          ''';

          _mapController = WebViewController()
            ..setJavaScriptMode(JavaScriptMode.unrestricted)
            ..loadHtmlString(htmlContent);
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_eventDetail == null && widget.eventId != 0) {
      return Scaffold(
        appBar: AppBar(backgroundColor: AppColors.white, elevation: 0, leading: BackButton(color: AppColors.black)),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 48, color: Colors.red),
              const SizedBox(height: 16),
              const Text('Failed to load event details.'),
              const SizedBox(height: 8),
              const Text('Please try again later.'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _fetchEventDetail,
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    final data = _eventDetail ?? {};
    
    // Improved image URL parsing to handle trailing commas or invalid data
    String? rawImageUrl = data['event_img'] ?? data['event_thumbnail'];
    String imageUrl = rawImageUrl?.toString().trim() ?? widget.imageUrl;
    if (imageUrl.endsWith(',')) {
      imageUrl = imageUrl.substring(0, imageUrl.length - 1);
    }
    
    final title = data['title'] ?? widget.title;
    final venue = data['venue'] ?? '';
    final address = '${data['city'] ?? ''}, ${data['country'] ?? ''}'.trim();
    
    // Improved date extraction with fallback to event_dates
    String startDate = data['start_date'] ?? '';
    String startTime = data['start_time'] ?? '';
    
    if (startDate.isEmpty && data['multiple_dates'] is List && (data['multiple_dates'] as List).isNotEmpty) {
      final firstDateObj = (data['multiple_dates'] as List).first;
      startDate = firstDateObj['start_date']?.toString() ?? '';
      startTime = firstDateObj['start_time']?.toString() ?? '';
    }

    final description = data['description'] ?? '';
    final refundPolicy = data['refund_policy'] ?? '';
    
    // Improved address extraction from API
    final mapAddress = (data['map_address'] != null && data['map_address'].toString().isNotEmpty)
        ? data['map_address'].toString()
        : '$venue, $address';
    final mapFullUrl = data['map_full_address']?.toString();

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
                      // Event Image Slider
                      SizedBox(
                        height: 200,
                        width: double.infinity,
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: Stack(
                            children: [
                              PageView.builder(
                                controller: _pageController,
                                itemCount: _galleryImages.length,
                                onPageChanged: (index) {
                                  setState(() => _currentImageIndex = index);
                                },
                                itemBuilder: (context, index) {
                                  final img = _galleryImages[index];
                                  return GestureDetector(
                                    onTap: () => _openImagePreview(index),
                                    child: CustomImage(
                                      resolvePublicUrl(img) ?? img,
                                      width: double.infinity,
                                      height: 200,
                                      fit: BoxFit.cover,
                                      whenEmpty: Container(
                                        height: 200,
                                        color: AppColors.lightGrey,
                                        child: const Icon(Icons.image_not_supported, size: 50),
                                      ),
                                    ),
                                  );
                                },
                              ),
                              if (_galleryImages.length > 1)
                                Positioned(
                                  bottom: 12,
                                  left: 0,
                                  right: 0,
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: List.generate(
                                      _galleryImages.length,
                                      (index) => Container(
                                        width: 8,
                                        height: 8,
                                        margin: const EdgeInsets.symmetric(horizontal: 4),
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          color: _currentImageIndex == index
                                              ? AppColors.primary
                                              : AppColors.white.withValues(alpha: 0.5),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
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
                                    Text(formatEventDate(startDate), style: const TextStyle(fontSize: 12, color: AppColors.darkGrey)),
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
                                  artist['slug'] ?? artist['username'] ?? '',
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
                                  mapAddress,
                                  style: const TextStyle(fontSize: 13, color: AppColors.darkGrey),
                                ),
                                const SizedBox(height: 12),
                                GestureDetector(
                                  onTap: () => _toggleMap(address: mapAddress, fullUrl: mapFullUrl),
                                  child: Row(
                                    children: [
                                      Text(
                                        _showMap ? 'Hide Map' : 'Show Map',
                                        style: const TextStyle(
                                          fontSize: 13, 
                                          fontWeight: FontWeight.w500,
                                          color: AppColors.primary,
                                        ),
                                      ),
                                      Icon(
                                        _showMap ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down, 
                                        size: 18,
                                        color: AppColors.primary,
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      
                      // Embedded Map
                      if (_showMap && _mapController != null) ...[
                        const SizedBox(height: 16),
                        Container(
                          height: 250,
                          width: double.infinity,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppColors.lightGrey),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: WebViewWidget(controller: _mapController!),
                          ),
                        ),
                      ],
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
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => SelectTicketsScreen(eventId: widget.eventId),
                          ),
                        );
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

  Widget _buildPerformer(String name, String imageUrl, String slug) {
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
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.lightGrey),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(30),
              child: CustomImage(
                imageUrl,
                width: 60,
                height: 60,
                fit: BoxFit.cover,
                whenEmpty: Container(
                  width: 60,
                  height: 60,
                  color: AppColors.lightGrey,
                  child: const Icon(Icons.person, color: AppColors.grey),
                ),
              ),
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
      ),
    );
  }
}

class _ImagePreviewModal extends StatefulWidget {
  final List<String> images;
  final int initialIndex;

  const _ImagePreviewModal({
    required this.images,
    required this.initialIndex,
  });

  @override
  State<_ImagePreviewModal> createState() => _ImagePreviewModalState();
}

class _ImagePreviewModalState extends State<_ImagePreviewModal> {
  late PageController _previewController;
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _previewController = PageController(initialPage: widget.initialIndex);
  }

  @override
  void dispose() {
    _previewController.dispose();
    super.dispose();
  }

  void _nextPage() {
    if (_currentIndex < widget.images.length - 1) {
      _previewController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _previousPage() {
    if (_currentIndex > 0) {
      _previewController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog.fullscreen(
      backgroundColor: Colors.black,
      child: Stack(
        children: [
          // Image Pager
          PageView.builder(
            controller: _previewController,
            itemCount: widget.images.length,
            onPageChanged: (index) {
              setState(() => _currentIndex = index);
            },
            itemBuilder: (context, index) {
              final img = widget.images[index];
              return InteractiveViewer(
                minScale: 0.5,
                maxScale: 4.0,
                child: Center(
                  child: CustomImage(
                    resolvePublicUrl(img) ?? img,
                    width: double.infinity,
                    fit: BoxFit.contain,
                  ),
                ),
              );
            },
          ),

          // Close Button
          Positioned(
            top: 40,
            right: 20,
            child: IconButton(
              icon: const Icon(Icons.close, color: Colors.white, size: 30),
              onPressed: () => Navigator.pop(context),
            ),
          ),

          // Navigation Buttons (Previous/Next)
          if (widget.images.length > 1) ...[
            // Previous Button
            if (_currentIndex > 0)
              Positioned(
                left: 10,
                top: 0,
                bottom: 0,
                child: Center(
                  child: IconButton(
                    icon: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.5),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 24),
                    ),
                    onPressed: _previousPage,
                  ),
                ),
              ),

            // Next Button
            if (_currentIndex < widget.images.length - 1)
              Positioned(
                right: 10,
                top: 0,
                bottom: 0,
                child: Center(
                  child: IconButton(
                    icon: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.5),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.arrow_forward_ios, color: Colors.white, size: 24),
                    ),
                    onPressed: _nextPage,
                  ),
                ),
              ),
          ],

          // Image Counter
          Positioned(
            bottom: 40,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${_currentIndex + 1} / ${widget.images.length}',
                  style: const TextStyle(color: Colors.white, fontSize: 16),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
