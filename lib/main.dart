import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:toastification/toastification.dart';

import 'app.dart';
import 'helpers/app_state.dart';
import 'services/connectivity_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  await AppState.init();
  Get.put(ConnectivityController());
  runApp(
    ToastificationWrapper(
      config: ToastificationConfig(
        applyMediaQueryViewInsets: true,
        alignment: Alignment.bottomCenter,
        animationDuration: const Duration(milliseconds: 300),
      ),
      child: const PamScannerApp(),
    ),
  );
}
