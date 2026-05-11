import 'package:flutter/material.dart';
import '../../api/api.client.dart';
import '../../helpers/app_colors.dart';
import '../../helpers/app_state.dart';

class SelectLocationScreen extends StatefulWidget {
  final String? initialLocation;
  const SelectLocationScreen({super.key, this.initialLocation});

  @override
  State<SelectLocationScreen> createState() => _SelectLocationScreenState();
}

class _SelectLocationScreenState extends State<SelectLocationScreen> {
  final TextEditingController _searchController = TextEditingController();
  bool _isLoading = true;
  List<dynamic>? _locations;
  String _searchQuery = '';
  String? _selectedCity;
  String? _originalCurrentCity;
  Set<String> _availableCities = {};

  @override
  void initState() {
    super.initState();
    _selectedCity = widget.initialLocation ?? AppState.selectedLocation.value;
    _originalCurrentCity = AppState.originalCurrentLocation.value ?? widget.initialLocation ?? AppState.selectedLocation.value;
    _fetchLocations();
  }

  Future<void> _fetchLocations() async {
    try {
      final dynamic data = await ApiClient.getEventLocations();
      print('=== SCREEN: LOCATION DATA RECEIVED ===');
      print('Full data: $data');
      print('Data type: ${data.runtimeType}');
      
      Set<String> tempAvailableCities = {};
      List<dynamic> tempLocations = [];
      
      if (data is List) {
        tempLocations = data;
      } else if (data is Map) {
        tempLocations = (data as Map<String, dynamic>).values.toList();
      }
      
      for (final countryData in tempLocations) {
        final cities = countryData['cities'] as List? ?? [];
        for (final city in cities) {
          final cityName = city['city']?.toString();
          if (cityName != null) {
            tempAvailableCities.add(cityName);
          }
        }
      }
      
      setState(() {
        _locations = tempLocations;
        _availableCities = tempAvailableCities;
        _isLoading = false;
      });
    } catch (e, stack) {
      debugPrint('Error fetching locations: $e');
      debugPrint('Stack trace: $stack');
      setState(() => _isLoading = false);
    }
  }

  List<dynamic> _filteredLocations() {
    if (_searchQuery.isEmpty) {
      return _locations ?? [];
    }
    final query = _searchQuery.toLowerCase();
    final filtered = <dynamic>[];
    if (_locations != null) {
      for (final countryData in _locations!) {
        final countryName = countryData['country_name'] ?? '';
        final cities = countryData['cities'] as List? ?? [];
        
        final filteredCities = cities.where((city) {
          final cityName = city['city']?.toString() ?? '';
          return cityName.toLowerCase().contains(query);
        }).toList();
        
        if (countryName.toLowerCase().contains(query) || filteredCities.isNotEmpty) {
          filtered.add({
            'country_name': countryName,
            'cities': countryName.toLowerCase().contains(query) ? cities : filteredCities,
          });
        }
      }
    }
    return filtered;
  }

  @override
  Widget build(BuildContext context) {
    final filteredLocations = _filteredLocations();
    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: AppBar(
        title: const Text('Select Location', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFF14103D),
        iconTheme: const IconThemeData(color: Colors.white),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: Container(
                color: AppColors.white,
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Container(
                        decoration: BoxDecoration(
                          color: const Color(0xFFF5F5F5),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: TextField(
                          controller: _searchController,
                          onChanged: (value) {
                            setState(() {
                              _searchQuery = value;
                            });
                          },
                          decoration: const InputDecoration(
                            hintText: 'Search City',
                            hintStyle: TextStyle(color: AppColors.grey),
                            prefixIcon: Icon(Icons.search, color: AppColors.grey),
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: _isLoading
                          ? const Center(child: CircularProgressIndicator())
                          : ListView(
                              padding: const EdgeInsets.symmetric(horizontal: 16),
                              children: [
                                // Show original current city at the top always
                                if (_originalCurrentCity != null && _originalCurrentCity!.isNotEmpty)
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        'Current Location',
                                        style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                          color: AppColors.grey,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      InkWell(
                                        onTap: () {
                                          setState(() {
                                            _selectedCity = _originalCurrentCity;
                                          });
                                          AppState.selectedLocation.value = _originalCurrentCity;
                                          Navigator.pop(context, _originalCurrentCity);
                                        },
                                        child: Padding(
                                          padding: const EdgeInsets.symmetric(vertical: 4),
                                          child: Row(
                                            children: [
                                              Radio<String>(
                                                value: _originalCurrentCity!,
                                                groupValue: _selectedCity,
                                                activeColor: AppColors.primary,
                                                onChanged: (value) {
                                                  setState(() {
                                                    _selectedCity = value;
                                                  });
                                                  AppState.selectedLocation.value = value;
                                                  Navigator.pop(context, value);
                                                },
                                              ),
                                              const SizedBox(width: 4),
                                              Text(
                                                _originalCurrentCity!,
                                                style: TextStyle(
                                                  fontSize: 16,
                                                  color: _selectedCity == _originalCurrentCity ? AppColors.primary : AppColors.black,
                                                  fontWeight: _selectedCity == _originalCurrentCity ? FontWeight.w600 : FontWeight.normal,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                      const SizedBox(height: 16),
                                    ],
                                  ),
                                // Show other locations from API
                                ...filteredLocations.map((countryData) {
                                  final countryName = countryData['country_name'] ?? '';
                                  final cities = countryData['cities'] as List? ?? [];
                                  return Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        countryName,
                                        style: const TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                          color: AppColors.black,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      ...cities.map((city) {
                                        final cityName = city['city']?.toString() ?? '';
                                        final isSelected = _selectedCity == cityName;
                                        return InkWell(
                                          onTap: () {
                                            setState(() {
                                              _selectedCity = cityName;
                                            });
                                            AppState.selectedLocation.value = cityName;
                                            Navigator.pop(context, cityName);
                                          },
                                          child: Padding(
                                            padding: const EdgeInsets.symmetric(vertical: 4),
                                            child: Row(
                                              children: [
                                                Radio<String>(
                                                  value: cityName,
                                                  groupValue: _selectedCity,
                                                  activeColor: AppColors.primary,
                                                  onChanged: (value) {
                                                    setState(() {
                                                      _selectedCity = value;
                                                    });
                                                    AppState.selectedLocation.value = value;
                                                    Navigator.pop(context, value);
                                                  },
                                                ),
                                                const SizedBox(width: 4),
                                                Text(
                                                  cityName,
                                                  style: TextStyle(
                                                    fontSize: 16,
                                                    color: isSelected ? AppColors.primary : AppColors.black,
                                                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        );
                                      }).toList(),
                                      const SizedBox(height: 12),
                                    ],
                                  );
                                }).toList(),
                              ],
                            ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
