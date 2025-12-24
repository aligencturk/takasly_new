import 'api_service.dart';
import '../core/constants/api_constants.dart';

class NotificationService {
  final ApiService _apiService = ApiService();

  Future<Map<String, dynamic>> getNotifications(int userId) async {
    try {
      // Constructing path dynamically: service/user/account/$userId/notifications
      // We don't have a constant for the full path pattern, so we build it.
      final response = await _apiService.get(
        'service/user/account/$userId/notifications',
      );
      return response;
    } catch (e) {
      rethrow;
    }
  }

  Future<Map<String, dynamic>> markAllNotificationsRead(
    String userToken,
  ) async {
    try {
      final response = await _apiService.put(ApiConstants.notAllRead, {
        'userToken': userToken,
      });
      return response;
    } catch (e) {
      rethrow;
    }
  }

  Future<Map<String, dynamic>> markNotificationRead(
    String userToken,
    int notID,
  ) async {
    try {
      final response = await _apiService.put(ApiConstants.notRead, {
        'userToken': userToken,
        'notID': notID,
      });
      return response;
    } catch (e) {
      rethrow;
    }
  }

  Future<Map<String, dynamic>> deleteNotification(
    String userToken,
    int notID,
  ) async {
    try {
      final response = await _apiService.delete(ApiConstants.notDelete, {
        'userToken': userToken,
        'notID': notID,
      });
      return response;
    } catch (e) {
      rethrow;
    }
  }

  Future<Map<String, dynamic>> deleteAllNotifications(String userToken) async {
    try {
      final response = await _apiService.delete(ApiConstants.notAllDelete, {
        'userToken': userToken,
      });
      return response;
    } catch (e) {
      rethrow;
    }
  }
}
