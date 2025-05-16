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
          try {
            activities.add(Activity.fromJson(item));
          } catch (e) {
            print('Error parsing activity in getActivities: $e');
            // Continue with next item
          }
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
          try {
            activities.add(Activity.fromJson(item));
          } catch (e) {
            print('Error parsing activity in getActivities: $e');
            // Continue with next item
          }
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
      print('Fetching activity by ID: $id');
      final response = await _httpService.get(ApiConstants.activity(id));
      final data = await _httpService.parseJsonResponse(response);
      return Activity.fromJson(data);
    } catch (e) {
      print('Error getting activity: $e');
      throw Exception('Failed to load activity');
    }
  }

  // Get activities by user ID - with enhanced debugging
  Future<List<Activity>> getActivitiesByUserId(String userId) async {
    try {
      print('Fetching activities for user: $userId');
      final response = await _httpService.get(ApiConstants.userActivities(userId));
      
      // Print the raw response for debugging
      print('Raw response status code: ${response.statusCode}');
      print('Raw response body type: ${response.body.runtimeType}');
      print('Raw response length: ${response.body.length}');
      // Print a snippet of the response to avoid flooding the console
      print('Raw response snippet: ${response.body.substring(0, min(200, response.body.length))}...');
      
      final data = await _httpService.parseJsonResponse(response);
      print('Parsed data type: ${data.runtimeType}');
      
      List<Activity> activities = [];
      
      if (data is List) {
        print('Processing list data with ${data.length} items');
        for (var item in data) {
          print('Processing item type: ${item.runtimeType}');
          try {
            activities.add(Activity.fromJson(item));
          } catch (e) {
            print('Error parsing activity item: $e');
            // Continue with next item
          }
        }
        return activities;
      } else if (data is Map) {
        if (data['activities'] is List) {
          print('Processing map with activities list');
          final activitiesList = data['activities'] as List;
          print('Activities list length: ${activitiesList.length}');
          
          for (var item in activitiesList) {
            print('Processing item type: ${item.runtimeType}');
            try {
              activities.add(Activity.fromJson(item));
            } catch (e) {
              print('Error parsing activity item: $e');
              // Continue with next item
            }
          }
          return activities;
        } else {
          // Try to parse as a single activity
          print('Attempting to parse data as a single activity');
          try {
            activities.add(Activity.fromJson(Map<String, dynamic>.from(data)));
            return activities;
          } catch (e) {
            print('Error parsing as single activity: $e');
          }
        }
      }
      
      print('Unexpected response format: $data');
      return [];
    } catch (e) {
      print('Error getting user activities with details: $e');
      print('Stack trace: ${StackTrace.current}');
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

// Helper function to avoid importing dart:math
int min(int a, int b) {
  return a < b ? a : b;
}