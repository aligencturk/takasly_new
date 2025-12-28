import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../theme/app_theme.dart';
import '../../viewmodels/auth_viewmodel.dart';
import '../../viewmodels/profile_viewmodel.dart';
import '../../models/profile/profile_detail_model.dart';
import 'profile_change_password_view.dart';
import '../../viewmodels/product_viewmodel.dart';
import '../../viewmodels/home_viewmodel.dart';
import '../home/home_view.dart';

class UserProfileView extends StatefulWidget {
  final int userId;
  final bool isByType;

  const UserProfileView({
    super.key,
    required this.userId,
    this.isByType = false,
  });

  @override
  State<UserProfileView> createState() => _UserProfileViewState();
}

class _UserProfileViewState extends State<UserProfileView> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authVM = Provider.of<AuthViewModel>(context, listen: false);
      final userToken = authVM.user?.token;

      Provider.of<ProfileViewModel>(
        context,
        listen: false,
      ).getProfileDetail(widget.userId, userToken);
    });
  }

  void _showReportDialog() {
    final TextEditingController reasonController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Kullanıcıyı Raporla"),
        content: TextField(
          controller: reasonController,
          decoration: const InputDecoration(
            hintText: "Raporlama sebebinizi yazın...",
          ),
          maxLines: 3,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("İptal"),
          ),
          ElevatedButton(
            onPressed: () async {
              final reason = reasonController.text.trim();
              if (reason.isEmpty) return;

              final authVM = context.read<AuthViewModel>();
              final profileVM = context.read<ProfileViewModel>();

              if (authVM.user?.token != null) {
                final success = await profileVM.reportUser(
                  userToken: authVM.user!.token,
                  reportedUserID: widget.userId,
                  reason: reason,
                  step: "user",
                );

                if (context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        success
                            ? "Kullanıcı raporlandı."
                            : "Raporlanırken hata oluştu.",
                      ),
                      backgroundColor: success ? Colors.green : Colors.red,
                    ),
                  );
                }
              }
            },
            child: const Text("Gönder"),
          ),
        ],
      ),
    );
  }

  void _showBlockConfirmDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Kullanıcıyı Engelle"),
        content: const Text(
          "Bu kullanıcıyı engellemek istediğinize emin misiniz? Bu işlemden sonra birbirinize mesaj gönderemeyeceksiniz.",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("İptal"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              final authVM = context.read<AuthViewModel>();
              final profileVM = context.read<ProfileViewModel>();

              if (authVM.user?.token != null) {
                final success = await profileVM.blockUser(
                  userToken: authVM.user!.token,
                  blockedUserID: widget.userId,
                );

                if (context.mounted) {
                  Navigator.pop(context);
                  if (success) {
                    // Trigger refresh on all data
                    context.read<ProductViewModel>().fetchProducts(
                      isRefresh: true,
                    );
                    context.read<HomeViewModel>().init();

                    Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(builder: (_) => const HomeView()),
                      (route) => false,
                    );
                  }
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        success
                            ? "Kullanıcı engellendi."
                            : "Engellenirken hata oluştu.",
                      ),
                      backgroundColor: success ? Colors.green : Colors.red,
                    ),
                  );
                }
              }
            },
            child: const Text("Engelle", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ProfileViewModel>(
      builder: (context, viewModel, child) {
        final profile = viewModel.profileDetail;
        final isBusy = viewModel.state == ProfileState.busy;
        final isError = viewModel.state == ProfileState.error;

        // Check if this is the current user's profile
        final authVM = Provider.of<AuthViewModel>(context, listen: false);
        final isCurrentUser = authVM.user?.userID == widget.userId;

        return Scaffold(
          backgroundColor: AppTheme.background,
          appBar: AppBar(
            title: Text(
              profile?.userFullname ?? 'Profil Detayı',
              style: const TextStyle(color: Colors.white, fontSize: 18),
            ),
            backgroundColor: AppTheme.primary,
            iconTheme: const IconThemeData(color: Colors.white),
            centerTitle: true,
            actions: [
              if (!isCurrentUser)
                PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert, color: Colors.white),
                  onSelected: (value) {
                    if (value == 'report') {
                      _showReportDialog();
                    } else if (value == 'block') {
                      _showBlockConfirmDialog();
                    }
                  },
                  itemBuilder: (BuildContext context) {
                    return [
                      const PopupMenuItem<String>(
                        value: 'report',
                        child: Row(
                          children: [
                            Icon(
                              Icons.report_problem_outlined,
                              size: 18,
                              color: Colors.orange,
                            ),
                            SizedBox(width: 8),
                            Text("Kullanıcıyı Raporla"),
                          ],
                        ),
                      ),
                      const PopupMenuItem<String>(
                        value: 'block',
                        child: Row(
                          children: [
                            Icon(
                              Icons.block_flipped,
                              size: 18,
                              color: Colors.red,
                            ),
                            SizedBox(width: 8),
                            Text("Kullanıcıyı Engelle"),
                          ],
                        ),
                      ),
                    ];
                  },
                ),
            ],
          ),
          body: isBusy
              ? const Center(child: CircularProgressIndicator())
              : isError
              ? Center(child: Text(viewModel.errorMessage ?? 'Bir hata oluştu'))
              : profile == null
              ? const Center(child: Text('Kullanıcı bulunamadı'))
              : SingleChildScrollView(
                  child: Column(
                    children: [
                      _buildHeader(profile),
                      const SizedBox(height: 16),
                      _buildStats(profile),
                      const SizedBox(height: 16),
                      _buildProductsGrid(profile),
                      const SizedBox(height: 16),
                      _buildReviewsList(profile),

                      if (isCurrentUser) ...[
                        const SizedBox(height: 16),
                        _buildCurrentUserMenu(context, authVM),
                        const SizedBox(height: 32),
                      ],
                      const SizedBox(height: 32),
                    ],
                  ),
                ),
        );
      },
    );
  }

  Widget _buildHeader(ProfileDetailModel profile) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          CircleAvatar(
            radius: 48,
            backgroundColor: AppTheme.primary.withOpacity(0.1),
            backgroundImage:
                (profile.userImage != null && profile.userImage!.isNotEmpty)
                ? NetworkImage(profile.userImage!)
                : null,
            child: (profile.userImage == null || profile.userImage!.isEmpty)
                ? Text(
                    (profile.userFullname?.isNotEmpty == true
                            ? profile.userFullname![0]
                            : "U")
                        .toUpperCase(),
                    style: AppTheme.safePoppins(
                      fontSize: 32,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.primary,
                    ),
                  )
                : null,
          ),
          const SizedBox(height: 16),
          Text(
            profile.userFullname ?? '',
            style: AppTheme.safePoppins(
              fontSize: 24,
              fontWeight: FontWeight.w600,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            profile.memberSince ?? '',
            style: AppTheme.safePoppins(
              fontSize: 14,
              fontWeight: FontWeight.w400,
              color: AppTheme.textSecondary,
            ),
          ),
          if (profile.averageRating != null)
            Padding(
              padding: const EdgeInsets.only(top: 8.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.star, color: Colors.amber, size: 20),
                  const SizedBox(width: 4),
                  Text(
                    "${profile.averageRating} (${profile.totalReviews ?? 0} Değerlendirme)",
                    style: AppTheme.safePoppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildStats(ProfileDetailModel profile) {
    if (profile.products == null) return const SizedBox.shrink();

    final productCount = profile.products!.length;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Expanded(child: _buildStatCard("Ürünler", "$productCount")),
          const SizedBox(width: 12),
          Expanded(
            child: _buildStatCard(
              "Değerlendirme",
              "${profile.totalReviews ?? 0}",
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: AppTheme.cardShadow,
      ),
      child: Column(
        children: [
          Text(
            value,
            style: AppTheme.safePoppins(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: AppTheme.primary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: AppTheme.safePoppins(
              fontSize: 12,
              fontWeight: FontWeight.w400,
              color: AppTheme.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProductsGrid(ProfileDetailModel profile) {
    if (profile.products == null || profile.products!.isEmpty) {
      return const Center(child: Text("Henüz ilan yok."));
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Text(
            "İlanlar (${profile.products!.length})",
            style: AppTheme.safePoppins(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: AppTheme.textPrimary,
            ),
          ),
        ),
        const SizedBox(height: 12),
        GridView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            childAspectRatio: 0.72,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
          ),
          itemCount: profile.products!.length,
          itemBuilder: (context, index) {
            final product = profile.products![index];

            return Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: ClipRRect(
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(10),
                      ),
                      child: Image.network(
                        product.productImage ?? '',
                        fit: BoxFit.cover,
                        width: double.infinity,
                        errorBuilder: (ctx, err, stack) =>
                            Container(color: Colors.grey[200]),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          product.productTitle ?? '',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTheme.safePoppins(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                        Text(
                          "${product.cityTitle} / ${product.districtTitle}",
                          style: AppTheme.safePoppins(
                            fontSize: 10,
                            fontWeight: FontWeight.w400,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildReviewsList(ProfileDetailModel profile) {
    if (profile.reviews == null || profile.reviews!.isEmpty)
      return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Text(
            "Değerlendirmeler (${profile.reviews!.length})",
            style: AppTheme.safePoppins(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: AppTheme.textPrimary,
            ),
          ),
        ),
        const SizedBox(height: 12),
        ListView.separated(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: profile.reviews!.length,
          separatorBuilder: (ctx, index) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            final review = profile.reviews![index];
            return Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: AppTheme.cardShadow,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 16,
                        backgroundImage:
                            (review.reviewerImage != null &&
                                review.reviewerImage!.isNotEmpty)
                            ? NetworkImage(review.reviewerImage!)
                            : null,
                        child: (review.reviewerImage == null)
                            ? const Icon(Icons.person, size: 16)
                            : null,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        review.reviewerName ?? 'Kullanıcı',
                        style: AppTheme.safePoppins(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                      const Spacer(),
                      Row(
                        children: [
                          const Icon(Icons.star, color: Colors.amber, size: 14),
                          const SizedBox(width: 4),
                          Text("${review.rating}"),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    review.comment ?? '',
                    style: AppTheme.safePoppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w400,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    review.reviewDate ?? '',
                    style: AppTheme.safePoppins(
                      fontSize: 10,
                      fontWeight: FontWeight.w400,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildCurrentUserMenu(BuildContext context, AuthViewModel authVM) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: AppTheme.cardShadow,
      ),
      child: Column(
        children: [
          _buildMenuItem(Icons.person_outline, "Hesap Bilgileri", () {}),
          _buildDivider(),
          _buildMenuItem(Icons.favorite_outline, "Favorilerim", () {}),
          _buildDivider(),
          _buildMenuItem(Icons.settings_outlined, "Ayarlar", () {}),
          _buildDivider(),
          _buildMenuItem(Icons.lock_reset, "Şifre Güncelle", () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const ProfileChangePasswordView(),
              ),
            );
          }),
          _buildDivider(),
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.red),
            title: Text(
              "Çıkış Yap",
              style: AppTheme.safePoppins(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.red,
              ),
            ),
            onTap: () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Çıkış Yap'),
                  content: const Text(
                    'Çıkış yapmak istediğinize emin misiniz?',
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('İptal'),
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.pop(context);
                        authVM.logout();
                      },
                      child: const Text(
                        'Çıkış Yap',
                        style: TextStyle(color: Colors.red),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildMenuItem(IconData icon, String title, VoidCallback onTap) {
    return ListTile(
      leading: Icon(icon, color: AppTheme.textSecondary),
      title: Text(
        title,
        style: AppTheme.safePoppins(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color: AppTheme.textPrimary,
        ),
      ),
      trailing: const Icon(Icons.chevron_right, color: AppTheme.textSecondary),
      onTap: onTap,
    );
  }

  Widget _buildDivider() {
    return const Divider(
      height: 1,
      indent: 16,
      endIndent: 16,
      color: Color(0xFFE0E0E0),
    );
  }
}
