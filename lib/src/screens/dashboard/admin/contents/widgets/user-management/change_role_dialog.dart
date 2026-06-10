import 'package:flutter/material.dart';
import '../../../../../../models/auth/user_model.dart';

const _brand   = Color(0xFF1A3C34);
const _gold    = Color(0xFFC9A84C);
const _bg      = Color(0xFFF5F0E8);

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
    Role.client:     Icons.person_outline_rounded,
    Role.homeOwner:  Icons.home_outlined,
    Role.admin:      Icons.admin_panel_settings_outlined,
    Role.operations: Icons.build_outlined,
    Role.finance:    Icons.account_balance_outlined,
    Role.support:    Icons.support_agent_outlined,
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
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _DialogHeader(
              icon: Icons.manage_accounts_rounded,
              title: 'Change Role',
              subtitle: '${widget.user.firstName} ${widget.user.lastName}',
            ),
            const SizedBox(height: 20),

            ...Role.values.map((role) {
              final active = _selected == role;
              return GestureDetector(
                onTap: () => setState(() => _selected = role),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 140),
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
                  decoration: BoxDecoration(
                    color: active ? _brand : Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: active ? _brand : const Color(0xFFEAE6DE),
                    ),
                  ),
                  child: Row(children: [
                    Icon(_roleIcons[role], size: 17,
                        color: active ? _gold : const Color(0xFF6B7280)),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(_label(role),
                          style: TextStyle(
                            fontSize: 13, fontWeight: FontWeight.w600,
                            color: active ? Colors.white : _brand,
                          )),
                    ),
                    if (active) const Icon(Icons.check_rounded, size: 16, color: _gold),
                  ]),
                ),
              );
            }),

            const SizedBox(height: 16),
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
                  onPressed: () {
                    Navigator.pop(context);
                    if (_selected != widget.user.role) widget.onChange(_toBackend(_selected));
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _brand,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  child: const Text('Update Role',
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

// ── Shared header ─────────────────────────────────────────────────────────────

class _DialogHeader extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  const _DialogHeader({required this.icon, required this.title, this.subtitle});

  @override
  Widget build(BuildContext context) => Row(children: [
    Container(
      width: 36, height: 36,
      decoration: BoxDecoration(color: _brand.withOpacity(0.08), borderRadius: BorderRadius.circular(9)),
      child: Icon(icon, size: 18, color: _brand),
    ),
    const SizedBox(width: 11),
    Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(title,
          style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: _brand, letterSpacing: -0.4)),
      if (subtitle != null)
        Text(subtitle!, style: const TextStyle(fontSize: 12, color: Color(0xFF9CA3AF))),
    ]),
  ]);
}