import 'package:flutter/material.dart';

class CustomTextField extends StatelessWidget {
  final String hintText;
  final IconData prefixIcon;
  final bool obscureText;
  final TextInputType keyboardType;
  final TextEditingController? controller;
  final Widget? suffixIcon;
  final TextInputAction? textInputAction;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final bool enabled;
  final bool readOnly;
  final int maxLines;
  final String? errorText;
  final FocusNode? focusNode;
  final Iterable<String>? autofillHints;

  const CustomTextField({
    super.key,
    required this.hintText,
    required this.prefixIcon,
    this.obscureText = false,
    this.keyboardType = TextInputType.text,
    this.controller,
    this.suffixIcon,
    this.textInputAction,
    this.onChanged,
    this.onSubmitted,
    this.enabled = true,
    this.readOnly = false,
    this.maxLines = 1,
    this.errorText,
    this.focusNode,
    this.autofillHints,
  });

  @override
  Widget build(BuildContext context) {
    final ThemeData theme =
    Theme.of(context);

    final Color backgroundColor =
    enabled
        ? theme.cardColor
        : theme.colorScheme.surfaceContainerHighest;

    final Color textColor =
    enabled
        ? theme.colorScheme.onSurface
        : theme.colorScheme.onSurfaceVariant;

    final Color hintColor =
        theme.colorScheme.onSurfaceVariant;

    final Color iconColor =
        theme.colorScheme.onSurfaceVariant;

    final Color borderColor =
        theme.dividerColor;

    final Color primaryColor =
        theme.colorScheme.primary;

    return TextField(
      controller: controller,
      focusNode: focusNode,
      obscureText: obscureText,
      keyboardType: keyboardType,
      textInputAction: textInputAction,
      enabled: enabled,
      readOnly: readOnly,
      maxLines:
      obscureText ? 1 : maxLines,
      onChanged: onChanged,
      onSubmitted: onSubmitted,
      autofillHints: autofillHints,
      cursorColor: primaryColor,
      style: TextStyle(
        color: textColor,
        fontSize: 15,
      ),
      decoration: InputDecoration(
        hintText: hintText,
        errorText: errorText,
        hintStyle: TextStyle(
          color: hintColor,
          fontSize: 14,
        ),
        prefixIcon: Icon(
          prefixIcon,
          color: iconColor,
          size: 20,
        ),
        suffixIcon: suffixIcon,
        filled: true,
        fillColor: backgroundColor,
        contentPadding:
        const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 18,
        ),
        enabledBorder:
        OutlineInputBorder(
          borderRadius:
          BorderRadius.circular(
            12,
          ),
          borderSide: BorderSide(
            color: borderColor,
          ),
        ),
        disabledBorder:
        OutlineInputBorder(
          borderRadius:
          BorderRadius.circular(
            12,
          ),
          borderSide: BorderSide(
            color: borderColor,
          ),
        ),
        focusedBorder:
        OutlineInputBorder(
          borderRadius:
          BorderRadius.circular(
            12,
          ),
          borderSide: BorderSide(
            color: primaryColor,
            width: 1.3,
          ),
        ),
        errorBorder:
        OutlineInputBorder(
          borderRadius:
          BorderRadius.circular(
            12,
          ),
          borderSide: BorderSide(
            color:
            theme.colorScheme.error,
          ),
        ),
        focusedErrorBorder:
        OutlineInputBorder(
          borderRadius:
          BorderRadius.circular(
            12,
          ),
          borderSide: BorderSide(
            color:
            theme.colorScheme.error,
            width: 1.3,
          ),
        ),
      ),
    );
  }
}