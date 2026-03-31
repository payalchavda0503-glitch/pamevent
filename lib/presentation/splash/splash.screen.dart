import 'package:flutter/material.dart';

import '../../api/api.client.dart';
import '../../helpers/app_colors.dart';
import '../../helpers/app_state.dart';
import '../../helpers/extensions/context.extension.dart';
import '../../helpers/utils.dart';
import '../../helpers/version.dart';
import '../auth/login.screen.dart';
import '../main_layout.dart';
import '../shared/widgets/custom_image.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    asap(() async {
      await AppVersion.setVersion();
      ApiClient.setVersionHeader(AppVersion.buildNumber);
      await fetchSettings();
      await Future.delayed(const Duration(seconds: 2));
      final dest = AppState.loggedIn ? const MainLayout() : const LoginScreen();
      if (mounted) context.replace(dest);
    });
  }

  Future<void> fetchSettings() async {
    final res = await ApiClient.settings();
    if (!mounted || res == null) return;
    setState(() => AppState.settings = res);
  }

  @override
  Widget build(BuildContext context) {
    final logo = AppState.logoSplash;
    final bg = AppState.splashBg;
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          if (bg?.isNotEmpty ?? false) CustomImage(bg!, fit: BoxFit.cover),
          DecoratedBox(
            decoration: BoxDecoration(
              color: AppColors.splash.withValues(alpha: 0.8),
            ),
          ),
          if (logo?.isNotEmpty ?? false)
            SafeArea(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(26),
                  child: CustomImage.svg(
                    logo!,
                    fit: BoxFit.contain,
                    width: 320,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
