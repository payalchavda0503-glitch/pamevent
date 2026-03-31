import 'dart:developer' as dev show log;

import 'package:dio/dio.dart';
import 'package:dio/io.dart' show DioForNative;
import 'package:flutter/foundation.dart' show defaultTargetPlatform, kDebugMode;

import '../helpers/extensions/string.extension.dart';
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
  static void handleToastMessage(Object? key) {
    if (key is String) {
      if (key.trim().isNotEmpty) ToastService.show(key);
    } else if (key is Map) {
      final errors = key.values.firstOrNull;
      if (errors is List && errors.isNotEmpty) {
        ToastService.show(errors.first);
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

  static Future<Profile?> login(String username, String password) async {
    try {
      final response = await _dio.postUri(
        ApiConfig.login,
        options: Options(headers: {cacheResponse: false}),
        data: FormData.fromMap({'username': username, 'password': password}),
      );
      if (response.data['status'] == 100) {
        return Profile.fromJson(response.data['data']);
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

  static Future<bool> register({
    required String name,
    required String username,
    required String email,
    required String password,
  }) async {
    try {
      final response = await _dio.postUri(
        ApiConfig.register,
        options: Options(headers: {cacheResponse: false}),
        data: FormData.fromMap({
          'name': name.trim(),
          'username': username.trim(),
          'email': email.trim(),
          'password': password,
        }),
      );
      handleToastMessage(response.data['message']);
      return response.data['status'] == 100;
    } catch (exception) {
      if (kDebugMode) rethrow;
      dev.log('Error in signUp ======> $exception');
    }
    return false;
  }

  static Future<String?> forgotPassword(String email) async {
    try {
      final response = await _dio.postUri(
        ApiConfig.forgotPassword,
        options: Options(headers: {cacheResponse: false}),
        data: FormData.fromMap({'email': email}),
      );
      if (response.data['status'] == 100) {
        handleToastMessage(response.data['message']);
        return response.data['data']['remember_code'];
      } else if (response.data['status'] == 101) {
        handleToastMessage(response.data['message']);
      }
    } catch (exception) {
      if (kDebugMode) rethrow;
      dev.log('Error in forgotPassword ======> $exception');
    }
    return null;
  }

  static Future<bool> resetPassword(String email, String password) async {
    try {
      final response = await _dio.postUri(
        ApiConfig.resetPassword,
        options: Options(headers: {cacheResponse: false}),
        data: FormData.fromMap({'email': email, 'password': password}),
      );
      handleToastMessage(response.data['message']);
      return response.data['status'] == 100;
    } catch (exception) {
      if (kDebugMode) rethrow;
      dev.log('Error in resetPassword ======> $exception');
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
}
