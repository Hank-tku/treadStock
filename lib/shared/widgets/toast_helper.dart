import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';

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

  /// Show a snackbar with a single action button (e.g. Undo on delete).
  /// The [onAction] callback runs when the action is tapped; the snackbar is
  /// dismissed automatically afterwards.
  static void showWithAction(
    BuildContext context,
    String message, {
    required String actionText,
    required VoidCallback onAction,
    Duration duration = const Duration(seconds: 5),
  }) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: duration,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.only(left: 16, right: 16, bottom: 64),
        action: SnackBarAction(
          label: actionText,
          textColor: StockColors.brand,
          onPressed: onAction,
        ),
      ),
    );
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
