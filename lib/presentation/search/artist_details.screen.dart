import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../api/api.config.dart';
import '../../api/api.client.dart';
import '../../helpers/app_colors.dart';
import '../../helpers/public_url.dart';
import '../event/event_details.screen.dart';
import '../shared/app_web_view.screen.dart';

class ArtistDetailsScreen extends StatefulWidget {
  final String name;
  final String imageUrl;
  final String artistSlug;

  const ArtistDetailsScreen({
    super.key,
    required this.name,
    required this.imageUrl,
    required this.artistSlug,
  });

  @override
  State<ArtistDetailsScreen> createState() => _ArtistDetailsScreenState();
}

class _ArtistDetailsScreenState extends State<ArtistDetailsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  Map<String, dynamic>? _artistDetail;
  bool _isLoading = true;
  List<dynamic> _upcomingEvents = [];
  List<dynamic> _pastEvents = [];
  bool _isUpcomingTab = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _fetchArtistDetail();
  }

  Future<void> _fetchArtistDetail() async {
    setState(() => _isLoading = true);
    try {
      final response = await ApiClient.getCustomerArtistDetail(widget.artistSlug);
      debugPrint('Artist Detail API Response: $response');
      if (response != null) {
        setState(() {
          _artistDetail = response;
          
          // Extract events from paginated structure: data['events']['data']
          final upcomingData = _artistDetail?['events'];
          if (upcomingData is Map && upcomingData['data'] is List) {
            _upcomingEvents = upcomingData['data'];
          } else if (upcomingData is List) {
            _upcomingEvents = upcomingData;
          } else {
            _upcomingEvents = [];
          }

          // Extract past events from paginated structure: data['past_events']['data']
          final pastData = _artistDetail?['past_events'];
          if (pastData is Map && pastData['data'] is List) {
            _pastEvents = pastData['data'];
          } else if (pastData is List) {
            _pastEvents = pastData;
          } else {
            _pastEvents = [];
          }
                        
          _isLoading = false;
        });
      } else {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      debugPrint('Error fetching artist details: $e');
      setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Safe extraction based on provided JSON
    final about = _artistDetail?['about'] ?? _artistDetail?['biography'] ?? '';
    final name = _artistDetail?['name'] ?? widget.name;
    final imageUrl = resolvePublicUrl(_artistDetail?['photo'] ?? _artistDetail?['image']) ?? widget.imageUrl;
    
    // Socials
    final social = _artistDetail?['social'] is Map ? _artistDetail!['social'] : {};
    
    // Tracks: JSON shows 'top_tracks'
    final tracksData = _artistDetail?['top_tracks'] ?? _artistDetail?['popular_tracks'] ?? _artistDetail?['tracks'];
    final tracks = tracksData is List ? tracksData : [];
    
    // Videos
    final videosData = _artistDetail?['videos'] ?? _artistDetail?['video_exclusives'];
    List<dynamic> videos = videosData is List ? videosData : [];
    
    // If no videos list, but there is a youtube link in socials, show it as a single video
    if (videos.isEmpty && social['youtube'] != null && social['youtube'].toString().isNotEmpty) {
      videos = [{
        'title': 'Official Video',
        'thumbnail': imageUrl, // Fallback to artist photo
        'url': social['youtube'],
      }];
    }
    
    final currentEvents = _isUpcomingTab ? _upcomingEvents : _pastEvents;

    return Scaffold(
      backgroundColor: AppColors.white,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _fetchArtistDetail,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Bar
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
                          child: const Icon(Icons.arrow_back, color: AppColors.white, size: 20),
                        ),
                      ),
                      Row(
                        children: const [
                          Icon(Icons.ios_share, color: AppColors.grey, size: 24),
                        ],
                      ),
                    ],
                  ),
                ),

                // Artist Info Card
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.white,
                      borderRadius: BorderRadius.circular(12),
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
                        Row(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.network(
                                imageUrl,
                                width: 60,
                                height: 60,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) => Container(
                                  width: 60,
                                  height: 60,
                                  color: AppColors.lightGrey,
                                  child: const Icon(Icons.person, size: 30, color: AppColors.grey),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                name,
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.black,
                                ),
                              ),
                            ),
                          ],
                        ),
                        if (about.isNotEmpty) ...[
                          const SizedBox(height: 12),
                          const Text(
                            'About :',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                          ),
                          Html(
                            data: about,
                            style: {
                              "body": Style(
                                fontSize: FontSize(13),
                                margin: Margins.zero,
                                padding: HtmlPaddings.zero,
                                color: AppColors.black,
                                maxLines: 3,
                                textOverflow: TextOverflow.ellipsis,
                              ),
                            },
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            'Read more',
                            style: TextStyle(
                              color: Color(0xFF6C63FF),
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            if (social['facebook'] != null && social['facebook'].toString().isNotEmpty) ...[
                              _buildSocialIcon(
                                'assets/svg/facebook.svg',
                                onTap: () => _openSocialLink(context, 'Facebook', social['facebook']),
                              ),
                              const SizedBox(width: 10),
                            ],
                            if (social['twitter'] != null && social['twitter'].toString().isNotEmpty) ...[
                              _buildSocialIcon(
                                'https://pamevent.com/assets/front/img/twitter_icon.png', 
                                isNetwork: true,
                                onTap: () => _openSocialLink(context, 'X (Twitter)', social['twitter']),
                              ),
                              const SizedBox(width: 10),
                            ],
                            if (social['instagram'] != null && social['instagram'].toString().isNotEmpty) ...[
                              _buildSocialIcon(
                                'https://pamevent.com/assets/front/img/instagram_icon.png',
                                isNetwork: true,
                                onTap: () => _openSocialLink(context, 'Instagram', social['instagram']),
                              ),
                              const SizedBox(width: 10),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                ),

                // Events Section
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16.0),
                  child: Text(
                    'Events',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: AppColors.black,
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                // Tabs
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Row(
                    children: [
                      GestureDetector(
                        onTap: () => setState(() => _isUpcomingTab = true),
                        child: _buildTabItem('Upcoming', _isUpcomingTab),
                      ),
                      const SizedBox(width: 8),
                      GestureDetector(
                        onTap: () => setState(() => _isUpcomingTab = false),
                        child: _buildTabItem('Past', !_isUpcomingTab),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // Event List (Vertical list matching HomeScreen design)
                if (_isLoading)
                  const Center(child: Padding(
                    padding: EdgeInsets.all(20.0),
                    child: CircularProgressIndicator(),
                  ))
                else if (currentEvents.isEmpty)
                  const Center(child: Padding(
                    padding: EdgeInsets.all(20.0),
                    child: Text('No events found'),
                  ))
                else
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Column(
                      children: currentEvents.map((event) => Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: _buildEventCard(event),
                      )).toList(),
                    ),
                  ),

                const SizedBox(height: 24),

                // Video Exclusive
                if (videos.isNotEmpty) ...[
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16.0),
                    child: Text(
                      'Video Exclusive',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: AppColors.black,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  ...videos.map((video) => Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8),
                        child: _buildVideoCard(video, name),
                      )).toList(),
                  const SizedBox(height: 24),
                ],

                // Popular Tracks
                if (tracks.isNotEmpty) ...[
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16.0),
                    child: Text(
                      'Popular Tracks',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: AppColors.black,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Container(
                      decoration: BoxDecoration(
                        color: AppColors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.lightGrey.withOpacity(0.5)),
                      ),
                      child: Column(
                        children: tracks.asMap().entries.map((entry) {
                          final index = entry.key;
                          final track = entry.value;
                          return _buildTrackItem(index, track, name, tracks.length);
                        }).toList(),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                ],

                // Spotify Tracks
                if (social['spotify'] != null && social['spotify'].toString().isNotEmpty) ...[
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16.0),
                    child: Text(
                      'Spotify Tracks',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: AppColors.black,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: SpotifyPlayerWidget(url: social['spotify'].toString()),
                  ),
                  const SizedBox(height: 24),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEventCard(dynamic event) {
    final eventId = event['id'] ?? event['event_id'] ?? 0;
    final title = event['title'] ?? 'Untitled Event';
    
    // Improved image URL extraction matching HomeScreen
    final rawThumbnail = event['thumbnail'] ?? event['event_thumbnail'] ?? event['image'] ?? event['event_img'] ?? event['photo'];
    String? imageUrl;
    
    if (event['event_thumbnail_url'] != null) {
      imageUrl = event['event_thumbnail_url'];
    } else if (event['thumbnail_url'] != null) {
      imageUrl = event['thumbnail_url'];
    } else if (rawThumbnail != null) {
      final t = rawThumbnail.toString().trim();
      if (t.startsWith('http://') || t.startsWith('https://')) {
        imageUrl = t;
      } else if (t.isNotEmpty && !t.contains('/')) {
        // If it's just a filename, assume it's an event thumbnail
        imageUrl = '${ApiConfig.host}/assets/admin/img/event-thumbnails/$t';
      } else {
        imageUrl = resolvePublicUrl(t);
      }
    }
    
    imageUrl ??= 'https://picsum.photos/200/200';
                    
    final location = event['venue_name'] ?? event['location'] ?? 'Online';
    final organizer = event['organizer_name'] ?? event['organizer']?['username'] ?? 'Unknown';
    final date = event['start_date'] != null 
        ? '${event['start_date']} / ${event['start_time'] ?? ''}'
        : '';
    
    // Price formatting matching HomeScreen
    String price = '0.00';
    final rawPrice = event['payment_info'] is Map 
        ? (event['payment_info']['calculate_price'] ?? event['payment_info']['original_price'])
        : (event['price'] ?? event['event_price'] ?? event['ticket_price'] ?? event['min_price'] ?? event['starting_price']);
    
    if (rawPrice != null) {
      if (rawPrice is num) {
        price = rawPrice.toStringAsFixed(2);
      } else {
        price = rawPrice.toString();
      }
    }
    final formattedPrice = '\$$price';

    final status = event['status_label'];
    final statusColor = event['status_color'] != null
        ? Color(int.parse(event['status_color'].replaceAll('#', '0xFF')))
        : null;

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => EventDetailsScreen(
              eventId: eventId,
              title: title,
              imageUrl: imageUrl!,
              price: formattedPrice,
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
            imageUrl: imageUrl!,
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
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
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
                  formattedPrice,
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

  Widget _buildVideoCard(dynamic video, String artistName) {
    final thumbnailUrl = resolvePublicUrl(video['thumbnail']) ?? 'https://picsum.photos/400/225';
    final title = video['title'] ?? 'Video';

    return Stack(
      alignment: Alignment.center,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Image.network(
            thumbnailUrl,
            width: double.infinity,
            height: 200,
            fit: BoxFit.cover,
          ),
        ),
        // Play Button Overlay
        Container(
          padding: const EdgeInsets.all(12),
          decoration: const BoxDecoration(
            color: Colors.red,
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.play_arrow, color: AppColors.white, size: 32),
        ),
        // YouTube Overlay
        Positioned(
          top: 12,
          left: 12,
          right: 12,
          child: Row(
            children: [
              CircleAvatar(
                radius: 12,
                backgroundImage: NetworkImage(widget.imageUrl),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '$artistName - $title',
                  style: const TextStyle(
                    color: AppColors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    shadows: [Shadow(color: Colors.black, blurRadius: 4)],
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
        Positioned(
          bottom: 12,
          right: 12,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.7),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: const [
                Text(
                  'Watch on ',
                  style: TextStyle(color: AppColors.white, fontSize: 10),
                ),
                Icon(Icons.play_circle_filled, color: Colors.red, size: 14),
                Text(
                  ' YouTube',
                  style: TextStyle(color: AppColors.white, fontSize: 10, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTrackItem(int index, dynamic track, String artistName, int totalTracks) {
    final imageUrl = resolvePublicUrl(track['image'] ?? track['photo'] ?? track['thumbnail']) ?? 'https://picsum.photos/50/50';
    final title = track['name'] ?? track['title'] ?? 'Track';
    
    // Format duration from ms if available
    String duration = '00:00';
    if (track['duration_ms'] != null) {
      final ms = track['duration_ms'] as int;
      final minutes = (ms / 60000).floor();
      final seconds = ((ms % 60000) / 1000).floor();
      duration = '$minutes:${seconds.toString().padLeft(2, '0')}';
    } else {
      duration = track['duration'] ?? track['time'] ?? '00:00';
    }

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(12.0),
          child: Row(
            children: [
              Text('${index + 1}', style: const TextStyle(fontSize: 14, color: AppColors.grey)),
              const SizedBox(width: 16),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: Image.network(
                  imageUrl,
                  width: 40,
                  height: 40,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => Container(
                    width: 40,
                    height: 40,
                    color: AppColors.lightGrey,
                    child: const Icon(Icons.music_note, size: 20, color: AppColors.grey),
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
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      artistName,
                      style: const TextStyle(fontSize: 12, color: AppColors.grey),
                    ),
                  ],
                ),
              ),
              Text(
                duration,
                style: const TextStyle(fontSize: 12, color: AppColors.grey),
              ),
            ],
          ),
        ),
        if (index < totalTracks - 1)
          const Divider(height: 1, color: AppColors.lightGrey, indent: 40),
      ],
    );
  }

  void _openSocialLink(BuildContext context, String title, dynamic rawUrl) {
    final url = resolvePublicUrl(rawUrl.toString());
    if (url != null) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => AppWebViewScreen(title: title, url: url),
        ),
      );
    }
  }

  Widget _buildSocialIcon(String iconPath, {bool isNetwork = false, VoidCallback? onTap}) {
        return GestureDetector(
          onTap: onTap,
          child: Container(
            width: 32,
            height: 32,
            padding: const EdgeInsets.all(8),
            decoration: const BoxDecoration(
              color: AppColors.black,
              shape: BoxShape.circle,
            ),
            child: isNetwork
                ? Image.network(
                    iconPath,
                    color: AppColors.white,
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) => const Icon(Icons.link, color: AppColors.white, size: 14),
                  )
                : SvgPicture.asset(
                    iconPath,
                    colorFilter: const ColorFilter.mode(AppColors.white, BlendMode.srcIn),
                    fit: BoxFit.contain,
                  ),
          ),
        );
      }

  Widget _buildTabItem(String title, bool isActive) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: isActive ? const Color(0xFF6C63FF) : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        title,
        style: TextStyle(
          color: isActive ? AppColors.white : AppColors.black,
          fontWeight: FontWeight.bold,
          fontSize: 14,
        ),
      ),
    );
  }
}

class SpotifyPlayerWidget extends StatefulWidget {
  final String url;
  const SpotifyPlayerWidget({super.key, required this.url});

  @override
  State<SpotifyPlayerWidget> createState() => _SpotifyPlayerWidgetState();
}

class _SpotifyPlayerWidgetState extends State<SpotifyPlayerWidget> {
  late final WebViewController _controller;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(const Color(0x00000000))
      ..loadRequest(Uri.parse(widget.url));
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 380,
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.lightGrey.withOpacity(0.5)),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: WebViewWidget(controller: _controller),
      ),
    );
  }
}
