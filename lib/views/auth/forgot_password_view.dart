import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../theme/app_theme.dart';
import '../../viewmodels/auth_viewmodel.dart';
import 'code_verification_view.dart';

class ForgotPasswordView extends StatefulWidget {
  const ForgotPasswordView({super.key});

  @override
  State<ForgotPasswordView> createState() => _ForgotPasswordViewState();
}

class _ForgotPasswordViewState extends State<ForgotPasswordView> {
  final _emailController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authViewModel = Provider.of<AuthViewModel>(context);

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('Şifremi Unuttum'),
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
                  'Şifre Sıfırlama',
                  style: AppTheme.safePoppins(
                    fontSize: 24,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Kayıtlı e-posta adresinizi giriniz. Size bir doğrulama kodu göndereceğiz.',
                  style: AppTheme.safePoppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                    color: AppTheme.textSecondary,
                  ),
                ),
                const SizedBox(height: 32),

                Text(
                  'E-posta',
                  style: AppTheme.safePoppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: AppTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,

                  decoration: const InputDecoration(
                    hintText: 'ornek@email.com',
                    prefixIcon: Icon(Icons.email_outlined),
                  ),
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
                            await authViewModel.forgotPassword(
                              _emailController.text.trim(),
                            );

                            if (context.mounted &&
                                authViewModel.state == AuthState.success) {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      const CodeVerificationView(),
                                ),
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
                            'Kod Gönder',
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
}
