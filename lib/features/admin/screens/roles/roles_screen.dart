import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/network/api_client.dart';
import '../../../../shared/widgets/empty_state.dart';
import '../../../../shared/widgets/loading_overlay.dart';
import '../../models/admin_models.dart';
import '../../providers/admin_provider.dart';

const _allPermissions = [
  'orders:view',
  'orders:create',
  'orders:delete',
  'orders:confirm',
  'orders:cancel',
  'pharmacies:view',
  'analytics:view',
  'clients:view',
  'activations:view',
];

class RolesScreen extends ConsumerWidget {
  const RolesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(adminRolesProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Роли'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.read(adminRolesProvider.notifier).load(),
          ),
        ],
      ),
      body: state.isLoading && state.roles.isEmpty
          ? const CenteredLoader()
          : state.error != null && state.roles.isEmpty
              ? AppErrorWidget(
                  message: state.error!,
                  onRetry: () => ref.read(adminRolesProvider.notifier).load(),
                )
              : state.roles.isEmpty
                  ? EmptyState(
                      icon: Icons.manage_accounts_outlined,
                      title: 'Нет ролей',
                      subtitle: 'Создайте первую роль',
                      action: ElevatedButton.icon(
                        onPressed: () => _showCreateSheet(context),
                        icon: const Icon(Icons.add),
                        label: const Text('Создать роль'),
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: () =>
                          ref.read(adminRolesProvider.notifier).load(),
                      color: AppColors.primary,
                      child: ListView.separated(
                        padding: const EdgeInsets.all(16),
                        itemCount: state.roles.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 10),
                        itemBuilder: (_, i) =>
                            _RoleCard(role: state.roles[i]),
                      ),
                    ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showCreateSheet(context),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('Новая роль'),
      ),
    );
  }

  void _showCreateSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => const _CreateRoleSheet(),
    );
  }
}

class _RoleCard extends ConsumerWidget {
  final AdminRole role;

  const _RoleCard({required this.role});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
                  child: Text(role.name,
                      style: Theme.of(context).textTheme.titleSmall),
                ),
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
            const SizedBox(height: 10),
            if (role.permissions.isEmpty)
              Text('Нет прав',
                  style: Theme.of(context).textTheme.bodySmall)
            else
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: role.permissions
                    .map((p) => _PermChip(permission: p))
                    .toList(),
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _delete(BuildContext context, WidgetRef ref) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Удалить роль?'),
        content: Text('Роль "${role.name}" будет удалена.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Отмена'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('Удалить'),
          ),
        ],
      ),
    );
    if (ok == true) {
      await ref.read(adminRolesProvider.notifier).delete(role.id);
    }
  }
}

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

class _CreateRoleSheet extends ConsumerStatefulWidget {
  const _CreateRoleSheet();

  @override
  ConsumerState<_CreateRoleSheet> createState() => _CreateRoleSheetState();
}

class _CreateRoleSheetState extends ConsumerState<_CreateRoleSheet> {
  final _nameController = TextEditingController();
  final _selected = <String>{};
  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_nameController.text.trim().isEmpty) return;
    setState(() => _isLoading = true);
    try {
      await ApiClient.instance.post(
        '/admin/roles',
        data: {
          'name': _nameController.text.trim(),
          'permissions': _selected.toList(),
        },
      );
      await ref.read(adminRolesProvider.notifier).load();
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Роль создана')),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Ошибка создания роли')),
        );
      }
    }
    if (mounted) setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        20,
        20,
        20,
        MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text('Новая роль',
                  style: Theme.of(context).textTheme.titleLarge),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _nameController,
            decoration: const InputDecoration(
              labelText: 'Название роли',
              prefixIcon: Icon(Icons.shield_outlined),
            ),
          ),
          const SizedBox(height: 16),
          Text('Права доступа',
              style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _allPermissions.map((p) {
              final isSelected = _selected.contains(p);
              return FilterChip(
                label: Text(p,
                    style: TextStyle(
                      fontSize: 12,
                      color: isSelected ? Colors.white : null,
                    )),
                selected: isSelected,
                onSelected: (v) => setState(
                    () => v ? _selected.add(p) : _selected.remove(p)),
                selectedColor: AppColors.primary,
                checkmarkColor: Colors.white,
                showCheckmark: false,
              );
            }).toList(),
          ),
          const SizedBox(height: 20),
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
                  : const Text('Создать роль'),
            ),
          ),
        ],
      ),
    );
  }
}
