import 'package:flutter/material.dart';
import '../helpers/app_colors.dart';
import 'shared/widgets/custom_text_field.widget.dart';
import 'event/event_details.screen.dart';
import 'search/search_results.screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController _searchController = TextEditingController();

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
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Search Bar
                GestureDetector(
                  onTap: () {
                    // We don't need to push a new screen, we just need to change the tab
                    // This will be handled by the MainLayout
                    // For now, we can just let the user tap the bottom nav bar
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      color: AppColors.scaffold,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
                    child: Row(
                      children: const [
                        Icon(Icons.search, color: AppColors.grey),
                        SizedBox(width: 12),
                        Text(
                          'Find events, artist & venues',
                          style: TextStyle(color: AppColors.grey, fontSize: 14),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // This Month Section Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'This Month',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: AppColors.black,
                      ),
                    ),
                    TextButton.icon(
                      onPressed: () {},
                      icon: const Icon(Icons.filter_list, color: AppColors.black, size: 18),
                      label: const Text(
                        'Filters',
                        style: TextStyle(color: AppColors.black, fontSize: 14),
                      ),
                      style: TextButton.styleFrom(
                        padding: EdgeInsets.zero,
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Event List
                _buildEventItem(
                  imageUrl: 'https://picsum.photos/200/200?random=1',
                  title: 'Come to celebrate',
                  location: 'Boukanye',
                  organizer: 'Guirrandmarketing group',
                  date: 'Frid 06 Feb / 8h PM',
                  price: '\$20 USD',
                  status: 'Few tickets left',
                  statusColor: Colors.pinkAccent,
                ),
                const SizedBox(height: 16),
                _buildEventItem(
                  imageUrl: 'https://picsum.photos/200/200?random=2',
                  title: 'Vayb & Princeess Lover',
                  location: 'Lakay bar restaurant',
                  organizer: 'Jeanpierre',
                  date: 'Frid 06 Feb / 8h PM',
                  price: '\$30 USD',
                  status: 'Sold out',
                  statusColor: AppColors.red,
                ),
                const SizedBox(height: 16),
                _buildEventItem(
                  imageUrl: 'https://picsum.photos/200/200?random=3',
                  title: 'The Last Party 2.0',
                  location: 'Parc St therese',
                  organizer: 'atgasam',
                  date: 'Frid 06 Feb / 8h PM',
                  price: '\$15 USD',
                ),

                const SizedBox(height: 24),
                Center(
                  child: TextButton(
                    onPressed: () {},
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
                SizedBox(
                  height: 140,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    children: [
                      _buildCategoryItem('Night Life', 'https://picsum.photos/200/300?random=4'),
                      const SizedBox(width: 12),
                      _buildCategoryItem('Social', 'https://picsum.photos/200/300?random=5'),
                      const SizedBox(width: 12),
                      _buildCategoryItem('Food', 'https://picsum.photos/200/300?random=6'),
                      const SizedBox(width: 12),
                      _buildCategoryItem('Concert', 'https://picsum.photos/200/300?random=7'),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEventItem({
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
              title: title,
              imageUrl: imageUrl,
            ),
          ),
        );
      },
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Image.network(
            imageUrl,
            width: 100,
            height: 100,
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
                  const Icon(Icons.bookmark_border, size: 20, color: AppColors.grey),
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
        image: DecorationImage(
          image: NetworkImage(imageUrl),
          fit: BoxFit.cover,
        ),
      ),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.transparent,
              Colors.black.withValues(alpha: 0.7),
            ],
          ),
        ),
        padding: const EdgeInsets.all(8),
        alignment: Alignment.bottomLeft,
        child: Text(
          title,
          style: const TextStyle(
            color: AppColors.white,
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),
      ),
    );
  }
}
