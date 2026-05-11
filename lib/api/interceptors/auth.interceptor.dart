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
    if (err.response?.statusCode == 401) {
      final expiredMsg = 'Session expired. Please log in again.';
      ToastService.show(
        expiredMsg,
        backgroundColor: AppColors.orange,
        long: true,
      );
      await AppState.logOut();
      AppState.hideLoader();
      handler.next(err);
    } else {
      handler.next(err);
    }
  }
}
