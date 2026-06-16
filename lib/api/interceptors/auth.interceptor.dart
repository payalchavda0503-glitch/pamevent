import 'package:dio/dio.dart';

import '../../helpers/app_colors.dart';
import '../../helpers/app_state.dart';
import '../../services/toast.service.dart';

class AuthInterceptor extends Interceptor {
  AuthInterceptor();

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    // 401 errors are now handled by CacheInterceptor with a dialog
    handler.next(err);
  }
}
