import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_application_1/config/api_constants.dart';
import 'package:flutter_application_1/models/activity.dart';

class ActivityService {
  // Get activities with pagination
  Future<Map<String, dynamic>> getActivities({
    int page = 1,
    int limit = 5,
  }) async {
    try {
      final uri = Uri.parse(ApiConstants.activities).replace(
        queryParameters: {
          'page': page.toString(),
          'limit': limit.toString(),
        },
      );

      final response = await http.get(uri);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        
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
      }
      
      throw Exception('Failed to load activities: ${response.statusCode}');
    } catch (e) {
      print('Error getting activities: $e');
      throw Exception('Failed to load activities');
    }
  }

  // Get activity by ID
  Future<Activity> getActivityById(String id) async {
    try {
      final response = await http.get(Uri.parse(ApiConstants.activity(id)));

      if (response.statusCode == 200) {
        return Activity.fromJson(json.decode(response.body));
      }
      
      throw Exception('Failed to load activity: ${response.statusCode}');
    } catch (e) {
      print('Error getting activity: $e');
      throw Exception('Failed to load activity');
    }
  }

  // Get activities by user ID
  Future<List<Activity>> getActivitiesByUserId(String userId) async {
    try {
      final response = await http.get(Uri.parse(ApiConstants.userActivities(userId)));

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((item) => Activity.fromJson(item)).toList();
      }
      
      throw Exception('Failed to load user activities: ${response.statusCode}');
    } catch (e) {
      print('Error getting user activities: $e');
      throw Exception('Failed to load user activities');
    }
  }

  // Create activity
  Future<Activity> createActivity(Map<String, dynamic> activityData) async {
    try {
      final response = await http.post(
        Uri.parse(ApiConstants.activities),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(activityData),
      );

      if (response.statusCode == 201) {
        return Activity.fromJson(json.decode(response.body));
      }
      
      throw Exception('Failed to create activity: ${response.statusCode}');
    } catch (e) {
      print('Error creating activity: $e');
      throw Exception('Failed to create activity');
    }
  }

  // Update activity
  Future<Activity> updateActivity(String id, Map<String, dynamic> activityData) async {
    try {
      final response = await http.put(
        Uri.parse(ApiConstants.activity(id)),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(activityData),
      );

      if (response.statusCode == 200) {
        return Activity.fromJson(json.decode(response.body));
      }
      
      throw Exception('Failed to update activity: ${response.statusCode}');
    } catch (e) {
      print('Error updating activity: $e');
      throw Exception('Failed to update activity');
    }
  }

  // Delete activity
  Future<bool> deleteActivity(String id) async {
    try {
      final response = await http.delete(Uri.parse(ApiConstants.activity(id)));
      return response.statusCode == 200;
    } catch (e) {
      print('Error deleting activity: $e');
      return false;
    }
  }
}