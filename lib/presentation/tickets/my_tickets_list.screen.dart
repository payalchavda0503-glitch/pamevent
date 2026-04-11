import 'package:flutter/material.dart';
import '../../helpers/app_colors.dart';
import '../../api/api.client.dart';
import 'ticket_details.screen.dart';
import '../../helpers/app_state.dart';
import '../../helpers/extensions/context.extension.dart';
import '../auth/login.screen.dart';
import '../shared/widgets/custom_button.widget.dart';

class MyTicketsListScreen extends StatefulWidget {
  final VoidCallback? onMenuTap;
  const MyTicketsListScreen({super.key, this.onMenuTap});

  @override
  State<MyTicketsListScreen> createState() => _MyTicketsListScreenState();
}

class _MyTicketsListScreenState extends State<MyTicketsListScreen> {
  int _selectedTabIndex = 0;
  bool _isLoading = true;
  List<dynamic> _upcomingTickets = [];
  List<dynamic> _pastTickets = [];

  @override
  void initState() {
    super.initState();
    if (AppState.loggedIn) {
      _fetchMyTickets();
    } else {
      _isLoading = false;
    }
  }

  Future<void> _fetchMyTickets() async {
    final response = await ApiClient.customerMyTickets();
    if (mounted) {
      setState(() {
        _isLoading = false;
        if (response != null && response['data'] != null) {
          final items = (response['data'] is List) 
                 ? response['data'] as List
                 : (response['data']['data'] is List ? response['data']['data'] as List : []);
          
          DateTime now = DateTime.now();
          _upcomingTickets.clear();
          _pastTickets.clear();
          for (var item in items) {
             final event = item['event'] ?? {};
             final dateStr = event['start_date'] ?? item['start_date'] ?? '';
             bool isPast = false;
             if (dateStr.isNotEmpty) {
                try {
                   final d = DateTime.parse(dateStr);
                   if (d.isBefore(now)) isPast = true;
                } catch (_) {}
             }
             if (isPast) {
               _pastTickets.add(item);
             } else {
               _upcomingTickets.add(item);
             }
          }
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: AppState.authRevision,
      builder: (context, _) {
        if (!AppState.loggedIn) {
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
            ),
            body: SafeArea(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Center(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 32),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.airplane_ticket_outlined, size: 72, color: AppColors.grey.withValues(alpha: 0.85)),
                            const SizedBox(height: 20),
                            Text(
                              'Sign in to view your tickets and bookings.',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 15,
                                color: AppColors.darkGrey.withValues(alpha: 0.95),
                                height: 1.4,
                              ),
                            ),
                            const SizedBox(height: 28),
                            CustomButton(
                              title: 'Sign in',
                              onTap: () async {
                                await context.push(const LoginScreen());
                                if (AppState.loggedIn) {
                                  setState(() => _isLoading = true);
                                  _fetchMyTickets();
                                }
                              },
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        final displayList = _selectedTabIndex == 0 ? _upcomingTickets : _pastTickets;

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
                  child: _isLoading 
                    ? const Center(child: CircularProgressIndicator())
                    : displayList.isEmpty
                      ? Center(
                          child: Text(
                            _selectedTabIndex == 0 ? 'No upcoming tickets' : 'No past tickets',
                            style: const TextStyle(color: AppColors.grey),
                          ),
                        )
                      : ListView.separated(
                          itemCount: displayList.length,
                          separatorBuilder: (context, index) => const Divider(height: 1, thickness: 1, color: AppColors.lightGrey),
                          itemBuilder: (context, index) {
                            final item = displayList[index];
                            final event = item['event'] ?? {};
                            final imageUrl = event['event_img'] ?? event['event_thumbnail'] ?? item['event_img'] ?? 'https://picsum.photos/100/100?random=$index';
                            final title = event['title'] ?? item['title'] ?? item['event_name'] ?? 'Ticket';
                            final date = event['start_date'] ?? item['start_date'] ?? 'N/A';
                            final time = event['start_time'] ?? item['start_time'] ?? 'N/A';
                            final location = event['venue'] ?? item['venue'] ?? 'N/A';
                            
                            return _buildTicketListItem(
                              imageUrl: imageUrl,
                              title: title,
                              date: date,
                              time: time,
                              location: location,
                              isUpcoming: _selectedTabIndex == 0,
                            );
                          },
                        ),
                ),
              ],
            ),
          ),
        );
      },
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
    required bool isUpcoming,
  }) {
    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const TicketDetailsScreen(), // Ensure this screen expects whatever it needs or modify it accordingly later
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
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    width: 60,
                    height: 60,
                    color: Colors.grey.shade300,
                    child: const Icon(Icons.image_not_supported, color: Colors.grey),
                  );
                },
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
                          color: isUpcoming ? Colors.teal : Colors.grey,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          isUpcoming ? 'upcoming' : 'past',
                          style: const TextStyle(color: AppColors.white, fontSize: 8, fontWeight: FontWeight.bold),
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
