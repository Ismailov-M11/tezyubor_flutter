import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/l10n/app_l10n.dart';
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
      final envName = env == AppEnvironment.admin ? 'Admin' : 'App';
      _loginController.clear();
      _passwordController.clear();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(envName),
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
    final l10n = context.l10n;
    final env = ref.watch(environmentProvider);
    final authState = ref.watch(authStateProvider);
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
                      SvgPicture.asset(
                        'assets/images/logo.svg',
                        width: 80,
                        height: 80,
                      ),
                      const SizedBox(height: 12),
                      RichText(
                        text: TextSpan(
                          style: const TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -1,
                          ),
                          children: [
                            TextSpan(
                              text: 'tez',
                              style: TextStyle(
                                color: isDark ? Colors.white : const Color(0xFF1a1a18),
                              ),
                            ),
                            const TextSpan(
                              text: 'yubor',
                              style: TextStyle(color: AppColors.primary),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        l10n.quickDelivery,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),


                const SizedBox(height: 28),

                // Title
                Text(
                  isAdmin ? l10n.adminLoginTitle : l10n.loginTitle,
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 6),
                Text(
                  l10n.loginHint,
                  style: Theme.of(context).textTheme.bodySmall,
                ),

                const SizedBox(height: 28),

                // Error
                if (authState.error != null) ...[
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.error.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                          color: AppColors.error.withValues(alpha: 0.3)),
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
                  label: isAdmin ? 'Email' : l10n.loginFieldLbl,
                  controller: _loginController,
                  keyboardType: isAdmin
                      ? TextInputType.emailAddress
                      : TextInputType.text,
                  textInputAction: TextInputAction.next,
                  prefixIcon: Icon(isAdmin ? Icons.email_outlined : Icons.person_outline),
                  onSubmitted: (_) =>
                      FocusScope.of(context).requestFocus(_passwordFocus),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return l10n.enterLoginHint;
                    return null;
                  },
                ),

                const SizedBox(height: 16),

                // Password field
                CustomTextField(
                  label: l10n.passwordLbl,
                  controller: _passwordController,
                  isPassword: true,
                  focusNode: _passwordFocus,
                  textInputAction: TextInputAction.done,
                  prefixIcon: const Icon(Icons.lock_outline),
                  onSubmitted: (_) => _submit(),
                  validator: (v) {
                    if (v == null || v.isEmpty) return l10n.enterPasswordHint;
                    return null;
                  },
                ),

                const SizedBox(height: 28),

                // Submit button
                CustomButton(
                  label: l10n.loginBtn,
                  isLoading: authState.isLoading,
                  onPressed: _submit,
                ),

                const SizedBox(height: 40),

                const SizedBox(height: 8),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
