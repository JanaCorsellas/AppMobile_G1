import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_application_1/config/api_constants.dart';
import 'package:flutter_application_1/models/notification.dart';
import 'package:flutter_application_1/services/http_service.dart';
import 'package:flutter_application_1/services/socket_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:socket_io_client/socket_io_client.dart';

class NotificationService extends ChangeNotifier {
  final HttpService _httpService;
  final SocketService _socketService;
  
  List<Notification> _notifications = [];
  List<Notification> _unreadNotifications = [];
  int _unreadCount = 0;
  bool _isLoading = false;
  String _error = '';
  
  // Getters
  List<Notification> get notifications => _notifications;
  List<Notification> get unreadNotifications => _unreadNotifications;
  int get unreadCount => _unreadCount;
  bool get isLoading => _isLoading;
  String get error => _error;
  
  NotificationService(this._httpService, this._socketService) {
    print('🔔 NotificationService: Inicializando...');
    _initializeSocketListeners();
    _loadCachedData();
  }
  
  // Inicializar escuchas de Socket.IO
  void _initializeSocketListeners() {
    print('🔔 NotificationService: Configurando escuchas de socket');
    _socketService.socket.on('notification', _handleNewNotification);
    _socketService.socket.on('unread_notifications_count', _handleUnreadCount);
    
    // Cuando el socket se conecta, pedimos el conteo de notificaciones no leídas
    _socketService.socket.onConnect((_) {
      print('🔔 NotificationService: Socket conectado, solicitando conteo de notificaciones');
      _socketService.socket.emit('get_unread_notifications_count');
      
      // Crear notificación de prueba (comentar en producción)
      _createTestNotification();
    });
  }
  
  // Crear notificación de prueba para desarrollo
  void _createTestNotification() async {
    // Solo en modo desarrollo
    if (kDebugMode) {
      print('🔔 NotificationService: Creando notificación de prueba');
      
      // Esperar 2 segundos para asegurarnos de que el usuario está conectado
      await Future.delayed(const Duration(seconds: 2));
      
      // Crear notificación local
      final testNotification = Notification(
        id: 'test_${DateTime.now().millisecondsSinceEpoch}',
        recipientId: _socketService.socket.auth?['userId'] ?? '',
        sender: SenderInfo(
          id: 'system',
          username: 'Sistema',
        ),
        type: 'system',
        content: 'Bienvenido a la aplicación. Esta es una notificación de prueba.',
        isRead: false,
        createdAt: DateTime.now(),
      );
      
      // Añadir a las listas
      _notifications.insert(0, testNotification);
      _unreadNotifications.insert(0, testNotification);
      _unreadCount++;
      
      // Guardar en caché
      _saveToCache();
      
      // Notificar
      notifyListeners();
    }
  }
  
  // Cargar datos en caché
  Future<void> _loadCachedData() async {
    try {
      print('🔔 NotificationService: Cargando datos de caché');
      final prefs = await SharedPreferences.getInstance();
      final notificationsJson = prefs.getString('notifications');
      final unreadCountStr = prefs.getString('unread_notifications_count');
      
      if (notificationsJson != null) {
        print('🔔 NotificationService: Datos de notificaciones encontrados en caché');
        final List<dynamic> decodedData = json.decode(notificationsJson);
        _notifications = decodedData
            .map((item) => Notification.fromJson(item))
            .toList();
            
        // Filtrar notificaciones no leídas
        _unreadNotifications = _notifications
            .where((notification) => !notification.isRead)
            .toList();
            
        print('🔔 NotificationService: Cargadas ${_notifications.length} notificaciones, ${_unreadNotifications.length} no leídas');
      }
      
      if (unreadCountStr != null) {
        _unreadCount = int.tryParse(unreadCountStr) ?? 0;
        print('🔔 NotificationService: Conteo de no leídas cargado: $_unreadCount');
      }
      
      notifyListeners();
    } catch (e) {
      _error = 'Error loading cached notifications: $e';
      print('🔔 NotificationService: $_error');
    }
  }
  
  // Manejar nueva notificación desde Socket.IO
  void _handleNewNotification(dynamic data) {
    try {
      print('🔔 NotificationService: Nueva notificación recibida: $data');
      
      // Asegurarse de que el dato sea un mapa
      final Map<String, dynamic> notificationData;
      if (data is Map<String, dynamic>) {
        notificationData = data;
      } else if (data is String) {
        notificationData = json.decode(data);
      } else {
        print('🔔 NotificationService: Formato de notificación desconocido: $data');
        return;
      }
      
      final notification = Notification.fromJson(notificationData);
      
      // Añadir a la lista de notificaciones
      _notifications.insert(0, notification);
      
      // Si no está leída, añadir a la lista de no leídas
      if (!notification.isRead) {
        _unreadNotifications.insert(0, notification);
        _unreadCount++;
      }
      
      // Guardar en caché
      _saveToCache();
      
      notifyListeners();
    } catch (e) {
      _error = 'Error processing notification: $e';
      print('🔔 NotificationService: $_error');
    }
  }
  
  // Manejar contador de notificaciones no leídas
  void _handleUnreadCount(dynamic count) {
    try {
      print('🔔 NotificationService: Conteo de notificaciones no leídas actualizado: $count');
      if (count is int) {
        _unreadCount = count;
      } else if (count is String) {
        _unreadCount = int.tryParse(count) ?? _unreadCount;
      } else if (count is Map && count.containsKey('count')) {
        _unreadCount = count['count'] is int ? count['count'] : int.tryParse(count['count'].toString()) ?? _unreadCount;
      }
      
      // Guardar en caché
      _saveUnreadCountToCache();
      
      notifyListeners();
    } catch (e) {
      _error = 'Error processing unread count: $e';
      print('🔔 NotificationService: $_error');
    }
  }
  
  // Guardar notificaciones en caché
  Future<void> _saveToCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        'notifications',
        json.encode(_notifications.map((n) => n.toJson()).toList()),
      );
      print('🔔 NotificationService: Notificaciones guardadas en caché: ${_notifications.length}');
    } catch (e) {
      _error = 'Error saving notifications to cache: $e';
      print('🔔 NotificationService: $_error');
    }
  }
  
  // Guardar contador de no leídas en caché
  Future<void> _saveUnreadCountToCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('unread_notifications_count', _unreadCount.toString());
      print('🔔 NotificationService: Conteo de no leídas guardado en caché: $_unreadCount');
    } catch (e) {
      _error = 'Error saving unread count to cache: $e';
      print('🔔 NotificationService: $_error');
    }
  }
  
  // Obtener notificaciones para el usuario actual
  Future<void> getNotifications({int page = 1, int limit = 20}) async {
    _isLoading = true;
    notifyListeners();
    
    try {
      print('🔔 NotificationService: Solicitando notificaciones (página $page, límite $limit)');
      
      // Intentar obtener usuario actual del socket
      final userId = _socketService.socket.auth?['userId'];
      if (userId == null || userId.isEmpty) {
        print('🔔 NotificationService: No se pudo obtener el ID de usuario del socket');
        throw Exception('No se pudo obtener el ID de usuario');
      }
      
      final uri = Uri.parse('${ApiConstants.baseUrl}/api/notifications/user/$userId')
          .replace(queryParameters: {
            'page': page.toString(),
            'limit': limit.toString(),
          });
      
      print('🔔 NotificationService: Realizando petición a ${uri.toString()}');
      final response = await _httpService.get(uri.toString());
      
      // Si la API aún no está lista, crear notificaciones de prueba locales
      if (response.statusCode >= 400) {
        print('🔔 NotificationService: API no disponible, creando datos de prueba');
        _createTestNotifications();
        return;
      }
      
      final data = await _httpService.parseJsonResponse(response);
      
      print('🔔 NotificationService: Respuesta recibida: $data');
      
      final List<Notification> fetchedNotifications = [];
      
      if (data['notifications'] != null) {
        for (var item in data['notifications']) {
          fetchedNotifications.add(Notification.fromJson(item));
        }
      }
      
      // Si es la primera página, reemplaza la lista, si no, añade
      if (page == 1) {
        _notifications = fetchedNotifications;
      } else {
        _notifications.addAll(fetchedNotifications);
      }
      
      // Actualizar lista de no leídas
      _updateUnreadNotifications();
      
      // Guardar en caché
      _saveToCache();
      
    } catch (e) {
      _error = 'Error fetching notifications: $e';
      print('🔔 NotificationService: $_error');
      
      // Si hay un error, crear notificaciones de prueba
      _createTestNotifications();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
  
  // Crear notificaciones de prueba cuando la API no está disponible
  void _createTestNotifications() {
    print('🔔 NotificationService: Creando notificaciones de prueba');
    
    // Solo en modo desarrollo
    if (kReleaseMode) return;
    
    final now = DateTime.now();
    
    // Tipos de notificación de ejemplo
    final types = ['chat', 'activity', 'challenge', 'achievement', 'follow', 'system'];
    final contents = [
      'Tienes un nuevo mensaje en el chat',
      'Pedro ha comentado en tu actividad "Carrera matutina"',
      'Se ha creado un nuevo reto: "5K en menos de 30 minutos"',
      '¡Has desbloqueado el logro "Corredor regular"!',
      'María ha comenzado a seguirte',
      'Bienvenido a la aplicación'
    ];
    
    _notifications = [];
    
    // Crear 5 notificaciones de prueba
    for (int i = 0; i < 5; i++) {
      final typeIndex = i % types.length;
      
      _notifications.add(
        Notification(
          id: 'test_$i',
          recipientId: _socketService.socket.auth?['userId'] ?? 'user_test',
          sender: SenderInfo(
            id: 'sender_$i',
            username: 'Usuario de prueba ${i+1}',
          ),
          type: types[typeIndex],
          content: contents[typeIndex],
          isRead: i > 2, // Primeras 3 no leídas
          createdAt: now.subtract(Duration(hours: i)),
        ),
      );
    }
    
    // Actualizar lista de no leídas
    _updateUnreadNotifications();
    
    // Guardar en caché
    _saveToCache();
  }
  
  // Actualizar lista de notificaciones no leídas
  void _updateUnreadNotifications() {
    _unreadNotifications = _notifications
        .where((notification) => !notification.isRead)
        .toList();
        
    _unreadCount = _unreadNotifications.length;
    
    print('🔔 NotificationService: Notificaciones no leídas actualizadas: $_unreadCount');
  }
  
  // Obtener notificaciones no leídas
  Future<void> getUnreadNotifications({int limit = 10}) async {
    _isLoading = true;
    notifyListeners();
    
    try {
      print('🔔 NotificationService: Solicitando notificaciones no leídas (límite $limit)');
      
      // Intentar obtener usuario actual del socket
      final userId = _socketService.socket.auth?['userId'];
      if (userId == null || userId.isEmpty) {
        print('🔔 NotificationService: No se pudo obtener el ID de usuario del socket');
        throw Exception('No se pudo obtener el ID de usuario');
      }
      
      final uri = Uri.parse('${ApiConstants.baseUrl}/api/notifications/unread/$userId')
          .replace(queryParameters: {'limit': limit.toString()});
      
      final response = await _httpService.get(uri.toString());
      
      // Si la API aún no está lista, usar datos locales
      if (response.statusCode >= 400) {
        print('🔔 NotificationService: API no disponible, usando datos locales');
        return;
      }
      
      final data = await _httpService.parseJsonResponse(response);
      
      _unreadNotifications = [];
      
      if (data is List) {
        for (var item in data) {
          _unreadNotifications.add(Notification.fromJson(item));
        }
      }
      
      // Actualizar contador
      _unreadCount = _unreadNotifications.length;
      _saveUnreadCountToCache();
      
    } catch (e) {
      _error = 'Error fetching unread notifications: $e';
      print('🔔 NotificationService: $_error');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
  
  // Obtener conteo de notificaciones no leídas
  Future<void> getUnreadCount() async {
    try {
      print('🔔 NotificationService: Solicitando conteo de no leídas');
      
      // Intentar obtener usuario actual del socket
      final userId = _socketService.socket.auth?['userId'];
      if (userId == null || userId.isEmpty) {
        print('🔔 NotificationService: No se pudo obtener el ID de usuario del socket');
        return;
      }
      
      final response = await _httpService.get(
        '${ApiConstants.baseUrl}/api/notifications/count/$userId',
      );
      
      // Si la API aún no está lista, usar datos locales
      if (response.statusCode >= 400) {
        print('🔔 NotificationService: API no disponible, usando conteo local');
        return;
      }
      
      final data = await _httpService.parseJsonResponse(response);
      
      if (data['count'] != null) {
        _unreadCount = data['count'];
        _saveUnreadCountToCache();
        notifyListeners();
      }
    } catch (e) {
      _error = 'Error fetching unread count: $e';
      print('🔔 NotificationService: $_error');
    }
  }
  
  // Marcar notificación como leída
  Future<bool> markAsRead(String notificationId) async {
    try {
      print('🔔 NotificationService: Marcando como leída: $notificationId');
      
      final index = _notifications.indexWhere((n) => n.id == notificationId);
      if (index == -1) {
        print('🔔 NotificationService: Notificación no encontrada: $notificationId');
        return false;
      }
      
      // Si ya está leída, no hacer nada
      if (_notifications[index].isRead) {
        print('🔔 NotificationService: La notificación ya está leída');
        return true;
      }
      
      // Actualizar localmente
      final notification = _notifications[index];
      _notifications[index] = notification.copyWith(isRead: true);
      
      // Actualizar lista de no leídas
      _updateUnreadNotifications();
      
      // Guardar en caché
      _saveToCache();
      _saveUnreadCountToCache();
      
      notifyListeners();
      
      // Intentar actualizar en el servidor
      try {
        final response = await _httpService.put(
          '${ApiConstants.baseUrl}/api/notifications/$notificationId/mark-read',
          body: {},
        );
        
        return response.statusCode >= 200 && response.statusCode < 300;
      } catch (e) {
        print('🔔 NotificationService: Error al actualizar en el servidor: $e');
        return true; // Devolvemos true porque se actualizó localmente
      }
    } catch (e) {
      _error = 'Error marking notification as read: $e';
      print('🔔 NotificationService: $_error');
      return false;
    }
  }
  
  // Marcar todas las notificaciones como leídas
  Future<bool> markAllAsRead() async {
    try {
      print('🔔 NotificationService: Marcando todas como leídas');
      
      // Actualizar localmente
      final List<Notification> updatedNotifications = _notifications.map((notification) {
        return notification.copyWith(isRead: true);
      }).toList();
      
      _notifications = updatedNotifications;
      
      // Vaciar lista de no leídas
      _unreadNotifications = [];
      _unreadCount = 0;
      
      // Guardar en caché
      _saveToCache();
      _saveUnreadCountToCache();
      
      notifyListeners();
      
      // Intentar actualizar en el servidor
      try {
        // Intentar obtener usuario actual del socket
        final userId = _socketService.socket.auth?['userId'];
        if (userId == null || userId.isEmpty) {
          print('🔔 NotificationService: No se pudo obtener el ID de usuario del socket');
          return true; // Devolvemos true porque se actualizó localmente
        }
        
        final response = await _httpService.put(
          '${ApiConstants.baseUrl}/api/notifications/mark-all-read',
          body: {'userId': userId},
        );
        
        return response.statusCode >= 200 && response.statusCode < 300;
      } catch (e) {
        print('🔔 NotificationService: Error al actualizar en el servidor: $e');
        return true; // Devolvemos true porque se actualizó localmente
      }
    } catch (e) {
      _error = 'Error marking all notifications as read: $e';
      print('🔔 NotificationService: $_error');
      return false;
    }
  }
  
  // Eliminar notificación
  Future<bool> deleteNotification(String notificationId) async {
    try {
      print('🔔 NotificationService: Eliminando notificación: $notificationId');
      
      // Verificar si la notificación no está leída antes de eliminarla
      final notification = _notifications.firstWhere(
        (n) => n.id == notificationId,
        orElse: () => null as Notification, // Esto nunca se usará realmente
      );
      
      bool wasUnread = false;
      if (notification != null && !notification.isRead) {
        wasUnread = true;
      }
      
      // Eliminar de las listas
      _notifications.removeWhere((n) => n.id == notificationId);
      _unreadNotifications.removeWhere((n) => n.id == notificationId);
      
      // Actualizar contador si era no leída
      if (wasUnread) {
        _unreadCount = _unreadCount > 0 ? _unreadCount - 1 : 0;
      }
      
      // Guardar en caché
      _saveToCache();
      _saveUnreadCountToCache();
      
      notifyListeners();
      
      // Intentar eliminar en el servidor
      try {
        final response = await _httpService.delete(
          '${ApiConstants.baseUrl}/api/notifications/$notificationId',
        );
        
        return response.statusCode >= 200 && response.statusCode < 300;
      } catch (e) {
        print('🔔 NotificationService: Error al eliminar en el servidor: $e');
        return true; // Devolvemos true porque se eliminó localmente
      }
    } catch (e) {
      _error = 'Error deleting notification: $e';
      print('🔔 NotificationService: $_error');
      return false;
    }
  }
  
  // Limpiar errores
  void clearError() {
    _error = '';
    notifyListeners();
  }
  
  @override
  void dispose() {
    print('🔔 NotificationService: Disposing...');
    _socketService.socket.off('notification');
    _socketService.socket.off('unread_notifications_count');
    super.dispose();
  }
}