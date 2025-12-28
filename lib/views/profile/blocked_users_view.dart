import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../theme/app_theme.dart';
import '../../viewmodels/auth_viewmodel.dart';
import '../../viewmodels/blocked_users_viewmodel.dart';
import '../../models/account/blocked_users_list_model.dart';

class BlockedUsersView extends StatefulWidget {
  const BlockedUsersView({super.key});

  @override
  State<BlockedUsersView> createState() => _BlockedUsersViewState();
}

class _BlockedUsersViewState extends State<BlockedUsersView> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authVM = context.read<AuthViewModel>();
      if (authVM.user?.userID != null) {
        context.read<BlockedUsersViewModel>().fetchBlockedUsers(
          authVM.user!.userID,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(title: const Text("Engellenen Kullanıcılar")),
      body: Consumer<BlockedUsersViewModel>(
        builder: (context, viewModel, child) {
          if (viewModel.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (viewModel.errorMessage != null) {
            return Center(child: Text(viewModel.errorMessage!));
          }

          if (viewModel.blockedUsers.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.block_flipped,
                    size: 64,
                    color: Colors.grey.shade300,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    "Engellenen kullanıcı bulunmuyor.",
                    style: AppTheme.safePoppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w400,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                ],
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: viewModel.blockedUsers.length,
            separatorBuilder: (context, index) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final user = viewModel.blockedUsers[index];
              return Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: AppTheme.cardShadow,
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 24,
                      backgroundImage:
                          (user.profilePhoto != null &&
                              user.profilePhoto!.isNotEmpty)
                          ? NetworkImage(user.profilePhoto!)
                          : null,
                      child:
                          (user.profilePhoto == null ||
                              user.profilePhoto!.isEmpty)
                          ? Text(
                              (user.userFullname?.isNotEmpty == true
                                      ? user.userFullname![0]
                                      : "U")
                                  .toUpperCase(),
                              style: AppTheme.safePoppins(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: AppTheme.primary,
                              ),
                            )
                          : null,
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Text(
                        user.userFullname ?? "Bilinmeyen Kullanıcı",
                        style: AppTheme.safePoppins(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(
                        Icons.person_remove_rounded,
                        color: Colors.red,
                      ),
                      onPressed: () => _showUnblockDialog(context, user),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  void _showUnblockDialog(BuildContext context, BlockedUser user) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Engeli Kaldır"),
        content: Text(
          "${user.userFullname} adlı kullanıcının engelini kaldırmak istediğinize emin misiniz?",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("İptal"),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              final authVM = context.read<AuthViewModel>();
              final success = await context
                  .read<BlockedUsersViewModel>()
                  .unblockUser(authVM.user!.token, user.userID!);

              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      success
                          ? "Kullanıcının engeli kaldırıldı."
                          : "Engel kaldırılırken hata oluştu.",
                    ),
                    backgroundColor: success ? Colors.green : Colors.red,
                  ),
                );
              }
            },
            child: const Text("Evet, Kaldır"),
          ),
        ],
      ),
    );
  }
}
