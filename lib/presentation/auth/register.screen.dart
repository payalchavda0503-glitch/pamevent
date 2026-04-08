import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import '../../api/api.client.dart';
import '../../api/models/auth/profile.dart';
import '../../helpers/app_colors.dart';
import '../../helpers/app_state.dart';
import '../../helpers/extensions/context.extension.dart';
import '../main_layout.dart';
import '../shared/widgets/custom_button.widget.dart';
import '../shared/widgets/custom_text_field.widget.dart';
import '../shared/widgets/width_constrained.widget.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  late final GlobalKey<FormState> _formKey;
  late final TextEditingController _name;
  late final TextEditingController _username;
  late final TextEditingController _email;
  late final TextEditingController _phone;
  late final TextEditingController _password;
  late final TapGestureRecognizer _loginRecognizer;

  bool _obscure = true;

  @override
  void initState() {
    super.initState();
    _formKey = GlobalKey<FormState>();
    _name = TextEditingController();
    _username = TextEditingController();
    _email = TextEditingController();
    _phone = TextEditingController();
    _password = TextEditingController();
    _loginRecognizer = TapGestureRecognizer()..onTap = () => Navigator.pop(context);
  }

  @override
  void dispose() {
    _name.dispose();
    _username.dispose();
    _email.dispose();
    _phone.dispose();
    _password.dispose();
    _loginRecognizer.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    if (_formKey.currentState?.validate() != true) return;
    FocusManager.instance.primaryFocus?.unfocus();
    
    AppState.showLoader();
    try {
      final response = await ApiClient.register(
        name: _name.text.trim(),
        username: _username.text.trim(),
        email: _email.text.trim(),
        phone: _phone.text.trim(),
        password: _password.text,
      );
      
      AppState.hideLoader();
      if (response != null && response['status'] == 100) {
        if (mounted) {
          // Success toast is usually handled by ApiClient, if not, we can add it here
          Navigator.pop(context); // Go back to login screen
        }
      }
    } catch (e) {
      AppState.hideLoader();
      debugPrint('Registration error: $e');
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
                    const Center(
                      child: Text(
                        'Create Account',
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
                          text: 'Already have an account? ',
                          style: const TextStyle(color: AppColors.black),
                          children: [
                            TextSpan(
                              text: 'Log in',
                              recognizer: _loginRecognizer,
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
                    CustomTextField(
                      controller: _name,
                      hint: 'Full Name',
                    ),
                    const SizedBox(height: 12),
                    CustomTextField(
                      controller: _username,
                      hint: 'Username',
                    ),
                    const SizedBox(height: 12),
                    CustomTextField(
                      controller: _email,
                      hint: 'Email Address',
                      keyboardType: TextInputType.emailAddress,
                    ),
                    const SizedBox(height: 12),
                    CustomTextField(
                      controller: _phone,
                      hint: 'Phone Number',
                      keyboardType: TextInputType.phone,
                    ),
                    const SizedBox(height: 12),
                    CustomTextField(
                      controller: _password,
                      hint: 'Password',
                      obscureText: _obscure,
                      textInputAction: TextInputAction.done,
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscure ? Icons.visibility_off : Icons.visibility,
                          color: AppColors.primary,
                        ),
                        onPressed: () => setState(() => _obscure = !_obscure),
                      ),
                    ),
                    const SizedBox(height: 32),
                    CustomButton(title: 'Register', onTap: _register),
                    const SizedBox(height: 22),
                    Center(
                      child: TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text(
                          'Back to Login',
                          style: TextStyle(color: AppColors.grey),
                        ),
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
