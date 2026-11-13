import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimens.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/utils/app_snackbar.dart';
import '../../../core/widgets/custom_button.dart';
import '../../../core/widgets/custom_text_field.dart';
import '../data/auth_repository.dart';
import '../providers/auth_provider.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _autofillDemo(String email) {
    setState(() {
      _emailController.text = email;
      _passwordController.text = 'password123';
    });
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final success = await ref.read(authStateProvider.notifier).signIn(
          _emailController.text,
          _passwordController.text,
        );

    if (!success && mounted) {
      final error = ref.read(authStateProvider).errorMessage;
      AppSnackBar.showError(context, error ?? AppStrings.genericError);
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authStateProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppDimens.space24),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Brand Icon / Header
                  Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      color: AppColors.primarySurface,
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColors.primaryLight, width: 2),
                    ),
                    child: const Icon(
                      Icons.build_rounded,
                      color: AppColors.primary,
                      size: 36,
                    ),
                  ),
                  const SizedBox(height: AppDimens.space16),

                  Text(
                    AppStrings.appName,
                    style: AppTextStyles.h1.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w800,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: AppDimens.space4),
                  Text(
                    AppStrings.appTagline,
                    style: AppTextStyles.bodyMedium,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: AppDimens.space32),

                  // Login Card
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(AppDimens.cardPadding),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            AppStrings.loginTitle,
                            style: AppTextStyles.h2,
                          ),
                          const SizedBox(height: AppDimens.space8),
                          Text(
                            AppStrings.loginSubtitle,
                            style: AppTextStyles.bodyMedium,
                          ),
                          const SizedBox(height: AppDimens.space24),

                          // Email Field
                          CustomTextField(
                            controller: _emailController,
                            label: AppStrings.emailLabel,
                            hintText: AppStrings.emailHint,
                            prefixIcon: Icons.email_outlined,
                            keyboardType: TextInputType.emailAddress,
                            validator: (val) {
                              if (val == null || val.trim().isEmpty) {
                                return AppStrings.emailRequired;
                              }
                              if (!val.contains('@')) {
                                return AppStrings.invalidEmail;
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: AppDimens.space16),

                          // Password Field
                          CustomTextField(
                            controller: _passwordController,
                            label: AppStrings.passwordLabel,
                            hintText: AppStrings.passwordHint,
                            prefixIcon: Icons.lock_outline,
                            obscureText: _obscurePassword,
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscurePassword
                                    ? Icons.visibility_off_outlined
                                    : Icons.visibility_outlined,
                                color: AppColors.textSecondary,
                              ),
                              onPressed: () {
                                setState(() {
                                  _obscurePassword = !_obscurePassword;
                                });
                              },
                            ),
                            validator: (val) {
                              if (val == null || val.trim().isEmpty) {
                                return AppStrings.passwordRequired;
                              }
                              if (val.trim().length < 4) {
                                return AppStrings.passwordTooShort;
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: AppDimens.space24),

                          // Sign In Button
                          CustomButton(
                            text: AppStrings.loginButton,
                            isLoading: authState.isLoading,
                            onPressed: _submit,
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: AppDimens.space24),

                  // Demo Accounts Quick Selector for Interviewer Demo
                  Container(
                    padding: const EdgeInsets.all(AppDimens.space16),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(AppDimens.radiusMedium),
                      border: Border.all(color: AppColors.divider),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.info_outline, size: 16, color: AppColors.primary),
                            const SizedBox(width: AppDimens.space8),
                            Text(
                              AppStrings.demoAccountsNotice,
                              style: AppTextStyles.h3.copyWith(fontSize: 13),
                            ),
                          ],
                        ),
                        const SizedBox(height: AppDimens.space8),
                        Text(
                          AppStrings.autofillPrompt,
                          style: AppTextStyles.caption,
                        ),
                        const SizedBox(height: AppDimens.space12),
                        Wrap(
                          spacing: AppDimens.space8,
                          runSpacing: AppDimens.space8,
                          children: AuthRepository.demoTechnicians.map((tech) {
                            final isSelected = _emailController.text == tech.email;
                            return ActionChip(
                              avatar: Icon(
                                Icons.person,
                                size: 16,
                                color: isSelected ? Colors.white : AppColors.primary,
                              ),
                              label: Text('${tech.name} (${tech.email})'),
                              backgroundColor: isSelected
                                  ? AppColors.primary
                                  : AppColors.primarySurface,
                              labelStyle: TextStyle(
                                color: isSelected ? Colors.white : AppColors.primaryDark,
                                fontWeight: FontWeight.w600,
                                fontSize: 12,
                              ),
                              onPressed: () => _autofillDemo(tech.email),
                            );
                          }).toList(),
                        ),
                        const SizedBox(height: AppDimens.space8),
                        Text(
                          AppStrings.demoPasswordNotice,
                          style: AppTextStyles.caption.copyWith(color: AppColors.textTertiary),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
