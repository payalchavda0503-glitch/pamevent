import 'package:flutter/material.dart';

import '../../../api/api.client.dart';
import '../../../helpers/app_state.dart';
import '../../../helpers/extensions/context.extension.dart';
import '../../../helpers/validator.dart';
import '../../shared/widgets/custom_button.widget.dart';
import '../../shared/widgets/custom_text_field.widget.dart';
import '../../shared/widgets/width_constrained.widget.dart';
import '../otp.screen.dart';

class ForgotPasswordDialog extends StatefulWidget {
  const ForgotPasswordDialog({super.key});

  @override
  State<ForgotPasswordDialog> createState() => _ForgotPasswordDialogState();
}

class _ForgotPasswordDialogState extends State<ForgotPasswordDialog> {
  late final TextEditingController _email;
  late final GlobalKey<FormState> _formKey;

  @override
  void initState() {
    super.initState();
    _formKey = GlobalKey<FormState>();
    _email = TextEditingController();
  }

  @override
  void setState(VoidCallback fn) {
    if (mounted) super.setState(fn);
  }

  @override
  void dispose() {
    _email.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return WidthConstrainedWidget(
      child: SimpleDialog(
        clipBehavior: Clip.antiAlias,
        shape: ContinuousRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ),
        title: const Text(
          'Enter your Email address to receive a verification code:',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        contentPadding: const EdgeInsets.all(20),
        children: [
          Form(
            key: _formKey,
            child: CustomTextField(
              controller: _email,
              hint: 'E-mail',
              validator: Validation.email,
            ),
          ),
          const SizedBox(height: 16),
          CustomButton(
            title: 'Reset password!',
            onTap: () async {
              if (_formKey.currentState?.validate() == true) {
                FocusManager.instance.primaryFocus?.unfocus();
                AppState.showLoader();
                final success = await ApiClient.forgotPassword(_email.text.trim());
                AppState.hideLoader();
                if (context.mounted && success) {
                  Navigator.pop(context); // Close dialog
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => OtpScreen(email: _email.text.trim()),
                    ),
                  );
                }
              }
            },
          ),
          CustomButton.outline(title: 'Cancel', onTap: context.pop),
        ],
      ),
    );
  }
}
