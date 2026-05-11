import 'package:flutter/material.dart';
import 'package:pretty_qr_code/pretty_qr_code.dart';
import '../../helpers/app_colors.dart';
import 'package:pamevent/helpers/public_url.dart';
import '../../helpers/utils.dart';
import '../main_layout.dart';
import '../shared/widgets/custom_button.widget.dart';
import '../shared/widgets/custom_image.dart';
import './ticket_details.screen.dart';
import '../../api/api.client.dart';

class OrderSuccessScreen extends StatefulWidget {
  final String orderId;
  final double amount;
  final String? eventName;
  final Map<String, dynamic>? bookingData;

  const OrderSuccessScreen({
    super.key,
    required this.orderId,
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
    _callBookingComplateApi();
  }

  Future<void> _callBookingComplateApi() async {
    final data = _fullBookingData?['data'] is Map ? _fullBookingData!['data'] : _fullBookingData;
    final eventId = data?['event_id']?.toString();
    final bookingId = data?['id']?.toString();

    if (eventId == null || bookingId == null) return;

    setState(() => _isLoading = true);

    final res = await ApiClient.bookingComplate(eventId, bookingId);
    if (res != null && mounted) {
      setState(() {
        _fullBookingData = res['data'] ?? res;
        _isLoading = false;
        _extractTickets();
      });
    } else if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  void _extractTickets() {
    final data = _fullBookingData?['data'] is Map ? _fullBookingData!['data'] : _fullBookingData;
    print('Extracting tickets from data: $data');
    if (data != null) {
      _tickets = data['qr_codes'] ?? 
                 data['tickets'] ?? 
                 data['booking_tickets'] ?? 
                 [];
      
      if (_tickets.isEmpty && (data['ticket_number'] != null || data['qr_code'] != null)) {
        _tickets = [data];
      }
      print('Extracted tickets count: ${_tickets.length}');
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
              _buildTicketCardSection(),
              
              const SizedBox(height: 16),

              // View Ticket Button
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 40),
                child: CustomButton(
                  title: 'View Ticket',
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => TicketDetailsScreen(
                          ticket: _fullBookingData ?? widget.bookingData ?? {},
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
    
    final eventTitle = event['title'] ?? event['event_title'] ?? data?['event_name'] ?? data?['title'] ?? widget.eventName ?? 'N/A';
    final eventImage = resolvePublicUrl(event['thumbnail'] ?? event['image'] ?? event['event_image'] ?? data?['event_image'] ?? data?['image'] ?? '');
    final eventDate = event['start_date'] ?? event['event_start_date'] ?? data?['event_date'] ?? data?['start_date'] ?? '';
    final eventTime = event['start_time'] ?? event['event_start_time'] ?? data?['event_start_time'] ?? data?['start_time'] ?? '';
    final eventLocation = event['event_address'] ?? event['address'] ?? data?['event_location'] ?? 'N/A';
    final bookingId = data?['id'] ?? data?['order_id'] ?? widget.orderId;

    final displayTickets = _tickets.isEmpty ? [null] : _tickets;

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
        children: [
          // Event Image (Static)
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            child: CustomImage(
              eventImage ?? '',
              height: 150,
              width: double.infinity,
              fit: BoxFit.cover,
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
                
                // Date, Time, Location Row (Static)
                Row(
                  children: [
                    const Icon(Icons.calendar_month, color: AppColors.primary, size: 14),
                    const SizedBox(width: 2),
                    Text(
                      formatEventDate(eventDate),
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
                
                const SizedBox(height: 12),
                
                // Pager for Booking ID and QR Code ONLY
                SizedBox(
                  height: 160, // Reduced height as it only contains ID and QR
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

                if (displayTickets.length > 1) ...[
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(
                      displayTickets.length,
                      (index) => Container(
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        width: 6,
                        height: 6,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: _currentPage == index ? AppColors.primary : Colors.grey.shade300,
                        ),
                      ),
                    ),
                  ),
                ],

                const SizedBox(height: 8),
                const Divider(height: 1),
                const SizedBox(height: 8),
                
                // Bottom Details (Static)
                _buildStaticBottomDetails(data, displayTickets.isNotEmpty ? displayTickets[0] : null),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDynamicIdAndQr(Map<String, dynamic>? ticket, Map<String, dynamic>? data) {
    final qrData = ticket != null 
        ? (ticket['ticket_number'] ?? ticket['qr_code'] ?? widget.orderId)
        : widget.orderId;
    final bookingId = ticket != null ? (ticket['booking_id'] ?? data?['id'] ?? data?['order_id'] ?? widget.orderId) : (data?['id'] ?? data?['order_id'] ?? widget.orderId);

    return Column(
      children: [
        Center(
          child: Text(
            'Booking ID : # $bookingId',
            style: const TextStyle(fontSize: 12, color: AppColors.black, fontWeight: FontWeight.w500),
          ),
        ),
        const SizedBox(height: 8),
        // QR Code
        Center(
          child: Column(
            children: [
              SizedBox(
                height: 100,
                width: 100,
                child: PrettyQrView.data(
                  data: qrData.toString(),
                  decoration: const PrettyQrDecoration(
                    shape: PrettyQrSmoothSymbol(
                      color: AppColors.black,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                qrData.toString(),
                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.black),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStaticBottomDetails(Map<String, dynamic>? data, Map<String, dynamic>? firstTicket) {
    final billingDetails = data?['billing_details'] ?? {};
    final purchaserName = billingDetails['fname'] ?? billingDetails['customer_name'] ?? data?['customer_name'] ?? data?['name'] ?? '-';
    final ticketName = firstTicket != null ? (firstTicket['ticket_type'] ?? firstTicket['category_name'] ?? firstTicket['ticket_name'] ?? 'General') : 'General';

    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Purchased by:', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.black)),
              const SizedBox(height: 4),
              Text(
                purchaserName, 
                maxLines: 1, 
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.black)
              ),
            ],
          ),
        ),
        Container(height: 30, width: 1, color: Colors.black26),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Ticket Name :', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.black)),
              const SizedBox(height: 4),
              Text(
                ticketName, 
                maxLines: 1, 
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.black)
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTicketDetails(Map<String, dynamic>? ticket, Map<String, dynamic>? data) {
    // This is no longer used
    return const SizedBox.shrink();
  }

  Widget _buildTicketCard(Map<String, dynamic>? ticket) {
    // This is no longer used directly as we merged it into _buildTicketCardSection
    return const SizedBox.shrink();
  }
}
