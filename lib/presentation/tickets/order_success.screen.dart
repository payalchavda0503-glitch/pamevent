import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'dart:convert';
import '../../helpers/app_colors.dart';
import '../../helpers/app_state.dart';
import 'package:pamevent/helpers/public_url.dart';
import '../../helpers/utils.dart';
import '../main_layout.dart';
import '../shared/widgets/custom_button.widget.dart';
import '../shared/widgets/custom_image.dart';
import './ticket_details.screen.dart';
import '../../api/api.client.dart';

class OrderSuccessScreen extends StatefulWidget {
  final String orderId; // This will be the numeric ID from booking_info['id'] for API calls
  final String displayId; // This will be the alphanumeric ID from booking_info['booking_id'] for UI display
  final String? eventId;
  final double amount;
  final String? eventName;
  final Map<String, dynamic>? bookingData;

  const OrderSuccessScreen({
    super.key,
    required this.orderId,
    required this.displayId,
    this.eventId,
    required this.amount,
    this.eventName,
    this.bookingData,
  });

  @override
  State<OrderSuccessScreen> createState() => _OrderSuccessScreenState();
}

class _OrderSuccessScreenState extends State<OrderSuccessScreen> {
  List<dynamic> _tickets = [];
  bool _isLoading = false;
  Map<String, dynamic>? _fullBookingData;
  final PageController _pageController = PageController();
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    _fullBookingData = widget.bookingData;
    _extractTickets();
    _fetchBookingDetails();
  }

  Future<void> _fetchBookingDetails() async {
    setState(() => _isLoading = true);
    try {
      // Get the ID from bookingData (could be numeric ID or booking_info map)
      final bookingData = widget.bookingData ?? {};
     
      final String? bookingId = (bookingData['id'] ?? 
                                 bookingData['id'] ?? 
                                 widget.orderId).toString();

      if (bookingId != null && bookingId.isNotEmpty) {
        final data = await ApiClient.customerBookingDetails(bookingId,id:bookingId).timeout(const Duration(seconds: 5));
         print('bookingData=-----$data$bookingId');
        if (data != null && data['status'] == 100) {
          setState(() {
            _fullBookingData = data['data'];
            _tickets = _findTicketsInMap(_fullBookingData ?? {});
          });
        }
      }
    } catch (e) {
      debugPrint('Error fetching booking details: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  List<dynamic> _findTicketsInMap(Map<String, dynamic> data) {
    // Check all possible keys for the ticket list
    final List<dynamic> tickets = 
        (data['booking_tickets'] is List && (data['booking_tickets'] as List).isNotEmpty) ? data['booking_tickets'] :
        (data['qr_codes'] is List && (data['qr_codes'] as List).isNotEmpty) ? data['qr_codes'] :
        (data['tickets'] is List && (data['tickets'] as List).isNotEmpty) ? data['tickets'] :
        (data['all_ticket_json'] is List && (data['all_ticket_json'] as List).isNotEmpty) ? data['all_ticket_json'] :
        [];
    
    if (tickets.isEmpty && (data['ticket_number'] != null || data['qr_code'] != null)) {
      return [data];
    }
    return tickets;
  }

  void _extractTickets() {
    // This is now handled within _callBookingComplateApi and _findTicketsInMap
    if (_fullBookingData != null) {
      _tickets = _findTicketsInMap(_fullBookingData!);
      debugPrint('Extracted tickets count: ${_tickets.length}');
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: AppColors.splash,
        elevation: 0,
        centerTitle: true,
        automaticallyImplyLeading: false,
        title: const Text(
          'Payment Success',
          style: TextStyle(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              const SizedBox(height: 12),
              // Success Icon
              const Icon(
                Icons.check_circle,
                color: AppColors.green,
                size: 60,
              ),
              const SizedBox(height: 4),
              const Text(
                'SUCCESS!',
                style: TextStyle(
                  color: AppColors.green,
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 4),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 40),
                child: Text(
                  'You transaction was successful. we have also sent you a mail for you ticket.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.black.withOpacity(0.7),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Ticket Card Section
              _buildTicketCard(),
              
              const SizedBox(height: 16),

              // View Ticket Button
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 40),
                child: CustomButton(
                  title: 'View Ticket',
                  onTap: () {
                    // Extract alphanumeric booking_id correctly
                    final data = _fullBookingData?['data'] is Map ? _fullBookingData!['data'] : _fullBookingData;
                    final displayId = data?['booking']?['id'] ?? data?['booking_id'] ?? widget.displayId;
                    
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => TicketDetailsScreen(
                          ticket: _fullBookingData ?? widget.bookingData ?? {},
                          bookingId: displayId.toString(),
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 12),
              // Back to Home Button
              TextButton(
                onPressed: () {
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(builder: (_) => const MainLayout()),
                    (route) => false,
                  );
                },
                child: const Text(
                  'Back to Home',
                  style: TextStyle(
                    color: AppColors.primary,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTicketCardSection() {
    if (_isLoading) {
      return const SizedBox(
        height: 400,
        child: Center(child: CircularProgressIndicator(color: AppColors.primary)),
      );
    }

    final data = _fullBookingData?['data'] is Map ? _fullBookingData!['data'] : _fullBookingData;
    final event = data?['event'] ?? {};
    
    // Title parsing
    String eventTitle = event['event_title'] ?? data?['event_title'] ?? event['title'] ?? data?['event_name'] ?? data?['title'] ?? widget.eventName ?? '-';
    if (eventTitle == 'N/A') eventTitle = '-';
    
    // Image parsing
    String? imageUrl;
    if (event['thumbnail'] != null) {
      imageUrl = event['thumbnail'].toString().trim();
    } else if (data?['thumbnail'] != null) {
      imageUrl = data?['thumbnail'].toString().trim();
    } else if (event['image'] != null) {
      imageUrl = event['image'].toString().trim();
    }
    
    if (imageUrl != null && imageUrl.endsWith(',')) {
      imageUrl = imageUrl.substring(0, imageUrl.length - 1);
    }
    
    final eventImg = event['event_img'] ?? event['event_thumbnail'] ?? data?['event_img'] ?? data?['photo'];
    final finalImageUrl = (imageUrl != null && (imageUrl.startsWith('http://') || imageUrl.startsWith('https://'))) 
        ? imageUrl 
        : (resolvePublicUrl(imageUrl ?? eventImg?.toString()) ?? '');

    // Date/Time/Location parsing
    String eventDate = event['event_start_date'] ?? data?['event_start_date'] ?? event['start_date'] ?? data?['start_date'] ?? '-';
    if (eventDate == 'N/A') eventDate = '-';
    if (eventDate != '-') eventDate = formatEventDate(eventDate);

    String eventTime = event['event_start_time'] ?? data?['event_start_time'] ?? event['start_time'] ?? data?['start_time'] ?? '-';
    if (eventTime == 'N/A') eventTime = '-';

    String eventLocation = event['event_location'] ?? data?['event_location'] ?? event['venue'] ?? data?['venue'] ?? '-';
    if (eventLocation == 'N/A') eventLocation = '-';

    // Tickets extraction - Robust check
    List<dynamic> displayTickets = [];
    if (_tickets.isNotEmpty) {
      displayTickets = _tickets;
    } else {
      final List<dynamic> possibleTickets = 
        (data?['booking_tickets'] is List) ? data!['booking_tickets'] :
        (data?['qr_codes'] is List) ? data!['qr_codes'] :
        (data?['tickets'] is List) ? data!['tickets'] :
        (data?['all_ticket_json'] is List) ? data!['all_ticket_json'] : [];
      
      if (possibleTickets.isNotEmpty) {
        displayTickets = possibleTickets;
      } else if (data != null && (data['qr_code'] != null || data['ticket_number'] != null)) {
        displayTickets = [data];
      } else {
        displayTickets = [null];
      }
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min, // Ensure container fits its content
        children: [
          // Event Image
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            child: CustomImage(
              finalImageUrl,
              height: 150,
              width: double.infinity,
              fit: BoxFit.cover,
              whenEmpty: Container(
                width: double.infinity,
                height: 150,
                color: Colors.grey.shade300,
                child: const Icon(Icons.image_not_supported, color: Colors.grey, size: 40),
              ),
            ),
          ),
          
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  eventTitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.black,
                  ),
                ),
                const SizedBox(height: 8),
                
                // Date, Time, Location Row
                Row(
                  children: [
                    const Icon(Icons.calendar_month, color: AppColors.primary, size: 14),
                    const SizedBox(width: 2),
                    Text(
                      eventDate,
                      style: const TextStyle(fontSize: 10, color: AppColors.grey),
                    ),
                    const SizedBox(width: 4),
                    const Text('|', style: TextStyle(color: AppColors.grey)),
                    const SizedBox(width: 4),
                    const Icon(Icons.access_time, color: AppColors.primary, size: 14),
                    const SizedBox(width: 2),
                    Text(
                      eventTime,
                      style: const TextStyle(fontSize: 10, color: AppColors.grey),
                    ),
                    const SizedBox(width: 4),
                    const Text('|', style: TextStyle(color: AppColors.grey)),
                    const SizedBox(width: 4),
                    const Icon(Icons.location_on, color: AppColors.primary, size: 14),
                    const SizedBox(width: 2),
                    Flexible(
                      child: Text(
                        eventLocation.toString().toUpperCase(),
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 10, color: AppColors.grey),
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 16),
                
                // Pager for Booking ID and QR Code
                SizedBox(
                  height: 260, // Increased height slightly to accommodate labels without overflow
                  child: PageView.builder(
                    controller: _pageController,
                    onPageChanged: (index) => setState(() => _currentPage = index),
                    itemCount: displayTickets.length,
                    itemBuilder: (context, index) {
                      final ticket = displayTickets[index];
                      return _buildDynamicIdAndQr(ticket, data);
                    },
                  ),
                ),

                // Bottom Pagination (X of Y with Arrows)
                if (displayTickets.length > 1) ...[
                  const Divider(height: 1),
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '${_currentPage + 1} of ${displayTickets.length}',
                          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                        ),
                        Row(
                          children: [
                            IconButton(
                              icon: const Icon(Icons.arrow_back_ios, size: 16),
                              onPressed: _currentPage > 0 
                                ? () => _pageController.previousPage(duration: const Duration(milliseconds: 300), curve: Curves.easeInOut)
                                : null,
                            ),
                            IconButton(
                              icon: const Icon(Icons.arrow_forward_ios, size: 16),
                              onPressed: _currentPage < displayTickets.length - 1 
                                ? () => _pageController.nextPage(duration: const Duration(milliseconds: 300), curve: Curves.easeInOut)
                                : null,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDynamicIdAndQr(dynamic ticket, Map<String, dynamic>? data) {
    String qrData;
    String bookingIdStr;
    String ticketIdStr;
    String attendeeName = 'Guest';
    String ticketType = 'General Admission';

    if (ticket is Map) {
      qrData = (ticket['qr_code'] ?? ticket['ticket_number'] ?? data?['id'] ?? data?['order_id'] ?? widget.displayId).toString();
      
      // Use displayId (alphanumeric booking_id) for the text ABOVE QR code
      bookingIdStr = (data?['booking_info']?['booking_id'] ?? data?['booking_id'] ?? data?['order_id'] ?? ticket['booking_id'] ?? widget.displayId).toString();
      
      ticketIdStr = (ticket['ticket_id'] ?? ticket['id'] ?? ticket['ticket_number'] ?? bookingIdStr).toString();
      
      if (ticketIdStr.startsWith('http') || ticketIdStr.startsWith('data:')) {
        ticketIdStr = (ticket['id'] ?? bookingIdStr).toString();
      }

      attendeeName = ticket['fname'] ?? ticket['name'] ?? ticket['customer_name'] ?? data?['fname'] ?? data?['name'] ?? 'Guest';
      ticketType = ticket['ticket_name'] ?? ticket['ticket_type'] ?? 'General Admission';
    } else {
      qrData = ticket?.toString() ?? widget.orderId;
      bookingIdStr = (data?['booking_id'] ?? data?['order_id'] ?? widget.orderId).toString();
      ticketIdStr = qrData.startsWith('http') || qrData.startsWith('data:') ? bookingIdStr : qrData;
    }

    if (bookingIdStr == 'N/A' || bookingIdStr.isEmpty) bookingIdStr = '-';
    if (ticketIdStr == 'N/A' || ticketIdStr.isEmpty) ticketIdStr = '-';
    if (attendeeName == 'N/A') attendeeName = 'Guest';
    if (ticketType == 'N/A') ticketType = 'General Admission';

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Booking ID ABOVE QR Code
        Text(
          'Booking ID: $bookingIdStr',
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.black),
        ),
        const SizedBox(height: 8),
        // QR Code Image
        Center(
          child: SizedBox(
            height: 140,
            width: 140,
            child: _buildQrCode(qrData),
          ),
        ),
        const SizedBox(height: 8),
        // Ticket ID BELOW QR Code
        Text(
          'Ticket ID: $ticketIdStr',
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.black),
        ),
        const SizedBox(height: 16),
        // Purchaser Info and Ticket Type inside the pager for responsiveness
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Purchase by', style: TextStyle(fontSize: 10, color: AppColors.darkGrey)),
                  const SizedBox(height: 2),
                  Text(attendeeName, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  const Text('Ticket type', style: TextStyle(fontSize: 10, color: AppColors.darkGrey)),
                  const SizedBox(height: 2),
                  Text(ticketType, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildQrCode(String data) {
    // 1. Check if it's a Base64 SVG (common in your API)
    if (data.startsWith('data:image/svg+xml;base64,')) {
      final base64Str = data.split(',').last;
      return SvgPicture.memory(
        base64Decode(base64Str),
        width: 140,
        height: 140,
        placeholderBuilder: (context) => const Center(child: CircularProgressIndicator(strokeWidth: 2)),
      );
    } 
    // 2. Check if it's a regular Base64 image
    else if (data.startsWith('data:image')) {
      final base64Str = data.split(',').last;
      return Image.memory(
        base64Decode(base64Str),
        width: 140,
        height: 140,
      );
    } 
    // 3. Check if it's a full URL or relative path from API
    else if (data.startsWith('http') || data.startsWith('/')) {
      return CustomImage(
        resolvePublicUrl(data),
        width: 140,
        height: 140,
        fit: BoxFit.contain,
      );
    }

    // Fallback: If it's just a raw ID string, we still use the API server to generate it 
    // to keep it consistent with the "API only" requirement.
    return CustomImage(
      'https://api.qrserver.com/v1/create-qr-code/?size=150x150&data=$data',
      width: 140,
      height: 140,
      fit: BoxFit.contain,
    );
  }

  Widget _buildStaticBottomDetails(Map<String, dynamic>? data, Map<String, dynamic>? currentTicket) {
    // This is now empty because labels are moved inside the pager for exact binding
    return const SizedBox.shrink();
  }

  Widget _buildTicketDetails(Map<String, dynamic>? ticket, Map<String, dynamic>? data) {
    // This is no longer used
    return const SizedBox.shrink();
  }

  Widget _buildTicketCard() {
    if (_fullBookingData == null) return const SizedBox.shrink();

    final event = _fullBookingData?['event'] ?? {};
    final booking = _fullBookingData?['booking'] ?? {};
    final qrCodes = _fullBookingData?['qr_codes'] as List? ?? [];
    final bookedTickets = _fullBookingData?['booked_tickets'] as List? ?? [];

    final String title = event['event_title'] ?? widget.eventName ?? '-';
    final String date = event['event_start_date'] ?? '-';
    final String time = event['event_start_time'] ?? '-';
    final String location = event['event_location'] ?? '-';
    final String finalImageUrl = event['thumbnail'] ?? '';

    final String bookingId = (booking['booking_id'] ?? widget.displayId).toString();
    final int ticketCount = qrCodes.isNotEmpty ? qrCodes.length : 1;

    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          // Event Image
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            child: CustomImage(
              finalImageUrl,
              height: 180,
              width: double.infinity,
              fit: BoxFit.cover,
            ),
          ),
          
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppColors.black,
                  ),
                ),
                const SizedBox(height: 12),
                
                // Date, Time, Location Row
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.calendar_today, size: 14, color: AppColors.primary),
                    const SizedBox(width: 4),
                    Text(date, style: const TextStyle(fontSize: 12, color: AppColors.grey)),
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 8),
                      child: Text('|', style: TextStyle(color: AppColors.grey)),
                    ),
                    const Icon(Icons.access_time, size: 14, color: AppColors.primary),
                    const SizedBox(width: 4),
                    Text(time, style: const TextStyle(fontSize: 12, color: AppColors.grey)),
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 8),
                      child: Text('|', style: TextStyle(color: AppColors.grey)),
                    ),
                    const Icon(Icons.location_on, size: 14, color: AppColors.primary),
                    const SizedBox(width: 4),
                    Flexible(child: Text(location, style: const TextStyle(fontSize: 12, color: AppColors.grey), overflow: TextOverflow.ellipsis)),
                  ],
                ),
                
                const SizedBox(height: 20),
                
                GestureDetector(
                  behavior: HitTestBehavior.translucent,
                  onHorizontalDragEnd: (details) {
                    if (ticketCount > 1) {
                      if (details.primaryVelocity! < 0) {
                        // Swiped left (go to next page)
                        if (_currentPage < ticketCount - 1) {
                          _pageController.nextPage(
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.easeInOut,
                          );
                        }
                      } else if (details.primaryVelocity! > 0) {
                        // Swiped right (go to previous page)
                        if (_currentPage > 0) {
                          _pageController.previousPage(
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.easeInOut,
                          );
                        }
                      }
                    }
                  },
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // QR Code Pager (Full width swipe area wrapping all ticket details)
                      SizedBox(
                        height: 285,
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            PageView.builder(
                              controller: _pageController,
                              onPageChanged: (index) => setState(() => _currentPage = index),
                              itemCount: ticketCount,
                              itemBuilder: (context, index) {
                                final currentTicket = qrCodes.isNotEmpty && index < qrCodes.length ? qrCodes[index] : null;
                                String qrData = (currentTicket?['qr_code'] ?? bookingId).toString();
                                
                                final String ticketId = (currentTicket?['ticket_id'] ?? bookingId).toString();
                                final String ticketName = (currentTicket?['ticket_name'] ?? 'Event Ticket').toString();

                                return Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 40),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.center,
                                    children: [
                                      // Booking ID above QR
                                      Text(
                                        'Booking ID : # $bookingId',
                                        style: const TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w500,
                                          color: AppColors.black,
                                        ),
                                      ),
                                      const SizedBox(height: 16),
                                      
                                      // QR Code
                                      SizedBox(
                                        width: 150,
                                        height: 150,
                                        child: _buildQrCode(qrData),
                                      ),
                                      const SizedBox(height: 12),
                                      
                                      // Ticket ID below QR
                                      Text(
                                        ticketId,
                                        style: const TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.bold,
                                          color: AppColors.black,
                                        ),
                                      ),
                                      const SizedBox(height: 12),
                                      
                                      // Ticket Type
                                      Text(
                                        'Ticket type: $ticketName',
                                        style: const TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.bold,
                                          color: Color(0xFF444444),
                                        ),
                                      ),
                                      
                                      if (ticketCount > 1) ...[
                                        const SizedBox(height: 12),
                                        Text(
                                          '${index + 1} of $ticketCount',
                                          style: const TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w500,
                                            color: AppColors.black,
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                );
                              },
                            ),
                            if (ticketCount > 1 && _currentPage > 0)
                              Positioned(
                                left: 0,
                                top: 87,
                                child: IconButton(
                                  icon: const Icon(Icons.chevron_left_rounded, size: 32, color: AppColors.grey),
                                  onPressed: () => _pageController.previousPage(duration: const Duration(milliseconds: 300), curve: Curves.easeInOut),
                                ),
                              ),
                            if (ticketCount > 1 && _currentPage < ticketCount - 1)
                              Positioned(
                                right: 0,
                                top: 87,
                                child: IconButton(
                                  icon: const Icon(Icons.chevron_right_rounded, size: 32, color: AppColors.grey),
                                  onPressed: () => _pageController.nextPage(duration: const Duration(milliseconds: 300), curve: Curves.easeInOut),
                                ),
                              ),
                          ],
                        ),
                      ),

                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 8),
                        child: Divider(),
                      ),

                      // Order Information Section
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Order Information', style: TextStyle(color: AppColors.grey, fontSize: 12)),
                          const Text('Ticket Name', style: TextStyle(color: AppColors.grey, fontSize: 12)),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            booking['fname'] ?? '-',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                          ),
                          Text(
                            bookedTickets.isNotEmpty 
                              ? '${bookedTickets[0]['ticket_qty']} x ${bookedTickets[0]['ticket_name']}'
                              : '-',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
