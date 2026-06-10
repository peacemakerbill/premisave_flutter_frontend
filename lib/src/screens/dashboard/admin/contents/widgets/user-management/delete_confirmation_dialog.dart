import 'package:flutter/material.dart';
import '../../../../../../models/auth/user_model.dart';

const _brand = Color(0xFF1A3C34);

class DeleteConfirmationDialog extends StatelessWidget {
  final UserModel user;
  final VoidCallback onConfirm;
  const DeleteConfirmationDialog({super.key, required this.user, required this.onConfirm});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Warning icon
            Container(
              width: 56, height: 56,
              decoration: BoxDecoration(
                color: const Color(0xFFFEF2F2),
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Icon(Icons.delete_outline_rounded, size: 28, color: Color(0xFFDC2626)),
            ),
            const SizedBox(height: 16),

            const Text('Delete User',
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: _brand, letterSpacing: -0.4)),
            const SizedBox(height: 8),

            Text(
              'Are you sure you want to delete ${user.firstName} ${user.lastName}?',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 13, color: Color(0xFF374151)),
            ),
            const SizedBox(height: 6),

            const Text(
              'This action cannot be undone. All user data will be permanently removed.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, color: Color(0xFF9CA3AF)),
            ),
            const SizedBox(height: 24),

            Row(children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(context),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Color(0xFFEAE6DE)),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  child: const Text('Cancel',
                      style: TextStyle(color: _brand, fontWeight: FontWeight.w600)),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: () { Navigator.pop(context); onConfirm(); },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFDC2626),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  child: const Text('Delete',
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                ),
              ),
            ]),
          ],
        ),
      ),
    );
  }
}