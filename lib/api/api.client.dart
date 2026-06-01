import 'dart:developer' as dev show log;
import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:dio/io.dart' show DioForNative;
import 'package:flutter/foundation.dart' show defaultTargetPlatform, kDebugMode, debugPrint;

import '../helpers/extensions/string.extension.dart';
import '../helpers/app_state.dart';
import '../services/toast.service.dart';
import './interceptors/auth.interceptor.dart';
import './interceptors/logging.interceptor.dart';
import './models/auth/profile.dart';
import './models/event/event.dart';
import 'api.config.dart';
import 'interceptors/cache.interceptor.dart';
import 'models/booking/booking.dart';

export 'package:dio/dio.dart';

class ApiClient {
  ApiClient._();

  /// Dio instance
  static late Dio _dio;

  static Dio get instance => _dio;

  static const noLog = 'no-logs';
  static const cacheResponse = 'do-cache';
  static const enableLogging = kDebugMode;

  static void init() {
    _dio = DioForNative(
      BaseOptions(
        validateStatus: (status) => status != null && status != 401,
        connectTimeout: Duration(seconds: 8),
        sendTimeout: Duration(seconds: 7),
        receiveTimeout: Duration(seconds: 20),
        headers: {
          'Content-Type': 'application/json',
          'app_platform': defaultTargetPlatform.name,
          cacheResponse: true,
        },
      ),
    );
    _dio.interceptors.addAll([
      if (enableLogging) LoggingInterceptor(),
      AuthInterceptor(),
      CacheInterceptor(),
    ]);
  }

  static void removeAuthHeader() {
    _dio.options.headers.remove('Authorization');
  }

  static void setAuthHeader(String value) {
    _dio.options.headers['Authorization'] = value;
  }

  static void setVersionHeader(int value) {
    _dio.options.headers['app_build_number'] = value;
  }

  // region Handle Error Response
  static bool _isResponseSafe(Response response) {
    if (response.data is! Map) {
      debugPrint('API Error: Response data is not a Map. Actual type: ${response.data.runtimeType}');
      debugPrint('Raw Response Data: ${response.data}');
      return false;
    }
    return true;
  }

  static void handleToastMessage(Object? key) {
    if (key is String) {
      if (key.toLowerCase().contains('unauthenticated') || key.toLowerCase().contains('invalid token') || key.toLowerCase().contains('token expired')) {
         ToastService.show('Session expired. Please log in again.');
         AppState.logOut();
         return;
      }
      if (key.trim().isNotEmpty) ToastService.show(key);
    } else if (key is Map) {
      final errors = key.values.firstOrNull;
      if (errors is List && errors.isNotEmpty) {
        final msg = errors.first.toString();
        if (msg.toLowerCase().contains('unauthenticated') || msg.toLowerCase().contains('invalid token') || msg.toLowerCase().contains('token expired')) {
           ToastService.show('Session expired. Please log in again.');
           AppState.logOut();
           return;
        }
        ToastService.show(msg);
      }
    }
  }

  static String getErrorMessage(Object? key) {
    if (key is String) {
      if (key.trim().isNotEmpty) return key;
    } else if (key is Map) {
      final errors = key.values.firstOrNull;
      if (errors is List && errors.firstOrNull is String) {
        return errors.first;
      }
    }
    return 'Something went wrong!';
  }
  // endregion

  static Future<Map<String, dynamic>?> settings() async {
    try {
      final response = await _dio.getUri(ApiConfig.init);
      if (!_isResponseSafe(response)) return null;
      if (response.data['status'] == 100) {
        return response.data['data'];
      } else if (response.data['status'] == 101) {
        handleToastMessage(response.data['message']);
      }
    } catch (exception) {
      if (kDebugMode) rethrow;
      dev.log('Error in settings ======> $exception');
    }
    return null;
  }

  static Future<Map<String, dynamic>?> home({String? filterVenue}) async {
    try {
      Uri uri = ApiConfig.home;
      if (filterVenue != null && filterVenue.isNotEmpty) {
        uri = uri.replace(queryParameters: {
          ...uri.queryParameters,
          'filter_venue': filterVenue,
        });
      }
      
      final response = await _dio.getUri(uri);
      
      if (!_isResponseSafe(response)) return null;
      if (response.data['status'] == 100) {
        return response.data['data'];
      } else if (response.data['status'] == 101) {
        handleToastMessage(response.data['message']);
      }
    } catch (exception) {
      if (kDebugMode) rethrow;
      dev.log('Error in home ======> $exception');
    }
    return null;
  }

  static Future<List<dynamic>?> getCategories() async {
    try {
      final response = await _dio.getUri(ApiConfig.categories);
      if (!_isResponseSafe(response)) return null;
      if (response.data['status'] == 100) {
        return response.data['data'] ?? [];
      } else if (response.data['status'] == 101) {
        handleToastMessage(response.data['message']);
      }
    } catch (exception) {
      if (kDebugMode) rethrow;
      dev.log('Error in getCategories ======> $exception');
    }
    return null;
  }

  static Future<Map<String, dynamic>?> getProfile() async {
    try {
      final response = await _dio.getUri(ApiConfig.profile);
      if (!_isResponseSafe(response)) return null;
      if (response.data['status'] == 100) {
        return response.data['data'];
      } else if (response.data['status'] == 101) {
        handleToastMessage(response.data['message']);
      }
    } catch (exception) {
      if (kDebugMode) rethrow;
      dev.log('Error in getProfile ======> $exception');
    }
    return null;
  }

  static Future<Map<String, dynamic>?> getCustomerEvents({
    int page = 1,
    String? category,
    String? eventType,
    String? searchInput,
    String? dates,
    String? minPrice,
    String? maxPrice,
    String? filterVenue,
  }) async {
    try {
      final Map<String, dynamic> formDataMap = {'page': page};
      if (category != null && category.isNotEmpty && category.toLowerCase() != 'all') {
        formDataMap['category'] = category.toLowerCase();
      }
      if (eventType != null && eventType.isNotEmpty) {
        formDataMap['event'] = eventType.toLowerCase();
      }
      if (searchInput != null && searchInput.isNotEmpty) {
        formDataMap['search-input'] = searchInput;
      }
      if (dates != null && dates.isNotEmpty) {
        formDataMap['dates'] = dates;
      }
      if (minPrice != null && minPrice.isNotEmpty) {
        formDataMap['min'] = minPrice;
      }
      if (maxPrice != null && maxPrice.isNotEmpty) {
        formDataMap['max'] = maxPrice;
      }
      if (filterVenue != null && filterVenue.isNotEmpty) {
        formDataMap['filter_venue'] = filterVenue;
      }

      final response = await _dio.postUri(
        ApiConfig.customerEvents,
        data: FormData.fromMap(formDataMap),
      );

      if (!_isResponseSafe(response)) return null;

      if (response.data['status'] == 100) {
        return response.data['data'];
      } else if (response.data['status'] == 101) {
        handleToastMessage(response.data['message']);
      }
    } catch (exception) {
      if (kDebugMode) rethrow;
      dev.log('Error in getCustomerEvents ======> $exception');
    }
    return null;
  }

  static Future<Map<String, dynamic>?> getCustomerEventDetail(int eventId) async {
    debugPrint('API CALL: getCustomerEventDetail with event_id: $eventId');
    try {
      final response = await _dio.postUri(
        ApiConfig.customerEventDetail,
        data: FormData.fromMap({'event_id': eventId}),
      );
      
      if (!_isResponseSafe(response)) return null;

      // Robust check: if response already has data we need
      if (response.data is Map && (response.data.containsKey('title') || response.data.containsKey('event_name'))) {
        return response.data;
      }

      if (response.data['status'] == 100) {
        return response.data['data'];
      } else if (response.data['status'] == 101) {
        handleToastMessage(response.data['message']);
      }
    } catch (exception) {
      dev.log('Error in getCustomerEventDetail ======> $exception');
    }
    return null;
  }

  static Future<dynamic> getCustomerEventTicketDetails(int eventId) async {
    try {
      final response = await _dio.postUri(
        ApiConfig.customerEventTicketDetails,
        data: FormData.fromMap({'event_id': eventId}),
      );
      
      if (!_isResponseSafe(response)) return null;

      if (response.data['status'] == 100) {
        return response.data['data'];
      } else if (response.data['status'] == 101) {
        handleToastMessage(response.data['message']);
      }
    } catch (exception) {
      if (kDebugMode) rethrow;
      dev.log('Error in getCustomerEventTicketDetails ======> $exception');
    }
    return null;
  }

  static Future<List<dynamic>?> getArtists(String artistIds) async {
    try {
      final response = await _dio.getUri(
        ApiConfig.artists.replace(queryParameters: {'artist': artistIds}),
      );
      if (!_isResponseSafe(response)) return null;
      print('Artists API Response: ${response.data}');
      if (response.data['status'] == 100) {
        final data = response.data['data'];
        if (data is List) {
          return data;
        } else if (data is Map && data['artists'] is List) {
          return data['artists'];
        } else if (data is Map) {
          // If it's a map but no 'artists' key, maybe it's just one artist or something else
          // Return as a list with one item or an empty list to avoid crash
          return [data];
        }
      } else if (response.data['status'] == 101) {
        handleToastMessage(response.data['message']);
      }
    } catch (exception) {
      if (kDebugMode) rethrow;
      dev.log('Error in getArtists ======> $exception');
    }
    return null;
  }

  static Future<dynamic> getAllArtists({int page = 1, int perPage = 20, String? search}) async {
    try {
      final queryParams = {
        'page': page.toString(),
        'per_page': perPage.toString(),
      };
      if (search != null && search.isNotEmpty) {
        queryParams['search'] = search;
      }
      final response = await _dio.getUri(
        ApiConfig.artists.replace(queryParameters: queryParams),
      );
      if (!_isResponseSafe(response)) return null;
      if (response.data['status'] == 100) {
        return response.data['data'];
      } else if (response.data['status'] == 101) {
        handleToastMessage(response.data['message']);
      }
    } catch (exception) {
      if (kDebugMode) rethrow;
      dev.log('Error in getAllArtists ======> $exception');
    }
    return null;
  }

  static Future<Map<String, dynamic>?> getCustomerArtistDetail(String slug) async {
    try {
      final url = ApiConfig.getArtistDetail(slug);
      debugPrint('Fetching Artist Detail from URL: $url');
      final response = await _dio.getUri(url);
      if (response.data['status'] == 100) {
        return response.data['data'];
      } else if (response.data['status'] == 101) {
        handleToastMessage(response.data['message']);
      }
    } catch (exception) {
      if (kDebugMode) rethrow;
      dev.log('Error in getCustomerArtistDetail ======> $exception');
    }
    return null;
  }

  static Future<Map<String, dynamic>?> getVenueDetail(String slug) async {
    try {
      debugPrint('Fetching Venue Detail with slug: $slug');
      debugPrint('Venue Detail API URL: ${ApiConfig.venueDetail}');
      final response = await _dio.postUri(
        ApiConfig.venueDetail,
        data: FormData.fromMap({'slug': slug}),
      );
      debugPrint('Venue Detail API Full Response: ${response.data}');
      
      // If the API returns the data directly without status/data wrapper
      if (response.data is Map && response.data.containsKey('venue')) {
        return response.data;
      }
      
      if (response.data['status'] == 100) {
        return response.data['data'];
      } else if (response.data['status'] == 101) {
        handleToastMessage(response.data['message']);
      }
    } catch (exception) {
      if (kDebugMode) rethrow;
      dev.log('Error in getVenueDetail ======> $exception');
    }
    return null;
  }

  static Future<Map<String, dynamic>?> getVenues({String? search, int page = 1, int perPage = 20}) async {
    try {
      final queryParams = <String, String>{
        'page': page.toString(),
        'per_page': perPage.toString(),
      };
      if (search != null && search.isNotEmpty) {
        queryParams['search'] = search;
      }
      final response = await _dio.getUri(
        ApiConfig.venues.replace(queryParameters: queryParams),
      );
      if (!_isResponseSafe(response)) return null;
      if (response.data['status'] == 100) {
        return response.data;
      } else if (response.data['status'] == 101) {
        handleToastMessage(response.data['message']);
      }
    } catch (exception) {
      if (kDebugMode) rethrow;
      dev.log('Error in getVenues ======> $exception');
    }
    return null;
  }

  static Future<Map<String, dynamic>?> customerSearch(String query, {String? filterVenue}) async {
    try {
      Uri uri = ApiConfig.customerSearch(query);
      if (filterVenue != null && filterVenue.isNotEmpty) {
        uri = uri.replace(queryParameters: {
          ...uri.queryParameters,
          'filter_venue': filterVenue,
        });
      }
      final response = await _dio.getUri(uri);
      if (response.data['status'] == 100) {
        return response.data['data'];
      } else if (response.data['status'] == 101) {
        handleToastMessage(response.data['message']);
      }
    } catch (exception) {
      if (kDebugMode) rethrow;
      dev.log('Error in customerSearch ======> $exception');
    }
    return null;
  }

  static Future<dynamic> getEventLocations() async {
    try {
      final response = await _dio.getUri(ApiConfig.getEventLocations);
      print('=== API CLIENT: LOCATIONS RESPONSE ===');
      print('Full response data: ${response.data}');
      print('Response data type: ${response.data.runtimeType}');
      
      if (!_isResponseSafe(response)) {
        return null;
      }
      
      if (response.data['status'] == 100) {
        print('Returning data: ${response.data['data']}');
        print('Returning data type: ${response.data['data'].runtimeType}');
        return response.data['data'];
      } else if (response.data['status'] == 101) {
        handleToastMessage(response.data['message']);
      }
    } catch (exception) {
      dev.log('Error in getEventLocations ======> $exception');
    }
    return null;
  }

  static Future<Map<String, dynamic>?> login({
    required String username,
    required String password,
  }) async {
    try {
      final response = await _dio.postUri(
        ApiConfig.login,
        data: FormData.fromMap({
          'username': username,
          'password': password,
        }),
      );
      if (response.data['status'] == 100) {
        return response.data;
      } else {
        handleToastMessage(response.data['message'] ?? 'Login failed');
      }
    } catch (exception) {
      if (kDebugMode) rethrow;
      dev.log('Error in login ======> $exception');
    }
    return null;
  }

  static Future<Map<String, dynamic>?> loginQr(String code) async {
    try {
      final response = await _dio.postUri(
        ApiConfig.loginQr,
        options: Options(headers: {cacheResponse: false}),
        data: FormData.fromMap({'qr_code': code}),
      );

      if (response.data['status'] == 100) {
        final profile = Profile.fromJson(response.data['data']);
        return {'profile': profile, 'raw': response.data['data']};
      } else if (response.data['status'] == 101) {
        handleToastMessage(response.data['message']);
        return null;
      }
    } catch (exception) {
      if (kDebugMode) rethrow;
      dev.log('Error in login ======> $exception');
    }
    return null;
  }

  static Future<bool> updateGuestUser(String name, String email) async {
    try {
      final response = await _dio.postUri(
        ApiConfig.updateGuestUser,
        options: Options(headers: {cacheResponse: false}),
        data: FormData.fromMap({'name': name, 'email': email}),
      );
      if (response.data['status'] == 100) {
        return true;
      } else if (response.data['status'] == 101) {
        handleToastMessage(response.data['message']);
        return false;
      }
    } catch (exception) {
      if (kDebugMode) rethrow;
      dev.log('Error in login ======> $exception');
    }
    return false;
  }

  static Future<Profile?> socialLogin({
    String? firstName,
    String? lastName,
    required String email,
    required String provider,
    required String providerId,
  }) async {
    try {
      final response = await _dio.postUri(
        ApiConfig.socialLogin,
        options: Options(headers: {cacheResponse: false}),
        data: {
          'provider': provider,
          'provider_id': providerId,
          'email': email.trim(),
          if (firstName.isNotEmpty) 'first_name': firstName!.trim(),
          if (lastName.isNotEmpty) 'last_name': lastName!.trim(),
        },
      );
      if (response.data['status'] == 100) {
        return Profile.fromJson(response.data['data']);
      } else if (response.data['status'] == 101) {
        handleToastMessage(response.data['message']);
        return null;
      }
    } catch (exception) {
      if (kDebugMode) rethrow;
      dev.log('Error in socialLogin ======> $exception');
    }
    return null;
  }

  static Future<Map<String, dynamic>?> register({
    required String name,
    required String username,
    required String email,
    required String phone,
    required String password,
  }) async {
    try {
      final response = await _dio.postUri(
        ApiConfig.register,
        data: FormData.fromMap({
          'name': name,
          'username': username,
          'email': email,
          'phone': phone,
          'password': password,
        }),
      );
      if (response.data['status'] == 100) {
        return response.data;
      } else {
        handleToastMessage(response.data['message'] ?? 'Registration failed');
      }
    } catch (exception) {
      if (kDebugMode) rethrow;
      dev.log('Error in register ======> $exception');
    }
    return null;
  }

  static Future<bool> forgotPassword(String email) async {
    try {
      final response = await _dio.postUri(
        ApiConfig.forgotPassword,
        data: FormData.fromMap({'email': email}),
      );
      if (response.data['status'] == 100) {
        handleToastMessage(response.data['message'] ?? 'Verification code sent');
        return true;
      } else {
        handleToastMessage(response.data['message'] ?? 'Error sending code');
      }
    } catch (exception) {
      if (kDebugMode) rethrow;
      dev.log('Error in forgotPassword ======> $exception');
    }
    return false;
  }

  static Future<bool> resetPassword({
    required String email,
    required String code,
    required String password,
  }) async {
    try {
      final response = await _dio.postUri(
        ApiConfig.resetPassword,
        data: FormData.fromMap({
          'email': email,
          'code': code,
          'password': password,
        }),
      );
      if (response.data['status'] == 100) {
        handleToastMessage(response.data['message'] ?? 'Password reset successful');
        return true;
      } else {
        handleToastMessage(response.data['message'] ?? 'Error resetting password');
      }
    } catch (exception) {
      if (kDebugMode) rethrow;
      dev.log('Error in resetPassword ======> $exception');
    }
    return false;
  }

  static Future<Map<String, dynamic>?> fetchProfile() async {
    try {
      final response = await _dio.getUri(ApiConfig.profile);
      if (response.data['status'] == 100) {
        return response.data['data'];
      }
    } catch (exception) {
      dev.log('Error in fetchProfile ======> $exception');
    }
    return null;
  }

  static Future<bool> updateProfile({
    required String name,
    required String email,
    required String username,
    required String phone,
    String? photoPath,
    String? country,
    String? state,
    String? city,
    String? zipCode,
    String? address,
  }) async {
    try {
      final Map<String, dynamic> formDataMap = {
        'name': name,
        'email': email,
        'username': username,
        'phone': phone,
      };

      if (photoPath != null && photoPath.isNotEmpty) {
        formDataMap['photo'] = await MultipartFile.fromFile(photoPath);
      }
      if (country != null) formDataMap['country'] = country;
      if (state != null) formDataMap['state'] = state;
      if (city != null) formDataMap['city'] = city;
      if (zipCode != null) formDataMap['zip_code'] = zipCode;
      if (address != null) formDataMap['address'] = address;

      final response = await _dio.postUri(
        ApiConfig.editProfile,
        data: FormData.fromMap(formDataMap),
      );

      if (response.data['status'] == 100) {
        handleToastMessage(response.data['message'] ?? 'Profile updated successfully');
        return true;
      } else {
        handleToastMessage(response.data['message'] ?? 'Error updating profile');
      }
    } catch (exception) {
      if (kDebugMode) rethrow;
      dev.log('Error in updateProfile ======> $exception');
    }
    return false;
  }

  static Future<bool> logout() async {
    try {
      final response = await _dio.postUri(
        ApiConfig.logout,
      );
      return response.data['status'] == 100;
    } catch (exception) {
      dev.log('Error in logout API ======> $exception');
    }
    return false;
  }

  static Future<bool> changePassword({
    required String oldPassword,
    required String newPassword,
  }) async {
    try {
      final response = await _dio.postUri(
        ApiConfig.changePassword,
        data: FormData.fromMap({
          'old_password': oldPassword,
          'new_password': newPassword,
        }),
      );
      if (response.data['status'] == 100) {
        handleToastMessage(response.data['message'] ?? 'Password changed successfully');
        return true;
      } else {
        handleToastMessage(response.data['message'] ?? 'Error changing password');
      }
    } catch (exception) {
      if (kDebugMode) rethrow;
      dev.log('Error in changePassword ======> $exception');
    }
    return false;
  }

  static Future<(String?, List<Event>?)> events() async {
    try {

      final response = await _dio.postUri(ApiConfig.events);

      if (response.data['status'] == 100) {

        final tempList = <Event>[];
        for (final raw in response.data['data'] as List) {
          try {
            tempList.add(Event.fromJson(raw));
          } catch (e) {
            dev.log('Error while parsing Event >> $e');
          }
        }
        return (null, tempList);
      } else if (response.data['status'] == 101) {
        final msg = getErrorMessage(response.data['message']);
        if (msg.isNotEmpty) return (msg, null);
      }
    } catch (exception) {

      if (kDebugMode) rethrow;

      dev.log('Error in events ======> $exception');
    }

    return ('Something went wrong!', null);
  }

  static Future<Event?> event({
    required int eventId,
    required int page,
    required int limit,
    String? lastSyncDate,
  })  async {
    try {
      final response = await _dio.postUri(
        ApiConfig.event,
        data: FormData.fromMap({
          'event_id': eventId,
          'limit': limit,
          'page': page,
          'last_sync_date': lastSyncDate,
        }),
      );
      if (response.data['status'] == 100) {
        return Event.fromJson(response.data['data']);
      } else if (response.data['status'] == 101) {
        handleToastMessage(response.data['message']);
      }
    } catch (exception) {
      if (kDebugMode) rethrow;
      dev.log('Error in event ======> $exception');
    }
    return null;
  }

  static Future<BookingPageResult> bookings({
    required int id,
    required int page,
     String? search,
  }) async {
    try {
      final response = await _dio.postUri(
        ApiConfig.bookings,
        data: FormData.fromMap({'event_id': id, 'page': page,'query':search??''}),
      );
      if (response.data['status'] == 100) {
        final tempList = <Booking>[];
        for (final raw in response.data['data']) {
          try {
            tempList.add(Booking.fromJson(raw));
          } catch (e) {
            dev.log('Error while parsing Booking >> $e');
          }
        }
        final hasMore = response.data['pagination']?['has_more'] ?? false;
        return BookingPageResult(bookings: tempList, hasMore: hasMore);
      } else if (response.data['status'] == 101) {
        handleToastMessage(response.data['message']);
      }
    } catch (exception) {
      if (kDebugMode) rethrow;
      dev.log('Error in bookings ======> $exception');
    }

    return BookingPageResult(bookings: [], hasMore: false);
  }


  static Future<Booking?> booking(String id) async {
    try {
      final response = await _dio.postUri(
        ApiConfig.booking,
        data: FormData.fromMap({'booking_id': id}),
      );
      if (response.data['status'] == 100) {
        return Booking.fromJson(response.data['data']);
      } else if (response.data['status'] == 101) {
        handleToastMessage(response.data['message']);
      }
    } catch (exception) {
      if (kDebugMode) rethrow;
      dev.log('Error in booking ======> $exception');
    }
    return null;
  }

  static Future getReport({
    required Uri url,
    required Map<String, String> body,
  }) async {
    try {
      final response = await _dio.postUri(url, data: FormData.fromMap(body));
      if (response.data['status'] == 100) {
        return response.data;
      } else if (response.data['status'] == 101) {
        handleToastMessage(response.data['message']);
      }
    } catch (exception) {
      if (kDebugMode) rethrow;
      dev.log('Error in report ======> $exception');
    }
    return null;
  }


  static Future getPhysicalTicketDataApi({
    required Uri url,
    required Map<String, String> body,
  }) async {
    try {
      final response = await _dio.postUri(url, data: FormData.fromMap(body));
      if (response.data['status'] == 100) {
        dev.log('Physical Ticket Data Response: ${response.data}');
        return response.data;
      } else if (response.data['status'] == 101) {
        handleToastMessage(response.data['message']);
      }
    } catch (exception) {
      if (kDebugMode) rethrow;
      dev.log('Error in report ======> $exception');
    }
    return null;
  }


  static Future<bool> syncTickets(
    int eventId,
    List<String> ticketCodes,
    List<String> barcodeCodes,
  ) async {
    try {
      final response = await _dio.postUri(
        ApiConfig.syncTickets,
        options: Options(headers: {cacheResponse: false}),
        data: FormData.fromMap({
          'event_id': eventId,
          'scan_codes[]': ticketCodes,
          'scan_barcodes[]': barcodeCodes,
        }),
      );

      final synced = response.data['status'] == 100;
      if (!synced) handleToastMessage(response.data['message']);
      return synced;
    } catch (exception) {
      if (kDebugMode) rethrow;
      dev.log('Error in syncTickets ======> $exception');
    }
    return false;
  }

  static Future<Map<String, dynamic>?> customerAddToCart(int eventId, {String? ticketId, String? qty, String? price, String? name}) async {
    try {
      final response = await _dio.postUri(
        ApiConfig.addToCart,
        data: FormData.fromMap({
          'event_id': eventId.toString(),
          if (ticketId != null) 'ticket_id': ticketId,
          if (qty != null) 'qty': qty,
          if (price != null) 'price': price,
          if (name != null) 'ticket_name': name,
          if (name != null) 'name': name,
        }),
      );
      if (!_isResponseSafe(response)) return null;
      if (response.data['status'] == 100) return response.data;
      handleToastMessage(response.data['message']);
    } catch (e) {
      if (kDebugMode) rethrow;
      dev.log('Error in customerAddToCart => $e');
    }
    return null;
  }

  static Future<Map<String, dynamic>?> customerApplyCoupon(Map<String, dynamic> form) async {
    try {
      final response = await _dio.postUri(
        ApiConfig.applyCoupon,
        data: _convertToFormData(form),
      );
      if (response.data['status'] == 100) return response.data;
      handleToastMessage(response.data['message']);
    } catch (e) {
      if (kDebugMode) rethrow;
      dev.log('Error in customerApplyCoupon => $e');
    }
    return null;
  }

  static Future<Map<String, dynamic>?> customerApplyReferral(Map<String, dynamic> form) async {
    try {
      final response = await _dio.postUri(
        ApiConfig.applyReferral,
        data: _convertToFormData(form),
      );
      if (response.data['status'] == 100) return response.data;
      handleToastMessage(response.data['message']);
    } catch (e) {
      if (kDebugMode) rethrow;
      dev.log('Error in customerApplyReferral => $e');
    }
    return null;
  }

  static Future<Map<String, dynamic>?> customerMyTickets() async {
    try {
      final response = await _dio.getUri(ApiConfig.customerMyTickets);
      if (response.data['status'] == 100) return response.data;
      handleToastMessage(response.data['message']);
    } catch (e) {
      if (kDebugMode) rethrow;
      dev.log('Error in customerMyTickets => $e');
    }
    return null;
  }

  static Future<Map<String, dynamic>?> customerRecentTickets({int page = 1}) async {
    try {
      final response = await _dio.getUri(
        ApiConfig.customerRecentTickets.replace(queryParameters: {'page': page.toString()}),
      );
      if (response.data['status'] == 100) return response.data;
      handleToastMessage(response.data['message']);
    } catch (e) {
      if (kDebugMode) rethrow;
      dev.log('Error in customerRecentTickets => $e');
    }
    return null;
  }

  static Future<Map<String, dynamic>?> customerPastTickets({int page = 1}) async {
    try {
      final response = await _dio.getUri(
        ApiConfig.customerPastTickets.replace(queryParameters: {'page': page.toString()}),
      );
      if (response.data['status'] == 100) return response.data;
      handleToastMessage(response.data['message']);
    } catch (e) {
      if (kDebugMode) rethrow;
      dev.log('Error in customerPastTickets => $e');
    }
    return null;
  }

  static Future<Map<String, dynamic>?> customerBookingDetails(String bookingId, {String? id}) async {
    try {
      final Map<String, dynamic> body = {
        'booking_id': bookingId,
        'order_id': bookingId,
      };

      if (id != null) {
        body['id'] = id;
      }

      final response = await _dio.postUri(
        ApiConfig.customerBookingDetails,
        data: FormData.fromMap(body),
      );
      if (!_isResponseSafe(response)) return null;
      if (response.data['status'] == 100) return response.data;
      handleToastMessage(response.data['message']);
    } catch (e) {
      if (kDebugMode) rethrow;
      dev.log('Error in customerBookingDetails => $e');
    }
    return null;
  }

  static Future<Map<String, dynamic>?> bookingComplete(String eventId, String bookingId, {String? id}) async {
    try {
      final response = await _dio.postUri(
        ApiConfig.bookingComplete,
        data: FormData.fromMap({
          'event_id': eventId,
          'booking_id': bookingId,
          if (id != null) 'id': id,
        }),
      );
      if (!_isResponseSafe(response)) return null;
      if (response.data['status'] == 100) return response.data;
      handleToastMessage(response.data['message']);
    } catch (e) {
      if (kDebugMode) rethrow;
      dev.log('Error in bookingComplete => $e');
    }
    return null;
  }

  static Future<Map<String, dynamic>?> customerGetPaymentGateways() async {
    try {
      final response = await _dio.getUri(ApiConfig.paymentGateway);
      if (response.data['status'] == 100) return response.data;
      handleToastMessage(response.data['message']);
    } catch (e) {
      if (kDebugMode) rethrow;
      dev.log('Error in getPaymentGateways => $e');
    }
    return null;
  }

  static FormData _convertToFormData(Map<String, dynamic> data) {
    final formData = FormData();
    
    data.forEach((key, value) {
      if (value is List) {
        for (var item in value) {
          // Add list items sequentially with [] suffix
          final String arrayKey = key.endsWith('[]') ? key : '$key[]';
          formData.fields.add(MapEntry(arrayKey, item.toString()));
        }
      } else if (value is Map) {
        // Handle nested maps (e.g., device_browser[device])
        value.forEach((nestedKey, nestedValue) {
          formData.fields.add(MapEntry('$key[$nestedKey]', nestedValue.toString()));
        });
      } else {
        // Regular fields
        formData.fields.add(MapEntry(key, value.toString()));
      }
    });

    return formData;
  }

  static Future<Map<String, dynamic>?> customerCheckout(Map<String, dynamic> body) async {
    try {
      final response = await _dio.postUri(
        ApiConfig.checkout,
        data: _convertToFormData(body),
      );
      if (response.data['status'] == 100) return response.data;
      handleToastMessage(response.data['message']);
    } catch (e) {
      if (kDebugMode) rethrow;
      dev.log('Error in customerCheckout => $e');
    }
    return null;
  }

  static Future<Map<String, dynamic>?> getMonCashPaymentUrl(Map<String, dynamic> body) async {
    try {
      final response = await _dio.postUri(
        ApiConfig.moncashPaymentUrl,
        data: _convertToFormData(body),
      );
      if (response.data['status'] == 100) return response.data;
      handleToastMessage(response.data['message']);
    } catch (e) {
      if (kDebugMode) rethrow;
      dev.log('Error in getMonCashPaymentUrl => $e');
    }
    return null;
  }

  static Future<double> getServiceFee(Map<String, dynamic> body) async {
      try {
        debugPrint('DEBUG: Calling getServiceFee with repeated keys payload: $body');
        
        final response = await _dio.postUri(
          ApiConfig.getServiceFee,
          data: _convertToFormData(body),
          options: Options(
            headers: {
              'Accept': 'application/json',
            },
          ),
        );
        
        debugPrint('DEBUG: getServiceFee Status Code: ${response.statusCode}');
        
        final dynamic responseData = response.data;
        debugPrint('DEBUG: getServiceFee Raw Response Data: $responseData');
        
        Map<String, dynamic> dataMap = {};
        if (responseData is Map) {
          dataMap = Map<String, dynamic>.from(responseData);
        } else if (responseData is String && responseData.trim().isNotEmpty) {
          try {
            dataMap = jsonDecode(responseData.trim());
          } catch (e) {
            debugPrint('DEBUG: getServiceFee Error decoding String: $e');
          }
        }

        if (dataMap.isNotEmpty) {
          if (dataMap['status']?.toString() == '100') {
            final data = dataMap['data'];
            if (data is Map) {
              final fee = double.tryParse(data['service_fee']?.toString() ?? '0') ?? 0.0;
              debugPrint('DEBUG: getServiceFee Successfully extracted fee: $fee');
              return fee;
            }
          } else {
            debugPrint('DEBUG: getServiceFee API Error Message: ${dataMap['message']}');
          }
        }
      } catch (e) {
        debugPrint('DEBUG: getServiceFee Exception => $e');
      }
      return 0.0;
    }

  static Future<String?> getBookingId() async {
    try {
      final response = await _dio.getUri(ApiConfig.getBookingId);
      if (response.data['status'] == 100) {
        return response.data['data']?['booking_id']?.toString() ?? 
               response.data['booking_id']?.toString();
      }
      handleToastMessage(response.data['message']);
    } catch (e) {
      dev.log('Error in getBookingId => $e');
    }
    return null;
  }

  static Future<Map<String, dynamic>?> createPaymentIntent({
    required dynamic amount,
    required String currency,
    required String bookingId,
    String? description,
    String? eventId,
    Map<String, dynamic>? gatewayInfo,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      // Backend expects integer, so we round the dollar amount to nearest integer (e.g. 2.89 -> 3)
      final int amountInt = amount is num ? amount.round() : int.tryParse(amount.toString().split('.').first) ?? 0;
      final String amountStr = amountInt.toString();
      
      debugPrint('DEBUG: Calling createPaymentIntent API: ${ApiConfig.createPaymentIntent}');
      debugPrint('DEBUG: Original Amount: $amount, Sending as Integer: $amountStr');
      
      final Map<String, dynamic> requestData = {
        'amount': amountStr,
        'currency': currency,
        'booking_id': bookingId,
        'description': description ?? 'Event Ticket Booking',
      };

      if (eventId != null) {
        requestData['event_id'] = eventId;
      }

      if (gatewayInfo != null) {
        gatewayInfo.forEach((key, value) {
          requestData['gateway_info[$key]'] = value.toString();
        });
      }

      if (metadata != null) {
        requestData['metadata'] = metadata;
        metadata.forEach((key, value) {
          requestData['metadata[$key]'] = value.toString();
        });
      }
print('=== createPaymentIntent API Response ===$requestData');
      final response = await _dio.postUri(
        ApiConfig.createPaymentIntent,
        data: requestData,
      );
      
      debugPrint('DEBUG: createPaymentIntent RAW API Response: ${response.data}');
      
      if (!_isResponseSafe(response)) {
        debugPrint('DEBUG: createPaymentIntent response is NOT safe');
        return null;
      }

      if (response.data['status'] == 100) {
        return response.data['data'] ?? response.data;
      } else {
        debugPrint('DEBUG: createPaymentIntent returned status: ${response.data['status']}');
        handleToastMessage(response.data['message']);
      }
    } catch (exception) {
      debugPrint('DEBUG: Exception in createPaymentIntent: $exception');
      if (kDebugMode) rethrow;
      dev.log('Error in createPaymentIntent ======> $exception');
    }
    return null;
  }

  static Future<bool> customerBookingComplete(Map<String, dynamic> body) async {
    try {
      final response = await _dio.postUri(
        ApiConfig.bookingComplete,
        options: Options(headers: {cacheResponse: false}),
        data: FormData.fromMap(body),
      );
      if (response.data['status'] == 100) return true;
      handleToastMessage(response.data['message']);
    } catch (e) {
      if (kDebugMode) rethrow;
      dev.log('Error in bookingComplete => $e');
    }
    return false;
  }
}
