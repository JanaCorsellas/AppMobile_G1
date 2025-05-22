// lib/services/user_service.dart - Compatible con Web
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart'; // Para kIsWeb
import 'package:flutter_application_1/config/api_constants.dart';
import 'package:flutter_application_1/models/user.dart';
import 'package:flutter_application_1/services/http_service.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:http_parser/http_parser.dart';

class UserService {
  final HttpService _httpService;
  
  // In-memory cache for users to reduce API calls
  final Map<String, User> _userCache = {};
  
  UserService(this._httpService);
  
  // Métodos existentes... (get, create, update, etc.)
  
  // ✅ ACTUALIZADO: Upload compatible con Web y Móvil
  Future<Map<String, dynamic>> uploadProfilePicture(String userId, dynamic imageFile) async {
  try {
    print('Uploading profile picture for user: $userId');
    print('Platform: ${kIsWeb ? "Web" : "Mobile"}');
    
    // Create multipart request
    final uri = Uri.parse('${ApiConstants.baseUrl}/api/users/$userId/profile-picture');
    final request = http.MultipartRequest('POST', uri);
    
    // Add authentication headers if available
    final headers = _httpService.getAuthHeadersForMultipart();
    request.headers.addAll(headers);
    
    // ✅ Manejo mejorado según plataforma
    http.MultipartFile multipartFile;
    
    if (kIsWeb) {
      // ✅ Para Web: imageFile es XFile
      final XFile xFile = imageFile as XFile;
      final bytes = await xFile.readAsBytes();
      
      // ✅ MEJORADO: Detectar MIME type y filename correctamente
      String? mimeType;
      String filename = xFile.name;
      
      // Intentar detectar MIME type por extensión si no está disponible
      if (xFile.mimeType != null && xFile.mimeType!.isNotEmpty) {
        mimeType = xFile.mimeType;
      } else {
        // Detectar por extensión
        final extension = filename.split('.').last.toLowerCase();
        switch (extension) {
          case 'jpg':
          case 'jpeg':
            mimeType = 'image/jpeg';
            break;
          case 'png':
            mimeType = 'image/png';
            break;
          case 'gif':
            mimeType = 'image/gif';
            break;
          case 'webp':
            mimeType = 'image/webp';
            break;
          default:
            mimeType = 'image/jpeg'; // Default fallback
        }
      }
      
      // Asegurar que el filename tenga extensión
      if (!filename.contains('.')) {
        final extension = mimeType?.split('/').last ?? 'jpg';
        filename = '$filename.$extension';
      }
      
      multipartFile = http.MultipartFile.fromBytes(
        'profilePicture', // ✅ IMPORTANTE: Nombre del campo debe coincidir
        bytes,
        filename: filename,
        contentType: MediaType.parse(mimeType ?? 'image/jpeg'),
      );
      
      print('Web: Uploading file $filename (${bytes.length} bytes)');
      print('MIME type: $mimeType');
    } else {
      // ✅ Para Móvil: imageFile es File
      final File file = imageFile as File;
      
      multipartFile = await http.MultipartFile.fromPath(
        'profilePicture', // ✅ IMPORTANTE: Nombre del campo debe coincidir
        file.path,
      );
      
      print('Mobile: Uploading file ${file.path}');
    }
    
    request.files.add(multipartFile);
    
    print('Sending multipart request...');
    print('Request URL: ${request.url}');
    print('Request headers: ${request.headers}');
    
    // Send the request
    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);
    
    print('Upload response status: ${response.statusCode}');
    print('Upload response body: ${response.body}');
    
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      
      // Update user cache with new profile picture
      if (_userCache.containsKey(userId)) {
        final cachedUser = _userCache[userId]!;
        final updatedUser = cachedUser.copyWith(
          profilePicture: data['profilePicture'],
        );
        _userCache[userId] = updatedUser;
      }
      
      return data;
    } else {
      final errorData = json.decode(response.body);
      throw Exception(errorData['message'] ?? 'Failed to upload image');
    }
  } catch (e) {
    print('Error uploading profile picture: $e');
    throw Exception('Failed to upload profile picture: $e');
  }
}

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

  // ✅ Delete profile picture
  Future<bool> deleteProfilePicture(String userId) async {
    try {
      print('Deleting profile picture for user: $userId');
      
      final response = await _httpService.delete(
        '${ApiConstants.baseUrl}/api/users/$userId/profile-picture'
      );
      
      if (response.statusCode == 200) {
        // Update user cache to remove profile picture
        if (_userCache.containsKey(userId)) {
          final cachedUser = _userCache[userId]!;
          final updatedUser = cachedUser.copyWith(profilePicture: null);
          _userCache[userId] = updatedUser;
        }
        
        return true;
      } else {
        return false;
      }
    } catch (e) {
      print('Error deleting profile picture: $e');
      return false;
    }
  }

  // ✅ Get profile picture URL
  String? getProfilePictureUrl(String? profilePicturePath) {
    if (profilePicturePath == null || profilePicturePath.isEmpty) {
      return null;
    }
    
    // If it's already a full URL, return as is
    if (profilePicturePath.startsWith('http')) {
      return profilePicturePath;
    }
    
    // Otherwise, construct the full URL
    return '${ApiConstants.baseUrl}/$profilePicturePath';
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