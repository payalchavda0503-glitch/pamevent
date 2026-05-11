import 'dart:developer' as dev;
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:permission_handler/permission_handler.dart';
import '../api/api.client.dart';
import '../helpers/app_state.dart';

class LocationService {
  static Future<void> initializeLocation() async {
    print('=== LOCATION SERVICE: Starting initialization ===');
    
    try {
      print('=== LOCATION SERVICE: Requesting permission ===');
      final permissionGranted = await _requestLocationPermission();
      
      if (!permissionGranted) {
        print('=== LOCATION SERVICE: Permission not granted ===');
        return;
      }
      
      print('=== LOCATION SERVICE: Permission granted, getting current location ===');
      final position = await _getCurrentLocation();
      
      if (position == null) {
        print('=== LOCATION SERVICE: Could not get current location ===');
        return;
      }
      
      print('=== LOCATION SERVICE: Got position - Lat: ${position.latitude}, Lng: ${position.longitude} ===');
      await _matchAndSetCity(position);
    } catch (e, stack) {
      print('=== LOCATION SERVICE: Error initializing location: $e ===');
      print('=== LOCATION SERVICE: Stack trace: $stack ===');
    }
  }

  static Future<bool> _requestLocationPermission() async {
    try {
      final status = await Permission.locationWhenInUse.request();
      dev.log('=== LOCATION SERVICE: Permission status: $status ===');
      return status.isGranted;
    } catch (e) {
      dev.log('=== LOCATION SERVICE: Error requesting permission: $e ===');
      return false;
    }
  }

  static Future<Position?> _getCurrentLocation() async {
    try {
      dev.log('=== LOCATION SERVICE: Checking if location services are enabled ===');
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      
      if (!serviceEnabled) {
        dev.log('=== LOCATION SERVICE: Location services disabled ===');
        return null;
      }
      
      dev.log('=== LOCATION SERVICE: Getting current position with high accuracy ===');
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 15),
        ),
      );
      
      dev.log('=== LOCATION SERVICE: Successfully got position ===');
      return position;
    } catch (e) {
      dev.log('=== LOCATION SERVICE: Error getting current position: $e ===');
      
      try {
        dev.log('=== LOCATION SERVICE: Trying with low accuracy ===');
        final position = await Geolocator.getCurrentPosition(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.low,
            timeLimit: Duration(seconds: 10),
          ),
        );
        dev.log('=== LOCATION SERVICE: Got position with low accuracy ===');
        return position;
      } catch (e2) {
        dev.log('=== LOCATION SERVICE: Failed to get position with low accuracy: $e2 ===');
        dev.log('=== LOCATION SERVICE: Trying to get last known position ===');
        try {
          final lastPosition = await Geolocator.getLastKnownPosition();
          if (lastPosition != null) {
            dev.log('=== LOCATION SERVICE: Got last known position ===');
            return lastPosition;
          }
        } catch (e3) {
          dev.log('=== LOCATION SERVICE: Failed to get last known position: $e3 ===');
        }
        return null;
      }
    }
  }

  static Future<void> _matchAndSetCity(Position position) async {
    try {
      print('=== LOCATION SERVICE: Fetching event locations from API ===');
      final locations = await ApiClient.getEventLocations();
      
      if (locations == null) {
        print('=== LOCATION SERVICE: No locations received from API ===');
        return;
      }
      
      // First collect all available city names from the API (store with original case)
      Map<String, String> availableCitiesMap = {};
      List<dynamic> locationList = [];
      if (locations is List) {
        locationList = locations;
      } else if (locations is Map) {
        locationList = (locations as Map<String, dynamic>).values.toList();
      }
      
      for (final countryData in locationList) {
        final countryName = countryData['country_name'] ?? 'Unknown';
        final cities = countryData['cities'] as List? ?? [];
        print('=== LOCATION SERVICE: Country: $countryName, Cities: $cities ===');
        for (final city in cities) {
          final originalCityName = city['city']?.toString();
          if (originalCityName != null) {
            final lowerCityName = originalCityName.toLowerCase();
            availableCitiesMap[lowerCityName] = originalCityName;
          }
        }
      }
      
      print('=== LOCATION SERVICE: Available cities (all): ${availableCitiesMap.values.toList()} ===');
      
      // Now use reverse geocoding to get user's city from coordinates
      print('=== LOCATION SERVICE: Starting reverse geocoding ===');
      List<Placemark> placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );
      
      print('=== LOCATION SERVICE: Reverse geocoding results: $placemarks ===');
      
      String? matchedCity;
      
      if (placemarks.isNotEmpty) {
        final placemark = placemarks.first;
        print('=== LOCATION SERVICE: Placemark: $placemark ===');
        print('=== LOCATION SERVICE: Placemark locality (city): ${placemark.locality} ===');
        print('=== LOCATION SERVICE: Placemark subLocality: ${placemark.subLocality} ===');
        print('=== LOCATION SERVICE: Placemark administrativeArea: ${placemark.administrativeArea} ===');
        
        // Check different placemark fields for a matching city
        List<String?> cityCandidates = [
          placemark.locality,
          placemark.subLocality,
          placemark.subAdministrativeArea,
        ];
        
        for (final candidate in cityCandidates) {
          if (candidate != null) {
            final lowerCandidate = candidate.toLowerCase();
            if (availableCitiesMap.containsKey(lowerCandidate)) {
              matchedCity = availableCitiesMap[lowerCandidate];
              print('=== LOCATION SERVICE: Found matching city: $matchedCity ===');
              break;
            }
          }
        }
      }
      
      // If we have a locality (city name) from reverse geocoding, set it even if it's not in the available list!
      String? cityFromGeocoding;
      if (placemarks.isNotEmpty) {
        cityFromGeocoding = placemarks.first.locality;
      }
      
      if (matchedCity != null) {
        print('=== LOCATION SERVICE: Setting AppState.originalCurrentLocation.value to: $matchedCity ===');
        AppState.originalCurrentLocation.value = matchedCity;
        print('=== LOCATION SERVICE: Set original current location to: $matchedCity ===');
      } else if (cityFromGeocoding != null && cityFromGeocoding.isNotEmpty) {
        print('=== LOCATION SERVICE: Setting AppState.originalCurrentLocation.value to geocoded city: $cityFromGeocoding ===');
        AppState.originalCurrentLocation.value = cityFromGeocoding;
        print('=== LOCATION SERVICE: Set original current location to geocoded city: $cityFromGeocoding ===');
      } else {
        print('=== LOCATION SERVICE: No matching city found in available cities ===');
      }
    } catch (e, stack) {
      print('=== LOCATION SERVICE: Error matching city: $e ===');
      print('=== LOCATION SERVICE: Stack trace: $stack ===');
    }
  }
}
