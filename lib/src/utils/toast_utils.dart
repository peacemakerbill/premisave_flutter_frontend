import 'package:flutter/material.dart';
import '../../main.dart';

class ToastUtils {
  static OverlayEntry? _overlayEntry;

  static void showSuccessToast(String message) {
    _show(message, Colors.green, Icons.check_circle);
  }

  static void showErrorToast(String message) {
    _show(message, Colors.red, Icons.error);
  }

  static void showInfoToast(String message) {
    _show(message, Colors.blue, Icons.info);
  }

  static void showWarningToast(String message) {
    _show(message, Colors.orange, Icons.warning);
  }

  static void _show(String message, Color color, IconData icon) {
    try {
      final overlay = navigatorKey.currentState?.overlay;
      if (overlay == null) {
        print('ToastUtils: Overlay is not available');
        return;
      }

      _overlayEntry?.remove();
      _overlayEntry = null;

      _overlayEntry = OverlayEntry(
        builder: (context) => Positioned(
          top: 50,
          right: 20,
          child: Material(
            color: Colors.transparent,
            child: _ToastWidget(
              message: message,
              color: color,
              icon: icon,
              onDismiss: () => _dismiss(),
            ),
          ),
        ),
      );

      overlay.insert(_overlayEntry!);

      Future.delayed(const Duration(seconds: 3), () {
        _dismiss();
      });
    } catch (e) {
      print('ToastUtils error: $e');
    }
  }

  static void _dismiss() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }
}

class _ToastWidget extends StatelessWidget {
  final String message;
  final Color color;
  final IconData icon;
  final VoidCallback onDismiss;

  const _ToastWidget({
    required this.message,
    required this.color,
    required this.icon,
    required this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: UniqueKey(),
      direction: DismissDirection.horizontal,
      onDismissed: (_) => onDismiss(),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 300),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.25),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: Colors.white, size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 13.5,
                  fontWeight: FontWeight.w500,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}