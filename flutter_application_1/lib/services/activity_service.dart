// lib/services/activity_service.dart - COMPLETO Y CORREGIDO
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
          'currentPage': data['page'] ?? data['currentPage'] ?? page,
        };
      } else {
        throw Exception('Unexpected response format');
      }
      
    } catch (e) {
      print('Error in getActivities: $e');
      throw Exception('Failed to load activities: $e');
    }
  }

  // ✅ NUEVO: Obtener actividades de usuarios seguidos (feed)
  Future<Map<String, dynamic>> getFollowingActivities(
    String userId, {
    int page = 1,
    int limit = 10,
  }) async {
    try {
      final uri = ApiConstants.followingActivities(userId) + "?page=${page}&limit=${limit}";
      print('🔍 Fetching following activities from: $uri');
      
      final response = await _httpService.get(uri);
      final data = await _httpService.parseJsonResponse(response);
      
      print('📱 Following activities response: $data');
      
      // Parse activities list y mantener datos de usuario adicionales
      final List<Activity> activities = [];
      final Map<String, Map<String, dynamic>> userDataMap = {}; // ✅ NUEVO: Mapa para datos de usuario
      
      if (data['activities'] != null) {
        for (var item in data['activities']) {
          try {
            final activity = Activity.fromJson(item);
            activities.add(activity);
            
            // ✅ NUEVO: Guardar datos adicionales del usuario
            if (item['userProfilePicture'] != null || 
                item['author'] != null || 
                item['user'] != null) {
              
              final userData = <String, dynamic>{};
              
              // Extraer imagen de perfil de diferentes fuentes posibles
              userData['profilePicture'] = item['userProfilePicture'] ?? 
                                         item['author']?['profilePicture'] ?? 
                                         item['author']?['profilePictureUrl'] ??
                                         item['user']?['profilePicture'] ??
                                         item['user']?['profilePictureUrl'];
              
              userData['username'] = item['userUsername'] ?? 
                                   item['author']?['username'] ?? 
                                   item['user']?['username'] ??
                                   activity.authorName;
              
              userData['userId'] = item['userId'] ?? 
                                 item['author']?['_id'] ?? 
                                 item['user']?['_id'] ??
                                 activity.author;
              
              userData['level'] = item['author']?['level'] ?? 
                                item['user']?['level'] ?? 1;
              
              // Usar el ID de la actividad como clave
              userDataMap[activity.id] = userData;
            }
          } catch (e) {
            print('Error parsing following activity: $e');
            // Continue with next item
          }
        }
      }
      
      return {
        'activities': activities,
        'userDataMap': userDataMap, // ✅ NUEVO: Incluir mapa de datos de usuario
        'totalActivities': data['totalActivities'] ?? 0,
        'totalPages': data['totalPages'] ?? 1,
        'currentPage': data['currentPage'] ?? page,
        'hasMore': data['hasMore'] ?? false,
        'followingCount': data['followingCount'] ?? 0,
      };
      
    } catch (e) {
      print('Error in getFollowingActivities: $e');
      throw Exception('Failed to load following activities: $e');
    }
  }

  // Get activities by user ID
  Future<List<Activity>> getActivitiesByUserId(String userId) async {
    try {
      print('Requesting activities for user: $userId');
      print('Request URL: ${ApiConstants.userActivities(userId)}');
      
      final response = await _httpService.get(ApiConstants.userActivities(userId));
      final data = await _httpService.parseJsonResponse(response);
      
      print('Raw response data type: ${data.runtimeType}');
      
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
      
      print('Unexpected response format, returning empty list');
      return [];
      
    } catch (e) {
      print('Error in getActivitiesByUserId: $e');
      throw Exception('Failed to load user activities: $e');
    }
  }

  // Get activity by ID
  Future<Activity?> getActivityById(String activityId) async {
    try {
      final response = await _httpService.get(ApiConstants.activity(activityId));
      final data = await _httpService.parseJsonResponse(response);
      return Activity.fromJson(data);
    } catch (e) {
      print('Error in getActivityById: $e');
      return null;
    }
  }

  // Create a new activity
  Future<Activity?> createActivity(Map<String, dynamic> activityData) async {
    try {
      final response = await _httpService.post(
        ApiConstants.activities,
        body: activityData,
      );
      final data = await _httpService.parseJsonResponse(response);
      return Activity.fromJson(data);
    } catch (e) {
      print('Error in createActivity: $e');
      throw Exception('Failed to create activity: $e');
    }
  }

  // Update an activity
  Future<Activity?> updateActivity(String activityId, Map<String, dynamic> activityData) async {
    try {
      final response = await _httpService.put(
        ApiConstants.activity(activityId),
        body: activityData,
      );
      final data = await _httpService.parseJsonResponse(response);
      return Activity.fromJson(data);
    } catch (e) {
      print('Error in updateActivity: $e');
      throw Exception('Failed to update activity: $e');
    }
  }

  // Delete an activity
  Future<bool> deleteActivity(String activityId) async {
    try {
      final response = await _httpService.delete(ApiConstants.activity(activityId));
      return response.statusCode == 200;
    } catch (e) {
      print('Error in deleteActivity: $e');
      return false;
    }
  }
}