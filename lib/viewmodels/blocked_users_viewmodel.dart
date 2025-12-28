import 'package:flutter/material.dart';
import '../../models/account/blocked_users_list_model.dart';
import '../../models/account/unblock_user_model.dart';
import '../../services/account_service.dart';

class BlockedUsersViewModel extends ChangeNotifier {
  final AccountService _accountService = AccountService();

  List<BlockedUser> _blockedUsers = [];
  List<BlockedUser> get blockedUsers => _blockedUsers;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  Future<void> fetchBlockedUsers(int userId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await _accountService.getBlockedUsers(userId);
      if (response.success == true && response.data != null) {
        _blockedUsers = response.data!.users ?? [];
      } else {
        _errorMessage =
            response.message ?? "Engellenen kullanıcılar yüklenemedi.";
      }
    } catch (e) {
      _errorMessage = "Bir hata oluştu: $e";
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> unblockUser(String userToken, int blockedUserID) async {
    try {
      final request = UnblockUserRequest(
        userToken: userToken,
        blockedUserID: blockedUserID,
      );
      await _accountService.unblockUser(request);

      // Remove from list locally
      _blockedUsers.removeWhere((user) => user.userID == blockedUserID);
      notifyListeners();

      return true;
    } catch (e) {
      _errorMessage = "Engeli kaldırırken hata oluştu: $e";
      notifyListeners();
      return false;
    }
  }
}
