// lib/utils/snackbar.dart
import 'package:flutter/material.dart';
import 'constants.dart'; // ✅ so it can use AppColors or AppTextStyle if needed

class AppSnackBar {
  /// 🔹 Show a success message
  static void success(BuildContext context, String message) {
    _show(
      context,
      message,
      backgroundColor: AppColors.primary,
      icon: Icons.check_circle,
    );
  }

  /// 🔹 Show an error message
  static void error(BuildContext context, String message) {
    _show(
      context,
      message,
      backgroundColor: AppColors.danger,
      icon: Icons.error_outline,
    );
  }

  /// 🔹 Show a warning or neutral info
  static void info(BuildContext context, String message) {
    _show(
      context,
      message,
      backgroundColor: Colors.orange.shade700,
      icon: Icons.info_outline,
    );
  }

  /// 🔸 Private helper
  static void _show(
    BuildContext context,
    String message, {
    Color? backgroundColor,
    IconData? icon,
  }) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: backgroundColor ?? Colors.black87,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        content: Row(
          children: [
            if (icon != null) Icon(icon, color: Colors.white, size: 20),
            if (icon != null) const SizedBox(width: 8),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(color: Colors.white, fontSize: 14),
              ),
            ),
          ],
        ),
        duration: const Duration(seconds: 3),
      ),
    );
  }
}
