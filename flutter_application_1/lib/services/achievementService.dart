import 'dart:convert';
import 'package:flutter_application_1/models/achievement.dart';
import 'package:flutter_application_1/config/api_constants.dart';
import 'package:flutter_application_1/services/http_service.dart';

class AchievementService {
  final HttpService _httpService;

  AchievementService(this._httpService);

  Future<List<Achievement>> getAllAchievements() async {
    try {
      final response = await _httpService.get(ApiConstants.allAchievements);
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

  Future<Map<String, dynamic>> getUserAchievements(String userId) async {
    try {
      final response = await _httpService.get(ApiConstants.userAchievements(userId));
      final data = await _httpService.parseJsonResponse(response);

      if (data['data'] != null) {
        final achievementData = data['data'];
        
        List<Achievement> unlocked = [];
        List<Achievement> locked = [];

        if (achievementData['unlocked'] != null) {
          unlocked = List<Achievement>.from(
            achievementData['unlocked'].map((x) => Achievement.fromJson(x)..isUnlocked = true)
          );
        }

        if (achievementData['locked'] != null) {
          locked = List<Achievement>.from(
            achievementData['locked'].map((x) => Achievement.fromJson(x)..isUnlocked = false)
          );
        }

        return {
          'unlocked': unlocked,
          'locked': locked,
          'totalCount': achievementData['totalCount'] ?? 0,
          'unlockedCount': achievementData['unlockedCount'] ?? 0,
        };
      }

      return {
        'unlocked': <Achievement>[],
        'locked': <Achievement>[],
        'totalCount': 0,
        'unlockedCount': 0,
      };
    } catch (e) {
      print('Error getting user achievements: $e');
      return {
        'unlocked': <Achievement>[],
        'locked': <Achievement>[],
        'totalCount': 0,
        'unlockedCount': 0,
      };
    }
  }

  Future<List<Achievement>> checkUserAchievements(String userId) async {
    try {
      final response = await _httpService.post(ApiConstants.checkUserAchievements(userId));
      final data = await _httpService.parseJsonResponse(response);

      List<Achievement> newlyUnlocked = [];
      if (data['newlyUnlocked'] != null) {
        newlyUnlocked = List<Achievement>.from(
          data['newlyUnlocked'].map((x) => Achievement.fromJson(x))
        );
      }

      return newlyUnlocked;
    } catch (e) {
      print('Error checking user achievements: $e');
      return [];
    }
  }

  Future<bool> initializeDefaultAchievements() async {
    try {
      final response = await _httpService.post(ApiConstants.initializeAchievements);
      return response.statusCode >= 200 && response.statusCode < 300;
    } catch (e) {
      print('Error initializing achievements: $e');
      return false;
    }
  }

  Future<Achievement?> createAchievement(Map<String, dynamic> achievementData) async {
    try {
      final response = await _httpService.post(
        ApiConstants.achievements,
        body: achievementData,
      );
      final data = await _httpService.parseJsonResponse(response);

      if (data['achievement'] != null) {
        return Achievement.fromJson(data['achievement']);
      }
      return null;
    } catch (e) {
      print('Error creating achievement: $e');
      return null;
    }
  }

  Future<Achievement?> updateAchievement(String id, Map<String, dynamic> achievementData) async {
    try {
      final response = await _httpService.put(
        ApiConstants.achievement(id),
        body: achievementData,
      );
      final data = await _httpService.parseJsonResponse(response);

      if (data['achievement'] != null) {
        return Achievement.fromJson(data['achievement']);
      }
      return null;
    } catch (e) {
      print('Error updating achievement: $e');
      return null;
    }
  }

  Future<bool> deleteAchievement(String id) async {
    try {
      final response = await _httpService.delete(ApiConstants.achievement(id));
      return response.statusCode >= 200 && response.statusCode < 300;
    } catch (e) {
      print('Error deleting achievement: $e');
      return false;
    }
  }
}