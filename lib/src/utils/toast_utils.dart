import 'package:flutter/material.dart';
import '../../main.dart';

class ToastUtils {
  static OverlayEntry? _currentToast;

  static void showSuccessToast(String message) {
    _show(message, Colors.green, Icons.check_circle_rounded);
  }

  static void showErrorToast(String message) {
    _show(message, Colors.red, Icons.error_rounded);
  }

  static void showInfoToast(String message) {
    _show(message, Colors.blue, Icons.info_rounded);
  }

  static void showWarningToast(String message) {
    _show(message, Colors.orange, Icons.warning_rounded);
  }

  static void _show(
      String message,
      Color color,
      IconData icon,
      ) {
    final context = scaffoldMessengerKey.currentContext;
    if (context == null) return;

    final overlay = Overlay.of(context);

    _currentToast?.remove();

    final toast = OverlayEntry(
      builder: (_) => Positioned(
        top: 16,
        right: 16,
        child: SafeArea(
          child: Material(
            color: Colors.transparent,
            child: Container(
              constraints: const BoxConstraints(maxWidth: 280),
              padding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 8,
              ),
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(8),
                boxShadow: const [
                  BoxShadow(
                    blurRadius: 8,
                    offset: Offset(0, 2),
                    color: Colors.black26,
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    icon,
                    color: Colors.white,
                    size: 16,
                  ),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      message,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );

    _currentToast = toast;
    overlay.insert(toast);

    Future.delayed(const Duration(seconds: 3), () {
      if (_currentToast == toast) {
        toast.remove();
        _currentToast = null;
      }
    });
  }
}