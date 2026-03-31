import 'package:flutter/material.dart';
import '../../helpers/app_colors.dart';

class ArtistDetailsScreen extends StatefulWidget {
  final String name;
  final String imageUrl;

  const ArtistDetailsScreen({
    super.key,
    required this.name,
    required this.imageUrl,
  });

  @override
  State<ArtistDetailsScreen> createState() => _ArtistDetailsScreenState();
}

class _ArtistDetailsScreenState extends State<ArtistDetailsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      body: SafeArea(
        child: SingleChildScrollView(
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
                      children: [
                        const Icon(Icons.ios_share, color: AppColors.grey, size: 24),
                        const SizedBox(width: 16),
                        const Icon(Icons.bookmark_border, color: AppColors.grey, size: 24),
                      ],
                    ),
                  ],
                ),
              ),

              // Artist Header
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                child: Row(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.network(
                        widget.imageUrl,
                        width: 100,
                        height: 100,
                        fit: BoxFit.cover,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Text(
                        widget.name,
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: AppColors.black,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),

              // About Section
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text.rich(
                      TextSpan(
                        text: 'About : ',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                        children: [
                          TextSpan(
                            text: 'Jonathan Perry, widely known by his stage name, J Perry, is a Haitian musician, singer, songwriter, and producer of international renown.',
                            style: TextStyle(fontWeight: FontWeight.normal),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Read less',
                      style: TextStyle(
                        color: AppColors.primary,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        _buildSocialIcon(Icons.facebook),
                        const SizedBox(width: 10),
                        _buildSocialIcon(Icons.camera_alt_outlined), // Placeholder for Twitter/X
                        const SizedBox(width: 10),
                        _buildSocialIcon(Icons.camera_alt), // Placeholder for Instagram
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 12),

              // Tabs
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                child: Row(
                  children: [
                    _buildTabItem('Upcoming', true),
                    const SizedBox(width: 16),
                    _buildTabItem('Past Event', false),
                  ],
                ),
              ),

              const SizedBox(height: 8),

              // Event List
              _buildEventListItem(
                'Come to celebrate',
                'Fri, 13th Feb 2026',
                '02:00 PM',
                'La Reserve',
                'https://picsum.photos/200/200?random=1',
              ),
              const Divider(height: 1, color: AppColors.lightGrey, indent: 16, endIndent: 16),
              _buildEventListItem(
                'Vayb & Princess Lover',
                'Fri, 26th Feb 2026',
                '05:00 PM',
                'Lakay bar',
                'https://picsum.photos/200/200?random=2',
              ),

              const SizedBox(height: 16),

              // Popular Tracks
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16.0),
                child: Text(
                  'Popular Tracks',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.black,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.scaffold,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      const Text('1', style: TextStyle(fontSize: 11, color: AppColors.grey)),
                      const SizedBox(width: 10),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: Image.network(
                          'https://picsum.photos/50/50?random=20',
                          width: 36,
                          height: 36,
                          fit: BoxFit.cover,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Rassemble',
                              style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                            ),
                            Text(
                              'Jperry',
                              style: TextStyle(fontSize: 11, color: AppColors.grey),
                            ),
                          ],
                        ),
                      ),
                      const Text(
                        '04:22',
                        style: TextStyle(fontSize: 11, color: AppColors.grey),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Video Exclusive
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16.0),
                child: Text(
                  'Video Exclusive',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.black,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.network(
                        'https://picsum.photos/400/225?random=30',
                        width: double.infinity,
                        height: 180,
                        fit: BoxFit.cover,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: const BoxDecoration(
                        color: AppColors.red,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.play_arrow, color: AppColors.white, size: 24),
                    ),
                    Positioned(
                      top: 8,
                      left: 8,
                      child: Row(
                        children: [
                          const CircleAvatar(radius: 10, backgroundImage: NetworkImage('https://picsum.photos/50/50?random=10')),
                          const SizedBox(width: 6),
                          const Text(
                            'J PERRY - TYLENOL (Official Video)',
                            style: TextStyle(color: AppColors.white, fontSize: 11, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSocialIcon(IconData icon) {
    return Container(
      padding: const EdgeInsets.all(6),
      decoration: const BoxDecoration(
        color: AppColors.black,
        shape: BoxShape.circle,
      ),
      child: Icon(icon, color: AppColors.white, size: 16),
    );
  }

  Widget _buildTabItem(String title, bool isActive) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: isActive ? AppColors.primary : Colors.transparent,
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text(
            title,
            style: TextStyle(
              color: isActive ? AppColors.white : AppColors.black,
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEventListItem(String title, String date, String time, String location, String imageUrl) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.network(
              imageUrl,
              width: 60,
              height: 60,
              fit: BoxFit.cover,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        title,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.cyan,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Text(
                        'Upcoming',
                        style: TextStyle(color: AppColors.white, fontSize: 8, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.calendar_month, size: 12, color: AppColors.primary),
                    const SizedBox(width: 2),
                    Text(
                      date,
                      style: const TextStyle(fontSize: 11, color: AppColors.grey),
                    ),
                    const SizedBox(width: 4),
                    const Text('|', style: TextStyle(color: AppColors.lightGrey, fontSize: 11)),
                    const SizedBox(width: 4),
                    const Icon(Icons.access_time, size: 12, color: AppColors.primary),
                    const SizedBox(width: 2),
                    Text(
                      time,
                      style: const TextStyle(fontSize: 11, color: AppColors.grey),
                    ),
                    const SizedBox(width: 4),
                    const Text('|', style: TextStyle(color: AppColors.lightGrey, fontSize: 11)),
                    const SizedBox(width: 4),
                    const Icon(Icons.location_on_outlined, size: 12, color: AppColors.primary),
                    const SizedBox(width: 2),
                    Expanded(
                      child: Text(
                        location,
                        style: const TextStyle(fontSize: 11, color: AppColors.primary),
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
}
