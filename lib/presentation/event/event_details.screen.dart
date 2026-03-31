import 'package:flutter/material.dart';
import '../../helpers/app_colors.dart';
import '../shared/widgets/custom_button.widget.dart';

class EventDetailsScreen extends StatefulWidget {
  final String title;
  final String imageUrl;

  const EventDetailsScreen({
    super.key,
    required this.title,
    required this.imageUrl,
  });

  @override
  State<EventDetailsScreen> createState() => _EventDetailsScreenState();
}

class _EventDetailsScreenState extends State<EventDetailsScreen> {
  int _selectedTabIndex = 0;

  @override
  Widget build(BuildContext context) {
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
                            child: Image.network(
                              widget.imageUrl,
                              width: double.infinity,
                              height: 200,
                              fit: BoxFit.cover,
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
                          // Date Box
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
                                  child: const Text(
                                    'Feb',
                                    style: TextStyle(color: AppColors.white, fontWeight: FontWeight.bold),
                                  ),
                                ),
                                const Padding(
                                  padding: EdgeInsets.symmetric(vertical: 8),
                                  child: Text(
                                    '13',
                                    style: TextStyle(
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
                                        widget.title,
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
                                    const Text('Fri, 13th Feb 2026', style: TextStyle(fontSize: 12, color: AppColors.darkGrey)),
                                    const Padding(
                                      padding: EdgeInsets.symmetric(horizontal: 4),
                                      child: Text('|', style: TextStyle(color: AppColors.grey)),
                                    ),
                                    const Icon(Icons.access_time, size: 14, color: AppColors.primary),
                                    const SizedBox(width: 4),
                                    const Text('02:00 PM', style: TextStyle(fontSize: 12, color: AppColors.darkGrey)),
                                    const Padding(
                                      padding: EdgeInsets.symmetric(horizontal: 4),
                                      child: Text('|', style: TextStyle(color: AppColors.grey)),
                                    ),
                                    const Icon(Icons.location_on, size: 14, color: AppColors.primary),
                                    const SizedBox(width: 4),
                                    const Expanded(
                                      child: Text(
                                        'La Reserve',
                                        style: TextStyle(fontSize: 12, color: AppColors.primary, fontWeight: FontWeight.w500),
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
                      const Text(
                        'FLEVA Carnival 2026 🔥🎭\nL\'expérience ultime où la couleur rencontre la chaleur !\nPréparez-vous à plonger dans l\'événement carnavalesque le plus vibrant de l\'année. FLEVA n\'est pas qu\'un simple carnaval, c\'est une célébration annuelle de l\'énergie, de la culture et de la fête pure. Le Vendredi 13 Février 2026, nous transformons La Réserve en un épicentre de vibrations intenses.',
                        style: TextStyle(fontSize: 13, color: AppColors.darkGrey, height: 1.4),
                      ),
                      const SizedBox(height: 24),

                      // Performers
                      const Text(
                        'Performers',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          _buildPerformer('Roody Roodboy', 'https://picsum.photos/100/100?random=10'),
                          const SizedBox(width: 12),
                          _buildPerformer('Tijozenny', 'https://picsum.photos/100/100?random=11'),
                          const SizedBox(width: 12),
                          _buildPerformer('Pierre Jean', 'https://picsum.photos/100/100?random=12'),
                        ],
                      ),
                      const SizedBox(height: 24),

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
                                const Text(
                                  'La Reserve',
                                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.primary),
                                ),
                                const SizedBox(height: 4),
                                const Text(
                                  'Impasse 23, Rue Avieu thomassin 25, Haiti',
                                  style: TextStyle(fontSize: 13, color: AppColors.darkGrey),
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
                      const Text(
                        'All tickets are refundable up to 1 days before the event.\nThe Pamevent fee is non refundable.',
                        style: TextStyle(fontSize: 13, color: AppColors.darkGrey),
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
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text.rich(
                    TextSpan(
                      text: 'Tickets start at ',
                      style: TextStyle(color: AppColors.darkGrey, fontSize: 14),
                      children: [
                        TextSpan(
                          text: '\$20',
                          style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.black, fontSize: 16),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(
                    width: 140,
                    child: CustomButton(
                      title: 'Get tickets',
                      onTap: () {},
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

  Widget _buildTab(String title, int index) {
    final isSelected = _selectedTabIndex == index;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedTabIndex = index;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : AppColors.scaffold,
          borderRadius: BorderRadius.circular(4),
        ),
        child: Text(
          title,
          style: TextStyle(
            color: isSelected ? AppColors.white : AppColors.darkGrey,
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  Widget _buildPerformer(String name, String imageUrl) {
    return Column(
      children: [
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.lightGrey),
            image: DecorationImage(
              image: NetworkImage(imageUrl),
              fit: BoxFit.cover,
            ),
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            border: Border.all(color: AppColors.lightGrey),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text(
            name,
            style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w500),
          ),
        ),
      ],
    );
  }
}
