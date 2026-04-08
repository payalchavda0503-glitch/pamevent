import 'package:flutter/material.dart';
import '../../../api/api.client.dart';
import '../../../helpers/app_colors.dart';

class FilterBottomSheet extends StatefulWidget {
  final Map<String, dynamic>? initialFilters;
  const FilterBottomSheet({super.key, this.initialFilters});

  @override
  State<FilterBottomSheet> createState() => _FilterBottomSheetState();
}

class _FilterBottomSheetState extends State<FilterBottomSheet> {
  final TextEditingController _dateController = TextEditingController();
  String _selectedCategory = 'All';
  String _selectedEvent = 'All'; // Changed default to All
  String _selectedPriceType = 'All';
  RangeValues _currentRangeValues = const RangeValues(0, 1000);
  List<dynamic> _categories = [];
  bool _isLoadingCategories = true;

  @override
  void initState() {
    super.initState();
    _fetchCategories();
    if (widget.initialFilters != null) {
      _selectedCategory = widget.initialFilters!['category'] ?? 'All';
      _selectedEvent = widget.initialFilters!['event'] ?? 'All';
      _dateController.text = widget.initialFilters!['dates'] ?? '';
      final min = double.tryParse(widget.initialFilters!['min'] ?? '0') ?? 0;
      final max = double.tryParse(widget.initialFilters!['max'] ?? '1000') ?? 1000;
      _currentRangeValues = RangeValues(min, max);
    }
  }

  Future<void> _fetchCategories() async {
    try {
      final categories = await ApiClient.getCategories();
      if (mounted) {
        setState(() {
          _categories = categories ?? [];
          _isLoadingCategories = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingCategories = false);
      }
    }
  }

  @override
  void dispose() {
    _dateController.dispose();
    super.dispose();
  }

  Future<void> _selectDateRange(BuildContext context) async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
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
        // API format: "2026-04-01  2026-04-10"
        _dateController.text =
            '${start.year}-${start.month.toString().padLeft(2, '0')}-${start.day.toString().padLeft(2, '0')}  ${end.year}-${end.month.toString().padLeft(2, '0')}-${end.day.toString().padLeft(2, '0')}';
      });
    }
  }

  void _submit() {
    final filters = <String, dynamic>{};
    if (_selectedCategory != 'All') filters['category'] = _selectedCategory;
    if (_selectedEvent != 'All') {
      filters['event'] = _selectedEvent == 'Online Events' ? 'online' : 'venue';
    }
    if (_dateController.text.isNotEmpty) filters['dates'] = _dateController.text;
    filters['min'] = _currentRangeValues.start.round().toString();
    filters['max'] = _currentRangeValues.end.round().toString();
    
    Navigator.pop(context, filters);
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
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Filters',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                TextButton(
                  onPressed: () {
                    setState(() {
                      _selectedCategory = 'All';
                      _selectedEvent = 'All';
                      _dateController.clear();
                      _currentRangeValues = const RangeValues(0, 1000);
                    });
                  },
                  child: const Text('Reset', style: TextStyle(color: AppColors.primary)),
                ),
              ],
            ),
            const SizedBox(height: 16),
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
                decoration: InputDecoration(
                  hintText: 'Start/End Date',
                  hintStyle: const TextStyle(color: AppColors.grey, fontSize: 13),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  border: InputBorder.none,
                  suffixIcon: _dateController.text.isNotEmpty 
                    ? IconButton(
                        icon: const Icon(Icons.clear, size: 18),
                        onPressed: () => setState(() => _dateController.clear()),
                      ) 
                    : null,
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
                  items: [
                    const DropdownMenuItem<String>(
                      value: 'All',
                      child: Text('All Categories'),
                    ),
                    ..._categories.map((cat) {
                      return DropdownMenuItem<String>(
                        value: cat['name']?.toString() ?? '',
                        child: Text(cat['name']?.toString() ?? ''),
                      );
                    }).toList(),
                  ],
                  onChanged: _isLoadingCategories ? null : (newValue) {
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
              'Event Type',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                SizedBox(
                  height: 32,
                  child: Radio<String>(
                    value: 'All',
                    groupValue: _selectedEvent,
                    activeColor: AppColors.primary,
                    onChanged: (value) {
                      setState(() {
                        _selectedEvent = value!;
                      });
                    },
                  ),
                ),
                const Text('All', style: TextStyle(fontSize: 14)),
              ],
            ),
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
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '\$${_currentRangeValues.start.round()} - \$${_currentRangeValues.end.round()}',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
              ],
            ),
            const SizedBox(height: 8),
            RangeSlider(
              values: _currentRangeValues,
              min: 0,
              max: 2000,
              divisions: 100,
              activeColor: AppColors.primary,
              inactiveColor: AppColors.lightGrey,
              onChanged: (RangeValues values) {
                setState(() {
                  _currentRangeValues = values;
                });
              },
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _submit,
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
