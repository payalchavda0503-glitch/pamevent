import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'dart:convert';
import '../../api/api.client.dart';
import '../../helpers/app_colors.dart';
import '../../helpers/public_url.dart';
import '../shared/widgets/custom_button.widget.dart';
import '../shared/widgets/custom_image.dart';

class TicketDetailsScreen extends StatefulWidget {
  final Map<String, dynamic> ticket;
  const TicketDetailsScreen({super.key, required this.ticket});

  @override
  State<TicketDetailsScreen> createState() => _TicketDetailsScreenState();
}

class _TicketDetailsScreenState extends State<TicketDetailsScreen> {
  bool _isLoading = true;
  Map<String, dynamic>? _bookingDetails;
  final PageController _pageController = PageController();
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    _fetchBookingDetails();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _fetchBookingDetails() async {
    final bookingId = widget.ticket['booking_id']?.toString() ?? widget.ticket['order_id']?.toString() ?? '';
    final id = widget.ticket['id']?.toString();
    if (bookingId.isEmpty) {
      setState(() => _isLoading = false);
      return;
    }

    final data = await ApiClient.customerBookingDetails(bookingId, id: id);
    print('data------------$data');
    if (mounted) {
      setState(() {
        _bookingDetails = data?['data'];
        _isLoading = false;
      });
    }
  }

  Widget _buildQrCode(String data) {
    if (data.startsWith('data:image/svg+xml;base64,')) {
      final base64Str = data.split(',').last;
      return SvgPicture.memory(
        base64Decode(base64Str),
        width: 150,
        height: 150,
        placeholderBuilder: (context) => const CircularProgressIndicator(),
      );
    } else if (data.startsWith('data:image')) {
       // Other base64 images (png/jpg)
       final base64Str = data.split(',').last;
       return Image.memory(
         base64Decode(base64Str),
         width: 150,
         height: 150,
       );
    }
    
    // Fallback to Google QR API
    return CustomImage(
      'https://api.qrserver.com/v1/create-qr-code/?size=150x150&data=$data',
      width: 150,
      height: 150,
    );
  }

  @override
  Widget build(BuildContext context) {
    final ticketData = _bookingDetails ?? widget.ticket;
    
    // Title parsing: check for event_title (new API) or title (old/fallback)
    final event = ticketData['event'] ?? {};
    final title = event['event_title'] ?? ticketData['event_title'] ?? event['title'] ?? ticketData['title'] ?? ticketData['event_name'] ?? 'Ticket';
    
    // Image parsing: check for thumbnail inside event (new API) or at root
    String? imageUrl;
    if (event['thumbnail'] != null) {
      imageUrl = event['thumbnail'].toString().trim();
    } else if (ticketData['thumbnail'] != null) {
      imageUrl = ticketData['thumbnail'].toString().trim();
    }
    
    // Clean trailing comma if any
    if (imageUrl != null && imageUrl.endsWith(',')) {
      imageUrl = imageUrl.substring(0, imageUrl.length - 1);
    }
    
    final eventImg = event['event_img'] ?? event['event_thumbnail'] ?? ticketData['event_img'] ?? ticketData['photo'];
    
    // If it's already a full URL, use it directly. Otherwise, resolve it.
    final finalImageUrl = (imageUrl != null && (imageUrl.startsWith('http://') || imageUrl.startsWith('https://'))) 
        ? imageUrl 
        : (resolvePublicUrl(imageUrl ?? eventImg?.toString()) ?? '');
    
    print('Final Image URL being used: "$finalImageUrl"');
    
    final date = event['event_start_date'] ?? ticketData['event_start_date'] ?? event['start_date'] ?? ticketData['start_date'] ?? 'N/A';
    final time = event['event_start_time'] ?? ticketData['event_start_time'] ?? event['start_time'] ?? ticketData['start_time'] ?? 'N/A';
    final location = event['event_location'] ?? ticketData['event_location'] ?? event['venue'] ?? ticketData['venue'] ?? 'N/A';
    final bookingId = ticketData['booking_id'] ?? ticketData['order_id'] ?? 'N/A';
    
    // Multiple tickets/QR codes handling: check for qr_codes (new API) or tickets (old)
    final List<dynamic> tickets = ticketData['qr_codes'] ?? ticketData['tickets'] ?? [];
    final int ticketCount = tickets.isNotEmpty ? tickets.length : 1;

    return Scaffold(
      backgroundColor: AppColors.white,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  GestureDetector(
                    onTap: () {
                      Navigator.pop(context);
                    },
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: const BoxDecoration(
                        color: AppColors.black,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.arrow_back_ios_new, color: AppColors.white, size: 16),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'My Tickets',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: AppColors.black,
                    ),
                  ),
                ],
              ),
            ),

            Expanded(
              child: _isLoading 
                ? const Center(child: CircularProgressIndicator())
                : SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Ticket Card
                      Container(
                        decoration: BoxDecoration(
                          color: AppColors.scaffold,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.1),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            // Event Image
                            ClipRRect(
                              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                              child: CustomImage(
                                finalImageUrl,
                                width: double.infinity,
                                height: 140,
                                fit: BoxFit.cover,
                                centerLoader: true,
                                whenEmpty: Container(
                                  width: double.infinity,
                                  height: 140,
                                  color: Colors.grey.shade300,
                                  child: const Icon(Icons.image_not_supported, color: Colors.grey, size: 40),
                                ),
                              ),
                            ),
                            
                            // Tickets Paging (Multiple QR Codes)
                            SizedBox(
                              height: 380, // Fixed height for the ticket info part
                              child: PageView.builder(
                                controller: _pageController,
                                onPageChanged: (index) {
                                  setState(() => _currentPage = index);
                                },
                                itemCount: ticketCount,
                                itemBuilder: (context, index) {
                                  final currentTicket = tickets.isNotEmpty ? tickets[index] : ticketData;
                                  final qrCodeData = currentTicket['ticket_number'] ?? currentTicket['qr_code'] ?? bookingId;
                                  final attendeeName = currentTicket['name'] ?? currentTicket['customer_name'] ?? 'Guest';
                                  final ticketType = currentTicket['ticket_name'] ?? currentTicket['ticket_type'] ?? 'General Admission';

                                  return Padding(
                                    padding: const EdgeInsets.all(16.0),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          title,
                                          style: const TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold,
                                          ),
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
                                        const SizedBox(height: 16),
                                        Center(
                                          child: Text(
                                            'Booking ID: $bookingId',
                                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                                          ),
                                        ),
                                        const SizedBox(height: 16),
                                        // QR Code
                                        Center(
                                          child: _buildQrCode(qrCodeData.toString()),
                                        ),
                                        const SizedBox(height: 8),
                                        if (!qrCodeData.toString().startsWith('data:'))
                                        Center(
                                          child: Text(
                                            qrCodeData.toString(),
                                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                                          ),
                                        ),
                                        const SizedBox(height: 24),
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                const Text('Order information', style: TextStyle(fontSize: 11, color: AppColors.darkGrey)),
                                                const SizedBox(height: 4),
                                                Text(attendeeName, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                                              ],
                                            ),
                                            Column(
                                              crossAxisAlignment: CrossAxisAlignment.end,
                                              children: [
                                                const Text('Ticket type', style: TextStyle(fontSize: 11, color: AppColors.darkGrey)),
                                                const SizedBox(height: 4),
                                                Text(ticketType, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  );
                                },
                              ),
                            ),
                            
                            // Bottom Pagination (Indicator)
                            if (ticketCount > 1)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                              decoration: BoxDecoration(
                                border: Border(top: BorderSide(color: AppColors.lightGrey.withValues(alpha: 0.5))),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    '${_currentPage + 1} of $ticketCount',
                                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
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
                                        onPressed: _currentPage < ticketCount - 1 
                                          ? () => _pageController.nextPage(duration: const Duration(milliseconds: 300), curve: Curves.easeInOut)
                                          : null,
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 32),

                      // Orders Section
                      const Text(
                        'Orders',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: AppColors.black,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          border: Border.symmetric(
                            horizontal: BorderSide(color: AppColors.lightGrey.withValues(alpha: 0.5)),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Booking ID: $bookingId',
                              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: AppColors.primary,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: const Text(
                                'Order details',
                                style: TextStyle(color: AppColors.white, fontSize: 11, fontWeight: FontWeight.bold),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 32),

                      // Action Buttons
                      Row(
                        children: [
                          Expanded(
                            child: CustomButton.outline(
                              title: 'Download ticket',
                              onTap: () {},
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: CustomButton.outline(
                              title: 'See more',
                              onTap: () {},
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 32),
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
}
