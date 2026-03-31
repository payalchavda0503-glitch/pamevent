import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:get/get.dart';

import '../helpers/app_colors.dart';
import 'background.service.dart';

class ToastService {
  // static ToastificationItem? _item;

  static void show(
      String msg, {
        bool long = false,
        Color? backgroundColor,
        Color? foregroundColor,
      }) async {
    if (!BackgroundService.isInForeground) return;

    Get.closeAllSnackbars();

    late final SnackbarController ctrl;
    ctrl = Get.snackbarFlutter(
      msg, // message
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: backgroundColor ?? AppColors.primary,
      colorText: AppColors.white,
      borderRadius: 12,
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      duration: Duration(seconds: long ? 10 : 2),
      isDismissible: true,
      forwardAnimationCurve: Curves.easeOutBack,
      mainButton: IconButton(
        icon: Icon(Icons.close, color: AppColors.white,size: 18,),
        onPressed: () {
          ctrl.close();
        },
      ),
    );
  }

  static void comingSoon() => show('Coming soon');
}
extension ExtensionSnackbar on GetInterface {
  SnackbarController snackbarFlutter(
      String message, {
        Color? colorText,
        Duration? duration = const Duration(seconds: 3),
        bool instantInit = true,
        SnackPosition? snackPosition,
        Widget? messageText,
        Widget? icon,
        bool? shouldIconPulse,
        double? maxWidth,
        EdgeInsets? margin,
        EdgeInsets? padding,
        double? borderRadius,
        Color? borderColor,
        double? borderWidth,
        Color? backgroundColor,
        Color? leftBarIndicatorColor,
        List<BoxShadow>? boxShadows,
        Gradient? backgroundGradient,
        IconButton? mainButton,
        OnTap? onTap,
        bool? isDismissible,
        bool? showProgressIndicator,
        DismissDirection? dismissDirection,
        AnimationController? progressIndicatorController,
        Color? progressIndicatorBackgroundColor,
        Animation<Color>? progressIndicatorValueColor,
        SnackStyle? snackStyle,
        Curve? forwardAnimationCurve,
        Curve? reverseAnimationCurve,
        Duration? animationDuration,
        double? barBlur,
        double? overlayBlur,
        SnackbarStatusCallback? snackbarStatus,
        Color? overlayColor,
        Form? userInputForm,
      }) {
    final getSnackBar = GetSnackBar(
      snackbarStatus: snackbarStatus,
      messageText: messageText ?? Text(message, textAlign: TextAlign.center,style: TextStyle(color: AppColors.white),),
      snackPosition: snackPosition ?? SnackPosition.TOP,
      borderRadius: borderRadius ?? 15,
      margin: margin ?? const EdgeInsets.symmetric(horizontal: 10,vertical: 20),
      duration: duration,
      barBlur: barBlur ?? 7.0,
      backgroundColor: backgroundColor ?? Colors.grey.withValues(alpha: 0.2),
      icon: icon,
      shouldIconPulse: shouldIconPulse ?? true,
      maxWidth: maxWidth,
      padding: padding ?? const EdgeInsets.all(16),
      borderColor: borderColor,
      borderWidth: borderWidth,
      leftBarIndicatorColor: leftBarIndicatorColor,
      boxShadows: boxShadows,
      backgroundGradient: backgroundGradient,
      mainButton: mainButton,
      onTap: onTap,
      isDismissible: isDismissible ?? true,
      dismissDirection: dismissDirection,
      showProgressIndicator: showProgressIndicator ?? false,
      progressIndicatorController: progressIndicatorController,
      progressIndicatorBackgroundColor: progressIndicatorBackgroundColor,
      progressIndicatorValueColor: progressIndicatorValueColor,
      snackStyle: snackStyle ?? SnackStyle.FLOATING,
      forwardAnimationCurve: forwardAnimationCurve ?? Curves.easeOutCirc,
      reverseAnimationCurve: reverseAnimationCurve ?? Curves.easeOutCirc,
      animationDuration: animationDuration ?? const Duration(seconds: 1),
      overlayBlur: overlayBlur ?? 0.0,
      overlayColor: overlayColor ?? Colors.transparent,
      userInputForm: userInputForm,
    );

    final controller = SnackbarController(getSnackBar);

    if (instantInit) {
      controller.show();
    } else {
      //routing.isSnackbar = true;
      ambiguate(SchedulerBinding.instance)?.addPostFrameCallback((_) {
        controller.show();
      });
    }
    return controller;
  }
}
