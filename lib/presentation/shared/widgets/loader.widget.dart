import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';

import '../../../helpers/app_colors.dart';
import '../../../helpers/app_state.dart';

class LoaderWidget extends StatelessWidget {
  const LoaderWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: AppState.isLoading,
      builder: (_, v, c) => v ? AbsorbPointer(child: c!) : const SizedBox(),
      child: Center(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 2, sigmaY: 2),
          child: FittedBox(
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                color: AppColors.black.withValues(alpha: 0.2),
              ),
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 22),
              child: const SpinKitThreeBounce(
                color: AppColors.primary,
                size: 20,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class LoaderAwareWidget extends StatelessWidget {
  const LoaderAwareWidget._(this.msg, this.child, {super.key});

  const LoaderAwareWidget.msg(this.msg, {super.key}) : child = null;
  const LoaderAwareWidget.custom({this.child, super.key}) : msg = null;
  const LoaderAwareWidget.noData({Key? key}) : this._(null, null, key: key);

  final String? msg;
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: AppState.isLoading,
      builder: (context, val, child) {
        if (val) return const SizedBox();
        return Center(child: this.child ?? child!);
      },
      child: Text(
        msg ?? 'No data found!',
        textAlign: TextAlign.center,
        style: const TextStyle(fontSize: 18, color: AppColors.primary),
      ),
    );
  }
}
