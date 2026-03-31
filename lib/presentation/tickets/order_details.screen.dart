import 'package:flutter/material.dart';
import '../../helpers/app_colors.dart';

class OrderDetailsScreen extends StatelessWidget {
  const OrderDetailsScreen({super.key});

  @override
  Widget build(BuildContext context) {
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
                const Text.rich(
                  TextSpan(
                    text: 'Booking # 69774a4f2860b ',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppColors.black,
                    ),
                    children: [
                      TextSpan(
                        text: '[completed]',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),

                // Booking Dates
                _buildInfoRow('Booking Date', 'Mon, Jan 26, 2026 06:04 am'),
                const SizedBox(height: 12),
                _buildInfoRow('Event Start Date', 'Fri, Jan 30, 2026 06:00 pm'),
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
                _buildInfoRow('Name', 'Valérie Chelsea'),
                const SizedBox(height: 12),
                _buildInfoRow('Email', 'valerheez@gmail.com'),
                const SizedBox(height: 12),
                _buildInfoRow('Phone', '+50938605664'),
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
                _buildInfoRow('Event', 'CHALOSKA'),
                const SizedBox(height: 8),
                _buildInfoRow('Ticket Price', '\$25.00'),
                const SizedBox(height: 8),
                _buildInfoRow('Service Fee', '\$2.12'),
                const SizedBox(height: 8),
                _buildInfoRow('Processing Fee', '\$1.09'),
                const SizedBox(height: 8),
                _buildInfoRow('Tax', '\$0.00'),
                const SizedBox(height: 8),
                _buildInfoRow('Total Paid', '\$28.21'),
                const SizedBox(height: 8),
                _buildInfoRow('Payment Status', 'completed'),
                const SizedBox(height: 8),
                _buildInfoRow('Payment Method', 'Moncash'),
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
