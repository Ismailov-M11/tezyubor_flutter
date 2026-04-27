import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../shared/widgets/loading_overlay.dart';
import '../../../auth/providers/auth_provider.dart';
import '../../providers/pharmacy_provider.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileState = ref.watch(pharmacyProfileProvider);
    final themeMode = ref.watch(themeModeProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final profile = profileState.profile;

    return Scaffold(
      appBar: AppBar(title: const Text('Настройки')),
      body: profileState.isLoading && profile == null
          ? const CenteredLoader()
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // Profile card
                if (profile != null) _ProfileCard(profile: profile),
                const SizedBox(height: 16),

                // Subscription warning
                if (profile != null && profile.isSubscriptionExpiringSoon)
                  _SubscriptionWarning(
                    daysLeft: profile.daysUntilExpiry ?? 0,
                  ),

                if (profile != null && profile.isSubscriptionExpiringSoon)
                  const SizedBox(height: 16),

                // Settings section
                _SettingsSection(
                  title: 'Внешний вид',
                  children: [
                    _SettingsTile(
                      icon: Icons.dark_mode_outlined,
                      title: 'Тёмная тема',
                      trailing: Switch(
                        value: themeMode == ThemeMode.dark,
                        onChanged: (_) =>
                            ref.read(themeModeProvider.notifier).toggle(),
                        activeColor: AppColors.primary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                _SettingsSection(
                  title: 'Аккаунт',
                  children: [
                    _SettingsTile(
                      icon: Icons.person_outline,
                      title: 'Профиль аптеки',
                      onTap: () {
                        // TODO: Edit profile
                      },
                    ),
                    _SettingsTile(
                      icon: Icons.lock_outline,
                      title: 'Изменить пароль',
                      onTap: () {
                        // TODO: Change password
                      },
                    ),
                    _SettingsTile(
                      icon: Icons.credit_card_outlined,
                      title: 'Подписка',
                      subtitle: profile?.subscriptionExpiry != null
                          ? 'До ${_formatDate(profile!.subscriptionExpiry!)}'
                          : null,
                      onTap: () {
                        // TODO: Subscription page
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                _SettingsSection(
                  title: 'Приложение',
                  children: [
                    _SettingsTile(
                      icon: Icons.info_outline,
                      title: 'О приложении',
                      subtitle: 'TezyUbor v1.0.0',
                      onTap: () {},
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Logout
                OutlinedButton.icon(
                  onPressed: () => _logout(context, ref),
                  icon: const Icon(Icons.logout, color: AppColors.error),
                  label: const Text(
                    'Выйти',
                    style: TextStyle(color: AppColors.error),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: AppColors.error),
                    minimumSize: const Size(double.infinity, 48),
                  ),
                ),
              ],
            ),
    );
  }

  String _formatDate(String iso) {
    try {
      final dt = DateTime.parse(iso);
      return '${dt.day.toString().padLeft(2, '0')}.${dt.month.toString().padLeft(2, '0')}.${dt.year}';
    } catch (_) {
      return iso;
    }
  }

  Future<void> _logout(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Выйти из аккаунта?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Отмена'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('Выйти'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await ref.read(authStateProvider.notifier).logout();
    }
  }
}

class _ProfileCard extends StatelessWidget {
  final dynamic profile;

  const _ProfileCard({required this.profile});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            CircleAvatar(
              radius: 28,
              backgroundColor: AppColors.primary.withOpacity(0.15),
              child: Text(
                profile.name.isNotEmpty ? profile.name[0].toUpperCase() : 'A',
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    profile.name as String,
                    style: Theme.of(context)
                        .textTheme
                        .titleMedium
                        ?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  if (profile.login != null)
                    Text(
                      profile.login as String,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  if (profile.phone != null)
                    Text(
                      profile.phone as String,
                      style: Theme.of(context).textTheme.bodySmall,
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

class _SubscriptionWarning extends StatelessWidget {
  final int daysLeft;

  const _SubscriptionWarning({required this.daysLeft});

  @override
  Widget build(BuildContext context) {
    final isExpired = daysLeft <= 0;
    final isCritical = daysLeft <= 7;
    final color = isExpired || isCritical ? AppColors.error : AppColors.warning;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(Icons.warning_amber, color: color),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              isExpired
                  ? 'Подписка истекла'
                  : 'Подписка истекает через $daysLeft дн.',
              style: TextStyle(color: color, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}

class _SettingsSection extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const _SettingsSection({required this.title, required this.children});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Text(
            title,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.5,
                ),
          ),
        ),
        Card(
          child: Column(
            children: children
                .asMap()
                .entries
                .map((e) => Column(
                      children: [
                        e.value,
                        if (e.key < children.length - 1)
                          Divider(
                            height: 1,
                            indent: 52,
                            color: Theme.of(context)
                                .colorScheme
                                .outline
                                .withOpacity(0.5),
                          ),
                      ],
                    ))
                .toList(),
          ),
        ),
      ],
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;

  const _SettingsTile({
    required this.icon,
    required this.title,
    this.subtitle,
    this.trailing,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: AppColors.primary, size: 22),
      title: Text(title, style: Theme.of(context).textTheme.bodyMedium),
      subtitle: subtitle != null
          ? Text(subtitle!, style: Theme.of(context).textTheme.bodySmall)
          : null,
      trailing: trailing ??
          (onTap != null
              ? Icon(
                  Icons.chevron_right,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                )
              : null),
      onTap: onTap,
    );
  }
}
