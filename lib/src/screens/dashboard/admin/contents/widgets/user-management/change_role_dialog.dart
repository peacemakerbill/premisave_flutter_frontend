import 'package:flutter/material.dart';
import '../../../../../../models/auth/user_model.dart';

const _brand = Color(0xFF1A3C34);
const _gold = Color(0xFFC9A84C);
const _stone = Color(0xFFF5F0E8);
const _slate = Color(0xFF6B7280);

class ChangeRoleDialog extends StatefulWidget {
  final UserModel user;
  final Function(String) onChange;
  const ChangeRoleDialog({super.key, required this.user, required this.onChange});

  @override
  State<ChangeRoleDialog> createState() => _ChangeRoleDialogState();
}

class _ChangeRoleDialogState extends State<ChangeRoleDialog> {
  late Role _selected;

  static const _roleIcons = <Role, IconData>{
    Role.client: Icons.person_outline_rounded,
    Role.homeOwner: Icons.home_outlined,
    Role.admin: Icons.admin_panel_settings_outlined,
    Role.operations: Icons.build_outlined,
    Role.finance: Icons.account_balance_outlined,
    Role.support: Icons.support_agent_outlined,
  };

  @override
  void initState() {
    super.initState();
    _selected = widget.user.role;
  }

  String _label(Role r) =>
      r == Role.homeOwner ? 'Home Owner' : r.name[0].toUpperCase() + r.name.substring(1);

  String _toBackend(Role r) =>
      r == Role.homeOwner ? 'HOME_OWNER' : r.name.toUpperCase();

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      backgroundColor: Colors.white,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: _stone,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.manage_accounts_rounded, color: _brand, size: 24),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Change Role',
                          style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: _brand,
                              letterSpacing: -0.4)),
                      Text('${widget.user.firstName} ${widget.user.lastName}',
                          style: const TextStyle(fontSize: 13, color: _slate)),
                    ],
                  ),
                ),
              ]),
              const SizedBox(height: 24),

              ...Role.values.map((role) {
                final active = _selected == role;
                return GestureDetector(
                  onTap: () => setState(() => _selected = role),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 160),
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    decoration: BoxDecoration(
                      color: active ? _brand : Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: active ? _brand : const Color(0xFFEAE6DE),
                      ),
                    ),
                    child: Row(children: [
                      Icon(_roleIcons[role],
                          size: 20,
                          color: active ? _gold : const Color(0xFF6B7280)),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(_label(role),
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: active ? Colors.white : _brand,
                            )),
                      ),
                      if (active)
                        Icon(Icons.check_rounded, size: 20, color: _gold),
                    ]),
                  ),
                );
              }),

              const SizedBox(height: 28),
              _ActionButtons(
                onCancel: () => Navigator.pop(context),
                onSave: () {
                  Navigator.pop(context);
                  if (_selected != widget.user.role) {
                    widget.onChange(_toBackend(_selected));
                  }
                },
                saveLabel: 'Update Role',
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Shared Action Buttons ───────────────────────────────────────────────────

class _ActionButtons extends StatelessWidget {
  final VoidCallback onCancel;
  final VoidCallback onSave;
  final String saveLabel;

  const _ActionButtons({
    required this.onCancel,
    required this.onSave,
    required this.saveLabel,
  });

  @override
  Widget build(BuildContext context) => Row(children: [
    Expanded(
      child: OutlinedButton(
        onPressed: onCancel,
        style: OutlinedButton.styleFrom(
          foregroundColor: _slate,
          side: const BorderSide(color: Color(0xFFEAE6DE)),
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        child: const Text('Cancel', style: TextStyle(fontWeight: FontWeight.w600)),
      ),
    ),
    const SizedBox(width: 12),
    Expanded(
      child: ElevatedButton(
        onPressed: onSave,
        style: ElevatedButton.styleFrom(
          backgroundColor: _brand,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          elevation: 0,
        ),
        child: Text(saveLabel, style: const TextStyle(fontWeight: FontWeight.w600)),
      ),
    ),
  ]);
}