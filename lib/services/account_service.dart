import '../core/constants/api_constants.dart';
import '../models/account/update_user_model.dart';
import '../models/account/change_password_model.dart';
import '../models/account/delete_user_model.dart';
import '../models/account/blocked_user_model.dart';
import '../models/account/blocked_users_list_model.dart';
import '../models/account/unblock_user_model.dart';
import 'api_service.dart';

class AccountService {
  final ApiService _apiService = ApiService();

  Future<UpdateUserResponseModel> updateUser(
    UpdateUserRequestModel request,
  ) async {
    final response = await _apiService.put(
      ApiConstants.updateUser,
      request.toJson(),
    );

    if (response != null) {
      // The API might return { error: false, success: true, message: "..." } at root
      // or wrapped in data. Based on standard structure let's assume root or handle check.
      // Usually project standards say: response is the map.
      return UpdateUserResponseModel.fromJson(response);
    } else {
      throw Exception("Update User failed: invalid response");
    }
  }

  Future<ChangePasswordResponseModel> changePassword(
    ChangePasswordRequestModel request,
  ) async {
    final response = await _apiService.post(
      ApiConstants.changePassword,
      request.toJson(),
    );

    if (response != null) {
      return ChangePasswordResponseModel.fromJson(response);
    } else {
      throw Exception("Change Password failed: invalid response");
    }
  }

  Future<void> deleteUser(DeleteUserRequestModel request) async {
    await _apiService.post(ApiConstants.deleteUser, request.toJson());
  }

  Future<void> blockUser(BlockedUserRequest request) async {
    await _apiService.post(ApiConstants.userBlocked, request.toJson());
  }

  Future<BlockedUsersListResponse> getBlockedUsers(int userId) async {
    final response = await _apiService.get(
      '${ApiConstants.blockedUsers}$userId/blockedUsers',
    );

    if (response != null) {
      return BlockedUsersListResponse.fromJson(response);
    } else {
      throw Exception("Get Blocked Users failed: invalid response");
    }
  }

  Future<void> unblockUser(UnblockUserRequest request) async {
    await _apiService.post(ApiConstants.userUnBlocked, request.toJson());
  }
}
