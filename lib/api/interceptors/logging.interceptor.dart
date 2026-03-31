import 'dart:convert' as c;
import 'dart:developer' as dev;

import 'package:dio/dio.dart';

enum ApiLogMode { normal, indented }

final _arrow = '↓' * 14;
final _bars = '=' * 14;

class LoggingInterceptor extends Interceptor {
  LoggingInterceptor();
  static const _encoder = c.JsonEncoder();
  static const noLogsKey = 'no-logs';

  @override
  Future onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    if (options.headers[noLogsKey] == true) {
      return handler.next(options);
    }
    _printWithArrows('[${options.method}] API Request');
    _printKV('URI', options.uri);
    if (options.headers.isNotEmpty) {
      dev.log('HEADERS:');
      options.headers.forEach((key, v) => _printKV(' - $key', v));
    }
    if (options.data != null) {
      if (options.data is FormData) {
        final data = options.data as FormData;
        if (data.fields.isNotEmpty) {
          dev.log('FIELDS:');
          for (final element in data.fields) {
            _printKV(' - ${element.key}', element.value);
          }
        }
        if (data.files.isNotEmpty) {
          dev.log('FILES:');
          for (final element in (options.data as FormData).files) {
            _printKV(' - ${element.key}', element.value.filename);
          }
        }
      } else {
        _printKV('BODY', _encoder.convert(options.data));
      }
    }
    _printWithBars('[${options.method}] API Request');
    return handler.next(options);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    if (err.requestOptions.headers[noLogsKey] == true) {
      return handler.next(err);
    }
    _printWithArrows('[${err.response?.statusCode}] Api Error');
    _printKV('URI', err.requestOptions.uri);
    dev.log('$err');
    if (err.response != null) _printKV('BODY', err.response!.data);
    _printWithBars('[${err.response?.statusCode}] Api Error');
    return handler.next(err);
  }

  @override
  Future onResponse(
    Response response,
    ResponseInterceptorHandler handler,
  ) async {
    if (response.requestOptions.headers[noLogsKey] == true) {
      return handler.next(response);
    }
    _printWithArrows('[${response.statusCode}] Api Response');
    _printKV('URI', response.requestOptions.uri);
    String? res;
    try {
      if (response.requestOptions.responseType == ResponseType.bytes) {
        res = 'Byte data';
      } else {
        res = _encoder.convert(response.data);
      }
    } finally {
      _printKV('BODY', res ?? 'Invalid json');
    }
    _printWithBars('[${response.statusCode}] Api Response');
    return handler.next(response);
  }

  void _printKV(String key, Object? v) => dev.log('$key: $v');
  void _printWithArrows(String message) => dev.log('$_arrow $message $_arrow');
  void _printWithBars(String message) => dev.log('$_bars $message $_bars');
}
