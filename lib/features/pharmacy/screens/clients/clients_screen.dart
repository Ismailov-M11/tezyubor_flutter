import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../shared/widgets/empty_state.dart';
import '../../../../shared/widgets/loading_overlay.dart';
import '../../providers/clients_provider.dart';

class ClientsScreen extends ConsumerStatefulWidget {
  const ClientsScreen({super.key});

  @override
  ConsumerState<ClientsScreen> createState() => _ClientsScreenState();
}

class _ClientsScreenState extends ConsumerState<ClientsScreen> {
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(clientsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Клиенты'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(56),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Поиск по номеру или имени',
                prefixIcon: const Icon(Icons.search, size: 20),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, size: 18),
                        onPressed: () {
                          _searchController.clear();
                          ref.read(clientsProvider.notifier).load();
                        },
                      )
                    : null,
                isDense: true,
              ),
              onChanged: (v) {
                setState(() {});
                if (v.length >= 3 || v.isEmpty) {
                  ref.read(clientsProvider.notifier).load(search: v);
                }
              },
            ),
          ),
        ),
      ),
      body: state.isLoading && state.clients.isEmpty
          ? const CenteredLoader()
          : state.error != null && state.clients.isEmpty
              ? AppErrorWidget(
                  message: state.error!,
                  onRetry: () => ref.read(clientsProvider.notifier).load(),
                )
              : state.clients.isEmpty
                  ? const EmptyState(
                      icon: Icons.people_outline,
                      title: 'Нет клиентов',
                      subtitle: 'Клиенты появятся после первых заказов',
                    )
                  : RefreshIndicator(
                      onRefresh: () =>
                          ref.read(clientsProvider.notifier).load(),
                      color: AppColors.primary,
                      child: ListView.separated(
                        padding: const EdgeInsets.all(16),
                        itemCount: state.clients.length,
                        separatorBuilder: (_, __) =>
                            const SizedBox(height: 8),
                        itemBuilder: (_, i) {
                          final c = state.clients[i];
                          return Card(
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor:
                                    AppColors.primary.withOpacity(0.1),
                                child: Text(
                                  c.name?.isNotEmpty == true
                                      ? c.name![0].toUpperCase()
                                      : c.phone[0],
                                  style: const TextStyle(
                                    color: AppColors.primary,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              title: Text(
                                c.name ?? c.phone,
                                style: Theme.of(context).textTheme.bodyMedium
                                    ?.copyWith(fontWeight: FontWeight.w600),
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  if (c.name != null)
                                    Text(c.phone,
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodySmall),
                                  if (c.lastAddress != null)
                                    Text(
                                      c.lastAddress!,
                                      style:
                                          Theme.of(context).textTheme.bodySmall,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                ],
                              ),
                              trailing: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    '${c.ordersCount}',
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleSmall
                                        ?.copyWith(color: AppColors.primary),
                                  ),
                                  Text(
                                    'заказов',
                                    style: Theme.of(context).textTheme.bodySmall,
                                  ),
                                ],
                              ),
                              isThreeLine: c.lastAddress != null,
                            ),
                          );
                        },
                      ),
                    ),
    );
  }
}
