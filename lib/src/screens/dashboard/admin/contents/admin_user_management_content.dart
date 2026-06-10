import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../models/auth/user_model.dart';
import '../../../../providers/admin/user_management_provider.dart';
import 'widgets/user-management/change_password_dialog.dart';
import 'widgets/user-management/change_role_dialog.dart';
import 'widgets/user-management/create_user_dialog.dart';
import 'widgets/user-management/delete_confirmation_dialog.dart';
import 'widgets/user-management/edit_user_dialog.dart';
import 'widgets/user-management/user_details_dialog.dart';

const _brand = Color(0xFF1A3C34);
const _gold = Color(0xFFC9A84C);

class AdminUserManagementContent extends ConsumerStatefulWidget {
  const AdminUserManagementContent({super.key});

  @override
  ConsumerState<AdminUserManagementContent> createState() => _AdminUserManagementContentState();
}

class _AdminUserManagementContentState extends ConsumerState<AdminUserManagementContent> {
  final _searchController = TextEditingController();
  Timer? _debounce;
  Role? _roleFilter;
  bool? _activeFilter;
  bool? _verifiedFilter;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(userManagementProvider.notifier).refreshUsers();
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  void _onSearch(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      value.isEmpty
          ? ref.read(userManagementProvider.notifier).refreshUsers()
          : ref.read(userManagementProvider.notifier).searchUsers(value);
    });
  }

  void _clearAll() {
    _debounce?.cancel();
    _searchController.clear();
    setState(() => _roleFilter = _activeFilter = _verifiedFilter = null);
    final n = ref.read(userManagementProvider.notifier);
    n.refreshUsers();
    n.filterByStatus(null, null);
    n.filterByRole(null);
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(userManagementProvider);
    final notifier = ref.read(userManagementProvider.notifier);

    return Stack(
      children: [
        Column(
          children: [
            _FiltersBar(
              controller: _searchController,
              roleFilter: _roleFilter,
              activeFilter: _activeFilter,
              verifiedFilter: _verifiedFilter,
              onSearch: _onSearch,
              onClearAll: _clearAll,
              onRoleChanged: (r) {
                setState(() => _roleFilter = r);
                notifier.filterByRole(r);
              },
              onActiveChanged: (v) {
                setState(() => _activeFilter = v);
                notifier.filterByStatus(v, _verifiedFilter);
              },
              onVerifiedChanged: (v) {
                setState(() => _verifiedFilter = v);
                notifier.filterByStatus(_activeFilter, v);
              },
              onSubmit: () {
                _debounce?.cancel();
                notifier.searchUsers(_searchController.text);
              },
              notifier: notifier,
            ),
            if (state.isLoading)
              const LinearProgressIndicator(color: _brand, backgroundColor: Color(0xFFF5F0E8)),
            if (state.error != null) _ErrorBanner(state: state, ref: ref),
            if (_searchController.text.isNotEmpty && !state.isLoading)
              _SearchBanner(query: _searchController.text, count: state.filteredUsers.length),
            Expanded(
              child: state.filteredUsers.isEmpty
                  ? _EmptyState(
                state: state,
                query: _searchController.text,
                onAdd: () => _showCreate(context, notifier),
              )
                  : ListView.builder(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 80),
                itemCount: state.filteredUsers.length,
                itemBuilder: (_, i) => _UserCard(
                  user: state.filteredUsers[i],
                  isExpanded: state.expandedUsers[state.filteredUsers[i].id] ?? false,
                  notifier: notifier,
                  onMenuAction: (action) => _handleAction(action, notifier, state.filteredUsers[i]),
                ),
              ),
            ),
          ],
        ),
        Positioned(
          right: 20,
          bottom: 20,
          child: FloatingActionButton.extended(
            onPressed: () => _showCreate(context, notifier),
            backgroundColor: _brand,
            icon: const Icon(Icons.person_add_rounded, color: _gold),
            label: const Text('Add User', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
          ),
        ),
      ],
    );
  }

  void _showCreate(BuildContext ctx, UserManagementNotifier notifier) {
    showDialog(
      context: ctx,
      builder: (_) => CreateUserDialog(onCreate: (data) async => notifier.createUser(data)),
    );
  }

  void _handleAction(String action, UserManagementNotifier notifier, UserModel user) {
    switch (action) {
      case 'activate': notifier.toggleUserStatus(user.id, true); break;
      case 'deactivate': notifier.toggleUserStatus(user.id, false); break;
      case 'verify': notifier.toggleVerification(user.id, true); break;
      case 'unverify': notifier.toggleVerification(user.id, false); break;
      case 'change_role':
        showDialog(context: context, builder: (_) => ChangeRoleDialog(user: user, onChange: (role) async => notifier.changeUserRole(user.id, role)));
        break;
      case 'delete':
        showDialog(context: context, builder: (_) => DeleteConfirmationDialog(user: user, onConfirm: () async => notifier.deleteUser(user.id)));
        break;
    }
  }
}

// ── Filters Bar (unchanged) ─────────────────────────────────────────────────

class _FiltersBar extends StatelessWidget {
  final TextEditingController controller;
  final Role? roleFilter;
  final bool? activeFilter;
  final bool? verifiedFilter;
  final ValueChanged<String> onSearch;
  final VoidCallback onClearAll;
  final ValueChanged<Role?> onRoleChanged;
  final ValueChanged<bool?> onActiveChanged;
  final ValueChanged<bool?> onVerifiedChanged;
  final VoidCallback onSubmit;
  final UserManagementNotifier notifier;

  const _FiltersBar({
    required this.controller,
    required this.roleFilter,
    required this.activeFilter,
    required this.verifiedFilter,
    required this.onSearch,
    required this.onClearAll,
    required this.onRoleChanged,
    required this.onActiveChanged,
    required this.onVerifiedChanged,
    required this.onSubmit,
    required this.notifier,
  });

  @override
  Widget build(BuildContext context) {
    final hasFilter = roleFilter != null || activeFilter != null || verifiedFilter != null;
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 12),
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Container(
                  height: 40,
                  decoration: BoxDecoration(color: const Color(0xFFF5F0E8), borderRadius: BorderRadius.circular(10)),
                  child: TextField(
                    controller: controller,
                    onChanged: onSearch,
                    onSubmitted: (_) => onSubmit(),
                    style: const TextStyle(fontSize: 13, color: _brand),
                    decoration: InputDecoration(
                      hintText: 'Search users…',
                      hintStyle: const TextStyle(fontSize: 13, color: Color(0xFF9CA3AF)),
                      prefixIcon: const Icon(Icons.search_rounded, size: 18, color: Color(0xFF9CA3AF)),
                      suffixIcon: controller.text.isNotEmpty
                          ? IconButton(icon: const Icon(Icons.close_rounded, size: 16, color: Color(0xFF9CA3AF)), onPressed: onClearAll)
                          : null,
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(vertical: 11),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              GestureDetector(
                onTap: onClearAll,
                child: Container(
                  height: 40,
                  width: 40,
                  decoration: BoxDecoration(color: const Color(0xFFF5F0E8), borderRadius: BorderRadius.circular(10)),
                  child: const Icon(Icons.refresh_rounded, size: 18, color: _brand),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _FilterPill(label: 'All', selected: roleFilter == null, onTap: () => onRoleChanged(null)),
                ...Role.values.map((r) => Padding(
                  padding: const EdgeInsets.only(left: 6),
                  child: _FilterPill(
                    label: r.name.replaceAll('_', ' '),
                    selected: roleFilter == r,
                    onTap: () => onRoleChanged(roleFilter == r ? null : r),
                  ),
                )),
                const SizedBox(width: 12),
                _FilterPill(label: 'Active', selected: activeFilter == true, onTap: () => onActiveChanged(activeFilter == true ? null : true)),
                Padding(
                  padding: const EdgeInsets.only(left: 6),
                  child: _FilterPill(label: 'Inactive', selected: activeFilter == false, onTap: () => onActiveChanged(activeFilter == false ? null : false)),
                ),
                const SizedBox(width: 12),
                _FilterPill(label: 'Verified', selected: verifiedFilter == true, onTap: () => onVerifiedChanged(verifiedFilter == true ? null : true)),
                Padding(
                  padding: const EdgeInsets.only(left: 6),
                  child: _FilterPill(label: 'Unverified', selected: verifiedFilter == false, onTap: () => onVerifiedChanged(verifiedFilter == false ? null : false)),
                ),
                if (hasFilter) ...[
                  const SizedBox(width: 10),
                  GestureDetector(
                    onTap: onClearAll,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(border: Border.all(color: const Color(0xFFEAE6DE)), borderRadius: BorderRadius.circular(20)),
                      child: const Text('Clear', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF6B7280))),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _FilterPill extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _FilterPill({required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 140),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
        decoration: BoxDecoration(
          color: selected ? _brand : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: selected ? _brand : const Color(0xFFEAE6DE)),
        ),
        child: Text(
          label,
          style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: selected ? Colors.white : const Color(0xFF6B7280)),
        ),
      ),
    );
  }
}

// ── User Card with visible menu ─────────────────────────────────────────────

class _UserCard extends StatelessWidget {
  final UserModel user;
  final bool isExpanded;
  final UserManagementNotifier notifier;
  final ValueChanged<String> onMenuAction;

  const _UserCard({
    required this.user,
    required this.isExpanded,
    required this.notifier,
    required this.onMenuAction,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: const Border(left: BorderSide(color: _gold, width: 3)),
      ),
      child: Column(
        children: [
          InkWell(
            onTap: () => _showDetails(context),
            borderRadius: BorderRadius.circular(14),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 12, 14),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 20,
                    backgroundColor: _brand,
                    backgroundImage: user.profilePictureUrl?.isNotEmpty == true ? NetworkImage(user.profilePictureUrl!) : null,
                    child: user.profilePictureUrl?.isNotEmpty != true
                        ? Text('${user.firstName.isNotEmpty ? user.firstName[0] : ''}${user.lastName.isNotEmpty ? user.lastName[0] : ''}',
                        style: const TextStyle(color: _gold, fontSize: 13, fontWeight: FontWeight.w700))
                        : null,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('${user.firstName} ${user.lastName}', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: _brand)),
                        Text(user.email, style: const TextStyle(fontSize: 11, color: Color(0xFF9CA3AF))),
                        const SizedBox(height: 5),
                        Row(
                          children: [
                            _Badge(label: user.role.name.replaceAll('_', ' '), color: _roleColor(user.role.name)),
                            const SizedBox(width: 5),
                            _Badge(label: user.active ? 'Active' : 'Inactive', color: user.active ? const Color(0xFF22C55E) : const Color(0xFFDC2626)),
                            const SizedBox(width: 5),
                            _Badge(label: user.verified ? 'Verified' : 'Unverified', color: user.verified ? const Color(0xFF3B82F6) : const Color(0xFFF59E0B)),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Icon(isExpanded ? Icons.expand_less_rounded : Icons.expand_more_rounded, size: 18, color: const Color(0xFF9CA3AF)),
                  PopupMenuButton<String>(
                    onSelected: onMenuAction,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    color: Colors.white,
                    elevation: 8,
                    icon: const Icon(Icons.more_vert_rounded, size: 18, color: Color(0xFF6B7280)),
                    itemBuilder: (_) => [
                      PopupMenuItem(value: user.active ? 'deactivate' : 'activate', child: const Text('Activate / Deactivate')),
                      PopupMenuItem(value: user.verified ? 'unverify' : 'verify', child: const Text('Verify / Unverify')),
                      const PopupMenuItem(value: 'change_role', child: Text('Change Role')),
                      PopupMenuItem(
                        value: 'delete',
                        child: const Text('Delete', style: TextStyle(color: Colors.red, fontWeight: FontWeight.w600)),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          if (isExpanded) _ExpandedDetails(user: user, notifier: notifier),
        ],
      ),
    );
  }

  void _showDetails(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => UserDetailsDialog(
        user: user,
        onEdit: () {
          Navigator.pop(context);
          showDialog(context: context, builder: (_) => EditUserDialog(user: user, onSave: (d) async => notifier.updateUser(user.id, d)));
        },
        onChangePassword: () {
          Navigator.pop(context);
          showDialog(context: context, builder: (_) => ChangePasswordDialog(userId: user.id, onSave: (p) async => notifier.updatePassword(user.id, p)));
        },
        onDelete: () {
          Navigator.pop(context);
          showDialog(context: context, builder: (_) => DeleteConfirmationDialog(user: user, onConfirm: () async => notifier.deleteUser(user.id)));
        },
      ),
    );
  }

  Color _roleColor(String role) {
    switch (role.toLowerCase()) {
      case 'admin': return const Color(0xFFDC2626);
      case 'client': return const Color(0xFF22C55E);
      case 'home_owner': return const Color(0xFF3B82F6);
      case 'operations': return const Color(0xFFF59E0B);
      case 'finance': return const Color(0xFF8B5CF6);
      case 'support': return const Color(0xFF14B8A6);
      default: return const Color(0xFF9CA3AF);
    }
  }
}

class _Badge extends StatelessWidget {
  final String label;
  final Color color;
  const _Badge({required this.label, required this.color});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
    decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(5)),
    child: Text(label, style: TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: color)),
  );
}

class _ExpandedDetails extends StatelessWidget {
  final UserModel user;
  final UserManagementNotifier notifier;
  const _ExpandedDetails({required this.user, required this.notifier});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Divider(color: Color(0xFFF3EFE6)),
          const SizedBox(height: 8),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            childAspectRatio: 3.2,
            crossAxisSpacing: 16,
            mainAxisSpacing: 6,
            children: [
              _Detail('Phone', user.phoneNumber),
              _Detail('Country', user.country),
              _Detail('Language', user.language),
              _Detail('Address', user.address1),
            ],
          ),
        ],
      ),
    );
  }
}

class _Detail extends StatelessWidget {
  final String label, value;
  const _Detail(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: Color(0xFF9CA3AF))),
        Text(value.isNotEmpty ? value : '—', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: _brand)),
      ],
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  final UserManagementState state;
  final WidgetRef ref;
  const _ErrorBanner({required this.state, required this.ref});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      color: const Color(0xFFFEF2F2),
      child: Row(
        children: [
          const Icon(Icons.error_outline_rounded, size: 16, color: Color(0xFFDC2626)),
          const SizedBox(width: 10),
          Expanded(child: Text(state.error!, style: const TextStyle(fontSize: 12, color: Color(0xFFDC2626)))),
          IconButton(icon: const Icon(Icons.close_rounded, color: Color(0xFFDC2626)), onPressed: () => ref.read(userManagementProvider.notifier).state = state.copyWith(error: null)),
        ],
      ),
    );
  }
}

class _SearchBanner extends StatelessWidget {
  final String query;
  final int count;
  const _SearchBanner({required this.query, required this.count});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      color: const Color(0xFFF5F0E8),
      child: Row(
        children: [
          const Icon(Icons.search_rounded, size: 14, color: _brand),
          const SizedBox(width: 8),
          Text('"$query"  ·  $count result${count == 1 ? '' : 's'}', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: _brand)),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final UserManagementState state;
  final String query;
  final VoidCallback onAdd;
  const _EmptyState({required this.state, required this.query, required this.onAdd});

  @override
  Widget build(BuildContext context) {
    if (state.isLoading) return const Center(child: CircularProgressIndicator(color: _brand));
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(query.isNotEmpty ? Icons.search_off_rounded : Icons.people_outline_rounded, size: 48, color: const Color(0xFFD1D5DB)),
          const SizedBox(height: 14),
          Text(query.isNotEmpty ? 'No results for "$query"' : 'No users yet', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF6B7280))),
          const SizedBox(height: 4),
          const Text('Try adjusting your search or filters', style: TextStyle(fontSize: 12, color: Color(0xFF9CA3AF))),
          if (query.isEmpty) ...[
            const SizedBox(height: 20),
            GestureDetector(
              onTap: onAdd,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                decoration: BoxDecoration(color: _brand, borderRadius: BorderRadius.circular(10)),
                child: const Text('Add First User', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.white)),
              ),
            ),
          ],
        ],
      ),
    );
  }
}