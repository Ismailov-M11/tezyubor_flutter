import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../shared/widgets/empty_state.dart';
import '../../../../shared/widgets/loading_overlay.dart';
import '../../providers/admin_provider.dart';

class ActivationsScreen extends ConsumerWidget {
  const ActivationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(adminActivationsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Активации'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () =>
                ref.read(adminActivationsProvider.notifier).load(),
          ),
        ],
      ),
      body: state.isLoading && state.activations.isEmpty
          ? const CenteredLoader()
          : state.error != null && state.activations.isEmpty
              ? AppErrorWidget(
                  message: state.error!,
                  onRetry: () =>
                      ref.read(adminActivationsProvider.notifier).load(),
                )
              : state.activations.isEmpty
                  ? const EmptyState(
                      icon: Icons.how_to_reg_outlined,
                      title: 'Нет активаций',
                      subtitle: 'Активации появятся после регистрации магазинов',
                    )
                  : RefreshIndicator(
                      onRefresh: () =>
                          ref.read(adminActivationsProvider.notifier).load(),
                      color: AppColors.primary,
                      child: ListView.separated(
                        padding: const EdgeInsets.all(16),
                        itemCount: state.activations.length,
                        separatorBuilder: (_, __) =>
                            const SizedBox(height: 8),
                        itemBuilder: (_, i) {
                          final a = state.activations[i];
                          return Card(
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor: a.isActive
                                    ? AppColors.success.withValues(alpha: 0.1)
                                    : AppColors.error.withValues(alpha: 0.1),
                                child: Icon(
                                  a.isActive
                                      ? Icons.check_circle_outline
                                      : Icons.cancel_outlined,
                                  color: a.isActive
                                      ? AppColors.success
                                      : AppColors.error,
                                  size: 20,
                                ),
                              ),
                              title: Text(
                                a.pharmacyName,
                                style: Theme.of(context)
                                    .textTheme
                                    .bodyMedium
                                    ?.copyWith(fontWeight: FontWeight.w600),
                              ),
                              subtitle: Column(
                                crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                children: [
                                  if (a.createdByName != null)
                                    Text(
                                      'Создал: ${a.createdByName}',
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodySmall,
                                    ),
                                  Text(
                                    _formatDate(a.createdAt),
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodySmall,
                                  ),
                                ],
                              ),
                              trailing: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: a.isActive
                                      ? AppColors.success.withValues(alpha: 0.1)
                                      : AppColors.error.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  a.isActive ? 'Активна' : 'Неактивна',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: a.isActive
                                        ? AppColors.success
                                        : AppColors.error,
                                  ),
                                ),
                              ),
                              isThreeLine: a.createdByName != null,
                            ),
                          );
                        },
                      ),
                    ),
    );
  }

  String _formatDate(String iso) {
    try {
      final dt = DateTime.parse(iso).toLocal();
      return '${dt.day.toString().padLeft(2, '0')}.${dt.month.toString().padLeft(2, '0')}.${dt.year}';
    } catch (_) {
      return iso;
    }
  }
}
