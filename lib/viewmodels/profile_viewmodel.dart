import 'package:flutter/material.dart';
import 'package:logger/logger.dart';
import '../models/profile/profile_detail_model.dart';
import '../services/auth_service.dart';

enum ProfileState { idle, busy, error, success }

class ProfileViewModel extends ChangeNotifier {
  final AuthService _authService = AuthService();
  final Logger _logger = Logger();

  ProfileState _state = ProfileState.idle;
  ProfileState get state => _state;

  ProfileDetailModel? _profileDetail;
  ProfileDetailModel? get profileDetail => _profileDetail;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  Future<void> getProfileDetail(int userId, String? userToken) async {
    _state = ProfileState.busy;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await _authService.getProfileDetail(userId, userToken);
      _profileDetail = response;
      _state = ProfileState.success;
      _logger.i("Profile detail loaded for user: $userId");
    } catch (e) {
      _state = ProfileState.error;
      _errorMessage = e.toString();
      _logger.e("Failed to load profile details: $e");
    } finally {
      notifyListeners();
    }
  }

  // Helper to check if the loaded profile belongs to the current user
  bool isCurrentUser(int? currentUserId) {
    if (currentUserId == null || _profileDetail == null) return false;
    return _profileDetail!.userID == currentUserId;
  }
}
