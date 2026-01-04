import 'package:flutter/material.dart';
import '../services/notification_service.dart';
import '../models/notification/notification_model.dart';
import 'package:logger/logger.dart';

class NotificationViewModel extends ChangeNotifier {
  final NotificationService _notificationService = NotificationService();
  final Logger _logger = Logger();

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  List<NotificationModel> _notifications = [];
  List<NotificationModel> get notifications => _notifications;

  int get unreadCount => _notifications.where((n) => !n.isRead).length;

  Future<void> fetchNotifications(int userId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await _notificationService.getNotifications(userId);

      if (response['success'] == true &&
          response['data'] != null &&
          response['data']['notifications'] != null) {
        final List list = response['data']['notifications'];
        _notifications = list
            .map((e) => NotificationModel.fromJson(e))
            .toList();
      } else {
        _notifications = [];
      }
    } catch (e) {
      _errorMessage = e.toString();
      _logger.e('Fetch notifications error: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> markAllAsRead(String userToken) async {
    try {
      final response = await _notificationService.markAllNotificationsRead(
        userToken,
      );
      if (response['success'] == true) {
        // Optimistically update local state
        _notifications = _notifications.map((n) {
          // Can't modify final fields, need to create new instance or make fields non-final
          // For now, assuming we refetch or rebuild list
          return NotificationModel(
            id: n.id,
            title: n.title,
            body: n.body,
            type: n.type,
            typeId: n.typeId,
            url: n.url,
            isRead: true,
            createDate: n.createDate,
          );
        }).toList();
        notifyListeners();
      }
    } catch (e) {
      _logger.e('Mark all read error: $e');
      // Optional: set errorMessage or show toast
    }
  }

  Future<void> markAsRead(String userToken, int notificationId) async {
    try {
      final response = await _notificationService.markNotificationRead(
        userToken,
        notificationId,
      );
      if (response['success'] == true) {
        final index = _notifications.indexWhere((n) => n.id == notificationId);
        if (index != -1) {
          final old = _notifications[index];
          _notifications[index] = NotificationModel(
            id: old.id,
            title: old.title,
            body: old.body,
            type: old.type,
            typeId: old.typeId,
            url: old.url,
            isRead: true,
            createDate: old.createDate,
          );
          notifyListeners();
        }
      }
    } catch (e) {
      _logger.e('Mark read error: $e');
    }
  }

  Future<void> deleteNotification(String userToken, int notificationId) async {
    try {
      final response = await _notificationService.deleteNotification(
        userToken,
        notificationId,
      );
      if (response['success'] == true) {
        _notifications.removeWhere((n) => n.id == notificationId);
        notifyListeners();
      }
    } catch (e) {
      _logger.e('Delete notification error: $e');
    }
  }

  Future<void> deleteAllNotifications(String userToken) async {
    try {
      final response = await _notificationService.deleteAllNotifications(
        userToken,
      );
      if (response['success'] == true) {
        _notifications.clear();
        notifyListeners();
      }
    } catch (e) {
      _logger.e('Delete all notification error: $e');
    }
  }
}
