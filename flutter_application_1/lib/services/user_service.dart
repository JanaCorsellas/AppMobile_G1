// lib/services/user_service.dart - Versión corregida
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart'; // Para kIsWeb
import 'package:flutter_application_1/config/api_constants.dart';
import 'package:flutter_application_1/models/user.dart';
import 'package:flutter_application_1/services/http_service.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:http_parser/http_parser.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';

class UserService {
  final HttpService _httpService;
  
  // In-memory cache for users to reduce API calls
  final Map<String, User> _userCache = {};
  
  UserService(this._httpService);
  
  // ✅ MEJORADO: Upload compatible con Web y Móvil + limpieza de caché
  Future<Map<String, dynamic>> uploadProfilePicture(String userId, dynamic imageFile) async {
    try {
      print('📸 Uploading profile picture for user: $userId');
      
      // ✅ PASO 1: Limpiar cache ANTES del upload
      await _clearUserProfileCache(userId);
      
      // Crear request
      final uri = Uri.parse('${ApiConstants.baseUrl}/api/users/$userId/profile-picture');
      final request = http.MultipartRequest('POST', uri);
      
      // Add auth headers
      final headers = await _httpService.getAuthHeaders();
      request.headers.addAll(headers);
      
      http.MultipartFile multipartFile;
      
      if (kIsWeb) {
        // ✅ Para Web: imageFile es XFile o Uint8List
        late Uint8List bytes;
        String filename = 'profile_image_${DateTime.now().millisecondsSinceEpoch}';
        String? mimeType = 'image/jpeg';
        
        if (imageFile is XFile) {
          bytes = await imageFile.readAsBytes();
          filename = imageFile.name;
          mimeType = imageFile.mimeType;
        } else if (imageFile is Uint8List) {
          bytes = imageFile;
        } else {
          throw Exception('Tipo de archivo no soportado en web: ${imageFile.runtimeType}');
        }
        
        if (mimeType != null && mimeType.contains('/')) {
          final extension = mimeType.split('/').last;
          filename = '$filename.$extension';
        }
        
        multipartFile = http.MultipartFile.fromBytes(
          'profilePicture',
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
          'profilePicture',
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
        
        // ✅ PASO 2: Limpiar cache DESPUÉS del upload exitoso
        await Future.delayed(const Duration(milliseconds: 200));
        await _clearUserProfileCache(userId);
        
        // ✅ PASO 3: Crear URL con cache-busting para forzar recarga
        final newImageUrl = data['user']?['profilePicture'] ?? data['profilePicture'];
        if (newImageUrl != null) {
          final cacheBustingUrl = _addCacheBustingToUrl(newImageUrl);
          data['profilePicture'] = cacheBustingUrl;
          data['user']?['profilePicture'] = cacheBustingUrl;
        }
        
        // Update user cache with new profile picture
        if (_userCache.containsKey(userId)) {
          final cachedUser = _userCache[userId]!;
          final updatedUser = cachedUser.copyWith(
            profilePicture: newImageUrl,
          );
          _userCache[userId] = updatedUser;
        }
        
        print('✅ Upload successful with cache clearing');
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

  // ✅ NUEVO: Método para limpiar caché de imagen específica del usuario
  Future<void> _clearUserImageCache(String userId) async {
    try {
      // Obtener usuario actual del caché
      final cachedUser = _userCache[userId];
      if (cachedUser?.profilePictureUrl != null) {
        await CachedNetworkImage.evictFromCache(cachedUser!.profilePictureUrl!);
        print('Caché de imagen limpiado para usuario: $userId');
      }
    } catch (e) {
      print('Error limpiando caché de imagen: $e');
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

 Future<bool> deleteProfilePicture(String userId) async {
    try {
      print('🗑️ Deleting profile picture for user: $userId');
      
      // ✅ PASO 1: Limpiar cache ANTES del delete
      await _clearUserProfileCache(userId);
      
      final response = await _httpService.delete(
        '${ApiConstants.baseUrl}/api/users/$userId/profile-picture'
      );
      
      print('Delete response status: ${response.statusCode}');
      print('Delete response body: ${response.body}');
      
      if (response.statusCode == 200) {
        // ✅ PASO 2: Limpiar cache DESPUÉS del delete exitoso
        await Future.delayed(const Duration(milliseconds: 200));
        await _clearUserProfileCache(userId);
        
        // ✅ PASO 3: Limpiar cache general para asegurar
        await _clearAllProfilePictureCache();
        
        // Update user cache to remove profile picture
        if (_userCache.containsKey(userId)) {
          final cachedUser = _userCache[userId]!;
          final updatedUser = cachedUser.copyWith(
            profilePicture: null,
            clearProfilePicture: true,
          );
          _userCache[userId] = updatedUser;
          
          print('User cache updated: profilePicture = ${updatedUser.profilePicture}');
        }
        
        print('✅ Delete successful with cache clearing');
        return true;
      } else {
        print('Failed to delete profile picture: ${response.statusCode}');
        return false;
      }
    } catch (e) {
      print('Error deleting profile picture: $e');
      return false;
    }
  }

   Future<void> _clearUserProfileCache(String userId) async {
    try {
      print('🧹 Clearing cache for user: $userId');
      
      // Obtener usuario del cache para las URLs
      final cachedUser = _userCache[userId];
      final urlsToClean = <String>[];
      
      if (cachedUser?.profilePictureUrl != null) {
        urlsToClean.add(cachedUser!.profilePictureUrl!);
      }
      
      if (cachedUser?.profilePicture != null) {
        urlsToClean.add(cachedUser!.profilePicture!);
      }
      
      // URLs comunes para este usuario
      urlsToClean.addAll([
        '${ApiConstants.baseUrl}/uploads/profile-pictures/${userId}',
        '${ApiConstants.baseUrl}/uploads/profile-pictures/${userId}.jpg',
        '${ApiConstants.baseUrl}/uploads/profile-pictures/${userId}.png',
      ]);
      
      // Limpiar cada URL y sus variaciones
      for (final url in urlsToClean) {
        await _clearUrlAndVariations(url);
      }
      
      print('✅ User cache cleared for: $userId');
    } catch (e) {
      print('❌ Error clearing user cache: $e');
    }
  }

  /// ✅ MÉTODO NUEVO: Limpiar URL y todas sus variaciones
  Future<void> _clearUrlAndVariations(String baseUrl) async {
    try {
      // Lista de variaciones comunes
      final urlsToClean = [
        baseUrl,
        baseUrl.split('?')[0], // Sin parámetros
        '$baseUrl?t=${DateTime.now().millisecondsSinceEpoch}',
        '${baseUrl.split('?')[0]}?t=${DateTime.now().millisecondsSinceEpoch}',
      ];
      
      for (final url in urlsToClean) {
        // Limpiar de CachedNetworkImage
        await CachedNetworkImage.evictFromCache(url);
        
        // Limpiar de DefaultCacheManager
        try {
          await DefaultCacheManager().removeFile(url);
        } catch (e) {
          // Ignorar errores de archivos no encontrados
        }
      }
      
      print('🧹 Cleared variations for: $baseUrl');
    } catch (e) {
      print('❌ Error clearing URL variations: $e');
    }
  }

  /// ✅ MÉTODO NUEVO: Limpiar todo el cache de profile pictures
  Future<void> _clearAllProfilePictureCache() async {
    try {
      print('🧹 Clearing ALL profile picture cache...');
      
      // Método agresivo: limpiar todo el cache de imágenes
      await CachedNetworkImage.evictFromCache('');
      await DefaultCacheManager().emptyCache();
      
      print('✅ All profile picture cache cleared');
    } catch (e) {
      print('❌ Error clearing all cache: $e');
    }
  }

  /// ✅ MÉTODO NUEVO: Agregar cache-busting a URL
  String _addCacheBustingToUrl(String originalUrl) {
    if (originalUrl.isEmpty) return originalUrl;
    
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final separator = originalUrl.contains('?') ? '&' : '?';
    return '$originalUrl${separator}cb=$timestamp';
  }

  /// ✅ MÉTODO MEJORADO: Get profile picture URL con cache-busting automático
  String? getProfilePictureUrl(String? profilePicturePath, {bool forceFresh = false}) {
    if (profilePicturePath == null || profilePicturePath.isEmpty) {
      return null;
    }
    
    String url;
    
    // If it's already a full URL, use as base
    if (profilePicturePath.startsWith('http')) {
      url = profilePicturePath;
    } else {
      // Otherwise, construct the full URL
      url = '${ApiConstants.baseUrl}/$profilePicturePath';
    }
    
    // Si se fuerza fresh o es una nueva carga, agregar cache-busting
    if (forceFresh) {
      url = _addCacheBustingToUrl(url);
    }
    
    return url;
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
  
  // ✅ MEJORADO: Clear cache con limpieza de imágenes
  void clearCache() {
    // Limpiar caché de usuarios
    _userCache.clear();
    
    // Limpiar caché de imágenes (de forma async sin esperar)
    _clearAllImageCache();
  }

  // ✅ NUEVO: Método para limpiar todo el caché de imágenes
  Future<void> _clearAllImageCache() async {
    try {
      // Esto limpia todo el caché de CachedNetworkImage
      await CachedNetworkImage.evictFromCache('');
      print('Todo el caché de imágenes ha sido limpiado');
    } catch (e) {
      print('Error limpiando todo el caché de imágenes: $e');
    }
  }
}