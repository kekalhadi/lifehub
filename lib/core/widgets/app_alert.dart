import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

enum AppAlertType { error, warning, success, info }

class AppAlert {
  static Future<void> show(
    BuildContext context, {
    required String title,
    required String message,
    AppAlertType type = AppAlertType.error,
    String buttonText = 'OK',
  }) {
    final color = switch (type) {
      AppAlertType.error => AppColors.danger,
      AppAlertType.warning => AppColors.warning,
      AppAlertType.success => AppColors.primary,
      AppAlertType.info => AppColors.primary,
    };

    final icon = switch (type) {
      AppAlertType.error => Icons.error_outline_rounded,
      AppAlertType.warning => Icons.warning_amber_rounded,
      AppAlertType.success => Icons.check_circle_outline_rounded,
      AppAlertType.info => Icons.info_outline_rounded,
    };

    return showDialog(
      context: context,
      barrierDismissible: true,
      builder: (_) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: 32, color: color),
              ),
              const SizedBox(height: 20),
              Text(
                title,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 10),
              Text(
                message,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: AppColors.gray500,
                    ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 28),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: color,
                    foregroundColor:
                        color == AppColors.primary ? Colors.black : Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  child: Text(
                    buttonText,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
