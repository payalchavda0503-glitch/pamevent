import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'dart:convert';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:open_filex/open_filex.dart';
import 'package:path/path.dart' as p;
import '../../api/api.client.dart';
import '../../helpers/app_colors.dart';
import '../../helpers/utils.dart';
import '../../helpers/app_state.dart';
import '../../helpers/public_url.dart';
import '../../services/toast.service.dart';
import '../shared/widgets/custom_button.widget.dart';
import '../shared/widgets/custom_image.dart';
import 'order_details.screen.dart';

class TicketDetailsScreen extends StatefulWidget {
  final Map<String, dynamic> ticket;
  final String? bookingId; // Optional alphanumeric booking ID
  const TicketDetailsScreen({super.key, required this.ticket, this.bookingId});

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
    // Check both root and nested 'data' field for IDs
    final ticketData = widget.ticket['data'] is Map ? widget.ticket['data'] : widget.ticket;
    
    // Priority: 
    // 1. Explicitly passed bookingId (alphanumeric)
    // 2. booking_id from ticket data
    // 3. order_id from ticket data
    // 4. id from ticket data
    final bookingId = widget.bookingId ?? 
                      ticketData['booking_id']?.toString() ?? 
                      ticketData['order_id']?.toString() ?? 
                      ticketData['id']?.toString() ?? '';
    
    // Internal ID (numeric) if available
    final id = ticketData['id']?.toString() ?? 
               ticketData['booking']?['id']?.toString() ?? 
               bookingId;
    if (bookingId.isEmpty) {
      setState(() => _isLoading = false);
      return;
    }

    setState(() => _isLoading = true);
    AppState.showLoader();

    try {
      final data = await ApiClient.customerBookingDetails(bookingId, id: id).timeout(const Duration(seconds: 15));
      debugPrint('FULL API RESPONSE (Ticket Details): $data$bookingId');
      if (mounted) {
        setState(() {
          _bookingDetails = data?['data'] ?? data;
        });
      }
    } catch (e) {
      debugPrint('Error fetching booking details: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
        AppState.hideLoader();
      }
    }
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
       // Other base64 images (png/jpg)
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
    return CustomImage(
      'https://api.qrserver.com/v1/create-qr-code/?size=150x150&data=$data',
      width: 140,
      height: 140,
      fit: BoxFit.contain,
    );
  }

  @override
  Widget build(BuildContext context) {
    // Normalize ticketData to check both root and nested 'data' field
    final Map<String, dynamic> ticketData = (_bookingDetails?['data'] is Map) 
        ? (_bookingDetails!['data'] as Map<String, dynamic>) 
        : (_bookingDetails ?? widget.ticket);
    
    // Title parsing: check for event_title (new API) or title (old/fallback)
    final event = ticketData['event'] ?? {};
    final title = event['event_title'] ?? ticketData['event_title'] ?? event['title'] ?? ticketData['title'] ?? ticketData['event_name'] ?? '-';
    
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
    
    String date = event['event_start_date'] ?? ticketData['event_start_date'] ?? event['start_date'] ?? ticketData['start_date'] ?? '-';
    if (date == 'N/A') date = '-';
    if (date != '-') date = formatEventDate(date);

    String time = event['event_start_time'] ?? ticketData['event_start_time'] ?? event['start_time'] ?? ticketData['start_time'] ?? '-';
    if (time == 'N/A') time = '-';

    String location = event['event_location'] ?? ticketData['event_location'] ?? event['venue'] ?? ticketData['venue'] ?? '-';
    if (location == 'N/A') location = '-';

    String bookingId = ticketData['booking']?['booking_id']?.toString() ?? ticketData['booking_id'] ?? ticketData['order_id'] ?? ticketData['id']?.toString() ?? '-';
    if (bookingId == 'N/A') bookingId = '-';
    
    // Multiple tickets/QR codes handling: check for qr_codes (new API) or tickets (old)
    List<dynamic> tickets = (ticketData['booking_tickets'] is List && (ticketData['booking_tickets'] as List).isNotEmpty) ? ticketData['booking_tickets'] :
                            (ticketData['qr_codes'] is List && (ticketData['qr_codes'] as List).isNotEmpty) ? ticketData['qr_codes'] :
                            (ticketData['tickets'] is List && (ticketData['tickets'] as List).isNotEmpty) ? ticketData['tickets'] :
                            (ticketData['all_ticket_json'] is List && (ticketData['all_ticket_json'] as List).isNotEmpty) ? ticketData['all_ticket_json'] :
                            [];
                             
    if (tickets.isEmpty && (ticketData['ticket_number'] != null || ticketData['qr_code'] != null)) {
      tickets = [ticketData];
    }
    final int ticketCount = tickets.isNotEmpty ? tickets.length : 1;
    debugPrint('Extracted tickets count in build: ${tickets.length}');
    // Get current ticket id based on the pager
    final currentVisibleTicket = tickets.isNotEmpty && _currentPage < tickets.length ? tickets[_currentPage] : ticketData;
    String currentOrderTicketId = currentVisibleTicket['ticket_id'] ?? currentVisibleTicket['id'] ?? '-';
    if (currentOrderTicketId == 'N/A') currentOrderTicketId = '-';
    
    final booking = ticketData['booking'] ?? {};
    final bookedTickets = ticketData['booked_tickets'] as List? ?? [];
    final String currentTicketName = currentVisibleTicket['ticket_name'] ?? currentVisibleTicket['ticket_type'] ?? 'Event Ticket';

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
                        margin: const EdgeInsets.symmetric(vertical: 10),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(24),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.1),
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
                                                  final currentTicket = tickets.isNotEmpty ? tickets[index] : ticketData;
                                                  String qrData = (currentTicket is Map ? (currentTicket['qr_code'] ?? currentTicket['ticket_number'] ?? bookingId) : (currentTicket ?? bookingId)).toString();
                                                  
                                                  final String ticketId = (currentTicket is Map 
                                                      ? (currentTicket['ticket_id'] ?? currentTicket['id'] ?? currentTicket['ticket_number'] ?? bookingId) 
                                                      : (currentTicket ?? bookingId)).toString();
                                                  final String ticketName = (currentTicket is Map 
                                                      ? (currentTicket['ticket_name'] ?? currentTicket['ticket_type'] ?? 'Event Ticket') 
                                                      : 'Event Ticket').toString();
       
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
                                              booking['fname'] ?? ticketData['fname'] ?? ticketData['customer_name'] ?? '-',
                                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                            ),
                                            Text(
                                              bookedTickets.isNotEmpty 
                                                ? '${bookedTickets[0]['ticket_qty']} x ${bookedTickets[0]['ticket_name']}'
                                                : (booking['quantity'] != null
                                                    ? '${booking['quantity']} x $currentTicketName'
                                                    : '-'),
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
                              'Ticket ID: $currentOrderTicketId',
                              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                            ),
                            GestureDetector(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => OrderDetailsScreen(
                                      bookingData: _bookingDetails ?? {},
                                      ticketId: currentOrderTicketId,
                                    ),
                                  ),
                                );
                              },
                              child: Container(
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
                              onTap: () async {
                                final paymentInfo = _bookingDetails?['payment_info'];
                                if (paymentInfo != null && paymentInfo['invoice'] != null) {
                                  final invoiceUrl = paymentInfo['invoice'].toString();
                                  if (invoiceUrl.isNotEmpty) {
                                    try {
                                      ToastService.show('Downloading invoice...');
                                      final uri = Uri.parse(invoiceUrl);
                                      final fileName = p.basename(uri.path).split('?').first;
                                      final name = fileName.isNotEmpty && fileName.endsWith('.pdf') ? fileName : 'invoice.pdf';
                                      
                                      final dir = await getTemporaryDirectory();
                                      final savePath = p.join(dir.path, name);
                                      
                                      final dio = Dio();
                                      await dio.download(invoiceUrl, savePath);
                                      
                                      ToastService.show('Opened invoice!', backgroundColor: Colors.green);
                                      await OpenFilex.open(savePath);
                                      return;
                                    } catch (e) {
                                      ToastService.show('Failed to download invoice.');
                                      return;
                                    }
                                  }
                                }
                                ToastService.show('Invoice link not available.');
                              },
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
