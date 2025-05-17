import 'dart:convert';
import 'package:flutter_application_1/models/achievement.dart';
import 'package:flutter_application_1/config/api_constants.dart';
import 'package:flutter_application_1/services/http_service.dart';

class AchievementService {
  final HttpService _httpService;

  AchievementService(this._httpService);

  Future<List<Achievement>> getAllAchievements() async {
    try {
      final response = await _httpService.get(ApiConstants.achievements);
      final data = await _httpService.parseJsonResponse(response);

      List<Achievement> achievements = [];
      if (data['achievements'] != null) {
        achievements = List<Achievement>.from(
          data['achievements'].map((x) => Achievement.fromJson(x))
        );
      }

      return achievements;
    } catch (e) {
      print('Error getting achievements: $e');
      return [];
    }
  }

  Future<List<Achievement>> getUserAchievements(String userId) async {
    try {
      final allAchievements = await getAllAchievements();
      
      // Comprobar qué logros ha desbloqueado el usuario
      for (var achievement in allAchievements) {
        achievement.isUnlocked = achievement.usersUnlocked.contains(userId);
      }
      
      return allAchievements;
    } catch (e) {
      print('Error getting user achievements: $e');
      return [];
    }
  }
}