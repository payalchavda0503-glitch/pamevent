import 'package:flutter/material.dart';
import '../../api/api.client.dart';
import '../../helpers/app_colors.dart';
import '../shared/widgets/custom_button.widget.dart';
import 'checkout.screen.dart';

class SelectTicketsScreen extends StatefulWidget {
  final int eventId;

  const SelectTicketsScreen({super.key, required this.eventId});

  @override
  State<SelectTicketsScreen> createState() => _SelectTicketsScreenState();
}

class _SelectTicketsScreenState extends State<SelectTicketsScreen> {
  bool _isLoading = true;
  List<dynamic> _tickets = [];
  Map<int, int> _ticketCounts = {};
  double _serviceFee = 0.0;
  double _processingFee = 0.0;
  
  // New state for multiple dates
  List<dynamic> _eventDates = [];
  dynamic _selectedDate;

  @override
  void initState() {
    super.initState();
    _fetchTickets();
  }

  Future<void> _fetchTickets() async {
    setState(() => _isLoading = true);
    final data = await ApiClient.getCustomerEventTicketDetails(widget.eventId);
    debugPrint('Ticket Details Response: $data');
    if (mounted) {
      setState(() {
        if (data is List) {
          _tickets = data;
        } else if (data is Map) {
          if (data['tickets'] is List) {
            _tickets = data['tickets'];
          } else if (data['ticket_types'] is List) {
            _tickets = data['ticket_types'];
          } else if (data['ticket_detail'] is List) {
            _tickets = data['ticket_detail'];
          } else {
             _tickets = [data]; 
          }
          _serviceFee = double.tryParse((data['service_fee'] ?? 0.0).toString()) ?? 0.0;
          _processingFee = double.tryParse((data['processing_fee'] ?? 0.0).toString()) ?? 0.0;
          
          // Extract dates from 'event_dates' or 'event_starts'
          final datesFromApi = data['event_dates'] ?? data['event_starts'];
          if (datesFromApi != null) {
             if (datesFromApi is List) {
                _eventDates = datesFromApi;
             } else {
                _eventDates = [datesFromApi];
             }
             if (_eventDates.isNotEmpty) {
                _selectedDate = _eventDates.first;
             }
          }
        }

        for (int i = 0; i < _tickets.length; i++) {
          _ticketCounts[i] = 0;
        }
        _isLoading = false;
      });
    }
  }

  double _calculateTicketsTotal() {
    double total = 0;
    for (int i = 0; i < _tickets.length; i++) {
      int count = _ticketCounts[i] ?? 0;
      double price = double.tryParse((_tickets[i]['final_price'] ?? _tickets[i]['price'])?.toString() ?? '0') ?? 0;
      total += count * price;
    }
    return total;
  }

  int _calculateTotalTickets() {
    int count = 0;
    for (int i = 0; i < _tickets.length; i++) {
      count += _ticketCounts[i] ?? 0;
    }
    return count;
  }

  @override
  Widget build(BuildContext context) {
    double ticketsTotal = _calculateTicketsTotal();
    int totalTickets = _calculateTotalTickets();
    double total = ticketsTotal;

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

            if (!_isLoading && _eventDates.isNotEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Select Date',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        border: Border.all(color: AppColors.lightGrey),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<dynamic>(
                          isExpanded: true,
                          value: _selectedDate,
                          items: _eventDates.map((date) {
                            // API format can be {start_date_time: ..., timezone: ...} or {startDateTime: ...}
                            final dateStr = date['start_date_time']?.toString() ?? date['startDateTime']?.toString() ?? 'Date';
                            final timezone = date['timezone']?.toString() ?? '';
                            return DropdownMenuItem<dynamic>(
                              value: date,
                              child: Text('$dateStr ${timezone.isNotEmpty ? "($timezone)" : ""}'),
                            );
                          }).toList(),
                          onChanged: (val) {
                            setState(() => _selectedDate = val);
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Divider(color: AppColors.lightGrey),
                    const SizedBox(height: 8),
                    const Text(
                      'Select Tickets',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),

            const SizedBox(height: 8),

            // Ticket Types
            Expanded(
              child: _isLoading 
                ? const Center(child: CircularProgressIndicator())
                : _tickets.isEmpty
                  ? const Center(child: Text("No tickets available"))
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: _tickets.length,
                      itemBuilder: (context, index) {
                        final ticket = _tickets[index];
                        final title = ticket['title'] ?? ticket['name'] ?? ticket['ticket_type'] ?? 'Ticket';
                        final description = ticket['description']?.toString() ?? '';
                        
                        final originalPrice = double.tryParse(ticket['price']?.toString() ?? '0') ?? 0;
                        final finalPrice = double.tryParse(ticket['final_price']?.toString() ?? ticket['price']?.toString() ?? '0') ?? 0;
                        
                        final earlyBirdEnabled = ticket['early_bird_discount']?.toString() == 'enable';
                        final discountDate = ticket['early_bird_discount_date']?.toString() ?? '';
                        final discountTime = ticket['early_bird_discount_time']?.toString() ?? '';
                        
                        final labels = ticket['ticket_labels'] is List ? ticket['ticket_labels'] as List<dynamic> : [];
                        
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 16),
                          child: _buildTicketTypeCard(
                            title: title,
                            description: description,
                            price: '\$${finalPrice.toStringAsFixed(2)}',
                            originalPrice: finalPrice < originalPrice ? '\$${originalPrice.toStringAsFixed(2)}' : null,
                            discountInfo: earlyBirdEnabled ? 'Discount available : (till : $discountDate $discountTime )' : null,
                            labels: labels,
                            count: _ticketCounts[index] ?? 0,
                            onCountChanged: (val) => setState(() => _ticketCounts[index] = val),
                          ),
                        );
                      },
                    ),
            ),

            // Summary Section
            if (!_isLoading)
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
                    '$totalTickets tickets selected',
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
                ],
              ),
            ),

            // Payment Button
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: CustomButton(
                title: 'Go to payment',
                onTap: () {
                  List<Map<String, dynamic>> selected = [];
                  for (int i = 0; i < _tickets.length; i++) {
                    int count = _ticketCounts[i] ?? 0;
                    if (count > 0) {
                      selected.add({
                        'ticket': _tickets[i],
                        'count': count,
                      });
                    }
                  }
                  
                  if (selected.isNotEmpty) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => CheckoutScreen(
                          eventId: widget.eventId,
                          selectedTickets: selected,
                          totalAmount: total,
                          serviceFee: _serviceFee,
                          processingFee: _processingFee,
                        ),
                      ),
                    );
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please select at least one ticket')));
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTicketTypeCard({
    required String title,
    required String description,
    required String price,
    String? originalPrice,
    String? discountInfo,
    required List<dynamic> labels,
    required int count,
    required Function(int) onCountChanged,
  }) {
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            title,
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                        ),
                        if (labels.isNotEmpty) ...[
                          const SizedBox(width: 8),
                          Wrap(
                            spacing: 6,
                            runSpacing: 6,
                            children: labels.map((labelObj) {
                              final labelText = labelObj['label']?.toString() ?? '';
                              final colorCode = labelObj['color_code']?.toString() ?? '';
                              final color = _parseColor(colorCode);
                              if (labelText.isEmpty) return const SizedBox.shrink();
                              
                              return Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: color.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(color: color.withOpacity(0.5), width: 0.5),
                                ),
                                child: Text(
                                  labelText,
                                  style: TextStyle(fontSize: 10, color: color, fontWeight: FontWeight.bold),
                                ),
                              );
                            }).toList(),
                          ),
                        ],
                      ],
                    ),
                    if (description.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Text(
                        description,
                        style: const TextStyle(fontSize: 13, color: AppColors.grey),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Text(
                    price,
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  if (originalPrice != null) ...[
                    const SizedBox(width: 8),
                    Text(
                      originalPrice,
                      style: const TextStyle(
                        fontSize: 14, 
                        color: AppColors.grey,
                        decoration: TextDecoration.lineThrough,
                      ),
                    ),
                  ],
                ],
              ),
              Container(
                decoration: BoxDecoration(
                  border: Border.all(color: AppColors.lightGrey),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    _buildCountButton(Icons.remove, () {
                      if (count > 0) onCountChanged(count - 1);
                    }),
                    Container(
                      width: 40,
                      alignment: Alignment.center,
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
              ),
            ],
          ),
          if (discountInfo != null) ...[
            const SizedBox(height: 12),
            const Divider(height: 1, color: AppColors.lightGrey, thickness: 0.5),
            const SizedBox(height: 12),
            Text(
              discountInfo,
              style: const TextStyle(fontSize: 12, color: AppColors.grey),
            ),
          ],
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

  Color _parseColor(String? colorCode) {
    if (colorCode == null || colorCode.isEmpty) return AppColors.primary;
    try {
      final hexCode = colorCode.replaceAll('#', '');
      if (hexCode.length == 6) {
        return Color(int.parse('FF$hexCode', radix: 16));
      } else if (hexCode.length == 8) {
        return Color(int.parse(hexCode, radix: 16));
      }
    } catch (e) {
      return AppColors.primary;
    }
    return AppColors.primary;
  }
}
