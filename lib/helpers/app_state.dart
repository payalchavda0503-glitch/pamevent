import 'dart:convert';
import 'dart:developer' as dev;

import 'package:flutter/material.dart';
import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../api/api.client.dart';
import '../api/models/auth/profile.dart';
import '../enums/pref_keys.dart';
import '../presentation/splash/splash.screen.dart';
import '../services/background.service.dart';
import 'extensions/context.extension.dart';

class AppState {
  /// Context For Restarting app
  static var navKey = GlobalKey<NavigatorState>();
  static void resetNavKey() {
    navKey.currentContext?.replaceAll(SplashScreen(), rootNav: true);
  }

  static Future<void> init() async {
    prefs = await SharedPreferences.getInstance();
    fbAuth = FacebookAuth.i;
    googleSignIn = GoogleSignIn(
      scopes: [
        'openid',
        'https://www.googleapis.com/auth/userinfo.profile',
        'https://www.googleapis.com/auth/userinfo.email',
      ],
    );
    ApiClient.init();
    await getProfile();
    AppLifecycleListener(
      onPause: BackgroundService.startBackgroundTask,
      onDetach: BackgroundService.stopBackgroundTask,
      onResume: BackgroundService.stopBackgroundTask,
    );
  }

  //region Auth
  static late final FacebookAuth fbAuth;
  static late final GoogleSignIn googleSignIn;
  //endregion

  //region Prefs
  static late final SharedPreferences prefs;
  static Future<void> clearPrefs() async {
    // Clear all preferences to ensure nothing is left
    await prefs.clear();
  }
  //endregion

  //region Global Settings
  static var settings = <String, dynamic>{};
  static Map<String, dynamic>? get _images => settings['app_settings'];

  // Login Page, Register Page
  static String? get logo => _images?['logo'];
  // Top Header, QR Scanner Screen
  static String? get logoHeader => _images?['logo_header'];
  // Splash Screen
  static String? get logoSplash => _images?['logo_splashscreen'];
  // Splash Screen Background
  static String? get splashBg => _images?['bg_splashscreen'];

  static String? get helpCenterLink => settings['help_center_link'];
  static String? get privacyPolicyLink => settings['privacy_policy_link'];
  static String? get termsConditionLink => settings['terms_condition_link'];
  static String? get deleteAccountLink => settings['delete_account_link'];
  //endregion

  //region Loader
  static final isLoading = ValueNotifier(false);
  static void showLoader() => isLoading.value = true;
  static void hideLoader() => isLoading.value = false;
  //endregion

  //region User Data
  static final authRevision = ValueNotifier(0);
  static Profile? profile;
  static String? get token => profile?.token;
  static bool get loggedIn => isValidToken && profile != null;
  static bool get isValidToken => token?.isNotEmpty ?? false;

  static Future<void> getProfile() async {
    final profileJson = prefs.getString(PrefKeys.profile.key);
    if (profileJson != null) {
      profile = Profile.fromJson(jsonDecode(profileJson));
      ApiClient.setAuthHeader(profile!.token);
      authRevision.value++;
    }
  }

  static Future<void> setProfile(
    Profile? newProfile, {
    bool local = false,
    bool loader = true,
  }) async {
    if (loader) showLoader();
    profile = newProfile;
    if (profile != null) {
      ApiClient.setAuthHeader(profile!.token);
      if (!local) {
        await prefs.setString(
          PrefKeys.profile.key,
          jsonEncode(profile!.toJson()),
        );
      }
    }
    authRevision.value++;
    if (loader) hideLoader();
  }

  static Future<void> logOut({bool restart = true}) async {
    showLoader();
    try {
      // Call Logout API - don't let it block the rest of logout if it fails
      try {
        await ApiClient.logout();
      } catch (e) {
        dev.log('Logout API failed: $e');
      }
      
      try {
        if (await googleSignIn.isSignedIn()) await googleSignIn.signOut();
      } catch (e) {
        dev.log('Google SignOut failed: $e');
      }

      try {
        final fbToken = await fbAuth.accessToken;
        if (fbToken?.tokenString.isNotEmpty ?? false) await fbAuth.logOut();
      } catch (e) {
        dev.log('FB Logout failed: $e');
      }
      
      profile = null;
      settings = {}; // Clear global settings/categories
      ApiClient.removeAuthHeader();
      await clearPrefs();
      authRevision.value++;
    } catch (e) {
      dev.log('Error during logout process: $e');
    } finally {
      hideLoader();
      if (restart) resetNavKey();
    }
  }
}
