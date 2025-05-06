import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_application_1/config/api_constants.dart';
import 'package:flutter_application_1/models/notification_models.dart';
import 'package:flutter_application_1/services/http_service.dart';
import 'package:flutter_application_1/services/socket_service.dart';

class NotificationService with ChangeNotifier {
  final HttpService _httpService;
  final SocketService _socketService;
  
  List<NotificationModel> _notifications = [];
  bool _isLoading = false;
  int _unreadCount = 0;
  bool _isInitialized = false;
  
  NotificationService(this._httpService, this._socketService) {
    _setupSocketListeners();
  }
  
  List<NotificationModel> get notifications => _notifications;
  bool get isLoading => _isLoading;
  int get unreadCount => _unreadCount;
  
  void _setupSocketListeners() {
    _socketService.socket.on('new_notification', (data) {
      print('New notification received via Socket.IO: $data');
      _handleNewNotification(data);
    });
  }
  
  Future<void> initialize(String userId) async {
    if (_isInitialized) return;
    
    await _loadCachedNotifications();
    await fetchNotifications(userId);
    
    _isInitialized = true;
  }
  
  Future<void> fetchNotifications(String userId, {bool onlyUnread = false, int page = 1, int limit = 20}) async {
    if (userId.isEmpty) return;
    
    _isLoading = true;
    notifyListeners();
    
    try {
      final uri = Uri.parse(ApiConstants.notifications(userId)).replace(
        queryParameters: {
          'unread': onlyUnread.toString(),
          'page': page.toString(),
          'limit': limit.toString(),
        },
      );
      
      final response = await _httpService.get(uri.toString());
      final data = await _httpService.parseJsonResponse(response);
      
      if (page == 1) {
        _notifications = [];
      }
      
      if (data['notifications'] != null && data['notifications'] is List) {
        for (var item in data['notifications']) {
          final notification = NotificationModel.fromJson(item);
          _notifications.add(notification);
        }
      }
      
      _unreadCount = data['unread'] ?? 0;
      await _saveNotificationsToCache();
      
    } catch (e) {
      print('Error fetching notifications: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
  
  Future<bool> markAsRead(String notificationId) async {
    try {
      final response = await _httpService.put(
        ApiConstants.markNotificationRead(notificationId)
      );
      
      if (response.statusCode >= 200 && response.statusCode < 300) {
        final index = _notifications.indexWhere((n) => n.id == notificationId);
        if (index != -1) {
          final notification = _notifications[index];
          if (!notification.read) {
            final updatedNotification = NotificationModel(
              id: notification.id,
              type: notification.type,
              title: notification.title,
              message: notification.message,
              data: notification.data,
              read: true,
              createdAt: notification.createdAt,
            );
            
            _notifications[index] = updatedNotification;
            _unreadCount = _unreadCount > 0 ? _unreadCount - 1 : 0;
            await _saveNotificationsToCache();
            notifyListeners();
          }
        }
        return true;
      }
      return false;
    } catch (e) {
      print('Error marking notification as read: $e');
      return false;
    }
  }
  
  Future<bool> markAllAsRead(String userId) async {
    try {
      final response = await _httpService.put(
        ApiConstants.markAllNotificationsRead(userId)
      );
      
      if (response.statusCode >= 200 && response.statusCode < 300) {
        _notifications = _notifications.map((notification) => 
          NotificationModel(
            id: notification.id,
            type: notification.type,
            title: notification.title,
            message: notification.message,
            data: notification.data,
            read: true,
            createdAt: notification.createdAt,
          )
        ).toList();
        
        _unreadCount = 0;
        await _saveNotificationsToCache();
        notifyListeners();
        return true;
      }
      return false;
    } catch (e) {
      print('Error marking all notifications as read: $e');
      return false;
    }
  }
  
  Future<bool> deleteNotification(String notificationId) async {
    try {
      final response = await _httpService.delete(
        ApiConstants.deleteNotification(notificationId)
      );
      
      if (response.statusCode >= 200 && response.statusCode < 300) {
        final index = _notifications.indexWhere((n) => n.id == notificationId);
        if (index != -1) {
          final wasUnread = !_notifications[index].read;
          _notifications.removeAt(index);
          
          if (wasUnread) {
            _unreadCount = _unreadCount > 0 ? _unreadCount - 1 : 0;
          }
          
          await _saveNotificationsToCache();
          notifyListeners();
        }
        return true;
      }
      return false;
    } catch (e) {
      print('Error deleting notification: $e');
      return false;
    }
  }
  
  void _handleNewNotification(dynamic data) {
    try {
      if (data == null) return;
      
      final Map<String, dynamic> notificationData = 
          data is Map<String, dynamic> ? data : json.decode(json.encode(data));
      
      if (!notificationData.containsKey('_id') && !notificationData.containsKey('id')) {
        notificationData['id'] = DateTime.now().millisecondsSinceEpoch.toString();
      }
      
      final notification = NotificationModel.fromJson(notificationData);
      _notifications.insert(0, notification);
      
      if (!notification.read) {
        _unreadCount++;
      }
      
      _saveNotificationsToCache();
      notifyListeners();
    } catch (e) {
      print('Error handling new notification: $e');
    }
  }
  
  Future<void> _saveNotificationsToCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final notificationsJson = json.encode(
        _notifications.map((notification) => notification.toJson()).toList(),
      );
      await prefs.setString('cached_notifications', notificationsJson);
    } catch (e) {
      print('Error saving notifications to cache: $e');
    }
  }

  Future<void> _loadCachedNotifications() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cachedData = prefs.getString('cached_notifications');
      
      if (cachedData != null) {
        final List<dynamic> notificationsJson = json.decode(cachedData);
        _notifications = notificationsJson
            .map((item) => NotificationModel.fromJson(item))
            .toList();
        _unreadCount = _notifications.where((n) => !n.read).length;
        notifyListeners();
      }
    } catch (e) {
      print('Error loading cached notifications: $e');
    }
  }

  void clearNotifications() {
    _notifications = [];
    _unreadCount = 0;
    _saveNotificationsToCache();
    notifyListeners();
  }
  
  NotificationModel? getNotificationById(String id) {
    try {
      return _notifications.firstWhere((n) => n.id == id);
    } catch (e) {
      return null;
    }
  }
  
  bool notificationRequiresAction(NotificationModel notification) {
    return notification.type == 'friend_request' || 
           notification.type == 'challenge_invitation';
  }
  
  @override
  void dispose() {
    _socketService.socket.off('new_notification');
    super.dispose();
  }
}