import 'package:flutter/material.dart';
import 'package:flutter_application_1/models/notification.dart' as app;
import 'package:flutter_application_1/services/notification_service.dart';

class NotificationProvider with ChangeNotifier {
  final NotificationService _notificationService;
  
  NotificationProvider(this._notificationService) {
    // Escuchar cambios en el servicio de notificaciones
    _notificationService.addListener(_onServiceChanged);
  }
  
  // Getters que reenvían al servicio
  List<app.Notification> get notifications => _notificationService.notifications;
  List<app.Notification> get unreadNotifications => _notificationService.unreadNotifications;
  int get unreadCount => _notificationService.unreadCount;
  bool get isLoading => _notificationService.isLoading;
  String get error => _notificationService.error;
  
  // Reenviar métodos al servicio
  Future<void> getNotifications({int page = 1, int limit = 20}) => 
      _notificationService.getNotifications(page: page, limit: limit);
  
  Future<void> getUnreadNotifications({int limit = 10}) => 
      _notificationService.getUnreadNotifications(limit: limit);
  
  Future<void> getUnreadCount() => 
      _notificationService.getUnreadCount();
  
  Future<bool> markAsRead(String notificationId) => 
      _notificationService.markAsRead(notificationId);
  
  Future<bool> markAllAsRead() => 
      _notificationService.markAllAsRead();
  
  Future<bool> deleteNotification(String notificationId) => 
      _notificationService.deleteNotification(notificationId);
  
  void clearError() => 
      _notificationService.clearError();
  
  // Callback para cuando el servicio cambia
  void _onServiceChanged() {
    notifyListeners();
  }
  
  @override
  void dispose() {
    _notificationService.removeListener(_onServiceChanged);
    super.dispose();
  }
}