import 'dart:async';
import 'dart:developer' as dev;
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import '../shared/widgets/price_display.widget.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '../../api/api.client.dart';
import '../../helpers/app_colors.dart';
import '../../helpers/public_url.dart';
import '../../helpers/utils.dart';
import '../shared/widgets/custom_button.widget.dart';
import '../shared/widgets/custom_image.dart';
import '../search/artist_details.screen.dart';
import '../search/venue_details.screen.dart';
import '../tickets/select_tickets.screen.dart';

class IframeWidget extends StatefulWidget {
  final String url;
  const IframeWidget({super.key, required this.url});

  @override
  State<IframeWidget> createState() => _IframeWidgetState();
}

class _IframeWidgetState extends State<IframeWidget> {
  late final WebViewController _controller;
  bool _hasError = false;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _initController();
  }

  void _initController() {
    String url = widget.url.trim();
    
    // Handle protocol-relative URLs
    if (url.startsWith('//')) {
      url = 'https:$url';
    }

    // Comprehensive YouTube URL parsing to ensure proper embed format
    if (url.contains('youtube.com') || url.contains('youtu.be')) {
      String videoId = '';
      if (url.contains('watch?v=')) {
        videoId = url.split('v=').last.split('&').first;
      } else if (url.contains('youtu.be/')) {
        videoId = url.split('youtu.be/').last.split('?').first;
      } else if (url.contains('embed/')) {
        videoId = url.split('embed/').last.split('?').first;
      } else if (url.contains('shorts/')) {
        videoId = url.split('shorts/').last.split('?').first;
      }

      if (videoId.isNotEmpty) {
        // Use origin matching Referer to avoid Error 152-4/153 and load privacy-enhanced embed
        url = 'https://www.youtube-nocookie.com/embed/$videoId?rel=0&modestbranding=1&enablejsapi=1&origin=https://pamevent.com';
      }
    }

    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(Colors.black)
      // Do not set a custom user agent by default to prevent triggering YouTube's bot/user-agent spoofing detection on iOS/Android
      ..setNavigationDelegate(
        NavigationDelegate(
          onProgress: (progress) {
            if (progress > 50 && mounted) {
              setState(() {
                _isLoading = false;
              });
            }
          },
          onPageFinished: (_) {
            if (mounted) {
              setState(() {
                _isLoading = false;
              });
            }
          },
          onWebResourceError: (error) {
            debugPrint('WebView Error: ${error.description} (Code: ${error.errorCode})');
            // Do NOT show error UI for common YouTube/WebView warnings
            if (mounted && (error.isForMainFrame ?? false) && error.errorCode != -1 && error.errorCode != 153 && error.errorCode != 152) {
            }
          },
        ),
      );

    _controller.loadRequest(
      Uri.parse(url.trim()),
      headers: {
        'Referer': 'https://pamevent.com/',
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: Colors.black,
      margin: EdgeInsets.zero, // Remove top margin to fix gap
      child: AspectRatio(
        aspectRatio: 16 / 9,
        child: Stack(
          alignment: Alignment.center,
          children: [
            if (!_hasError)
              WebViewWidget(controller: _controller),
            
            if (_isLoading && !_hasError)
              const Center(
                child: SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: AppColors.primary,
                  ),
                ),
              ),

            if (_hasError)
              Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error_outline, color: Colors.white, size: 20),
                    TextButton(
                      onPressed: () => launchUrl(Uri.parse(widget.url), mode: LaunchMode.externalApplication),
                      child: const Text('Open Video', style: TextStyle(fontSize: 10, color: AppColors.primary)),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class DescriptionHtml extends StatelessWidget {
  final String description;
  final List<dynamic>? faqs;
  final bool isFaq;

  const DescriptionHtml({
    super.key,
    required this.description,
    this.faqs,
    this.isFaq = false,
  });

  @override
  Widget build(BuildContext context) {
    if (isFaq && faqs != null) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: faqs!.map((faq) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  faq['question'] ?? faq['title'] ?? 'Question',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: AppColors.black,
                  ),
                ),
                const SizedBox(height: 2),
                _buildHtml(context, (faq['answer'] ?? faq['description'] ?? '').toString()),
              ],
            ),
          );
        }).toList(),
      );
    }
    return _buildHtml(context, description);
  }

  Widget _buildHtml(BuildContext context, String htmlData) {
    if (htmlData.isEmpty || htmlData.toLowerCase().contains('no description available')) return const SizedBox.shrink();

    // 1. Replace non-breaking spaces with standard spaces
    String cleaned = htmlData.replaceAll('&nbsp;', ' ');

    // 2. Strip width and height attributes from iframe tags so that flutter_html does not force layout heights
    cleaned = cleaned.replaceAllMapped(RegExp(r'<iframe([^>]+)>', caseSensitive: false), (match) {
      String attrs = match.group(1)!;
      attrs = attrs
          .replaceAll(RegExp(r'\b(width|height)\s*=\s*("[^"]*"|' r"'[^']*'" r'|[^\s>]+)', caseSensitive: false), '')
          .trim();
      return '<iframe $attrs>';
    });

    // 3. Recursively remove empty tags (even with attributes) and collapse spaces/breaks to eliminate vertical layout gaps
    String previous;
    do {
      previous = cleaned;
      cleaned = cleaned
          .replaceAll(RegExp(r'<p[^>]*>[ \s]*</p>', caseSensitive: false), '')
          .replaceAll(RegExp(r'<p[^>]*>[ \s]*<br\s*/?>[ \s]*</p>', caseSensitive: false), '')
          .replaceAll(RegExp(r'<span[^>]*>[ \s]*</span>', caseSensitive: false), '')
          .replaceAll(RegExp(r'<div[^>]*>[ \s]*</div>', caseSensitive: false), '')
          .replaceAll(RegExp(r'(<br\s*/?>[ \s]*)+', caseSensitive: false), '<br />')
          .trim();
    } while (cleaned != previous);

    // 4. Remove leading/trailing breaks
    cleaned = cleaned
        .replaceAll(RegExp(r'^(<br\s*/?>\s*)+', caseSensitive: false), '')
        .replaceAll(RegExp(r'(<br\s*/?>\s*)+$', caseSensitive: false), '')
        .trim();

    // Compute layout constraints for the WebView iframe based on the device width to prevent extra empty wrapper gaps
    final double contentWidth = MediaQuery.of(context).size.width - 32.0; // Subtract padding: 16.0 left + 16.0 right
    final double iframeHeight = contentWidth * 9 / 16; // Maintain 16:9 aspect ratio

    return Html(
      data: cleaned,
      onLinkTap: (url, _, __) {
        if (url != null) {
          launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
        }
      },
      extensions: [
        TagExtension(
          tagsToExtend: {"iframe"},
          builder: (extensionContext) {
            final url = extensionContext.attributes['src'];
            if (url == null || url.isEmpty) return const SizedBox();
            return IframeWidget(key: ValueKey(url), url: url);
          },
        ),
      ],
      style: {
        "body": Style(
          fontSize: FontSize(13),
          color: AppColors.darkGrey,
          lineHeight: LineHeight(1.4),
          margin: Margins.zero,
          padding: HtmlPaddings.zero,
        ),
        "p": Style(
          margin: Margins.only(bottom: 8),
          padding: HtmlPaddings.zero,
        ),
        "div": Style(
          margin: Margins.zero,
          padding: HtmlPaddings.zero,
        ),
        "iframe": Style(
          margin: Margins.zero,
          padding: HtmlPaddings.zero,
          display: Display.block,
          width: Width(contentWidth),
          height: Height(iframeHeight),
        ),
        "hr": Style(
          margin: Margins.only(top: 8, bottom: 8),
          padding: HtmlPaddings.zero,
        ),
      },
    );
  }
}

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
  List<dynamic> _faqs = [];
  List<dynamic> _sponsors = [];
  int _currentImageIndex = 0;
  Timer? _sliderTimer;
  final PageController _pageController = PageController();
  WebViewController? _mapController;
  Widget? _cachedDescription;
  Widget? _cachedFaq;

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
    setState(() {
      _isLoading = true;
      _cachedDescription = null; // Clear cache on new fetch
      _cachedFaq = null;
    });
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
          _faqs = data['faqs'] is List ? data['faqs'] : data['faq'] is List ? data['faq'] : [];
          _sponsors = (data['sponsors'] is List) 
              ? data['sponsors'] 
              : (data['event_sponsors'] is List ? data['event_sponsors'] : []);
          
          print('FAQs count: ${_faqs.length}');
          print('Sponsors count: ${_sponsors.length}');
          
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
          
          // If the URL is already an embed URL from google, we try to ensure it has the q parameter for the pin
          if (mapUrl.contains('google.com/maps') && !mapUrl.contains('q=')) {
            final encodedAddress = Uri.encodeComponent(address ?? '');
            if (encodedAddress.isNotEmpty) {
               if (mapUrl.contains('?')) {
                 mapUrl += '&q=$encodedAddress';
               } else {
                 mapUrl += '?q=$encodedAddress';
               }
            }
          }
        } else if (address != null && address.isNotEmpty) {
          final encodedAddress = Uri.encodeComponent(address);
          // Using a more reliable embed format for pins
          mapUrl = 'https://maps.google.com/maps?q=$encodedAddress&t=&z=15&ie=UTF8&iwloc=B&output=embed';
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
     final venuepic = data['event_address'] ?? '';
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
                        onPressed: () {
                          String shareUrl = '';
                          if (data['share_link'] is Map) {
                            shareUrl = data['share_link']['link']?.toString() ?? '';
                          } else {
                            shareUrl = data['share_link']?.toString() ?? '';
                          }

                          if (shareUrl.isNotEmpty) {
                            Share.share(shareUrl);
                          } else {
                            final slug = data['slug'] ?? '';
                            final id = widget.eventId;
                            if (slug.isNotEmpty) {
                              final manualUrl = 'https://pamevent.com/event/$slug/$id';
                              Share.share('Check out this event: $title\n$manualUrl');
                            }
                          }
                        },
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
                                      child: GestureDetector(
                                        onTap: () {
                                          final venueName = data['venue']?.toString() ?? '';
                                          final venueSlug = data['venue_detail']?['slug']?.toString() ?? venueName;
                                          if (venueSlug.isNotEmpty) {
                                            Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                builder: (context) => VenueDetailsScreen(
                                                  slug: venueSlug,
                                                  name: venueName,
                                                ),
                                              ),
                                            );
                                          }
                                        },
                                        child: Text(
                                          venuepic,
                                          style: const TextStyle(fontSize: 12, color: AppColors.primary, fontWeight: FontWeight.w500),
                                          overflow: TextOverflow.ellipsis,
                                        ),
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
                          if (_sponsors.isNotEmpty) ...[
                            const SizedBox(width: 16),
                            _buildTab('Sponsors', 2),
                          ],
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Tab Content
                      _buildTabContent(description),
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
                                GestureDetector(
                                   onTap: () {
                                      final venueName = data['venue']?.toString() ?? '';
                                      final venueSlug = data['venue_detail']?['slug']?.toString() ?? venueName;
                                      if (venueSlug.isNotEmpty) {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) => VenueDetailsScreen(
                                              slug: venueSlug,
                                              name: venueName,
                                            ),
                                          ),
                                        );
                                      }
                                    },
                                   child: Text(
                                     venue,
                                     style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.primary),
                                   ),
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
                        GestureDetector(
                          onTap: () => _openInMaps(mapAddress),
                          child: Container(
                            height: 250,
                            width: double.infinity,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: AppColors.lightGrey),
                            ),
                            child: Stack(
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(12),
                                  child: WebViewWidget(controller: _mapController!),
                                ),
                                // Overlay to make it clickable
                                Positioned.fill(
                                  child: Container(
                                    color: Colors.transparent,
                                  ),
                                ),
                              ],
                            ),
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
                        PriceDisplay(
                          price: data['payment_info']?['calculate_price'] ?? widget.price,
                          originalPrice: data['payment_info']?['original_price'] ?? data['payment_info']?['calculate_price'] ?? data['original_price'],
                          isDiscounted: data['payment_info']?['early_bird_discount'] == 'enable' || data['early_bird_discount'] == 'enable',
                          priceStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
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
                            builder: (context) {
                              final settings = _eventDetail?['settings'];
                              return SelectTicketsScreen(
                                eventId: widget.eventId,
                                feePerTicketPerc: double.tryParse(settings?['fee_per_ticket_perc']?.toString() ?? ''),
                                feePerTicketAmount: double.tryParse(settings?['fee_per_ticket_amount']?.toString() ?? ''),
                                gateways: _eventDetail?['gateways'],
                              );
                            },
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

  Widget _buildTabContent(String description) {
    // Determine which tab is active
    if (_selectedTabIndex == 0) {
      // About Tab: Show description
      // Cache the widget to prevent re-building it on every parent setState
      return _cachedDescription ??= DescriptionHtml(description: description);
    } else if (_selectedTabIndex == 1) {
      // FAQ Tab
      if (_faqs.isEmpty) {
        return const SizedBox.shrink();
      }
      return _cachedFaq ??= DescriptionHtml(description: '', faqs: _faqs, isFaq: true);
    } else if (_selectedTabIndex == 2 && _sponsors.isNotEmpty) {
      // Sponsors Tab (only if visible)
      if (_sponsors.isEmpty) {
        return const SizedBox.shrink();
      }
      return Wrap(
        spacing: 12,
        runSpacing: 12,
        children: _sponsors.map((sponsor) {
          final name = sponsor['name'] ?? sponsor['title'] ?? 'Sponsor';
          final logo = resolvePublicUrl(sponsor['logo'] ?? sponsor['picture'] ?? '');
          return Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.lightGrey),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (logo != null && logo.isNotEmpty)
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: CustomImage(
                        logo,
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
                if (logo == null || logo.isEmpty)
                  const Icon(Icons.business, size: 40, color: AppColors.grey),
                Padding(
                  padding: const EdgeInsets.all(4),
                  child: Text(
                    name,
                    style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w500),
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      );
    } else {
      // Fallback to About tab if invalid index
      return DescriptionHtml(description: description);
    }
  }

  Future<void> _openInMaps(String address) async {
    final encodedAddress = Uri.encodeComponent(address);
    final Uri googleMapsUrl = Uri.parse("https://www.google.com/maps/search/?api=1&query=$encodedAddress");
    final Uri appleMapsUrl = Uri.parse("https://maps.apple.com/?q=$encodedAddress");
    final Uri androidGeoUrl = Uri.parse("geo:0,0?q=$encodedAddress");

    try {
      if (Platform.isAndroid) {
        if (await canLaunchUrl(androidGeoUrl)) {
          await launchUrl(androidGeoUrl);
        } else {
          await launchUrl(googleMapsUrl, mode: LaunchMode.externalApplication);
        }
      } else if (Platform.isIOS) {
        if (await canLaunchUrl(appleMapsUrl)) {
          await launchUrl(appleMapsUrl);
        } else {
          await launchUrl(googleMapsUrl, mode: LaunchMode.externalApplication);
        }
      } else {
        await launchUrl(googleMapsUrl, mode: LaunchMode.externalApplication);
      }
    } catch (e) {
      dev.log('Error launching maps: $e');
      if (await canLaunchUrl(googleMapsUrl)) {
        await launchUrl(googleMapsUrl, mode: LaunchMode.externalApplication);
      }
    }
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
