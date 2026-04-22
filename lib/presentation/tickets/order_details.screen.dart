import 'package:flutter/material.dart';
import '../../helpers/app_colors.dart';

class OrderDetailsScreen extends StatelessWidget {
  final Map<String, dynamic> bookingData;
  final String ticketId;
  const OrderDetailsScreen({super.key, required this.bookingData, required this.ticketId});

  @override
  Widget build(BuildContext context) {
    final paymentInfo = bookingData['payment_info'] ?? {};
    final billingDetails = bookingData['billing_details'] ?? {};
    final event = bookingData['event'] ?? {};

    final bookingId = bookingData['booking_id'] ?? bookingData['order_id'] ?? 'N/A';
    final paymentStatus = paymentInfo['payment_status'] ?? bookingData['payment_status'] ?? 'pending';

    final createdAt = bookingData['created_at'] ?? 'N/A';
    final eventStartDate = event['start_date'] ?? event['event_start_date'] ?? 'N/A';
    final eventStartTime = event['start_time'] ?? event['event_start_time'] ?? '';

    final name = billingDetails['name'] ?? billingDetails['customer_name'] ?? bookingData['customer_name'] ?? bookingData['name'] ?? 'N/A';
    final email = billingDetails['email'] ?? bookingData['customer_email'] ?? bookingData['email'] ?? 'N/A';
    final phone = billingDetails['phone'] ?? bookingData['customer_phone'] ?? bookingData['phone'] ?? 'N/A';

    final eventTitle = event['title'] ?? event['event_title'] ?? bookingData['event_name'] ?? bookingData['title'] ?? 'N/A';
    
    // Format prices safely
    String formatPrice(dynamic value) {
      if (value == null || value.toString().isEmpty) return '\$0.00';
      final valStr = value.toString();
      final doubleVal = double.tryParse(valStr) ?? 0.0;
      return '\$${doubleVal.toStringAsFixed(2)}';
    }

    final ticketPrice = formatPrice(paymentInfo['ticket_price'] ?? bookingData['ticket_price']);
    final addonPriceFee = formatPrice(paymentInfo['addon_price_fee']);
    final serviceFee = formatPrice(paymentInfo['service_fee'] ?? bookingData['service_fee']);
    final processingFee = formatPrice(paymentInfo['processing_fee'] ?? bookingData['processing_fee']);
    final tax = formatPrice(paymentInfo['tax'] ?? bookingData['tax']);
    final totalPaid = formatPrice(paymentInfo['total_paid'] ?? bookingData['total'] ?? bookingData['grand_total']);
    
    final paymentMethod = paymentInfo['payment_method'] ?? bookingData['payment_method'] ?? bookingData['gateway'] ?? 'N/A';
    final quantity = paymentInfo['quantity']?.toString() ?? bookingData['quantity']?.toString() ?? '1';

    return Scaffold(
      backgroundColor: AppColors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Back Button
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: const BoxDecoration(
                      color: AppColors.black,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.arrow_back_ios_new,
                      color: AppColors.white,
                      size: 16,
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Order Details Header
                const Text(
                  'Order details',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: AppColors.black,
                  ),
                ),
                const SizedBox(height: 12),

                // Booking # and status
                Text.rich(
                  TextSpan(
                    text: 'Ticket ID: $ticketId ',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppColors.black,
                    ),
                    children: [
                      TextSpan(
                        text: '[$paymentStatus]',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: paymentStatus.toString().toLowerCase() == 'completed' ? Colors.green : AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),

                // Booking Dates
                _buildInfoRow('Booking Date', eventStartDate),
                const SizedBox(height: 12),
                _buildInfoRow('Event Start Date', '$eventStartDate $eventStartTime'.trim()),
                const SizedBox(height: 20),

                // Billing Details Section
                const Text(
                  'Billing Details',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppColors.black,
                  ),
                ),
                const SizedBox(height: 8),
                _buildInfoRow('Name', name),
                const SizedBox(height: 12),
                _buildInfoRow('Email', email),
                const SizedBox(height: 12),
                _buildInfoRow('Phone', phone),
                const SizedBox(height: 20),

                // Payment Info Section
                const Text(
                  'Payment Info',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppColors.black,
                  ),
                ),
                const SizedBox(height: 8),
                _buildInfoRow('Event', eventTitle),
                const SizedBox(height: 8),
                _buildInfoRow('Ticket Price', ticketPrice),
                if (addonPriceFee != '\$0.00') ...[
                  const SizedBox(height: 8),
                  _buildInfoRow('Add-on Price & Fee', addonPriceFee),
                ],
                const SizedBox(height: 8),
                _buildInfoRow('Service Fee', serviceFee),
                const SizedBox(height: 8),
                _buildInfoRow('Processing Fee', processingFee),
                const SizedBox(height: 8),
                _buildInfoRow('Tax', tax),
                const SizedBox(height: 8),
                _buildInfoRow('Total Paid', totalPaid),
                const SizedBox(height: 8),
                Row(
                   children: [
                      const Text('Payment Status : ', style: TextStyle(fontSize: 13, color: AppColors.darkGrey)),
                      Container(
                         padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                         decoration: BoxDecoration(
                            color: paymentStatus.toString().toLowerCase() == 'completed' ? Colors.green : AppColors.primary,
                            borderRadius: BorderRadius.circular(4),
                         ),
                         child: Text(paymentStatus, style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                      ),
                   ],
                ),
                const SizedBox(height: 8),
                _buildInfoRow('Payment Method', paymentMethod),
                const SizedBox(height: 8),
                _buildInfoRow('Quantity', quantity),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text.rich(
          TextSpan(
            text: '$label : ',
            style: const TextStyle(
              fontSize: 13,
              color: AppColors.darkGrey,
            ),
            children: [
              TextSpan(
                text: value,
                style: const TextStyle(
                  fontWeight: FontWeight.w400,
                  color: AppColors.grey,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
