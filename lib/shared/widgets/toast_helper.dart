import 'package:flutter/material.dart';

/// Toast helper for showing SnackBar messages.
/// Design: DESIGN.md interaction-spec Toast section.
class ToastHelper {
  ToastHelper._();

  static void showSuccess(BuildContext context, String message) {
    _show(context, message, duration: const Duration(seconds: 2));
  }

  static void showError(BuildContext context, String message) {
    _show(context, message, duration: const Duration(seconds: 3));
  }

  static void _show(BuildContext context, String message,
      {required Duration duration}) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: duration,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.only(
          left: 16,
          right: 16,
          bottom: 64, // above tab bar
        ),
      ),
    );
  }
}
