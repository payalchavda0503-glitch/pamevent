import 'package:flutter/material.dart';
import '../../helpers/app_colors.dart';
import '../shared/widgets/custom_button.widget.dart';

class SelectTicketsScreen extends StatefulWidget {
  const SelectTicketsScreen({super.key});

  @override
  State<SelectTicketsScreen> createState() => _SelectTicketsScreenState();
}

class _SelectTicketsScreenState extends State<SelectTicketsScreen> {
  int earlyBirdCount = 1;
  int generalAdmissionCount = 1;
  
  final double earlyBirdPrice = 45.50;
  final double generalAdmissionPrice = 50.00;
  final double serviceFee = 6.00;
  final double processingFee = 2.80;

  @override
  Widget build(BuildContext context) {
    double total = (earlyBirdCount * earlyBirdPrice) + 
                  (generalAdmissionCount * generalAdmissionPrice) + 
                  serviceFee + processingFee;

    return Scaffold(
      backgroundColor: AppColors.white,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
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
                  const Text(
                    'Tickets',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: AppColors.black,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Ticket Types
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                children: [
                  _buildTicketTypeCard(
                    'Early Bird',
                    '\$${earlyBirdPrice.toStringAsFixed(2)}',
                    earlyBirdCount,
                    (val) => setState(() => earlyBirdCount = val),
                  ),
                  const SizedBox(height: 16),
                  _buildTicketTypeCard(
                    'General Admission Phase 1',
                    '\$${generalAdmissionPrice.toStringAsFixed(2)}',
                    generalAdmissionCount,
                    (val) => setState(() => generalAdmissionCount = val),
                  ),
                ],
              ),
            ),

            // Summary Section
            Container(
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                color: AppColors.white,
                border: Border(top: BorderSide(color: AppColors.lightGrey, width: 0.5)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${earlyBirdCount + generalAdmissionCount} tickets selected',
                    style: const TextStyle(fontSize: 14, color: AppColors.grey),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Total',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      Text(
                        '\$${total.toStringAsFixed(2)}',
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Service fee',
                        style: TextStyle(fontSize: 14, color: AppColors.grey),
                      ),
                      Text(
                        '\$${serviceFee.toStringAsFixed(2)}',
                        style: const TextStyle(fontSize: 14, color: AppColors.grey),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Processing fee',
                        style: TextStyle(fontSize: 14, color: AppColors.grey),
                      ),
                      Text(
                        '\$${processingFee.toStringAsFixed(2)}',
                        style: const TextStyle(fontSize: 14, color: AppColors.grey),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Payment Button
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: CustomButton(
                title: 'Go to payment',
                onTap: () {
                  // Handle payment navigation
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTicketTypeCard(String title, String price, int count, Function(int) onCountChanged) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              Text(
                price,
                style: const TextStyle(fontSize: 12, color: AppColors.grey),
              ),
            ],
          ),
          Row(
            children: [
              _buildCountButton(Icons.remove, () {
                if (count > 0) onCountChanged(count - 1);
              }),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12.0),
                child: Text(
                  '$count',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
              _buildCountButton(Icons.add, () {
                onCountChanged(count + 1);
              }),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCountButton(IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(4),
        child: Icon(icon, size: 20, color: AppColors.black),
      ),
    );
  }
}
