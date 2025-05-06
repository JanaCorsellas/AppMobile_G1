// flutter_application_1/lib/models/notification_model.dart (archivo completo)
import 'package:flutter/material.dart';

class NotificationModel {
  final String id;
  final String type;
  final String title;
  final String message;
  final Map<String, dynamic>? data;
  final bool read;
  final DateTime createdAt;

  NotificationModel({
    required this.id,
    required this.type,
    required this.title,
    required this.message,
    this.data,
    required this.read,
    required this.createdAt,
  });

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      id: json['_id'] ?? json['id'] ?? '',
      type: json['type'] ?? '',
      title: json['title'] ?? '',
      message: json['message'] ?? '',
      data: json['data'],
      read: json['read'] ?? false,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type,
      'title': title,
      'message': message,
      'data': data,
      'read': read,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  // Método para obtener el ícono según el tipo de notificación
  IconData getIcon() {
    switch (type) {
      case 'achievement_unlocked':
        return Icons.emoji_events;
      case 'challenge_completed':
        return Icons.flag;
      case 'friend_request':
        return Icons.person_add;
      case 'activity_update':
        return Icons.directions_run;
      case 'chat_message':
        return Icons.chat;
      case 'system':
        return Icons.info;
      default:
        return Icons.notifications;
    }
  }

  // Método para obtener el color según el tipo de notificación
  Color getColor() {
    switch (type) {
      case 'achievement_unlocked':
        return Colors.amber;
      case 'challenge_completed':
        return Colors.green;
      case 'friend_request':
        return Colors.blue;
      case 'activity_update':
        return Colors.purple;
      case 'chat_message':
        return Colors.teal;
      case 'system':
        return Colors.grey;
      default:
        return Colors.deepPurple;
    }
  }
}