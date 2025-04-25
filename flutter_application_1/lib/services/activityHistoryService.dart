import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_application_1/config/api_constants.dart';
import 'package:flutter_application_1/models/activityHistory.dart';

class ActivityHistoryService {
  // Get history by activity ID
  Future<Map<String, dynamic>> getHistoryByActivityId(
    String activityId, {
    int page = 1,
    int limit = 10,
  }) async {
    try {
      final uri = Uri.parse(ApiConstants.activityHistoryByActivityId(activityId)).replace(
        queryParameters: {
          'page': page.toString(),
          'limit': limit.toString(),
        },
      );

      final response = await http.get(uri);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        
        // Parse histories list
        final List<ActivityHistory> histories = [];
        if (data['histories'] != null) {
          for (var item in data['histories']) {
            histories.add(ActivityHistory.fromJson(item));
          }
        }
        
        return {
          'histories': histories,
          'total': data['total'] ?? 0,
          'page': data['page'] ?? 1,
          'pages': data['pages'] ?? 1,
        };
      }
      
      throw Exception('Failed to load activity history: ${response.statusCode}');
    } catch (e) {
      print('Error getting activity history: $e');
      throw Exception('Failed to load activity history');
    }
  }

  // Get all history entries with pagination
  Future<Map<String, dynamic>> getAllHistory({
    int page = 1,
    int limit = 10,
  }) async {
    try {
      final uri = Uri.parse(ApiConstants.activityHistory).replace(
        queryParameters: {
          'page': page.toString(),
          'limit': limit.toString(),
        },
      );

      final response = await http.get(uri);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        
        // Parse histories list
        final List<ActivityHistory> histories = [];
        if (data['histories'] != null) {
          for (var item in data['histories']) {
            histories.add(ActivityHistory.fromJson(item));
          }
        }
        
        return {
          'histories': histories,
          'total': data['total'] ?? 0,
          'page': data['page'] ?? 1,
          'pages': data['pages'] ?? 1,
        };
      }
      
      throw Exception('Failed to load history: ${response.statusCode}');
    } catch (e) {
      print('Error getting history: $e');
      throw Exception('Failed to load history');
    }
  }

  // Search history with custom query
  Future<Map<String, dynamic>> searchHistory(
    Map<String, dynamic> queryData, {
    int page = 1,
    int limit = 10,
  }) async {
    try {
      final uri = Uri.parse('${ApiConstants.activityHistory}/search').replace(
        queryParameters: {
          'page': page.toString(),
          'limit': limit.toString(),
        },
      );

      final response = await http.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'query': queryData}),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        
        // Parse histories list
        final List<ActivityHistory> histories = [];
        if (data['histories'] != null) {
          for (var item in data['histories']) {
            histories.add(ActivityHistory.fromJson(item));
          }
        }
        
        return {
          'histories': histories,
          'total': data['total'] ?? 0,
          'page': data['page'] ?? 1,
          'pages': data['pages'] ?? 1,
        };
      }
      
      throw Exception('Failed to search history: ${response.statusCode}');
    } catch (e) {
      print('Error searching history: $e');
      throw Exception('Failed to search history');
    }
  }

  // Delete history entry
  Future<bool> deleteHistoryEntry(String historyId) async {
    try {
      final response = await http.delete(
        Uri.parse('${ApiConstants.activityHistory}/$historyId'),
      );
      return response.statusCode == 200;
    } catch (e) {
      print('Error deleting history entry: $e');
      return false;
    }
  }
}