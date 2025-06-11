import 'package:flutter/material.dart';
class Achievement {
  final String id;
  final String title;
  final String description;
  final String condition;
  final String icon;
  final List<String> usersUnlocked;
  final String type;
  final double targetValue;
  final String? activityType;
  final String difficulty;
  final int points;
  final DateTime? createdAt;
  bool isUnlocked;

  Achievement({
    required this.id,
    required this.title,
    required this.description,
    required this.condition,
    required this.icon,
    required this.usersUnlocked,
    required this.type,
    required this.targetValue,
    this.activityType,
    required this.difficulty,
    required this.points,
    this.createdAt,
    this.isUnlocked = false,
  });

  factory Achievement.fromJson(Map<String, dynamic> json) {
    List<String> parseUsersList(dynamic users) {
      if (users == null) return [];
      if (users is List) {
        return users.map((user) {
          if (user is Map) {
            return user['_id']?.toString() ?? '';
          } else {
            return user.toString();
          }
        }).toList();
      }
      return [];
    }

    return Achievement(
      id: json['_id'] ?? '',
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      condition: json['condition'] ?? '',
      icon: json['icon'] ?? 'emoji_events',
      usersUnlocked: parseUsersList(json['usersUnlocked']),
      type: json['type'] ?? 'activity_count',
      targetValue: (json['targetValue'] ?? 0).toDouble(),
      activityType: json['activityType'],
      difficulty: json['difficulty'] ?? 'bronze',
      points: json['points'] ?? 10,
      createdAt: json['createdAt'] != null ? DateTime.parse(json['createdAt']) : null,
      isUnlocked: false, // Se actualizará después
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'title': title,
      'description': description,
      'condition': condition,
      'icon': icon,
      'usersUnlocked': usersUnlocked,
      'type': type,
      'targetValue': targetValue,
      'activityType': activityType,
      'difficulty': difficulty,
      'points': points,
      'createdAt': createdAt?.toIso8601String(),
    };
  }

  // Obtener color según la dificultad
  Color getDifficultyColor() {
    switch (difficulty) {
      case 'bronze':
        return const Color(0xFFCD7F32);
      case 'silver':
        return const Color(0xFFC0C0C0);
      case 'gold':
        return const Color(0xFFFFD700);
      case 'diamond':
        return const Color(0xFFB9F2FF);
      default:
        return Colors.grey;
    }
  }

  // Obtener icono según el tipo
  IconData getTypeIcon() {
    switch (icon) {
      case 'directions_run':
        return Icons.directions_run;
      case 'directions_bike':
        return Icons.directions_bike;
      case 'directions_walk':
        return Icons.directions_walk;
      case 'terrain':
        return Icons.terrain;
      case 'timer':
        return Icons.timer;
      case 'speed':
        return Icons.speed;
      case 'emoji_events':
        return Icons.emoji_events;
      case 'event':
        return Icons.event_available;
      case 'landscape':
        return Icons.landscape;
      default:
        return Icons.emoji_events;
    }
  }

  // Formatear el valor objetivo según el tipo
  String getFormattedTargetValue() {
    switch (type) {
      case 'distance_total':
      case 'distance_single':
        if (targetValue >= 1000) {
          return '${(targetValue / 1000).toStringAsFixed(targetValue % 1000 == 0 ? 0 : 2)} km';
        } else {
          return '${targetValue.toInt()} m';
        }
      case 'time_total':
      case 'time_single':
      case 'time_monthly':
      case 'time_yearly':
        if (targetValue >= 60) {
          final hours = (targetValue / 60).floor();
          final minutes = (targetValue % 60).toInt();
          if (hours > 0 && minutes > 0) {
            return '${hours}h ${minutes}min';
          } else if (hours > 0) {
            return '${hours}h';
          } else {
            return '${minutes}min';
          }
        } else {
          return '${targetValue.toInt()} min';
        }
      case 'speed_average':
        return '${(targetValue * 3.6).toStringAsFixed(1)} km/h';
      case 'elevation_gain':
        return '${targetValue.toInt()} m';
      case 'activity_count':
        return '${targetValue.toInt()} actividades';
      case 'consecutive_days':
        return '${targetValue.toInt()} días';
      default:
        return targetValue.toString();
    }
  }

  Achievement copyWith({
    String? id,
    String? title,
    String? description,
    String? condition,
    String? icon,
    List<String>? usersUnlocked,
    String? type,
    double? targetValue,
    String? activityType,
    String? difficulty,
    int? points,
    DateTime? createdAt,
    bool? isUnlocked,
  }) {
    return Achievement(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      condition: condition ?? this.condition,
      icon: icon ?? this.icon,
      usersUnlocked: usersUnlocked ?? this.usersUnlocked,
      type: type ?? this.type,
      targetValue: targetValue ?? this.targetValue,
      activityType: activityType ?? this.activityType,
      difficulty: difficulty ?? this.difficulty,
      points: points ?? this.points,
      createdAt: createdAt ?? this.createdAt,
      isUnlocked: isUnlocked ?? this.isUnlocked,
    );
  }
}