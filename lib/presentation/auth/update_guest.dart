import 'package:flutter/material.dart';
import '../../api/models/auth/profile.dart';

class UpdateGuest extends StatelessWidget {
  final Profile profile;
  final String? title;
  const UpdateGuest({super.key, required this.profile, this.title});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Text('Update Guest Placeholder'),
      ),
    );
  }
}
