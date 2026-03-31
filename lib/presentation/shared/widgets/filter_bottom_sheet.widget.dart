import 'package:flutter/material.dart';
import '../../../helpers/app_colors.dart';

class FilterBottomSheet extends StatefulWidget {
  const FilterBottomSheet({super.key});

  @override
  State<FilterBottomSheet> createState() => _FilterBottomSheetState();
}

class _FilterBottomSheetState extends State<FilterBottomSheet> {
  final TextEditingController _dateController = TextEditingController();
  String _selectedCategory = 'All';
  String _selectedEvent = 'Online Events';
  String _selectedPriceType = 'All';
  RangeValues _currentRangeValues = const RangeValues(5, 73);

  @override
  void dispose() {
    _dateController.dispose();
    super.dispose();
  }

  Future<void> _selectDateRange(BuildContext context) async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime.now(),
      lastDate: DateTime(2030),
      helpText: 'Select event date range',
      confirmText: 'SELECT',
      saveText: 'SAVE',
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.primary,
              onPrimary: AppColors.white,
              onSurface: AppColors.black,
              surface: AppColors.white,
              secondary: AppColors.primary,
            ),
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(
                foregroundColor: AppColors.primary,
                textStyle: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            appBarTheme: const AppBarTheme(
              backgroundColor: AppColors.primary,
              foregroundColor: AppColors.white,
              elevation: 0,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        final start = picked.start;
        final end = picked.end;
        _dateController.text =
            '${start.day.toString().padLeft(2, '0')}/${start.month.toString().padLeft(2, '0')}/${start.year} - ${end.day.toString().padLeft(2, '0')}/${end.month.toString().padLeft(2, '0')}/${end.year}';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Filter by Date
            const Text(
              'Filter by Date',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Container(
              decoration: BoxDecoration(
                border: Border.all(color: AppColors.lightGrey),
                borderRadius: BorderRadius.circular(8),
              ),
              child: TextField(
                controller: _dateController,
                decoration: const InputDecoration(
                  hintText: 'Start/End Date',
                  hintStyle: TextStyle(color: AppColors.grey, fontSize: 13),
                  contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  border: InputBorder.none,
                ),
                readOnly: true,
                onTap: () => _selectDateRange(context),
              ),
            ),
            const Divider(height: 32, color: AppColors.lightGrey),

            // Category
            const Text(
              'Category',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: AppColors.scaffold,
                borderRadius: BorderRadius.circular(8),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _selectedCategory,
                  isExpanded: true,
                  style: const TextStyle(fontSize: 14, color: AppColors.black),
                  icon: const Icon(Icons.arrow_drop_down, color: AppColors.black),
                  items: ['All', 'Music', 'Food', 'Social'].map((String value) {
                    return DropdownMenuItem<String>(
                      value: value,
                      child: Text(value),
                    );
                  }).toList(),
                  onChanged: (newValue) {
                    setState(() {
                      _selectedCategory = newValue!;
                    });
                  },
                ),
              ),
            ),
            const Divider(height: 32, color: AppColors.lightGrey),

            // Events
            const Text(
              'Events',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                SizedBox(
                  height: 32,
                  child: Radio<String>(
                    value: 'Online Events',
                    groupValue: _selectedEvent,
                    activeColor: AppColors.primary,
                    onChanged: (value) {
                      setState(() {
                        _selectedEvent = value!;
                      });
                    },
                  ),
                ),
                const Text('Online Events', style: TextStyle(fontSize: 14)),
              ],
            ),
            Row(
              children: [
                SizedBox(
                  height: 32,
                  child: Radio<String>(
                    value: 'Venue Events',
                    groupValue: _selectedEvent,
                    activeColor: AppColors.primary,
                    onChanged: (value) {
                      setState(() {
                        _selectedEvent = value!;
                      });
                    },
                  ),
                ),
                const Text('Venue Events', style: TextStyle(fontSize: 14)),
              ],
            ),
            const Divider(height: 32, color: AppColors.lightGrey),

            // Price Filter
            const Text(
              'Price Filter',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: AppColors.scaffold,
                borderRadius: BorderRadius.circular(8),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _selectedPriceType,
                  isExpanded: true,
                  style: const TextStyle(fontSize: 14, color: AppColors.black),
                  icon: const Icon(Icons.arrow_drop_down, color: AppColors.black),
                  items: ['All', 'Free', 'Paid'].map((String value) {
                    return DropdownMenuItem<String>(
                      value: value,
                      child: Text(value),
                    );
                  }).toList(),
                  onChanged: (newValue) {
                    setState(() {
                      _selectedPriceType = newValue!;
                    });
                  },
                ),
              ),
            ),
            const SizedBox(height: 8),
            RangeSlider(
              values: _currentRangeValues,
              min: 0,
              max: 100,
              divisions: 100,
              activeColor: AppColors.primary,
              inactiveColor: AppColors.lightGrey,
              onChanged: (RangeValues values) {
                setState(() {
                  _currentRangeValues = values;
                });
              },
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '\$${_currentRangeValues.start.round()} - \$${_currentRangeValues.end.round()}',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
                ElevatedButton(
                  onPressed: () {},
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                  ),
                  child: const Text(
                    'Price Filter',
                    style: TextStyle(color: AppColors.white, fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                child: const Text(
                  'Submit',
                  style: TextStyle(color: AppColors.white, fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
