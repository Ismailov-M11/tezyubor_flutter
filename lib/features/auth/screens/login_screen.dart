import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_constants.dart';
import '../../../shared/widgets/custom_button.dart';
import '../../../shared/widgets/custom_text_field.dart';
import '../models/auth_models.dart';
import '../providers/auth_provider.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _loginController = TextEditingController();
  final _passwordController = TextEditingController();
  final _passwordFocus = FocusNode();

  int _logoTapCount = 0;

  @override
  void dispose() {
    _loginController.dispose();
    _passwordController.dispose();
    _passwordFocus.dispose();
    super.dispose();
  }

  void _onLogoTap() {
    _logoTapCount++;
    if (_logoTapCount >= AppConstants.logoTapCountToSwitchEnv) {
      _logoTapCount = 0;
      ref.read(environmentProvider.notifier).toggle();
      final env = ref.read(environmentProvider);
      final envName = env == AppEnvironment.admin ? 'Администратор' : 'Аптека';
      _loginController.clear();
      _passwordController.clear();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Окружение: $envName'),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final env = ref.read(environmentProvider);
    final notifier = ref.read(authStateProvider.notifier);
    bool success;

    if (env == AppEnvironment.admin) {
      success = await notifier.loginAdmin(
        email: _loginController.text.trim(),
        password: _passwordController.text,
      );
    } else {
      success = await notifier.loginPharmacy(
        login: _loginController.text.trim(),
        password: _passwordController.text,
      );
    }

    if (success && mounted) {
      final user = ref.read(authStateProvider).user;
      if (user?.role == UserRole.admin) {
        context.go('/admin/orders');
      } else {
        context.go('/pharmacy/orders');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final env = ref.watch(environmentProvider);
    final authState = ref.watch(authStateProvider);
    final themeMode = ref.watch(themeModeProvider);
    final isAdmin = env == AppEnvironment.admin;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Theme toggle
                Align(
                  alignment: Alignment.topRight,
                  child: IconButton(
                    icon: Icon(
                      isDark ? Icons.light_mode : Icons.dark_mode,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                    onPressed: () =>
                        ref.read(themeModeProvider.notifier).toggle(),
                  ),
                ),

                const SizedBox(height: 24),

                // Logo with tap detector for env switch
                GestureDetector(
                  onTap: _onLogoTap,
                  child: Column(
                    children: [
                      Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Icon(
                          Icons.local_pharmacy,
                          size: 44,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'TezyUbor',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Быстрая доставка лекарств',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 32),

                // Environment badge
                AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                  decoration: BoxDecoration(
                    color: isAdmin
                        ? AppColors.info.withOpacity(0.15)
                        : AppColors.primary.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isAdmin
                          ? AppColors.info.withOpacity(0.4)
                          : AppColors.primary.withOpacity(0.3),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        isAdmin ? Icons.admin_panel_settings : Icons.storefront,
                        size: 14,
                        color: isAdmin ? AppColors.info : AppColors.primary,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        isAdmin ? 'Администратор' : 'Аптека',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: isAdmin ? AppColors.info : AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 28),

                // Title
                Text(
                  isAdmin ? 'Вход для администратора' : 'Вход для аптеки',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 6),
                Text(
                  isAdmin
                      ? 'Введите email и пароль администратора'
                      : 'Введите логин и пароль аптеки',
                  style: Theme.of(context).textTheme.bodySmall,
                ),

                const SizedBox(height: 28),

                // Error
                if (authState.error != null) ...[
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.error.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                          color: AppColors.error.withOpacity(0.3)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.error_outline,
                            color: AppColors.error, size: 18),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            authState.error!,
                            style: const TextStyle(
                                color: AppColors.error, fontSize: 13),
                          ),
                        ),
                        GestureDetector(
                          onTap: () =>
                              ref.read(authStateProvider.notifier).clearError(),
                          child: const Icon(Icons.close,
                              color: AppColors.error, size: 16),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                // Login field
                CustomTextField(
                  label: isAdmin ? 'Email' : 'Логин',
                  hint: isAdmin ? 'admin@tezyubor.uz' : 'pharmacy_login',
                  controller: _loginController,
                  keyboardType: isAdmin
                      ? TextInputType.emailAddress
                      : TextInputType.text,
                  textInputAction: TextInputAction.next,
                  prefixIcon: Icon(isAdmin ? Icons.email_outlined : Icons.person_outline),
                  onSubmitted: (_) =>
                      FocusScope.of(context).requestFocus(_passwordFocus),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) {
                      return isAdmin
                          ? 'Введите email'
                          : 'Введите логин';
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 16),

                // Password field
                CustomTextField(
                  label: 'Пароль',
                  controller: _passwordController,
                  isPassword: true,
                  focusNode: _passwordFocus,
                  textInputAction: TextInputAction.done,
                  prefixIcon: const Icon(Icons.lock_outline),
                  onSubmitted: (_) => _submit(),
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Введите пароль';
                    return null;
                  },
                ),

                const SizedBox(height: 28),

                // Submit button
                CustomButton(
                  label: 'Войти',
                  isLoading: authState.isLoading,
                  onPressed: _submit,
                ),

                const SizedBox(height: 40),

                // Hint for env switch
                Text(
                  'Нажмите на лого 5 раз, чтобы сменить окружение',
                  style: Theme.of(context)
                      .textTheme
                      .bodySmall
                      ?.copyWith(fontSize: 10),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
