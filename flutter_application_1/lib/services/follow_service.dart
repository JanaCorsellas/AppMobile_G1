// lib/services/follow_service.dart - Servicio corregido con URLs correctas
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_application_1/config/api_constants.dart';
import 'package:flutter_application_1/models/user.dart';
import 'package:flutter_application_1/services/auth_service.dart';

class FollowService with ChangeNotifier {
  bool _isLoading = false;
  String _error = '';
  
  bool get isLoading => _isLoading;
  String get error => _error;

  // Headers con autenticación
  Map<String, String> _getHeaders(String? token) {
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  /// Seguir a un usuario
  Future<bool> followUser(String currentUserId, String targetUserId, String? token) async {
    if (currentUserId == targetUserId) {
      _error = 'No puedes seguirte a ti mismo';
      notifyListeners();
      return false;
    }

    _isLoading = true;
    _error = '';
    notifyListeners();

    try {
      print('Intentando seguir usuario: $currentUserId -> $targetUserId');
      
      final response = await http.post(
        Uri.parse(ApiConstants.followUser(currentUserId, targetUserId)),
        headers: _getHeaders(token),
      );

      print('Respuesta seguir usuario: ${response.statusCode}');
      print('Body: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        print('Usuario seguido exitosamente');
        _isLoading = false;
        notifyListeners();
        return data['success'] ?? true;
      } else {
        final errorData = json.decode(response.body);
        _error = errorData['message'] ?? 'Error al seguir usuario';
      }
    } catch (e) {
      _error = 'Error de conexión: $e';
      print('Error al seguir usuario: $e');
    }

    _isLoading = false;
    notifyListeners();
    return false;
  }

  /// Dejar de seguir a un usuario
  Future<bool> unfollowUser(String currentUserId, String targetUserId, String? token) async {
    _isLoading = true;
    _error = '';
    notifyListeners();

    try {
      print('Intentando dejar de seguir usuario: $currentUserId -> $targetUserId');
      
      // CORREGIDO: Backend usa POST, no DELETE
      final response = await http.post(
        Uri.parse(ApiConstants.unfollowUser(currentUserId, targetUserId)),
        headers: _getHeaders(token),
      );

      print('Respuesta unfollow usuario: ${response.statusCode}');
      print('Body: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        print('Usuario unfollowed exitosamente');
        _isLoading = false;
        notifyListeners();
        return data['success'] ?? true;
      } else {
        final errorData = json.decode(response.body);
        _error = errorData['message'] ?? 'Error al dejar de seguir usuario';
      }
    } catch (e) {
      _error = 'Error de conexión: $e';
      print('Error al unfollow usuario: $e');
    }

    _isLoading = false;
    notifyListeners();
    return false;
  }

  Future<List<User>> getFollowers(String userId, String? token) async {
  _isLoading = true;
  _error = '';
  notifyListeners();

  try {
    print('🔍 Obteniendo seguidores para usuario: $userId');
    
    final response = await http.get(
      Uri.parse(ApiConstants.getUserFollowers(userId)),
      headers: _getHeaders(token),
    );

    print('📡 Respuesta seguidores: ${response.statusCode}');
    print('📄 Body: ${response.body}');

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final List<dynamic> followersJson = data['followers'] ?? [];
      
      print('👥 Seguidores JSON recibidos: ${followersJson.length}');
      
      final List<User> followers = [];
      for (var followerJson in followersJson) {
        try {
          print('🔍 Procesando seguidor: ${followerJson['username']} - Followers: ${followerJson['followersCount']} - Following: ${followerJson['followingCount']}');
          final user = User.fromJson(followerJson);
          followers.add(user);
          print('✅ Seguidor agregado: ${user.username} - FollowersCount: ${user.followersCount}');
        } catch (e) {
          print('❌ Error procesando seguidor: $e');
          print('📄 Datos del seguidor: $followerJson');
        }
      }

      print('🎯 Total seguidores procesados: ${followers.length}');
      _isLoading = false;
      notifyListeners();
      return followers;
    } else {
      final errorData = json.decode(response.body);
      _error = errorData['message'] ?? 'Error al obtener seguidores';
    }
  } catch (e) {
    _error = 'Error de conexión: $e';
    print('❌ Error al obtener seguidores: $e');
  }

  _isLoading = false;
  notifyListeners();
  return [];
}

/// ✅ MEJORADO: Obtener lista de usuarios que sigue con debugging
Future<List<User>> getFollowing(String userId, String? token) async {
  _isLoading = true;
  _error = '';
  notifyListeners();

  try {
    print('🔍 Obteniendo siguiendo para usuario: $userId');
    
    final response = await http.get(
      Uri.parse(ApiConstants.getUserFollowing(userId)),
      headers: _getHeaders(token),
    );

    print('📡 Respuesta siguiendo: ${response.statusCode}');
    print('📄 Body: ${response.body}');

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final List<dynamic> followingJson = data['following'] ?? [];
      
      print('👤 Siguiendo JSON recibidos: ${followingJson.length}');
      
      final List<User> following = [];
      for (var followingUserJson in followingJson) {
        try {
          print('🔍 Procesando seguido: ${followingUserJson['username']} - Followers: ${followingUserJson['followersCount']} - Following: ${followingUserJson['followingCount']}');
          final user = User.fromJson(followingUserJson);
          following.add(user);
          print('✅ Seguido agregado: ${user.username} - FollowersCount: ${user.followersCount}');
        } catch (e) {
          print('❌ Error procesando seguido: $e');
          print('📄 Datos del seguido: $followingUserJson');
        }
      }

      print('🎯 Total seguidos procesados: ${following.length}');
      _isLoading = false;
      notifyListeners();
      return following;
    } else {
      final errorData = json.decode(response.body);
      _error = errorData['message'] ?? 'Error al obtener siguiendo';
    }
  } catch (e) {
    _error = 'Error de conexión: $e';
    print(' Error al obtener siguiendo: $e');
  }

  _isLoading = false;
  notifyListeners();
  return [];
}

  /// Verificar estado de seguimiento entre dos usuarios
  Future<Map<String, bool>> checkFollowStatus(String currentUserId, String targetUserId, String? token) async {
    try {
      print('🔍 Verificando estado de seguimiento: $currentUserId <-> $targetUserId');
      
      final response = await http.get(
        Uri.parse(ApiConstants.checkFollowStatus(currentUserId, targetUserId)),
        headers: _getHeaders(token),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return {
          'isFollowing': data['isFollowing'] ?? false,
          'isFollowedBy': data['isFollowedBy'] ?? false,
        };
      }
    } catch (e) {
      print(' Error verificando estado de seguimiento: $e');
    }

    return {
      'isFollowing': false,
      'isFollowedBy': false,
    };
  }

  /// Obtener estadísticas de seguimiento
  Future<Map<String, dynamic>?> getFollowStats(String userId, String? token) async {
    try {
      print('Obteniendo estadísticas de seguimiento para: $userId');
      
      final response = await http.get(
        Uri.parse(ApiConstants.getUserFollowStats(userId)),
        headers: _getHeaders(token),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return {
          'followersCount': data['followersCount'] ?? 0,
          'followingCount': data['followingCount'] ?? 0,
          'followers': (data['followers'] as List?)?.map((json) => User.fromJson(json)).toList() ?? [],
          'following': (data['following'] as List?)?.map((json) => User.fromJson(json)).toList() ?? [],
        };
      }
    } catch (e) {
      print('Error obteniendo estadísticas: $e');
    }

    return null;
  }

  /// CORREGIDO: Buscar usuarios por nombre
  Future<List<User>> searchUsers(String query, String? token) async {
  if (query.trim().isEmpty || query.length < 2) return [];

  try {
    print(' Buscando usuarios: $query');
    
    final response = await http.get(
      Uri.parse('${ApiConstants.searchUsers}?search=${Uri.encodeComponent(query)}'),
      headers: _getHeaders(token),
    );

    print(' Respuesta búsqueda: ${response.statusCode}');
    print(' Body: ${response.body}');

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      
      // BACKEND devuelve: { "users": [...] }
      final List<dynamic> usersJson = data['users'] ?? [];
      
      print('👥 Usuarios encontrados: ${usersJson.length}');
      
      final List<User> users = [];
      for (var userJson in usersJson) {
        try {
          print('Procesando usuario: ${userJson['username']} - Followers: ${userJson['followersCount']} - Following: ${userJson['followingCount']}');
          final user = User.fromJson(userJson);
          users.add(user);
          print(' Usuario agregado: ${user.username} - FollowersCount: ${user.followersCount}');
        } catch (e) {
          print(' Error procesando usuario: $e');
          print('Datos del usuario: $userJson');
        }
      }
      
      print(' Total usuarios procesados correctamente: ${users.length}');
      return users;
    }
    
    print(' Error en respuesta: ${response.statusCode} - ${response.body}');
    return [];
  } catch (e) {
    print(' Error en searchUsers: $e');
    return [];
  }
}

  void clearError() {
    _error = '';
    notifyListeners();
  }
}