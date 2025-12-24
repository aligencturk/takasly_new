import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../theme/app_theme.dart';
import '../../viewmodels/auth_viewmodel.dart';
import '../auth/login_view.dart';
import '../auth/register_view.dart';

class ProfileView extends StatefulWidget {
  const ProfileView({super.key});

  @override
  State<ProfileView> createState() => _ProfileViewState();
}

class _ProfileViewState extends State<ProfileView> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authViewModel = Provider.of<AuthViewModel>(context, listen: false);
      if (authViewModel.user != null) {
        authViewModel.getUser();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final authViewModel = Provider.of<AuthViewModel>(context);
    final isLoggedIn = authViewModel.user != null;

    if (!isLoggedIn) {
      return Scaffold(
        backgroundColor: AppTheme.background,
        body: SafeArea(child: _buildGuestProfile(context)),
      );
    }

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(
          'Profilim',
          style: AppTheme.safePoppins(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: AppTheme.textPrimary,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: 16),
            // Profile Header
            _buildProfileHeader(context, authViewModel),
            const SizedBox(height: 24),

            // Menu Items
            _buildMenuItem(
              context,
              icon: Icons.favorite_border_rounded,
              title: "Favorilerim",
              onTap: () {
                // Navigate to Favorites
              },
            ),
            _buildDivider(),
            _buildMenuItem(
              context,
              icon: Icons.notifications_none_rounded,
              title: "Bildirimler",
              onTap: () {
                // Navigate to Notifications
              },
            ),
            _buildDivider(),
            _buildMenuItem(
              context,
              icon: Icons.grid_view_rounded,
              title: "İlanlarım",
              onTap: () {
                // Navigate to My Ads
              },
            ),
            _buildDivider(),
            const SizedBox(height: 24),

            // Settings Section
            _buildMenuItem(
              context,
              icon: Icons.settings_outlined,
              title: "Ayarlar",
              onTap: () {
                // Navigate to Settings
              },
            ),
            _buildDivider(),
            _buildMenuItem(
              context,
              icon: Icons.help_outline_rounded,
              title: "Yardım Merkezi",
              onTap: () {
                // Navigate to Help
              },
            ),
            _buildDivider(),
            _buildMenuItem(
              context,
              icon: Icons.info_outline_rounded,
              title: "Hakkımızda",
              onTap: () {
                // Navigate to About
              },
            ),

            const SizedBox(height: 24),

            // Logout
            _buildMenuItem(
              context,
              icon: Icons.logout_rounded,
              title: "Çıkış Yap",
              textColor: AppTheme.error,
              iconColor: AppTheme.error,
              onTap: () {
                _showLogoutConfirmation(context, authViewModel);
              },
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileHeader(
    BuildContext context,
    AuthViewModel authViewModel,
  ) {
    final profile = authViewModel.userProfile;
    final isLoading = authViewModel.state == AuthState.busy;

    // Show loading only if we have absolutely no profile data yet and it's loading
    // But usually user data might be cached or incomplete.
    // If isLoading is true and profile is null, show loader.
    if (isLoading && profile == null) {
      return const Center(child: CircularProgressIndicator());
    }

    return InkWell(
      onTap: () {
        // Maybe navigate to "Edit Profile" or full details?
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
        child: Row(
          children: [
            Container(
              height: 64,
              width: 64,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.grey[200],
                image:
                    (profile?.profilePhoto != null &&
                        profile!.profilePhoto!.isNotEmpty)
                    ? DecorationImage(
                        image: NetworkImage(profile.profilePhoto!),
                        fit: BoxFit.cover,
                      )
                    : null,
              ),
              child:
                  (profile?.profilePhoto == null ||
                      profile!.profilePhoto!.isEmpty)
                  ? Center(
                      child: Text(
                        (profile?.userFullname?.isNotEmpty == true
                                ? profile!.userFullname![0]
                                : "U")
                            .toUpperCase(),
                        style: AppTheme.safePoppins(
                          fontSize: 24,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.primary,
                        ),
                      ),
                    )
                  : null,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    profile?.userFullname ?? "Kullanıcı",
                    style: AppTheme.safePoppins(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    (profile != null &&
                            profile.totalReviews != null &&
                            profile.totalReviews! > 0)
                        ? "${profile.averageRating} (${profile.totalReviews} Değerlendirme)"
                        : "Henüz değerlendirme yok",
                    style: AppTheme.safePoppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w400,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.chevron_right_rounded,
              color: AppTheme.textSecondary,
              size: 24,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    Color? textColor,
    Color? iconColor,
  }) {
    return ListTile(
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 24),
      leading: Icon(icon, color: iconColor ?? AppTheme.textPrimary, size: 24),
      title: Text(
        title,
        style: AppTheme.safePoppins(
          fontSize: 16,
          fontWeight: FontWeight.w400,
          color: textColor ?? AppTheme.textPrimary,
        ),
      ),
      trailing: const Icon(
        Icons.chevron_right_rounded,
        color: AppTheme.textSecondary,
        size: 20,
      ),
    );
  }

  Widget _buildDivider() {
    return Divider(
      height: 1,
      thickness: 1,
      indent: 64,
      color: Colors.grey[100],
    );
  }

  Widget _buildGuestProfile(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: AppTheme.cardShadow,
              ),
              child: const Icon(
                Icons.person_outline_rounded,
                size: 64,
                color: AppTheme.primary,
              ),
            ),
            const SizedBox(height: 32),
            Text(
              'Hesabınıza Giriş Yapın',
              textAlign: TextAlign.center,
              style: AppTheme.safePoppins(
                fontSize: 24,
                fontWeight: FontWeight.w600,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Takas yapmak ve ilan vermek için giriş yapın veya kayıt olun.',
              textAlign: TextAlign.center,
              style: AppTheme.safePoppins(
                fontSize: 16,
                fontWeight: FontWeight.w400,
                color: AppTheme.textSecondary,
              ),
            ),
            const SizedBox(height: 48),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const LoginView()),
                  );
                },
                child: const Text('Giriş Yap'),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: OutlinedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const RegisterView(),
                    ),
                  );
                },
                child: const Text('Kayıt Ol'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showLogoutConfirmation(
    BuildContext context,
    AuthViewModel authViewModel,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Çıkış Yap'),
        content: const Text('Çıkış yapmak istediğinize emin misiniz?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('İptal'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              authViewModel.logout();
            },
            child: const Text('Çıkış Yap', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
