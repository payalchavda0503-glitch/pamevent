import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';

import '../../helpers/app_colors.dart';
import '../../helpers/app_state.dart';
import '../../services/toast.service.dart';
import '../api.client.dart';

class CacheInterceptor extends Interceptor {
  CacheInterceptor();

  String getCacheKey(RequestOptions options) {
    String? keySuffix;
    final requestBody = options.data;
    if (requestBody is FormData) {
      keySuffix = jsonEncode(Map.fromEntries(requestBody.fields));
    } else if (requestBody is Map) {
      keySuffix = jsonEncode(requestBody);
    }
    return options.path + (keySuffix ?? '');
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) async {
    if (response.statusCode == 200 && response.data is Map && response.data['status'] == 100) {
      final headers = response.requestOptions.headers;
      const cacheResponse = 'do-cache';
      final cacheHeader = headers[cacheResponse];
      if (cacheHeader == true) {
        final cacheKey = getCacheKey(response.requestOptions);
        AppState.prefs.setString(cacheKey, jsonEncode(response.data));
      }
    }
    super.onResponse(response, handler);
  }

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    // Check for 401 Unauthorized errors
    if (err.response?.statusCode == 401) {
      ApiClient.handleSessionExpired();
      return; // Stop further error handling for 401
    }

    final connectionError = [
      DioExceptionType.connectionError,
      DioExceptionType.connectionTimeout,
      DioExceptionType.receiveTimeout,
      DioExceptionType.sendTimeout,
    ].contains(err.type);
    final cacheKey = getCacheKey(err.requestOptions);
    if (connectionError) {
      if (AppState.prefs.containsKey(cacheKey)) {
        handler.resolve(
          Response(
            requestOptions: err.requestOptions,
            data: jsonDecode((AppState.prefs.getString(cacheKey))!),
          ),
        );
        return;
      } else {
        AppState.hideLoader();
      }
    }
    handler.next(err);
  }
}
