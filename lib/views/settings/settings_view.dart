import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../theme/app_theme.dart';
import '../../viewmodels/auth_viewmodel.dart';
import '../profile/profile_edit_view.dart';
import 'blocked_users_view.dart';
import 'change_password_view.dart';
import 'contact_view.dart';
import 'widgets/delete_account_dialogs.dart';
import 'widgets/settings_section.dart';
import 'widgets/settings_tile.dart';

class SettingsView extends StatelessWidget {
  const SettingsView({super.key});

  @override
  Widget build(BuildContext context) {
    final authViewModel = Provider.of<AuthViewModel>(context);

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(title: const Text("Ayarlar")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 24.0),
        child: Column(
          children: [
            SettingsSection(
              children: [
                SettingsTile(
                  icon: Icons.person_outline_rounded,
                  title: "Profili Düzenle",
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const ProfileEditView(),
                      ),
                    );
                  },
                ),
                _buildDivider(),
                SettingsTile(
                  icon: Icons.lock_outline_rounded,
                  title: "Şifre Değiştir",
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const ChangePasswordView(),
                      ),
                    );
                  },
                ),
                _buildDivider(),
                SettingsTile(
                  icon: Icons.block_flipped,
                  title: "Engellenen Kullanıcılar",
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const BlockedUsersView(),
                      ),
                    );
                  },
                ),
              ],
            ),
            const SizedBox(height: 24),
            SettingsSection(
              children: [
                SettingsTile(
                  icon: Icons.support_agent_rounded,
                  title: "Bize Ulaşın",
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const ContactView(),
                      ),
                    );
                  },
                ),
              ],
            ),
            const SizedBox(height: 24),
            SettingsSection(
              children: [
                SettingsTile(
                  icon: Icons.delete_outline_rounded,
                  title: "Hesabı Sil",
                  textColor: AppTheme.error,
                  iconColor: AppTheme.error,
                  onTap: () =>
                      DeleteAccountDialogs.show(context, authViewModel),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDivider() {
    return Divider(
      height: 1,
      thickness: 1,
      indent: 60,
      endIndent: 0,
      color: Colors.grey.shade100,
    );
  }
}
