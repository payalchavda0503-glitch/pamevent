import 'package:flutter/material.dart';

import '../../../helpers/app_colors.dart';

class CustomButton extends StatelessWidget {
  const CustomButton({
    required this.title,
    required this.onTap,
    this.fontSize,
    this.fontWeight,
    this.elevation,
    this.shrinkWrap = false,
    this.secondary = false,
    this.danger = false,
    this.radius = 12,
    super.key,
  }) : isOutlined = false;

  const CustomButton.outline({
    required this.title,
    required this.onTap,
    this.fontSize,
    this.fontWeight,
    this.shrinkWrap = false,
    this.danger = false,
    this.radius = 12,
    super.key,
  }) : isOutlined = true,
       secondary = false,
       elevation = null;

  final String title;
  final void Function()? onTap;
  final double? fontSize;
  final FontWeight? fontWeight;
  final double? elevation;
  final double radius;

  final bool isOutlined;
  final bool secondary;
  final bool shrinkWrap;

  final bool danger;

  @override
  Widget build(BuildContext context) {
    final color = danger ? AppColors.red : AppColors.primary;
    return SizedBox(
      width: shrinkWrap ? null : double.infinity,
      child: Builder(
        builder: (context) {
          if (isOutlined) {
            return OutlinedButton(
              onPressed: onTap,
              style: OutlinedButton.styleFrom(
                elevation: elevation ?? 0,
                textStyle: TextStyle(
                  fontSize: fontSize ?? 16,
                  fontWeight: fontWeight,
                ),
                foregroundColor: color,
                padding: const EdgeInsets.symmetric(
                  horizontal: 22,
                  vertical: 12,
                ),
                side: BorderSide(color: color, width: .5),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(radius),
                ),
              ),
              child: Text(title, textAlign: TextAlign.center),
            );
          }
          return ElevatedButton(
            onPressed: onTap,
            style: ElevatedButton.styleFrom(
              elevation: elevation ?? 0,
              textStyle: TextStyle(
                fontSize: fontSize ?? 16,
                fontWeight: fontWeight,
              ),
              padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
              foregroundColor: secondary ? color : AppColors.white,
              backgroundColor: secondary ? AppColors.white : color,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(radius),
              ),
            ),
            child: Text(title, textAlign: TextAlign.center),
          );
        },
      ),
    );
  }
}
