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

  @override
  void initState() {
    super.initState();
    _fetchTickets();
  }

  Future<void> _fetchTickets() async {
    setState(() => _isLoading = true);
    final data = await ApiClient.getCustomerEventTicketDetails(widget.eventId);
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
             // Let's assume the root data might be a single ticket or nested inside data
             _tickets = [data]; 
          }
          _serviceFee = double.tryParse((data['service_fee'] ?? 0.0).toString()) ?? 0.0;
          _processingFee = double.tryParse((data['processing_fee'] ?? 0.0).toString()) ?? 0.0;
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
      double price = double.tryParse(_tickets[i]['price']?.toString() ?? '0') ?? 0;
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

            const SizedBox(height: 16),

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
                        final priceStr = ticket['price']?.toString() ?? '0';
                        final price = double.tryParse(priceStr) ?? 0;
                        final labels = ticket['ticket_labels'] is List ? ticket['ticket_labels'] as List<dynamic> : [];
                        
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 16),
                          child: _buildTicketTypeCard(
                            title,
                            '\$${price.toStringAsFixed(2)}',
                            labels,
                            _ticketCounts[index] ?? 0,
                            (val) => setState(() => _ticketCounts[index] = val),
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

  Widget _buildTicketTypeCard(String title, String price, List<dynamic> labels, int count, Function(int) onCountChanged) {
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
              if (labels.isNotEmpty) ...[
                const SizedBox(height: 8),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: labels.map((labelObj) {
                    final labelText = labelObj['label']?.toString() ?? '';
                    final colorCode = labelObj['color_code']?.toString() ?? '';
                    final color = _parseColor(colorCode);
                    if (labelText.isEmpty) return const SizedBox.shrink();
                    
                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(4),
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
