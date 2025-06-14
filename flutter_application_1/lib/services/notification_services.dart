import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_application_1/config/api_constants.dart';
import 'package:flutter_application_1/models/notification_models.dart';
import 'package:flutter_application_1/services/http_service.dart';
import 'package:flutter_application_1/services/socket_service.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationService with ChangeNotifier {
  final HttpService _httpService;
  final SocketService _socketService;
  
  List<NotificationModel> _notifications = [];
  bool _isLoading = false;
  int _unreadCount = 0;
  bool _isInitialized = false;
  String? _fcmToken;
  
  // Plugin para notificaciones locales
  final FlutterLocalNotificationsPlugin _localNotifications = 
      FlutterLocalNotificationsPlugin();
  
  NotificationService(this._httpService, this._socketService);
  
  List<NotificationModel> get notifications => _notifications;
  bool get isLoading => _isLoading;
  int get unreadCount => _unreadCount;
  String? get fcmToken => _fcmToken;

  /// Inicializa el servicio de notificaciones
  Future<void> initialize(String userId) async {
    if (_isInitialized) return;
    
    try {
      print("Inicializando NotificationService para usuario: $userId");
      
      await _initializeLocalNotifications();
      await _initializeFirebaseMessaging();
      await _loadCachedNotifications();
      await fetchNotifications(userId);
      await _sendFCMTokenToServer(userId);
      setupSocketNotifications();
      
      _isInitialized = true;
      print("NotificationService inicializado correctamente");
      
    } catch (e) {
      print("Error inicializando NotificationService: $e");
    }
  }

  /// Configura las notificaciones locales
  Future<void> _initializeLocalNotifications() async {
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    
    const DarwinInitializationSettings initializationSettingsIOS =
        DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    
    const InitializationSettings initializationSettings =
        InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsIOS,
    );
    
    await _localNotifications.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );
    
    print("Notificaciones locales inicializadas");
  }

  /// Maneja cuando el usuario toca una notificación local
  void _onNotificationTapped(NotificationResponse response) {
    final payload = response.payload;
    if (payload != null) {
      try {
        final data = json.decode(payload);
        print("Notificación tocada: ${data['type']}");
        // El main.dart ya maneja la navegación
      } catch (e) {
        print('Error parsing notification payload: $e');
      }
    }
  }

  /// Configura Firebase Messaging
  Future<void> _initializeFirebaseMessaging() async {
    try {
      // Obtener el token FCM
      _fcmToken = await FirebaseMessaging.instance.getToken();
      print("🔑 FCM Token obtenido: $_fcmToken");

      // Configurar listeners para mensajes
      setupFirebaseMessaging();
      
      // Escuchar cambios en el token
      FirebaseMessaging.instance.onTokenRefresh.listen((newToken) {
        _fcmToken = newToken;
        print("FCM Token actualizado: $newToken");
        _updateFCMTokenOnServer(newToken);
      });
      
    } catch (e) {
      print("Error configurando Firebase Messaging: $e");
    }
  }

  /// Configura listeners de Firebase Messaging
  void setupFirebaseMessaging() {
    // Mensajes cuando la app está en primer plano
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      print('Mensaje FCM recibido (foreground): ${message.notification?.title}');
      _showLocalNotification(message);
      _handleFirebaseFCM(message);
    });

    // Mensajes cuando la app se abre desde una notificación
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      print('Notificación FCM tocada: ${message.notification?.title}');
      _handleFirebaseFCM(message);
    });
  }

  /// Muestra una notificación local cuando la app está en primer plano
  Future<void> _showLocalNotification(RemoteMessage message) async {
    final notification = message.notification;
    if (notification == null) return;

    final type = message.data['type'] as String?;
    String channelId = 'general';
    String channelName = 'Notificaciones generales';
    String channelDescription = 'Notificaciones generales de la aplicación';
    
    // Personalizar canal según el tipo de notificación
    switch (type) {
      case 'friend_request':
        channelId = 'friend_requests';
        channelName = 'Solicitudes de amistad';
        channelDescription = 'Notificaciones de solicitudes de amistad';
        break;
      case 'activity_update':
        channelId = 'activity_updates';
        channelName = 'Actividades de amigos';
        channelDescription = 'Notificaciones cuando tus amigos publican nuevas actividades';
        break;
      case 'achievement_unlocked':
        channelId = 'achievements';
        channelName = 'Logros desbloqueados';
        channelDescription = 'Notificaciones de logros desbloqueados';
        break;
      case 'challenge_completed':
        channelId = 'challenges';
        channelName = 'Retos completados';
        channelDescription = 'Notificaciones de retos completados';
        break;
      case 'chat_message':
        channelId = 'chat_messages';
        channelName = 'Mensajes de chat';
        channelDescription = 'Notificaciones de mensajes de chat';
        break;
    }

    final androidDetails = AndroidNotificationDetails(
      channelId,
      channelName,
      channelDescription: channelDescription,
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
      enableVibration: true,
      playSound: true,
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    final details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _localNotifications.show(
      DateTime.now().millisecondsSinceEpoch.remainder(100000),
      notification.title,
      notification.body,
      details,
      payload: json.encode(message.data),
    );
  }

  /// Procesa notificaciones FCM y las agrega a la lista
  void _handleFirebaseFCM(RemoteMessage message) {
    final data = message.data;
    _handleNewNotification({
      'id': data['id'] ?? DateTime.now().millisecondsSinceEpoch.toString(),
      'type': data['type'] ?? 'general',
      'title': data['title'] ?? message.notification?.title ?? 'Nueva notificación',
      'message': data['body'] ?? message.notification?.body ?? '',
      'data': data,
      'read': false,
      'createdAt': DateTime.now().toIso8601String(),
    });
  }

  /// Envía el token FCM al servidor
  Future<void> _sendFCMTokenToServer(String userId) async {
    if (_fcmToken == null) {
      print("⚠️ No hay token FCM para enviar al servidor");
      return;
    }

    try {
      final response = await _httpService.post(
        '${ApiConstants.baseUrl}/api/users/$userId/fcm-token',
        body: {
          'fcmToken': _fcmToken,
        },
      );
      
      if (response.statusCode >= 200 && response.statusCode < 300) {
        print('Token FCM enviado al servidor correctamente');
      } else {
        print('Error enviando token FCM: ${response.statusCode}');
        print('Respuesta del servidor: ${response.body}');
      }
    } catch (e) {
      print('Error enviando token FCM al servidor: $e');
    }
  }

  /// Actualiza el token FCM en el servidor cuando se renueva
  Future<void> _updateFCMTokenOnServer(String newToken) async {
    try {
      final response = await _httpService.put(
        '${ApiConstants.baseUrl}/api/users/fcm-token',
        body: {
          'fcmToken': newToken,
        },
      );
      
      if (response.statusCode >= 200 && response.statusCode < 300) {
        print('Token FCM actualizado en servidor');
      } else {
        print('Error actualizando token FCM: ${response.statusCode}');
        print('Respuesta del servidor: ${response.body}');
      }
    } catch (e) {
      print('Error actualizando token FCM en servidor: $e');
    }
  }

  /// Envía una notificación de prueba (para testing)
  Future<bool> sendTestNotification(String userId) async {
    try {
      final response = await _httpService.post(
        '${ApiConstants.baseUrl}/api/users/$userId/test-notification',
        body: {
          'title': 'Notificación de prueba',
          'body': 'Esta es una notificación de prueba desde la app',
          'type': 'test'
        },
      );
      
      if (response.statusCode >= 200 && response.statusCode < 300) {
        print('Notificación de prueba enviada correctamente');
        return true;
      } else {
        print('Error enviando notificación de prueba: ${response.statusCode}');
        print('Respuesta: ${response.body}');
        return false;
      }
    } catch (e) {
      print('Error enviando notificación de prueba: $e');
      return false;
    }
  }

  /// Maneja nuevas notificaciones y las agrega a la lista
  void _handleNewNotification(Map<String, dynamic> notificationData) {
    try {
      final notification = NotificationModel.fromJson(notificationData);
      
      // Verificar si ya existe para evitar duplicados
      final existingIndex = _notifications.indexWhere((n) => n.id == notification.id);
      if (existingIndex != -1) {
        print("Notificación duplicada ignorada: ${notification.id}");
        return;
      }
      
      // Agregar al inicio de la lista
      _notifications.insert(0, notification);
      
      // Incrementar contador de no leídas
      if (!notification.read) {
        _unreadCount++;
      }
      
      // Limitar el número de notificaciones en memoria
      if (_notifications.length > 100) {
        _notifications = _notifications.take(100).toList();
      }
      
      _saveNotificationsToCache();
      notifyListeners();
      
      print("Nueva notificación agregada: ${notification.title}");
    } catch (e) {
      print('Error manejando nueva notificación: $e');
    }
  }

  /// Obtiene notificaciones del servidor
  Future<void> fetchNotifications(String userId, {bool onlyUnread = false, int page = 1, int limit = 20}) async {
    if (userId.isEmpty) return;
    
    _isLoading = true;
    notifyListeners();
    
    try {
      final uri = Uri.parse('${ApiConstants.baseUrl}/api/notifications/$userId').replace(
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
      
      if (data is Map && data['notifications'] is List) {
        final notificationsList = data['notifications'] as List;
        for (var item in notificationsList) {
          final notification = NotificationModel.fromJson(item);
          _notifications.add(notification);
        }
        _unreadCount = data['unreadCount'] ?? 0;
      } else if (data is List) {
        for (var item in data) {
          final notification = NotificationModel.fromJson(item);
          _notifications.add(notification);
        }
        _unreadCount = _notifications.where((n) => !n.read).length;
      }
      
      await _saveNotificationsToCache();
      print("${_notifications.length} notificaciones cargadas del servidor");
      
    } catch (e) {
      print('Error obteniendo notificaciones: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Marca una notificación como leída
  Future<bool> markAsRead(String notificationId) async {
    try {
      final response = await _httpService.put(
        '${ApiConstants.baseUrl}/api/notifications/$notificationId/read'
      );
      
      if (response.statusCode >= 200 && response.statusCode < 300) {
        final index = _notifications.indexWhere((n) => n.id == notificationId);
        if (index != -1 && !_notifications[index].read) {
          final notification = _notifications[index];
          _notifications[index] = NotificationModel(
            id: notification.id,
            type: notification.type,
            title: notification.title,
            message: notification.message,
            data: notification.data,
            read: true,
            createdAt: notification.createdAt,
          );
          
          _unreadCount = (_unreadCount - 1).clamp(0, double.infinity).toInt();
          await _saveNotificationsToCache();
          notifyListeners();
        }
        return true;
      }
      return false;
    } catch (e) {
      print('Error marcando notificación como leída: $e');
      return false;
    }
  }

  /// Marca todas las notificaciones como leídas
  Future<bool> markAllAsRead(String userId) async {
    try {
      final response = await _httpService.put(
        '${ApiConstants.baseUrl}/api/notifications/$userId/read-all'
      );
      
      if (response.statusCode >= 200 && response.statusCode < 300) {
        for (int i = 0; i < _notifications.length; i++) {
          if (!_notifications[i].read) {
            final notification = _notifications[i];
            _notifications[i] = NotificationModel(
              id: notification.id,
              type: notification.type,
              title: notification.title,
              message: notification.message,
              data: notification.data,
              read: true,
              createdAt: notification.createdAt,
            );
          }
        }
        _unreadCount = 0;
        await _saveNotificationsToCache();
        notifyListeners();
        return true;
      }
      return false;
    } catch (e) {
      print('Error marcando todas las notificaciones como leídas: $e');
      return false;
    }
  }

  /// Elimina una notificación
  Future<bool> deleteNotification(String notificationId) async {
    try {
      final response = await _httpService.delete(
        '${ApiConstants.baseUrl}/api/notifications/$notificationId'
      );
      
      if (response.statusCode >= 200 && response.statusCode < 300) {
        final index = _notifications.indexWhere((n) => n.id == notificationId);
        if (index != -1) {
          if (!_notifications[index].read) {
            _unreadCount = (_unreadCount - 1).clamp(0, double.infinity).toInt();
          }
          _notifications.removeAt(index);
          await _saveNotificationsToCache();
          notifyListeners();
        }
        return true;
      }
      return false;
    } catch (e) {
      print('Error eliminando notificación: $e');
      return false;
    }
  }

  /// Guarda notificaciones en caché local
  Future<void> _saveNotificationsToCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final notificationsJson = _notifications.map((n) => n.toJson()).toList();
      await prefs.setString('cached_notifications', json.encode(notificationsJson));
      await prefs.setInt('unread_count', _unreadCount);
    } catch (e) {
      print('Error guardando notificaciones en caché: $e');
    }
  }

  /// Carga notificaciones desde caché local
  Future<void> _loadCachedNotifications() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cachedData = prefs.getString('cached_notifications');
      final cachedUnreadCount = prefs.getInt('unread_count') ?? 0;
      
      if (cachedData != null) {
        final List<dynamic> notificationsJson = json.decode(cachedData);
        _notifications = notificationsJson
            .map((json) => NotificationModel.fromJson(json))
            .toList();
        _unreadCount = cachedUnreadCount;
        notifyListeners();
        print("${_notifications.length} notificaciones cargadas desde caché");
      }
    } catch (e) {
      print('Error cargando notificaciones desde caché: $e');
    }
  }

  /// Configura escucha de notificaciones en tiempo real vía Socket
  void setupSocketNotifications() {
    _socketService.socket?.on('new_notification', (data) {
      print('Notificación recibida vía socket: $data');
      _handleNewNotification(data);
    });
    
    _socketService.socket?.on('notification_deleted', (data) {
      if (data['notificationId'] != null) {
        final notificationId = data['notificationId'].toString();
        final index = _notifications.indexWhere((n) => n.id == notificationId);
        if (index != -1) {
          if (!_notifications[index].read) {
            _unreadCount = (_unreadCount - 1).clamp(0, double.infinity).toInt();
          }
          _notifications.removeAt(index);
          _saveNotificationsToCache();
          notifyListeners();
        }
      }
    });
  }

  /// Limpia todas las notificaciones
  void clearNotifications() {
    _notifications.clear();
    _unreadCount = 0;
    _saveNotificationsToCache();
    notifyListeners();
  }

  /// Obtiene una notificación por ID
  NotificationModel? getNotificationById(String id) {
    try {
      return _notifications.firstWhere((n) => n.id == id);
    } catch (e) {
      return null;
    }
  }

  /// Verifica si una notificación requiere acción del usuario
  bool notificationRequiresAction(NotificationModel notification) {
    return notification.type == 'friend_request' || 
           notification.type == 'challenge_invitation';
  }

  @override
  void dispose() {
    _localNotifications.cancelAll();
    _socketService.socket?.off('new_notification');
    _socketService.socket?.off('notification_deleted');
    super.dispose();
  }
}