import 'package:flutter/material.dart';

class WidthConstrainedWidget extends StatelessWidget {
  final double? maxWidth;
  final Widget child;

  const WidthConstrainedWidget({super.key, this.maxWidth, required this.child});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth ?? 480),
        child: child,
      ),
    );
  }
}
