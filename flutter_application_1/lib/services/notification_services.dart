import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_application_1/config/api_constants.dart';
import 'package:flutter_application_1/models/notification_models.dart';
import 'package:flutter_application_1/services/http_service.dart';
import 'package:flutter_application_1/services/socket_service.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

class NotificationService with ChangeNotifier {
  final HttpService _httpService;
  final SocketService _socketService;
  
  List<NotificationModel> _notifications = [];
  bool _isLoading = false;
  int _unreadCount = 0;
  bool _isInitialized = false;

  String? _fcmToken;
  String? get fcmToken => _fcmToken;
  
  NotificationService(this._httpService, this._socketService);
  
  List<NotificationModel> get notifications => _notifications;
  bool get isLoading => _isLoading;
  int get unreadCount => _unreadCount;

  static GlobalKey<ScaffoldMessengerState>? _scaffoldMessengerKey;

  static void setScaffoldMessengerKey(GlobalKey<ScaffoldMessengerState> key) {
    _scaffoldMessengerKey = key;
  }

  Future<void> setupFirebaseMessaging() async {
  // Obtener el token FCM
    try {
      _fcmToken = await FirebaseMessaging.instance.getToken();
      print('FCM Token: $_fcmToken');
    
      // Aquí deberías enviar el token a tu servidor
      if (_fcmToken != null) {
        await _sendTokenToServer(_fcmToken!);
      }
    } catch (e) {
      print('Error obteniendo FCM token: $e');
    }

    // Listeners existentes
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      print('Received a foreground FCM message: ${message.notification?.title}');
      _handleFirebaseFCM(message);
    });

    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      print('FCM notification clicked!');
      _handleFirebaseFCM(message);
    });

    // Listener para cuando el token se actualiza
    FirebaseMessaging.instance.onTokenRefresh.listen((newToken) {
      print('FCM Token refreshed: $newToken');
      _fcmToken = newToken;
      _sendTokenToServer(newToken);
    });
  }

  void _handleFirebaseFCM(RemoteMessage message) {
    final data = message.data;
    final notificationData = {
      'id': data['id'] ?? DateTime.now().millisecondsSinceEpoch.toString(),
      'type': data['type'] ?? 'chat_message',
      'title': data['title'] ?? message.notification?.title ?? 'Nuevo mensaje',
      'message': data['body'] ?? message.notification?.body ?? '',
      'data': data,
      'read': false,
      'createdAt': DateTime.now().toIso8601String(),
    };

    _handleNewNotification(notificationData);

    _showInAppNotification(
      title: notificationData['title']!,
      message: notificationData['message']!,
      type: notificationData['type']!,
    );
  }
  void _showInAppNotification({
    required String title,
    required String message,
    required String type,
  }) {
    if (_scaffoldMessengerKey?.currentState == null) {
      print('ScaffoldMessenger no disponible, mostrando en consola:');
      print('$title: $message');
      return;
    }

    _scaffoldMessengerKey!.currentState!.showSnackBar(
      SnackBar(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.white,
                fontSize: 16,
              ),
            ),
            if (message.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                message,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                ),
              ),
            ],
          ],
        ),
        backgroundColor: _getColorForType(type),
        duration: const Duration(seconds: 5),
        action: SnackBarAction(
          label: 'Ver',
          textColor: Colors.white,
          onPressed: () {
            // Navegar a notificaciones - puedes ajustar esto
            print('Navegar a notificaciones');
          },
        ),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  }

  Color _getColorForType(String type) {
    switch (type) {
      case 'chat_message':
        return Colors.teal;
      case 'friend_request':
        return Colors.blue;
      case 'achievement_unlocked':
        return Colors.amber;
      case 'challenge_completed':
        return Colors.green;
      default:
        return Colors.deepPurple;
    }
  }

  IconData _getIconForType(String type) {
    switch (type) {
      case 'chat_message':
        return Icons.chat;
      case 'friend_request':
        return Icons.person_add;
      case 'achievement_unlocked':
        return Icons.emoji_events;
      case 'challenge_completed':
        return Icons.flag;
      default:
        return Icons.notifications;
    }
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
      
      if (data is List) {
        for (var item in data) {
          final notification = NotificationModel.fromJson(item);
          _notifications.add(notification);
        }
      }
      
      //_unreadCount = data['unread'] ?? 0;
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

  Future<void> _sendTokenToServer(String token) async {
  try {
    // Por ahora solo imprimir, luego configurar la ruta del servidor
    print('Enviando FCM token al servidor: $token');
    
    // TODO: Descomentar cuando tengas la ruta en tu API
    /*
    final response = await _httpService.post(
      ApiConstants.updateFcmToken, // Crear esta ruta en api_constants.dart
      body: {
        'fcmToken': token,
        'platform': 'web',
      },
    );
    
    if (response.statusCode == 200) {
      print('FCM Token enviado al servidor exitosamente');
    } else {
      print('Error enviando FCM token al servidor: ${response.statusCode}');
    }
    */
  } catch (e) {
    print('Error enviando FCM token: $e');
  }
}
  
  @override
  void dispose() {
    _socketService.socket.off('new_notification');
    super.dispose();
  }
}