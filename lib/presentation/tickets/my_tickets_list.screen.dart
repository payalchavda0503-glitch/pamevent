import 'package:flutter/material.dart';
import '../../helpers/app_colors.dart';
import 'ticket_details.screen.dart';

class MyTicketsListScreen extends StatefulWidget {
  final VoidCallback? onMenuTap;
  const MyTicketsListScreen({super.key, this.onMenuTap});

  @override
  State<MyTicketsListScreen> createState() => _MyTicketsListScreenState();
}

class _MyTicketsListScreenState extends State<MyTicketsListScreen> {
  int _selectedTabIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: AppBar(
        backgroundColor: AppColors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.menu, color: AppColors.black),
          onPressed: widget.onMenuTap,
        ),
        title: const Text(
          'My Tickets',
          style: TextStyle(color: AppColors.black, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list, color: AppColors.black),
            onPressed: () {
              // Handle filter action
            },
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Tabs
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Row(
                children: [
                  _buildTab('Upcoming', 0),
                  const SizedBox(width: 16),
                  _buildTab('Past Event', 1),
                ],
              ),
            ),
            const Divider(height: 1, thickness: 1, color: AppColors.lightGrey),

            // List
            Expanded(
              child: ListView(
                children: [
                  _buildTicketListItem(
                    imageUrl: 'https://picsum.photos/100/100?random=30',
                    title: 'Come to celebrate',
                    date: 'Fri, 13th Feb 2026',
                    time: '02:00 PM',
                    location: 'La Reserve',
                  ),
                  const Divider(height: 1, thickness: 1, color: AppColors.lightGrey),
                  _buildTicketListItem(
                    imageUrl: 'https://picsum.photos/100/100?random=31',
                    title: 'Vayb & Princess Lover',
                    date: 'Fri, 26th Feb 2026',
                    time: '05:00 PM',
                    location: 'Lakay bar',
                  ),
                  const Divider(height: 1, thickness: 1, color: AppColors.lightGrey),
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
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(4),
        ),
        child: Text(
          title,
          style: TextStyle(
            color: isSelected ? AppColors.white : AppColors.black,
            fontSize: 14,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
          ),
        ),
      ),
    );
  }

  Widget _buildTicketListItem({
    required String imageUrl,
    required String title,
    required String date,
    required String time,
    required String location,
  }) {
    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const TicketDetailsScreen(),
          ),
        );
      },
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
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
            const SizedBox(width: 12),
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
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.teal,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text(
                          'upcoming',
                          style: TextStyle(color: AppColors.white, fontSize: 8, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.calendar_today, size: 12, color: AppColors.primary),
                      const SizedBox(width: 4),
                      Text(date, style: const TextStyle(fontSize: 11, color: AppColors.darkGrey)),
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 4),
                        child: Text('|', style: TextStyle(color: AppColors.grey)),
                      ),
                      const Icon(Icons.access_time, size: 12, color: AppColors.primary),
                      const SizedBox(width: 4),
                      Text(time, style: const TextStyle(fontSize: 11, color: AppColors.darkGrey)),
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 4),
                        child: Text('|', style: TextStyle(color: AppColors.grey)),
                      ),
                      const Icon(Icons.location_on, size: 12, color: AppColors.primary),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          location,
                          style: const TextStyle(fontSize: 11, color: AppColors.primary, fontWeight: FontWeight.w500),
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
      ),
    );
  }
}
