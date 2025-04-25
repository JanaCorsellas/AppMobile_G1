// lib/services/user_service.dart
import 'dart:convert';
import 'package:flutter_application_1/config/api_constants.dart';
import 'package:flutter_application_1/models/user.dart';
import 'package:flutter_application_1/services/http_service.dart';

class UserService {
  final HttpService _httpService;
  
  // In-memory cache for users to reduce API calls
  final Map<String, User> _userCache = {};
  
  UserService(this._httpService);
  
  // Get all users with pagination
  Future<Map<String, dynamic>> getUsers({
    int page = 1,
    int limit = 10,
    bool includeHidden = false,
  }) async {
    try {
      final uri = Uri.parse(ApiConstants.users).replace(
        queryParameters: {
          'page': page.toString(),
          'limit': limit.toString(),
          if (includeHidden) 'includeInvisible': 'true',
        },
      );

      final response = await _httpService.get(uri.toString());
      final data = await _httpService.parseJsonResponse(response);
      
      // Parse users list
      final List<User> users = [];
      if (data['users'] != null) {
        for (var item in data['users']) {
          final user = User.fromJson(item);
          users.add(user);
          
          // Update cache if id is not empty
          if (user.id.isNotEmpty) {
            _userCache[user.id] = user;
          }
        }
      }
      
      return {
        'users': users,
        'totalUsers': data['totalUsers'] ?? 0,
        'totalPages': data['totalPages'] ?? 1,
        'currentPage': data['currentPage'] ?? 1,
      };
    } catch (e) {
      print('Error getting users: $e');
      throw Exception('Failed to load users: $e');
    }
  }

  // Get user by ID - with fallback to cache or local data
  Future<User?> getUserById(String id) async {
    // Return from cache if available 
    if (_userCache.containsKey(id)) {
      return _userCache[id];
    }
    
    try {
      // Check if the ID is a valid MongoDB ObjectId (24 hex chars)
      final isValidObjectId = RegExp(r'^[0-9a-fA-F]{24}$').hasMatch(id);
      
      // If not a valid ObjectId, try alternative approaches
      if (!isValidObjectId) {
        // Check if we can get the current user from shared preferences
        final userData = await _httpService.getFromCache('user');
        if (userData != null) {
          final cachedUser = User.fromJson(userData);
          if (cachedUser.id == id || cachedUser.email == id) {
            return cachedUser;
          }
        }
        
        // If it looks like an email, try to find by email instead
        if (id.contains('@')) {
          return await getUserByEmail(id);
        }
        
        throw Exception('Invalid user ID format');
      }
      
      final response = await _httpService.get(ApiConstants.user(id));
      final data = await _httpService.parseJsonResponse(response);
      
      final user = User.fromJson(data);
      
      // Add to cache
      if (user.id.isNotEmpty) {
        _userCache[user.id] = user;
      }
      
      return user;
    } catch (e) {
      print('Error getting user: $e');
      
      // Try to get from cache or shared preferences as a fallback
      final userData = await _httpService.getFromCache('user');
      if (userData != null) {
        return User.fromJson(userData);
      }
      
      throw Exception('Failed to load user: $e');
    }
  }

  // Get user by email
  Future<User?> getUserByEmail(String email) async {
    try {
      final response = await _httpService.get('${ApiConstants.baseUrl}/api/users/email/$email');
      
      if (response.statusCode == 200) {
        final user = User.fromJson(await _httpService.parseJsonResponse(response));
        
        // Add to cache
        if (user.id.isNotEmpty) {
          _userCache[user.id] = user;
        }
        
        return user;
      }
      
      // If not found, try alternative approach
      return await _findUserByEmail(email);
    } catch (e) {
      print('Error getting user by email: $e');
      throw Exception('Failed to load user by email');
    }
  }
  
  // Helper method to find a user by email via search if direct lookup fails
  Future<User?> _findUserByEmail(String email) async {
    try {
      final response = await _httpService.post(
        '${ApiConstants.baseUrl}/api/users/search',
        body: {'email': email}
      );
      
      final data = await _httpService.parseJsonResponse(response);
      
      if (data is List && data.isNotEmpty) {
        final user = User.fromJson(data[0]);
        if (user.id.isNotEmpty) {
          _userCache[user.id] = user;
        }
        return user;
      }
      
      return null;
    } catch (e) {
      print('Error in alternative user search: $e');
      return null;
    }
  }

  // Create user
  Future<User> createUser(Map<String, dynamic> userData) async {
    try {
      final response = await _httpService.post(
        ApiConstants.users,
        body: userData,
      );
      
      final data = await _httpService.parseJsonResponse(response);
      
      final newUser = User.fromJson(data['user'] ?? data);
      
      // Add to cache
      if (newUser.id.isNotEmpty) {
        _userCache[newUser.id] = newUser;
      }
      
      return newUser;
    } catch (e) {
      print('Error creating user: $e');
      throw Exception('Failed to create user: $e');
    }
  }

  // Update user
  Future<User> updateUser(String id, Map<String, dynamic> userData) async {
    try {
      final response = await _httpService.put(
        ApiConstants.user(id),
        body: userData,
      );
      
      final data = await _httpService.parseJsonResponse(response);
      
      final updatedUser = User.fromJson(data['user'] ?? data);
      
      // Update cache
      if (updatedUser.id.isNotEmpty) {
        _userCache[updatedUser.id] = updatedUser;
      }
      
      return updatedUser;
    } catch (e) {
      print('Error updating user: $e');
      throw Exception('Failed to update user: $e');
    }
  }
Future<void> saveUserToCache(User user) async {
  if (user.id.isNotEmpty) {
    // Update cache
    _userCache[user.id] = user;
    
    // Save to shared preferences
    await _httpService.saveToCache('user', user.toJson());
  }
}
  // Delete user
  Future<bool> deleteUser(String id) async {
    try {
      final response = await _httpService.delete(ApiConstants.user(id));
      
      if (response.statusCode >= 200 && response.statusCode < 300) {
        // Remove from cache
        _userCache.remove(id);
        return true;
      }
      
      return false;
    } catch (e) {
      print('Error deleting user: $e');
      return false;
    }
  }

  // Toggle user visibility
  Future<Map<String, dynamic>> toggleUserVisibility(String id) async {
    try {
      final response = await _httpService.put(
        ApiConstants.toggleUserVisibility(id),
      );
      
      final result = await _httpService.parseJsonResponse(response);
      
      // Update cache if user data is returned
      if (result['user'] != null) {
        final userData = result['user'];
        final userId = userData['id'] ?? userData['_id'];
        
        if (userId != null) {
          // Remove from cache to force refresh next time
          _userCache.remove(userId.toString());
        }
      }
      
      return result;
    } catch (e) {
      print('Error toggling user visibility: $e');
      throw Exception('Failed to toggle user visibility: $e');
    }
  }
  
  // Clear cache
  void clearCache() {
    _userCache.clear();
  }
}