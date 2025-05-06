import 'dart:convert';
import 'package:flutter_application_1/services/http_service.dart';
import 'package:flutter_application_1/config/api_constants.dart';
import 'package:flutter_application_1/models/activity.dart';

class ActivityService {
  final HttpService _httpService;

  ActivityService(this._httpService);

  // Get activities with pagination
  Future<Map<String, dynamic>> getActivities({
    int page = 1,
    int limit = 5,
  }) async {
    try {
      final uri = ApiConstants.activities + "?page=${page}&limit=${limit}";
      final response = await _httpService.get(uri);
      final data = await _httpService.parseJsonResponse(response);
      
      // Parse activities list
      final List<Activity> activities = [];
      
      // Handle different response formats
      if (data is List) {
        // If response is a direct list of activities
        for (var item in data) {
          activities.add(Activity.fromJson(item));
        }
        
        return {
          'activities': activities,
          'totalActivities': activities.length,
          'totalPages': 1,
          'currentPage': 1,
        };
        
      } else if (data['activities'] != null) {
        // If response is an object with activities field
        for (var item in data['activities']) {
          activities.add(Activity.fromJson(item));
        }
        
        return {
          'activities': activities,
          'totalActivities': data['total'] ?? data['totalActivities'] ?? activities.length,
          'totalPages': data['pages'] ?? data['totalPages'] ?? 1,
          'currentPage': data['page'] ?? data['currentPage'] ?? 1,
        };
      }
      
      return {
        'activities': activities,
        'totalActivities': 0,
        'totalPages': 1,
        'currentPage': 1,
      };
    } catch (e) {
      print('Error getting activities: $e');
      throw Exception('Failed to load activities');
    }
  }

  // Get activity by ID
  Future<Activity> getActivityById(String id) async {
    try {
      final response = await _httpService.get(ApiConstants.activity(id));
      final data = await _httpService.parseJsonResponse(response);
      return Activity.fromJson(data);
    } catch (e) {
      print('Error getting activity: $e');
      throw Exception('Failed to load activity');
    }
  }

  // Get activities by user ID
  Future<List<Activity>> getActivitiesByUserId(String userId) async {
    try {
      final response = await _httpService.get(ApiConstants.userActivities(userId));
      final data = await _httpService.parseJsonResponse(response);
      
      if (data is List) {
        return data.map((item) => Activity.fromJson(item)).toList();
      } else {
        print('Unexpected response format: $data');
        return [];
      }
    } catch (e) {
      print('Error getting user activities: $e');
      throw Exception('Failed to load user activities');
    }
  }

  // Create activity
  Future<Activity> createActivity(Map<String, dynamic> activityData) async {
    try {
      final response = await _httpService.post(
        ApiConstants.activities,
        body: activityData,
      );

      final data = await _httpService.parseJsonResponse(response);
      return Activity.fromJson(data);
    } catch (e) {
      print('Error creating activity: $e');
      throw Exception('Failed to create activity');
    }
  }

  // Update activity
  Future<Activity> updateActivity(String id, Map<String, dynamic> activityData) async {
    try {
      final response = await _httpService.put(
        ApiConstants.activity(id),
        body: activityData,
      );

      final data = await _httpService.parseJsonResponse(response);
      return Activity.fromJson(data);
    } catch (e) {
      print('Error updating activity: $e');
      throw Exception('Failed to update activity');
    }
  }

  // Delete activity
  Future<bool> deleteActivity(String id) async {
    try {
      final response = await _httpService.delete(ApiConstants.activity(id));
      return response.statusCode == 200;
    } catch (e) {
      print('Error deleting activity: $e');
      return false;
    }
  }
}