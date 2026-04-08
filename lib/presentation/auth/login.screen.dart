import 'dart:io';

import 'package:app_tracking_transparency/app_tracking_transparency.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../api/api.client.dart';
import '../../api/models/auth/profile.dart';
import '../../helpers/app_colors.dart';
import '../../helpers/app_state.dart';
import '../../helpers/extensions/context.extension.dart';
import '../../helpers/extensions/string.extension.dart';
import '../../services/toast.service.dart';
import '../main_layout.dart';
import '../scanner/scanner.screen.dart';
import '../shared/widgets/custom_button.widget.dart';
import '../shared/widgets/custom_image.dart';
import '../shared/widgets/custom_text_field.widget.dart';
import '../shared/widgets/width_constrained.widget.dart';
import 'dialogs/forgot_password.dialog.dart';
import 'register.screen.dart';
import 'update_guest.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  late final GlobalKey<FormState> _formKey;

  late final TextEditingController _username;
  late final TextEditingController _password;

  bool obscure = true;

  late final TapGestureRecognizer _createAccount;

  @override
  void initState() {
    super.initState();
    _formKey = GlobalKey<FormState>();
    _username = TextEditingController();
    _password = TextEditingController();
    _createAccount = TapGestureRecognizer();
    _createAccount.onTap = () => context.push(const RegisterScreen());
    if (kDebugMode) {
      _username.text = 'chavda';
      _password.text = '123456';
    }
    // if (kDebugMode) {
    //   _username.text = 'glinca21078';
    //   _password.text = 'KR233LXLD4';
    // }
  }

  @override
  void dispose() {
    _username.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _handleAfterLogin(Profile? profile) async {
    if (!mounted || profile == null) return;
    AppState.setProfile(profile, loader: false);
    context.replace(const MainLayout());
  }
  Future<void> _handleBarcode(Profile? profile,String? title) async {
    if (!mounted || profile == null) return;
    AppState.setProfile(profile, loader: false);
    context.replace( UpdateGuest(profile: profile,title: title,));
  }

  Future<void> _login() async {
    if (_formKey.currentState?.validate() != true) return;
    FocusManager.instance.primaryFocus?.unfocus();
    AppState.showLoader();
    try {
      final response = await ApiClient.login(
        username: _username.text.trim(),
        password: _password.text,
      );
      AppState.hideLoader();
      if (response != null && response['status'] == 100) {
        final profile = Profile.fromJson(response['data']);
        ToastService.show(response['message'] ?? 'Login successful!');
        _handleAfterLogin(profile);
      }
    } catch (e) {
      AppState.hideLoader();
      debugPrint('Login error: $e');
    }
  }

  Future<void> _loginwithQR()
  async {
    final data = await context.push<String>(
      ScannerScreen(),
    );
    //final data="EB39192D5F";
    if (!context.mounted) return;
    if (data is String) {
      AppState.showLoader();
      final result = await ApiClient.loginQr(
      data
      );

      Profile profile = result!['profile'];
      Map<String, dynamic> rawData = result['raw'];
      AppState.hideLoader();
      _handleBarcode(profile,rawData['event_title']);
    }
  }

  Future<void> _handleGoogleAuth() async {
    try {
      AppState.showLoader();
      // Helps avoid "stuck" sessions on some devices.
      try {
        if (await AppState.googleSignIn.isSignedIn()) {
          await AppState.googleSignIn.signOut();
        }
      } catch (_) {}
      final user = await AppState.googleSignIn.signIn();
      if (user?.id == null) {
        AppState.hideLoader();
        return ToastService.show('Sign-in cancelled or failed!');
      }
      final username = user!.displayName?.spread;
      AppState.showLoader();
      final profile = await ApiClient.socialLogin(
        firstName: username?.first,
        lastName: username?.last,
        providerId: user.id,
        email: user.email,
        provider: 'google',
      );
      AppState.hideLoader();
      _handleAfterLogin(profile);
    } catch (error) {
      if (kDebugMode) rethrow;

      // Provide a useful error message for release builds (important for app review).
      if (error is PlatformException) {
        final msg = (error.message ?? '').trim();
        final details = (error.details ?? '').toString();
        final combined = '$msg $details'.trim();

        // Common Android misconfiguration: SHA-1/SHA-256 not registered for the RELEASE key
        // or missing correct OAuth client configuration.
        if (combined.contains('ApiException: 10') ||
            combined.contains('DEVELOPER_ERROR') ||
            combined.contains('developer_error')) {
          return ToastService.show(
            'Google Sign-In is not configured for this app build (release SHA key). '
            'Add the release SHA-1/SHA-256 in your Firebase/Google Cloud OAuth setup and rebuild.',
            backgroundColor: AppColors.red,
            long: true,
          );
        }

        return ToastService.show(
          'Google Sign-In failed: ${error.code}${msg.isNotEmpty ? " — $msg" : ""}',
          backgroundColor: AppColors.red,
          long: true,
        );
      }

      ToastService.show(
        'Failed to login with google.',
        backgroundColor: AppColors.red,
      );
    } finally {
      AppState.hideLoader();
    }
  }

  Future<void> _handleTrackAndLogin() async {
    // IMPORTANT: Facebook login must work on Android too (Meta review).
    //
    // On iOS, ATT is not required for Facebook login itself. We'll request it
    // opportunistically, but we never block login if the user declines.
    if (Platform.isIOS) {
      try {
        var status = await AppTrackingTransparency.trackingAuthorizationStatus;
        if (status == TrackingStatus.notDetermined) {
          await AppTrackingTransparency.requestTrackingAuthorization();
        }
      } catch (_) {
        // Ignore ATT errors; login must still work.
      }
    }

    await _handleFaceBookAuth();
  }

  Future<void> _handleFaceBookAuth() async {
    try {
      AppState.showLoader();
      final result = await AppState.fbAuth.login(
        permissions: const ['public_profile', 'email'],
        loginTracking: LoginTracking.enabled,
      );
      if (result.status != LoginStatus.success) {
        return ToastService.show('Sign-in cancelled.');
      }
      final auth = await AppState.fbAuth.getUserData(fields: 'name,email');
      if (auth.isEmpty) return ToastService.show('Failed to get user info.');
      final name = (auth['name'] as String?)?.spread;
      final email = auth['email'];
      if (email is! String || email.trim().isEmpty) {
        return ToastService.show(
          'Facebook did not provide an email for this account. Please login with Google or Username/Password.',
          backgroundColor: AppColors.red,
          long: true,
        );
      }
      AppState.showLoader();
      final profile = await ApiClient.socialLogin(
        firstName: name?.first,
        lastName: name?.last,
        providerId: auth['id'],
        email: email,
        provider: 'facebook',
      );
      AppState.hideLoader();
      _handleAfterLogin(profile);
    } catch (error) {
      if (kDebugMode) rethrow;
      ToastService.show('Failed to login with facebook.');
    } finally {
      AppState.hideLoader();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          child: SafeArea(
            minimum: const EdgeInsets.symmetric(horizontal: 32, vertical: 22),
            child: WidthConstrainedWidget(
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Center(child: CustomImage.svg(AppState.logo, height: 80)),
                    const SizedBox(height: 22),
                    Center(
                      child: const Text(
                        'Welcome back',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    Center(
                      child: const Text(
                        'Log in',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(height: 22),
                    Center(
                      child: Text.rich(
                        TextSpan(
                          text: 'Not a member? ',
                          style: const TextStyle(color: AppColors.black),
                          children: [
                            TextSpan(
                              text: 'Create an Account',
                              recognizer: _createAccount,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: AppColors.primary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),
                    CustomTextField(controller: _username, hint: 'Username'),
                    const SizedBox(height: 12),
                    CustomTextField(
                      controller: _password,
                      hint: 'Password',
                      obscureText: obscure,
                      textInputAction: TextInputAction.done,
                      suffixIcon: IconButton(
                        icon: Icon(
                          obscure ? Icons.visibility_off : Icons.visibility,
                          color: AppColors.primary,
                        ),
                        onPressed: () => setState(() => obscure = !obscure),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: () {
                          showDialog(
                            context: context,
                            builder: (_) => const ForgotPasswordDialog(),
                          );
                        },
                        child: const Text(
                          'Forgot Password?',
                          style: TextStyle(
                            color: AppColors.primary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    CustomButton(title: 'Login', onTap: _login),
                    const Row(
                      children: [
                        Expanded(child: Divider(color: AppColors.lightGrey)),
                        Padding(
                          padding: EdgeInsets.symmetric(
                            vertical: 22,
                            horizontal: 12,
                          ),
                          child: Text(
                            'OR',
                            style: TextStyle(
                              color: AppColors.lightGrey,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        Expanded(child: Divider(color: AppColors.lightGrey)),
                      ],
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SignInButton.google(onPressed: _handleGoogleAuth),
                        const SizedBox(width: 16),
                        SignInButton.facebook(onPressed: _handleTrackAndLogin),
                      ],
                    ),
                    const SizedBox(height: 42),
                    Center(
                      child: const Text(
                        '@2024 copyright',
                        style: TextStyle(fontSize: 10, color: AppColors.grey),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class SignInButton extends StatelessWidget {
  const SignInButton.google({
    super.key,
    required this.onPressed, //
  }) : icon = 'assets/svg/google.svg';

  const SignInButton.facebook({
    super.key,
    required this.onPressed, //
  }) : icon = 'assets/svg/facebook.svg';

  final String icon;
  final VoidCallback onPressed;

  final Color color = AppColors.scaffold;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.white,
          shape: BoxShape.circle,
          border: Border.all(
            color: AppColors.lightGrey..withValues(alpha: 0.1),
          ),
        ),
        child: SizedBox.square(dimension: 26, child: SvgPicture.asset(icon)),
      ),
    );
  }
}
