import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../theme/app_theme.dart';
import '../../viewmodels/auth_viewmodel.dart';
import 'login_view.dart';

class UpdatePasswordView extends StatefulWidget {
  const UpdatePasswordView({super.key});

  @override
  State<UpdatePasswordView> createState() => _UpdatePasswordViewState();
}

class _UpdatePasswordViewState extends State<UpdatePasswordView> {
  final _passwordController = TextEditingController();
  final _passwordConfirmController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  bool _obscurePassword = true;
  bool _obscureConfirm = true;

  @override
  void dispose() {
    _passwordController.dispose();
    _passwordConfirmController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authViewModel = Provider.of<AuthViewModel>(context);

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('Yeni Şifre Belirle'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Yeni Şifre',
                  style: AppTheme.safePoppins(
                    fontSize: 24,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Lütfen hesabınız için yeni bir şifre belirleyiniz.',
                  style: AppTheme.safePoppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                    color: AppTheme.textSecondary,
                  ),
                ),
                const SizedBox(height: 32),

                _buildPasswordField(
                  controller: _passwordController,
                  label: 'Yeni Şifre',
                  hint: '••••••••',
                  obscureText: _obscurePassword,
                  onToggleVisibility: () =>
                      setState(() => _obscurePassword = !_obscurePassword),
                ),

                const SizedBox(height: 16),

                _buildPasswordField(
                  controller: _passwordConfirmController,
                  label: 'Yeni Şifre (Tekrar)',
                  hint: '••••••••',
                  obscureText: _obscureConfirm,
                  onToggleVisibility: () =>
                      setState(() => _obscureConfirm = !_obscureConfirm),
                ),

                const SizedBox(height: 24),

                if (authViewModel.state == AuthState.error &&
                    authViewModel.errorMessage != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 16.0),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.red.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.red.shade200),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.error_outline, color: Colors.red),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              authViewModel.errorMessage!,
                              style: const TextStyle(color: Colors.red),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: authViewModel.state == AuthState.busy
                        ? null
                        : () async {
                            await authViewModel.updatePassword(
                              _passwordController.text,
                              _passwordConfirmController.text,
                            );

                            if (context.mounted &&
                                authViewModel.state == AuthState.success) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    'Şifreniz başarıyla güncellendi! Giriş yapabilirsiniz.',
                                  ),
                                ),
                              );

                              // Navigate to LoginView
                              Navigator.pushAndRemoveUntil(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const LoginView(),
                                ),
                                (route) => false,
                              );
                            }
                          },
                    child: authViewModel.state == AuthState.busy
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : Text(
                            'Şifreyi Güncelle',
                            style: AppTheme.safePoppins(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPasswordField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required bool obscureText,
    required VoidCallback onToggleVisibility,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppTheme.safePoppins(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: AppTheme.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          obscureText: obscureText,

          decoration: InputDecoration(
            hintText: hint,
            prefixIcon: const Icon(Icons.lock_outline),
            suffixIcon: IconButton(
              icon: Icon(
                obscureText
                    ? Icons.visibility_outlined
                    : Icons.visibility_off_outlined,
              ),
              onPressed: onToggleVisibility,
            ),
          ),
        ),
      ],
    );
  }
}
