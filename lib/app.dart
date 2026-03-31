import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'helpers/app_colors.dart';
import 'helpers/app_state.dart';
import 'presentation/shared/widgets/loader.widget.dart';
import 'presentation/splash/splash.screen.dart';

class PamScannerApp extends StatelessWidget {
  const PamScannerApp({super.key});

  static const _border = OutlineInputBorder(
    borderRadius: BorderRadius.all(Radius.circular(12)),
    borderSide: BorderSide(color: AppColors.lightGrey),
  );

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      theme: ThemeData(
        fontFamily: 'Inter',
        scaffoldBackgroundColor: AppColors.scaffold,
        cardTheme: const CardThemeData(color: AppColors.white),
        dialogTheme: const DialogThemeData(
          backgroundColor: AppColors.white,
          shape: ContinuousRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(22)),
          ),
        ),
        bottomSheetTheme: const BottomSheetThemeData(
          backgroundColor: AppColors.white,
          showDragHandle: true,
          constraints: BoxConstraints(minWidth: double.infinity),
          shape: ContinuousRectangleBorder(
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(42),
              topRight: Radius.circular(42),
            ),
          ),
        ),
        appBarTheme: const AppBarTheme(
          elevation: 0,
          toolbarHeight: 80,
          centerTitle: false,
          foregroundColor: AppColors.white,
          backgroundColor: AppColors.primary,
        ),
        inputDecorationTheme: const InputDecorationTheme(
          filled: true,
          fillColor: AppColors.white,
          border: _border,
          enabledBorder: _border,
          errorBorder: _border,
          focusedBorder: _border,
          focusedErrorBorder: _border,
          disabledBorder: _border,
        ),
      ),
      home: const SplashScreen(),
      navigatorKey: AppState.navKey,
      builder: (context, child) {
        return Stack(
          fit: StackFit.expand,
          children: [child!, const LoaderWidget()],
        );
      },
    );
  }
}
