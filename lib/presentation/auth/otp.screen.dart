import 'package:flutter/material.dart';

class OtpScreen extends StatelessWidget {
  final String code;
  final String email;
  const OtpScreen({super.key, required this.code, required this.email});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Text('OTP Screen Placeholder'),
      ),
    );
  }
}
