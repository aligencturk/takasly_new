import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../theme/app_theme.dart';
import '../../viewmodels/auth_viewmodel.dart';
import '../home/home_view.dart';
import 'update_password_view.dart';

class CodeVerificationView extends StatefulWidget {
  const CodeVerificationView({super.key});

  @override
  State<CodeVerificationView> createState() => _CodeVerificationViewState();
}

class _CodeVerificationViewState extends State<CodeVerificationView> {
  final _codeController = TextEditingController();

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Listen to AuthViewModel
    final authViewModel = Provider.of<AuthViewModel>(context);

    // Listen for state changes to navigate
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (authViewModel.state == AuthState.success) {
        if (authViewModel.currentFlow == AuthFlow.register &&
            authViewModel.user != null) {
          // Register success -> Home
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('Doğrulama Başarılı!')));
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (context) => const HomeView()),
            (route) => false,
          );
        } else if (authViewModel.currentFlow == AuthFlow.forgotPassword) {
          // Forgot Password success -> Update Password
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const UpdatePasswordView()),
          );
        }
      }
    });

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('Doğrulama'),
        backgroundColor: AppTheme.primary,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        titleTextStyle: AppTheme.safePoppins(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: Colors.white,
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 20),
              // Icon
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: AppTheme.primary.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.verified_user_rounded,
                  size: 64,
                  color: AppTheme.primary,
                ),
              ),
              const SizedBox(height: 32),
              Text(
                'Doğrulama Kodu',
                textAlign: TextAlign.center,
                style: AppTheme.safePoppins(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Lütfen e-posta adresinize gönderilen doğrulama kodunu giriniz.',
                textAlign: TextAlign.center,
                style: AppTheme.safePoppins(
                  fontSize: 15,
                  fontWeight: FontWeight.w400,
                  color: AppTheme.textSecondary,
                ),
              ),
              const SizedBox(height: 48),

              // Code Input
              TextField(
                controller: _codeController,
                keyboardType: TextInputType.number,
                maxLength: 6,
                textAlign: TextAlign.center,
                style: AppTheme.safePoppins(
                  fontSize: 24,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textPrimary,
                  letterSpacing: 8,
                ),
                decoration: InputDecoration(
                  hintText: '######',
                  counterText: "",
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding: const EdgeInsets.symmetric(vertical: 16),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: const BorderSide(
                      color: AppTheme.primary,
                      width: 2,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 24),

              if (authViewModel.state == AuthState.error &&
                  authViewModel.errorMessage != null)
                Container(
                  margin: const EdgeInsets.only(bottom: 24),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppTheme.error.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppTheme.error.withOpacity(0.2)),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.error_outline_rounded,
                        color: AppTheme.error,
                        size: 20,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          authViewModel.errorMessage!,
                          style: AppTheme.safePoppins(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: AppTheme.error,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

              SizedBox(
                height: 56,
                child: ElevatedButton(
                  onPressed: authViewModel.state == AuthState.busy
                      ? null
                      : () {
                          final code = _codeController.text.trim();
                          authViewModel.verifyCode(code);
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primary,
                    foregroundColor: Colors.white,
                    elevation: 4,
                    shadowColor: AppTheme.primary.withOpacity(0.4),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
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
                          'Doğrula',
                          style: AppTheme.safePoppins(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                ),
              ),

              const SizedBox(height: 24),

              Center(
                child: TextButton(
                  onPressed: authViewModel.state == AuthState.busy
                      ? null
                      : () async {
                          await authViewModel.resendCode();
                          if (context.mounted &&
                              authViewModel.state != AuthState.error &&
                              authViewModel.errorMessage == null) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Yeni kod gönderildi!'),
                              ),
                            );
                          }
                        },
                  child: Text(
                    'Tekrar Kod Gönder',
                    style: AppTheme.safePoppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.primary,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
