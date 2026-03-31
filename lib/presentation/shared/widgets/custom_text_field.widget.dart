import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../helpers/app_colors.dart';

class CustomTextField extends StatelessWidget {
  final TextEditingController? controller;

  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final TextCapitalization textCapitalization;
  final String? Function(String value)? validator;

  final String hint;
  final double? fontSize;

  final bool obscureText;
  final bool readOnly;
  final bool autofocus;

  final bool required;
  final Function(String value)? onSubmitted;
  final Function(String value)? onChanged;
  final VoidCallback? onTap;

  /// Defaults to [AppColor.lightGrey]
  final Color? fillColor;

  final int? maxLines;
  final int? maxLength;

  final List<TextInputFormatter>? inputFormatters;

  final Widget? prefixIcon;
  final Widget? suffixIcon;

  final String? header;

  const CustomTextField({
    super.key,
    required this.controller,
    this.keyboardType = TextInputType.text,
    this.textInputAction = TextInputAction.next,
    this.obscureText = false,
    this.readOnly = false,
    this.autofocus = false,
    this.required = true,
    this.onSubmitted,
    this.onTap,
    this.onChanged,
    this.maxLines,
    this.maxLength,
    this.validator,
    this.inputFormatters,
    this.prefixIcon,
    this.suffixIcon,
    required this.hint,
    this.textCapitalization = TextCapitalization.none,
    this.fillColor,
    this.fontSize,
  }) : header = null;

  const CustomTextField.header({
    super.key,
    required this.controller,
    required String title,
    this.keyboardType = TextInputType.text,
    this.textInputAction = TextInputAction.next,
    this.obscureText = false,
    this.readOnly = false,
    this.autofocus = false,
    this.required = true,
    this.onSubmitted,
    this.onTap,
    this.onChanged,
    this.maxLines,
    this.maxLength,
    this.validator,
    this.inputFormatters,
    this.prefixIcon,
    this.suffixIcon,
    required this.hint,
    this.textCapitalization = TextCapitalization.none,
    this.fillColor,
    this.fontSize,
  }) : header = title;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        if (header != null) ...[
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              header!,
              style: const TextStyle(fontSize: 12, color: AppColors.grey),
            ),
          ),
          const SizedBox(height: 8),
        ],
        TextFormField(
          autofocus: autofocus,
          controller: controller,
          keyboardType: keyboardType,
          textInputAction: textInputAction,
          obscureText: obscureText,
          textCapitalization: textCapitalization,
          readOnly: readOnly,
          onTap: onTap,
          validator: (val) {
            if (required && (val?.isEmpty ?? true)) return '*required field';
            return validator?.call(val ?? '');
          },
          onChanged: onChanged ?? (String val) {},
          style: TextStyle(fontSize: fontSize ?? 16),
          inputFormatters: inputFormatters,
          maxLines: maxLines ?? 1,
          maxLength: maxLength,
          cursorColor: AppColors.primary,
          autocorrect: false,
          enableSuggestions: false,
          decoration: InputDecoration(
            prefixIcon: prefixIcon,
            errorMaxLines: 3,
            suffixIcon: suffixIcon,
            fillColor: fillColor,
            hintText: hint,
            prefixIconColor: AppColors.primary,
            suffixIconColor: AppColors.primary,
            hintStyle: const TextStyle(color: AppColors.grey),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16),
          ),
        ),
      ],
    );
  }
}
