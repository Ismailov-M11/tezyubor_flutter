import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/l10n/app_l10n.dart';
import '../../../../shared/widgets/empty_state.dart';
import '../../../../shared/widgets/loading_overlay.dart';
import '../../models/admin_models.dart';
import '../../providers/admin_provider.dart';

const _allPermissions = [
  'orders:view',
  'orders:create',
  'orders:confirm',
  'orders:cancel',
  'orders:delete',
  'pharmacies:view',
  'pharmacies:create',
  'pharmacies:edit',
  'pharmacies:delete',
  'clients:view',
  'analytics:view',
  'activations:view',
];

// ─── Main screen ──────────────────────────────────────────────────────────────

class RolesScreen extends ConsumerStatefulWidget {
  const RolesScreen({super.key});

  @override
  ConsumerState<RolesScreen> createState() => _RolesScreenState();
}

class _RolesScreenState extends ConsumerState<RolesScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.adminRolesTitle),
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(text: l10n.adminRolesTab),
            Tab(text: l10n.adminUsersTab),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [
          _RolesTab(),
          _UsersTab(),
        ],
      ),
    );
  }
}

// ─── Roles Tab ────────────────────────────────────────────────────────────────

class _RolesTab extends ConsumerWidget {
  const _RolesTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final state = ref.watch(adminRolesProvider);

    if (state.isLoading && state.roles.isEmpty) return const CenteredLoader();
    if (state.error != null && state.roles.isEmpty) {
      return AppErrorWidget(
        message: state.error!,
        onRetry: () => ref.read(adminRolesProvider.notifier).load(),
      );
    }
    if (state.roles.isEmpty) {
      return EmptyState(
        icon: Icons.manage_accounts_outlined,
        title: l10n.adminNoRoles,
        subtitle: l10n.adminNoRolesSub,
        action: ElevatedButton.icon(
          onPressed: () => _showCreateSheet(context, null),
          icon: const Icon(Icons.add),
          label: Text(l10n.adminCreateRole),
        ),
      );
    }

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: () => ref.read(adminRolesProvider.notifier).load(),
        color: AppColors.primary,
        child: ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: state.roles.length,
          separatorBuilder: (_, __) => const SizedBox(height: 10),
          itemBuilder: (_, i) => _RoleCard(role: state.roles[i]),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showCreateSheet(context, null),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: Text(l10n.adminCreateRole),
      ),
    );
  }

  void _showCreateSheet(BuildContext context, AdminRole? role) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _RoleFormSheet(role: role),
    );
  }
}

// ─── Role Card ────────────────────────────────────────────────────────────────

class _RoleCard extends ConsumerWidget {
  final AdminRole role;

  const _RoleCard({required this.role});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.shield_outlined,
                    size: 18, color: AppColors.primary),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(role.name,
                          style: Theme.of(context).textTheme.titleSmall),
                      Text(
                        '${role.usersCount} ${l10n.adminUsersTab.toLowerCase()} · '
                        '${role.permissions.length} ${l10n.adminPermissions.toLowerCase()}',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.edit_outlined, size: 18),
                  color: AppColors.primary,
                  style: IconButton.styleFrom(
                    backgroundColor: AppColors.primary.withValues(alpha: 0.08),
                    padding: const EdgeInsets.all(6),
                    minimumSize: const Size(32, 32),
                  ),
                  onPressed: () => _showEditSheet(context, ref),
                ),
                const SizedBox(width: 6),
                IconButton(
                  icon: const Icon(Icons.delete_outline, size: 18),
                  color: AppColors.error,
                  style: IconButton.styleFrom(
                    backgroundColor: AppColors.error.withValues(alpha: 0.08),
                    padding: const EdgeInsets.all(6),
                    minimumSize: const Size(32, 32),
                  ),
                  onPressed: () => _delete(context, ref),
                ),
              ],
            ),
            if (role.permissions.isNotEmpty) ...[
              const SizedBox(height: 10),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: role.permissions
                    .map((p) => _PermChip(
                          permission: l10n.permissionLabel(p),
                        ))
                    .toList(),
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _showEditSheet(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _RoleFormSheet(role: role),
    );
  }

  Future<void> _delete(BuildContext context, WidgetRef ref) async {
    final l10n = context.l10n;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.adminDeleteRole),
        content: Text('"${role.name}"'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: Text(l10n.yes),
          ),
        ],
      ),
    );
    if (ok == true && context.mounted) {
      final success =
          await ref.read(adminRolesProvider.notifier).delete(role.id);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(
                  success ? context.l10n.adminRoleDeleted : context.l10n.error)),
        );
      }
    }
  }
}

// ─── Permission chip ──────────────────────────────────────────────────────────

class _PermChip extends StatelessWidget {
  final String permission;

  const _PermChip({required this.permission});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        permission,
        style: const TextStyle(
          fontSize: 11,
          color: AppColors.primary,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}

// ─── Role Form Sheet ──────────────────────────────────────────────────────────

class _RoleFormSheet extends ConsumerStatefulWidget {
  final AdminRole? role;

  const _RoleFormSheet({this.role});

  @override
  ConsumerState<_RoleFormSheet> createState() => _RoleFormSheetState();
}

class _RoleFormSheetState extends ConsumerState<_RoleFormSheet> {
  late final TextEditingController _nameController;
  late final Set<String> _selected;
  bool _isLoading = false;

  bool get _isEdit => widget.role != null;

  @override
  void initState() {
    super.initState();
    _nameController =
        TextEditingController(text: widget.role?.name ?? '');
    _selected = {...widget.role?.permissions ?? []};
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final l10n = context.l10n;
    if (_nameController.text.trim().isEmpty) return;
    setState(() => _isLoading = true);

    bool success;
    if (_isEdit) {
      success = await ref.read(adminRolesProvider.notifier).update(
            widget.role!.id,
            name: _nameController.text.trim(),
            permissions: _selected.toList(),
          );
    } else {
      success = await ref.read(adminRolesProvider.notifier).create(
            _nameController.text.trim(),
            _selected.toList(),
          );
    }

    if (mounted) {
      setState(() => _isLoading = false);
      if (success) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_isEdit ? l10n.adminRoleUpdated : l10n.adminRoleCreated),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.error)),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.85,
      maxChildSize: 0.95,
      builder: (ctx, scrollController) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: Column(
          children: [
            const SizedBox(height: 8),
            Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              child: Row(
                children: [
                  Text(
                    _isEdit ? l10n.adminEditRole : l10n.adminCreateRole,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: ListView(
                controller: scrollController,
                padding: const EdgeInsets.all(20),
                children: [
                  TextField(
                    controller: _nameController,
                    decoration: InputDecoration(
                      labelText: l10n.adminRoleName,
                      hintText: l10n.adminRoleNameHint,
                      prefixIcon: const Icon(Icons.shield_outlined),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Text(l10n.adminPermissions,
                          style: Theme.of(context).textTheme.titleSmall),
                      const Spacer(),
                      TextButton(
                        onPressed: () => setState(
                            () => _selected.addAll(_allPermissions)),
                        child: Text(l10n.adminSelectAll,
                            style: const TextStyle(fontSize: 12)),
                      ),
                      TextButton(
                        onPressed: () =>
                            setState(() => _selected.clear()),
                        child: Text(l10n.adminClearAll,
                            style: const TextStyle(fontSize: 12)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _allPermissions.map((p) {
                      final isSelected = _selected.contains(p);
                      return FilterChip(
                        label: Text(
                          l10n.permissionLabel(p),
                          style: TextStyle(
                            fontSize: 12,
                            color: isSelected ? Colors.white : null,
                          ),
                        ),
                        selected: isSelected,
                        onSelected: (v) => setState(
                            () => v ? _selected.add(p) : _selected.remove(p)),
                        selectedColor: AppColors.primary,
                        checkmarkColor: Colors.white,
                        showCheckmark: false,
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _submit,
                      child: _isLoading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: Colors.white),
                            )
                          : Text(l10n.adminSaveRole),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Users Tab ────────────────────────────────────────────────────────────────

class _UsersTab extends ConsumerWidget {
  const _UsersTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final state = ref.watch(adminUsersProvider);
    final rolesState = ref.watch(adminRolesProvider);

    if (state.isLoading && state.users.isEmpty) return const CenteredLoader();
    if (state.error != null && state.users.isEmpty) {
      return AppErrorWidget(
        message: state.error!,
        onRetry: () => ref.read(adminUsersProvider.notifier).load(),
      );
    }
    if (state.users.isEmpty) {
      return EmptyState(
        icon: Icons.people_outline,
        title: l10n.adminNoUsers,
        action: ElevatedButton.icon(
          onPressed: () => _showUserSheet(context, null, rolesState.roles),
          icon: const Icon(Icons.add),
          label: Text(l10n.adminCreateUser),
        ),
      );
    }

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: () => ref.read(adminUsersProvider.notifier).load(),
        color: AppColors.primary,
        child: ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: state.users.length,
          separatorBuilder: (_, __) => const SizedBox(height: 8),
          itemBuilder: (_, i) => _UserCard(
            user: state.users[i],
            roles: rolesState.roles,
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showUserSheet(context, null, rolesState.roles),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: Text(l10n.adminCreateUser),
      ),
    );
  }

  void _showUserSheet(
      BuildContext context, AdminUser? user, List<AdminRole> roles) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _UserFormSheet(user: user, roles: roles),
    );
  }
}

// ─── User Card ────────────────────────────────────────────────────────────────

class _UserCard extends ConsumerWidget {
  final AdminUser user;
  final List<AdminRole> roles;

  const _UserCard({required this.user, required this.roles});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final theme = Theme.of(context);

    return Card(
      child: ListTile(
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
        leading: CircleAvatar(
          backgroundColor: user.isActive
              ? AppColors.primary.withValues(alpha: 0.1)
              : Colors.grey.withValues(alpha: 0.1),
          child: Text(
            user.name.isNotEmpty ? user.name[0].toUpperCase() : '?',
            style: TextStyle(
              color: user.isActive ? AppColors.primary : Colors.grey,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        title: Text(user.name,
            style: theme.textTheme.bodyMedium
                ?.copyWith(fontWeight: FontWeight.w600)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(user.email, style: theme.textTheme.bodySmall),
            if (user.roles.isNotEmpty)
              Wrap(
                spacing: 4,
                children: user.roles
                    .map((r) => Chip(
                          label: Text(r.name,
                              style: const TextStyle(fontSize: 10)),
                          padding: EdgeInsets.zero,
                          visualDensity: VisualDensity.compact,
                          materialTapTargetSize:
                              MaterialTapTargetSize.shrinkWrap,
                          backgroundColor:
                              AppColors.primary.withValues(alpha: 0.1),
                          labelStyle:
                              const TextStyle(color: AppColors.primary),
                          side: BorderSide.none,
                        ))
                    .toList(),
              ),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: user.isActive
                    ? AppColors.success.withValues(alpha: 0.1)
                    : AppColors.error.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                user.isActive ? l10n.adminUserActive : l10n.adminUserInactive,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color:
                      user.isActive ? AppColors.success : AppColors.error,
                ),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.edit_outlined, size: 18),
              onPressed: () => _showEditSheet(context, ref),
            ),
          ],
        ),
        isThreeLine: user.roles.isNotEmpty,
      ),
    );
  }

  void _showEditSheet(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _UserFormSheet(user: user, roles: roles),
    );
  }
}

// ─── User Form Sheet ──────────────────────────────────────────────────────────

class _UserFormSheet extends ConsumerStatefulWidget {
  final AdminUser? user;
  final List<AdminRole> roles;

  const _UserFormSheet({this.user, required this.roles});

  @override
  ConsumerState<_UserFormSheet> createState() => _UserFormSheetState();
}

class _UserFormSheetState extends ConsumerState<_UserFormSheet> {
  late final TextEditingController _nameCtrl;
  late final TextEditingController _emailCtrl;
  final _passwordCtrl = TextEditingController();
  late bool _isActive;
  late Set<String> _selectedRoleIds;
  bool _isLoading = false;
  bool _showPassword = false;

  bool get _isEdit => widget.user != null;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.user?.name ?? '');
    _emailCtrl = TextEditingController(text: widget.user?.email ?? '');
    _isActive = widget.user?.isActive ?? true;
    _selectedRoleIds = {
      ...widget.user?.roles.map((r) => r.id).toList() ?? []
    };
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final l10n = context.l10n;
    if (_nameCtrl.text.trim().isEmpty || _emailCtrl.text.trim().isEmpty) return;
    if (!_isEdit && _passwordCtrl.text.trim().length < 6) return;

    setState(() => _isLoading = true);

    bool success;
    if (_isEdit) {
      success = await ref.read(adminUsersProvider.notifier).update(
            widget.user!.id,
            name: _nameCtrl.text.trim(),
            email: _emailCtrl.text.trim(),
            password: _passwordCtrl.text.trim().isEmpty
                ? null
                : _passwordCtrl.text.trim(),
            roleIds: _selectedRoleIds.toList(),
            isActive: _isActive,
          );
    } else {
      success = await ref.read(adminUsersProvider.notifier).create(
            name: _nameCtrl.text.trim(),
            email: _emailCtrl.text.trim(),
            password: _passwordCtrl.text.trim(),
            roleIds: _selectedRoleIds.toList(),
            isActive: _isActive,
          );
    }

    if (mounted) {
      setState(() => _isLoading = false);
      if (success) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(
                  _isEdit ? l10n.adminUserUpdated : l10n.adminUserCreated)),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.error)),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.9,
      maxChildSize: 0.95,
      builder: (ctx, scrollCtrl) => Padding(
        padding:
            EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
        child: Column(
          children: [
            const SizedBox(height: 8),
            Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              child: Row(
                children: [
                  Text(
                    _isEdit ? l10n.adminEditUser : l10n.adminCreateUser,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: ListView(
                controller: scrollCtrl,
                padding: const EdgeInsets.all(20),
                children: [
                  TextField(
                    controller: _nameCtrl,
                    decoration: InputDecoration(
                      labelText: l10n.adminProfileName,
                      prefixIcon: const Icon(Icons.person_outline),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _emailCtrl,
                    keyboardType: TextInputType.emailAddress,
                    decoration: InputDecoration(
                      labelText: l10n.adminUserEmail,
                      prefixIcon: const Icon(Icons.email_outlined),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _passwordCtrl,
                    obscureText: !_showPassword,
                    decoration: InputDecoration(
                      labelText: _isEdit
                          ? '${l10n.passwordLbl} (${l10n.adminPasswordLeaveBlank})'
                          : l10n.passwordLbl,
                      hintText: _isEdit ? '••••••' : l10n.adminPasswordMin,
                      prefixIcon: const Icon(Icons.lock_outline),
                      suffixIcon: IconButton(
                        icon: Icon(_showPassword
                            ? Icons.visibility_off_outlined
                            : Icons.visibility_outlined),
                        onPressed: () =>
                            setState(() => _showPassword = !_showPassword),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Active toggle
                  SwitchListTile(
                    title: Text(l10n.adminActiveAccount),
                    value: _isActive,
                    onChanged: (v) => setState(() => _isActive = v),
                    activeTrackColor: AppColors.primary,
                    contentPadding: EdgeInsets.zero,
                  ),
                  const SizedBox(height: 12),
                  Text(l10n.adminUserRoles,
                      style: Theme.of(context).textTheme.titleSmall),
                  const SizedBox(height: 8),
                  if (widget.roles.isEmpty)
                    Text(l10n.adminNoAvailableRoles,
                        style: Theme.of(context).textTheme.bodySmall)
                  else
                    ...widget.roles.map((role) => CheckboxListTile(
                          title: Text(role.name),
                          subtitle: Text(
                            '${role.permissions.length} ${l10n.adminPermissions.toLowerCase()}',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                          value: _selectedRoleIds.contains(role.id),
                          onChanged: (v) => setState(() => v == true
                              ? _selectedRoleIds.add(role.id)
                              : _selectedRoleIds.remove(role.id)),
                          activeColor: AppColors.primary,
                          controlAffinity: ListTileControlAffinity.leading,
                          contentPadding: EdgeInsets.zero,
                        )),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _submit,
                      child: _isLoading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: Colors.white),
                            )
                          : Text(l10n.save),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
