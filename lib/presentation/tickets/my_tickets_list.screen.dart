import 'package:flutter/material.dart';
import '../../helpers/app_colors.dart';
import '../../api/api.client.dart';
import 'ticket_details.screen.dart';
import '../../helpers/app_state.dart';
import '../../helpers/extensions/context.extension.dart';
import '../auth/login.screen.dart';
import '../shared/widgets/custom_button.widget.dart';
import '../shared/widgets/custom_image.dart';
import '../../helpers/public_url.dart';

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
    print('MyTicketsListScreen initState - LoggedIn: ${AppState.loggedIn}');
    AppState.authRevision.addListener(_onAuthChanged);
    if (AppState.loggedIn) {
      _fetchMyTickets();
    } else {
      _isLoading = false;
    }
  }

  void _onAuthChanged() {
    if (AppState.loggedIn && _upcomingTickets.isEmpty && _pastTickets.isEmpty && !_isLoading) {
      print('Auth changed, triggering re-fetch...');
      setState(() => _isLoading = true);
      _fetchMyTickets();
    }
  }

  @override
  void dispose() {
    AppState.authRevision.removeListener(_onAuthChanged);
    super.dispose();
  }

  Future<void> _fetchMyTickets() async {
    print('Starting _fetchMyTickets API calls (Recent & Past)...');
    
    // Call both APIs in parallel
    final results = await Future.wait([
      ApiClient.customerRecentTickets(page: 1),
      ApiClient.customerPastTickets(page: 1),
    ]);

    final recentResponse = results[0];
    final pastResponse = results[1];

    print('Recent Response: $recentResponse');
    print('Past Response: $pastResponse');

    if (mounted) {
      setState(() {
        _isLoading = false;
        
        _upcomingTickets.clear();
        _pastTickets.clear();

        // Parse Recent Tickets
        if (recentResponse != null && recentResponse['data'] != null) {
          final data = recentResponse['data'];
          // Based on user input, recent bookings might be in a list or inside a 'data' key if paginated
          if (data is List) {
            _upcomingTickets.addAll(data);
          } else if (data is Map && data['data'] is List) {
            _upcomingTickets.addAll(data['data']);
          }
        }

        // Parse Past Tickets
        if (pastResponse != null && pastResponse['data'] != null) {
          final data = pastResponse['data'];
          if (data is List) {
            _pastTickets.addAll(data);
          } else if (data is Map && data['data'] is List) {
            _pastTickets.addAll(data['data']);
          }
        }
        
        print('Parsed ${_upcomingTickets.length} upcoming and ${_pastTickets.length} past tickets');
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
                                // Listener in initState will automatically trigger _fetchMyTickets
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
                            
                            // Image parsing: check for thumbnail (new API) or event_img
                            String? imageUrl;
                            if (item['thumbnail'] != null) {
                              imageUrl = item['thumbnail'].toString().trim();
                            } else if (event['thumbnail'] != null) {
                              imageUrl = event['thumbnail'].toString().trim();
                            } else {
                              imageUrl = event['event_img'] ?? event['event_thumbnail'] ?? item['event_img'] ?? '';
                            }
                            
                            // Clean trailing comma if any
                            if (imageUrl != null && imageUrl.endsWith(',')) {
                              imageUrl = imageUrl.substring(0, imageUrl.length - 1);
                            }

                            // Title parsing: check for event_title (new API) or title
                            final title = item['event_title'] ?? event['event_title'] ?? event['title'] ?? item['title'] ?? item['event_name'] ?? 'Ticket';
                            
                            final date = item['event_start_date'] ?? event['start_date'] ?? item['start_date'] ?? 'N/A';
                            final time = item['event_start_time'] ?? event['start_time'] ?? item['start_time'] ?? 'N/A';
                            final location = item['event_location'] ?? event['venue'] ?? item['venue'] ?? 'N/A';
                            
                            return _buildTicketListItem(
                              item: item,
                              imageUrl: imageUrl ?? '',
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
    required Map<String, dynamic> item,
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
            builder: (context) => TicketDetailsScreen(ticket: item),
          ),
        );
      },
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: CustomImage(
                (imageUrl.startsWith('http://') || imageUrl.startsWith('https://')) 
                    ? imageUrl 
                    : resolvePublicUrl(imageUrl),
                width: 60,
                height: 60,
                fit: BoxFit.cover,
                whenEmpty: Container(
                  width: 60,
                  height: 60,
                  color: Colors.grey.shade300,
                  child: const Icon(Icons.image_not_supported, color: Colors.grey),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          title,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            height: 1.2,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
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
                    ],
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
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
