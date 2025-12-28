import 'package:flutter/material.dart';
import '../../../theme/app_theme.dart';
import '../../../viewmodels/auth_viewmodel.dart';
// Note: We avoid importing provider here if we pass the viewModel directly or context
// But typically we pass the viewmodel or use a callback.
// The original code passed AuthViewModel.

class DeleteAccountDialogs {
  static void show(BuildContext context, AuthViewModel authViewModel) {
    _showFirstConfirmation(context, authViewModel);
  }

  static void _showFirstConfirmation(
    BuildContext context,
    AuthViewModel authViewModel,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          "Hesabı Sil",
          style: AppTheme.safePoppins(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: AppTheme.textPrimary,
          ),
        ),
        content: Text(
          "Hesabınızı silmek istediğinize emin misiniz?",
          style: AppTheme.safePoppins(
            fontSize: 15,
            fontWeight: FontWeight.w400,
            color: AppTheme.textSecondary,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              "Vazgeç",
              style: AppTheme.safePoppins(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: AppTheme.textSecondary,
              ),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _showSecondConfirmation(context, authViewModel);
            },
            child: Text(
              "Devam Et",
              style: AppTheme.safePoppins(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppTheme.error,
              ),
            ),
          ),
        ],
      ),
    );
  }

  static void _showSecondConfirmation(
    BuildContext context,
    AuthViewModel authViewModel,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          "Emin misiniz?",
          style: AppTheme.safePoppins(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: AppTheme.textPrimary,
          ),
        ),
        content: Text(
          "Bu işlem geri alınamaz ve tüm verileriniz kalıcı olarak silinecektir.",
          style: AppTheme.safePoppins(
            fontSize: 15,
            fontWeight: FontWeight.w400,
            color: AppTheme.textSecondary,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              "Vazgeç",
              style: AppTheme.safePoppins(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: AppTheme.textSecondary,
              ),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _showThirdConfirmation(context, authViewModel);
            },
            child: Text(
              "Anladım, Devam Et",
              style: AppTheme.safePoppins(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppTheme.error,
              ),
            ),
          ),
        ],
      ),
    );
  }

  static void _showThirdConfirmation(
    BuildContext context,
    AuthViewModel authViewModel,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          "Son Onay",
          style: AppTheme.safePoppins(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: AppTheme.textPrimary,
          ),
        ),
        content: Text(
          "Hesabınızı kalıcı olarak silmeyi onaylıyor musunuz?",
          style: AppTheme.safePoppins(
            fontSize: 15,
            fontWeight: FontWeight.w400,
            color: AppTheme.textSecondary,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              "Vazgeç",
              style: AppTheme.safePoppins(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: AppTheme.textSecondary,
              ),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              authViewModel.deleteAccount();
            },
            child: Text(
              "HESABI SİL",
              style: AppTheme.safePoppins(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppTheme.error,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
