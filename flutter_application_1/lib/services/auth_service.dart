// lib/services/auth_service.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_application_1/config/api_constants.dart';
import 'package:flutter_application_1/models/user.dart';
import 'package:flutter_application_1/services/socket_service.dart';
import 'package:jwt_decoder/jwt_decoder.dart';

class AuthService with ChangeNotifier {
  User? _currentUser;
  String? _accessToken;
  String? _refreshToken;
  bool _isLoggedIn = false;
  bool _isLoading = false;
  String _error = '';

  User? get currentUser => _currentUser;
  String? get accessToken => _accessToken;
  String? get refreshToken => _refreshToken;
  bool get isLoggedIn => _isLoggedIn;
  bool get isLoading => _isLoading;
  String get error => _error;

  bool? get isAdmin => _currentUser?.role == 'admin';

  // Initialize service and check for stored tokens
  Future<void> initialize() async {
    _isLoading = true;
    notifyListeners();
    
    final prefs = await SharedPreferences.getInstance();
    final storedAccessToken = prefs.getString('access_token');
    final storedRefreshToken = prefs.getString('refresh_token');
    final userData = prefs.getString('user');
    
    if (storedAccessToken != null && storedRefreshToken != null && userData != null) {
      try {
        print("Found stored tokens, checking validity");
        
        // Check if access token is expired
        bool isAccessTokenExpired = false;
        try {
          isAccessTokenExpired = JwtDecoder.isExpired(storedAccessToken);
        } catch (e) {
          print("Error decoding token: $e");
          isAccessTokenExpired = true;
        }
        
        if (isAccessTokenExpired) {
          print("Access token expired, attempting refresh");
          // Try to refresh the token
          _refreshToken = storedRefreshToken;
          final success = await refreshAuthToken();
          if (!success) {
            // If refresh failed, log out
            print("Token refresh failed, logging out");
            await logout();
            _isLoading = false;
            notifyListeners();
            return;
          }
        } else {
          // Set the tokens
          _accessToken = storedAccessToken;
          _refreshToken = storedRefreshToken;
          print("Using stored valid access token");
        }
        
        // Parse user data
        try {
          final parsedJson = json.decode(userData);
          print("Attempting to parse stored user data: $parsedJson");
          
          // Verificar si hay ID antes de crear el usuario
          if (!parsedJson.containsKey('_id') && !parsedJson.containsKey('id')) {
            print("ADVERTENCIA: No se encontró ID de usuario en los datos almacenados");
          }
          
          final user = User.fromJson(parsedJson);
          
          if (user.id.isEmpty) {
            print("ERROR: ID de usuario vacío después de analizar los datos almacenados");
            await logout();
          } else {
            _currentUser = user;
            _isLoggedIn = true;
            print("Usuario inicializado correctamente con ID: ${user.id}");
            // Imprimir datos completos del usuario para debug
            print("Datos completos del usuario: ${json.encode(user.toJson())}");
          }
        } catch (e) {
          print('Error parsing user data: $e');
          await logout();
        }
      } catch (e) {
        print('Error analyzing stored data: $e');
        await logout();
      }
    } else {
      print("No stored tokens found");
    }
    
    _isLoading = false;
    notifyListeners();
  }

  Future<User?> login(String username, String password, SocketService socketService) async {
    _isLoading = true;
    _error = '';
    notifyListeners();
    
    try {
      print("Login request URL: ${ApiConstants.login}");
      print("Login request body: ${json.encode({
        'email': username, 
        'password': password
      })}");
      
      final response = await http.post(
        Uri.parse(ApiConstants.login),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'email': username, // Backend expects email here
          'password': password
        }),
      );

      print("Server response (login): ${response.body}");

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        
        if (data['token'] != null && data['refreshToken'] != null && data['user'] != null) {
          _accessToken = data['token'];
          _refreshToken = data['refreshToken'];
          
          final userData = data['user'];
          
          // Imprimir todos los campos para depuración
          print("Datos de usuario recibidos: $userData");
          
          // Verificar si está el ID
          if (!userData.containsKey('_id') && !userData.containsKey('id')) {
            print("ERROR: No se encontró '_id' o 'id' en la respuesta del servidor");
            print("Campos disponibles: ${userData.keys.toList()}");
            _error = 'Error en respuesta del servidor: falta ID de usuario';
            _isLoading = false;
            notifyListeners();
            return null;
          }
          
          final user = User.fromJson(userData);
          
          if (user.id.isEmpty) {
            print("Error: ID de usuario vacío después del login");
            _error = 'Error de autenticación: ID de usuario vacío';
            _isLoading = false;
            notifyListeners();
            return null;
          }
          
          print("Usuario creado exitosamente con ID: ${user.id}");
          print("Bio: ${user.bio}, ProfilePicture: ${user.profilePicture != null}");
          
          _currentUser = user;
          _isLoggedIn = true;
          
          // Save to shared preferences
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('access_token', _accessToken!);
          await prefs.setString('refresh_token', _refreshToken!);
          await prefs.setString('user', json.encode(userData));
          
          // Connect to socket
          socketService.disconnect();
          await Future.delayed(Duration(milliseconds: 500));
          socketService.connect(user);
          
          _isLoading = false;
          notifyListeners();
          return user;
        } else {
          print("ERROR: Falta token, refreshToken o usuario en la respuesta del servidor");
          print("Datos recibidos: $data");
          _error = 'Formato de respuesta del servidor inválido';
        }
      } else {
        print("ERROR: Código de estado HTTP ${response.statusCode}");
        
        // Intentar extraer el mensaje de error de la respuesta
        try {
          final errorData = json.decode(response.body);
          _error = errorData['message'] ?? 'Credenciales inválidas';
        } catch (e) {
          _error = 'Credenciales inválidas';
        }
      }
      
      _isLoading = false;
      notifyListeners();
      return null;
    } catch (e) {
      print('Error de conexión: $e');
      _error = 'Error de conexión: $e';
      _isLoading = false;
      notifyListeners();
      return null;
    }
  }

  Future<bool> refreshAuthToken() async {
    if (_refreshToken == null) {
      return false;
    }
    
    try {
      print("Intentando renovar token con refreshToken: ${_refreshToken!.substring(0, 20)}...");
      
      final response = await http.post(
        Uri.parse(ApiConstants.refreshToken),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'refreshToken': _refreshToken,
        }),
      );
      
      print("Respuesta de refresh token: ${response.body}");
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['token'] != null) {
          _accessToken = data['token'];
          
          // Actualizar en SharedPreferences
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('access_token', _accessToken!);
          
          print("Token de acceso renovado exitosamente");
          notifyListeners();
          return true;
        } else {
          print("Error: La respuesta no contiene un nuevo token");
        }
      } else {
        print("Error al renovar token: Código ${response.statusCode}");
        print("Respuesta: ${response.body}");
      }
      return false;
    } catch (e) {
      print('Error al renovar token: $e');
      return false;
    }
  }

  Future<bool> register(String username, String email, String password) async {
    _isLoading = true;
    _error = '';
    notifyListeners();
    
    try {
      print("Register request URL: ${ApiConstants.register}");
      print("Register request body: ${json.encode({
        'username': username,
        'email': email,
        'password': password
      })}");
      
      final response = await http.post(
        Uri.parse(ApiConstants.register),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'username': username,
          'email': email,
          'password': password
        }),
      );

      print("Server response (register): ${response.body}");
      
      _isLoading = false;
      notifyListeners();
      
      if (response.statusCode == 201 || response.statusCode == 200) {
        return true;
      } else {
        // Intentar extraer el mensaje de error
        try {
          final errorData = json.decode(response.body);
          _error = errorData['message'] ?? 'Error en el registro';
        } catch (e) {
          _error = 'Error en el registro';
        }
        return false;
      }
    } catch (e) {
      _error = 'Error de registro: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }
  
  void updateCurrentUser(User updatedUser) {
    _currentUser = updatedUser;
    
    // Also update in shared preferences for persistence
    _saveUserData(updatedUser);
    notifyListeners();
  }

  // Add a helper method to save user data
  Future<void> _saveUserData(User user) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('user', json.encode(user.toJson()));
      print("User data updated in local storage");
    } catch (e) {
      print("Error saving user data: $e");
    }
  }
  
  Future<void> logout([SocketService? socketService]) async {
    try {
      // Llamar a la API de logout si tenemos un token de acceso
      if (_accessToken != null && _refreshToken != null) {
        try {
          print("Enviando solicitud de logout al servidor");
          await http.post(
            Uri.parse(ApiConstants.logout),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $_accessToken'
            },
            body: json.encode({
              'refreshToken': _refreshToken
            }),
          );
          print("Logout exitoso en el servidor");
        } catch (e) {
          print('Error al llamar a la API de logout: $e');
        }
      }
      
      // Desconectar socket independientemente del resultado de la API
      if (socketService != null) {
        socketService.disconnect();
        print("Socket desconectado");
      }
      
      // Limpiar estado local
      _currentUser = null;
      _accessToken = null;
      _refreshToken = null;
      _isLoggedIn = false;
      
      // Limpiar tokens almacenados
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('access_token');
      await prefs.remove('refresh_token');
      await prefs.remove('user');
      
      print("Datos locales eliminados, logout completo");
      notifyListeners();
    } catch (e) {
      print('Error durante el logout: $e');
    }
  }

  // Helper method to check if access token is expired
  bool isTokenExpired() {
    if (_accessToken == null) return true;
    
    try {
      return JwtDecoder.isExpired(_accessToken!);
    } catch (e) {
      print('Error al verificar expiración del token: $e');
      return true;
    }
  }

  // Add auth header to request
  Map<String, String> getAuthHeaders() {
    if (_accessToken == null) return {};
    return {'Authorization': 'Bearer $_accessToken'};
  }

  void clearError() {
    _error = '';
    notifyListeners();
  }
}