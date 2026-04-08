import 'package:flutter/material.dart';
import '../../api/api.client.dart';
import '../../helpers/app_colors.dart';
import '../../helpers/app_state.dart';
import '../../helpers/extensions/context.extension.dart';
import '../shared/widgets/custom_button.widget.dart';
import '../shared/widgets/custom_text_field.widget.dart';
import '../shared/widgets/width_constrained.widget.dart';

class OtpScreen extends StatefulWidget {
  final String email;
  const OtpScreen({super.key, required this.email, String? code});

  @override
  State<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends State<OtpScreen> {
  late final GlobalKey<FormState> _formKey;
  late final TextEditingController _code;
  late final TextEditingController _password;
  bool _obscure = true;

  @override
  void initState() {
    super.initState();
    _formKey = GlobalKey<FormState>();
    _code = TextEditingController();
    _password = TextEditingController();
  }

  @override
  void dispose() {
    _code.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _resetPassword() async {
    if (_formKey.currentState?.validate() != true) return;
    FocusManager.instance.primaryFocus?.unfocus();

    AppState.showLoader();
    final success = await ApiClient.resetPassword(
      email: widget.email,
      code: _code.text.trim(),
      password: _password.text,
    );
    AppState.hideLoader();

    if (success && mounted) {
      Navigator.pop(context); // Close OTP screen to return to login
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Reset Password'),
        elevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: AppColors.black,
      ),
      body: Center(
        child: SingleChildScrollView(
          child: SafeArea(
            minimum: const EdgeInsets.symmetric(horizontal: 32, vertical: 22),
            child: WidthConstrainedWidget(
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Enter the verification code sent to ${widget.email} and your new password.',
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 16),
                    ),
                    const SizedBox(height: 32),
                    CustomTextField(
                      controller: _code,
                      hint: 'Verification Code',
                      keyboardType: TextInputType.number,
                    ),
                    const SizedBox(height: 12),
                    CustomTextField(
                      controller: _password,
                      hint: 'New Password',
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
                    CustomButton(title: 'Reset Password', onTap: _resetPassword),
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
