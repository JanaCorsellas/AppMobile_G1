import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_application_1/config/api_constants.dart';
import 'package:flutter_application_1/models/user.dart';
import 'package:flutter_application_1/services/socket_service.dart';
import 'package:jwt_decoder/jwt_decoder.dart';
import 'dart:html' as html; // AÑADIDO PARA GOOGLE OAUTH

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
          _refreshToken = storedRefreshToken;
          final success = await refreshAuthToken();
          if (!success) {
            print("Token refresh failed, logging out");
            await logout();
            _isLoading = false;
            notifyListeners();
            return;
          }
        } else {
          _accessToken = storedAccessToken;
          _refreshToken = storedRefreshToken;
          _currentUser = User.fromJson(json.decode(userData));
          _isLoggedIn = true;
          print("Valid token found, user logged in automatically");
        }
      } catch (e) {
        print("Error during initialization: $e");
        await logout();
      }
    }
    
    _isLoading = false;
    notifyListeners();
  }
  Future<bool> loginWithGoogle() async {
    _isLoading = true;
    _error = '';
    notifyListeners();

    try {
      if (kIsWeb) {
        // Para web: redirección directa (MÁS SIMPLE Y CONFIABLE)
        const String googleAuthUrl = '${ApiConstants.baseUrl}/api/auth/google';
        
        // Guardar estado para saber que estamos haciendo login con Google
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('auth_source', 'google_login');
        
        print('Redirigiendo a Google Auth: $googleAuthUrl');
        
        // Redirigir directamente - el backend maneja todo
        html.window.location.href = googleAuthUrl;
        
        return true; // La redirección maneja el resto
        
      } else {
        _error = 'Google OAuth solo disponible en web por ahora';
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _error = 'Error al conectar con Google: $e';
      print('Error en loginWithGoogle: $e');
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> handleGoogleCallback(String token, String refreshToken) async {
    try {
      _isLoading = true;
      notifyListeners();

      // Guardar tokens
      _accessToken = token;
      _refreshToken = refreshToken;

      // Obtener datos del usuario del token
      try {
        final payload = JwtDecoder.decode(token);
        print('Token payload: $payload');
        
        // Crear usuario básico desde el token
        _currentUser = User(
          id: payload['id'] ?? payload['userId'] ?? '',
          email: payload['email'] ?? '',
          username: payload['username'] ?? payload['name'] ?? '',
          role: payload['role'] ?? 'user',
          level: payload['level'] ?? 1,
          totalDistance: payload['totalDistance']?.toDouble() ?? 0.0,
          totalTime: payload['totalTime'] ?? 0,
          activities: [],
          achievements: [],
          challengesCompleted: [],
          profilePicture: payload['profilePicture'],
          bio: payload['bio'],
          visibility: payload['visibility'] ?? true,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );
      } catch (e) {
        print('Error decodificando token: $e');
        // Si no podemos decodificar, intentamos obtener datos del servidor
        final response = await http.get(
          Uri.parse('${ApiConstants.baseUrl}/api/auth/me'),
          headers: {'Authorization': 'Bearer $token'},
        );
        
        if (response.statusCode == 200) {
          final userData = json.decode(response.body);
          _currentUser = User.fromJson(userData);
        } else {
          throw Exception('No se pudieron obtener datos del usuario');
        }
      }

      _isLoggedIn = true;

      // Guardar en SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('access_token', _accessToken!);
      await prefs.setString('refresh_token', _refreshToken!);
      await prefs.setString('user', json.encode(_currentUser!.toJson()));
      await prefs.remove('auth_source'); // Limpiar flag de Google

      print('Google OAuth completado exitosamente para: ${_currentUser!.email}');

      _isLoading = false;
      notifyListeners();
      return true;

    } catch (e) {
      print('Error en handleGoogleCallback: $e');
      _error = 'Error procesando autenticación de Google: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
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
          'email': username,
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
          
          print("Datos de usuario recibidos: $userData");
          
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
          
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('access_token', _accessToken!);
          await prefs.setString('refresh_token', _refreshToken!);
          await prefs.setString('user', json.encode(userData));

          // Conectar socket
          socketService.disconnect();
          await Future.delayed(Duration(milliseconds: 500));
          socketService.connect(_currentUser, accessToken: _accessToken);

          print("Login exitoso para: ${_currentUser!.email}");

          _isLoading = false;
          notifyListeners();
          return _currentUser;
        }
      }
      
      final data = json.decode(response.body);
      _error = data['message'] ?? 'Error en el login';
      _isLoading = false;
      notifyListeners();
      return null;
      
    } catch (e) {
      _error = 'Error de login: $e';
      _isLoading = false;
      notifyListeners();
      return null;
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

    print("Server response (register): ${response.statusCode}");
    print("Server response body: ${response.body}");
    
    _isLoading = false;
    notifyListeners();
    if (response.statusCode == 200 || response.statusCode == 201) {
      print("Registro exitoso - código ${response.statusCode}");
      

      try {
        final responseData = json.decode(response.body);
        
        if (responseData.containsKey('token') && 
            responseData.containsKey('refreshToken') && 
            responseData.containsKey('user')) {
          
          print("Procesando tokens del registro...");
          
          _accessToken = responseData['token'];
          _refreshToken = responseData['refreshToken'];
          _currentUser = User.fromJson(responseData['user']);
          _isLoggedIn = true;

          // Guardar en SharedPreferences
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('access_token', _accessToken!);
          await prefs.setString('refresh_token', _refreshToken!);
          await prefs.setString('user', json.encode(responseData['user']));

          print('Usuario registrado y autenticado: ${_currentUser!.username}');
          notifyListeners();
        }
      } catch (e) {
        print("No se pudieron procesar tokens automáticamente: $e");
      }
      
      return true; 
      
    } else {
      print(" Error del servidor: ${response.statusCode}");
      try {
        final errorData = json.decode(response.body);
        _error = errorData['message'] ?? 'Error en el registro';
      } catch (e) {
        _error = 'Error en el registro - código ${response.statusCode}';
      }
      return false;
    }
  } catch (e) {
    print(' Error de registro: $e');
    _error = 'Error de conexión. Verifica tu internet e inténtalo de nuevo.';
    _isLoading = false;
    notifyListeners();
    return false;
  }
}

  Future<bool> refreshAuthToken() async {
    if (_refreshToken == null) {
      print("No refresh token available");
      return false;
    }
    
    try {
      print("Attempting to refresh token...");
      final response = await http.post(
        Uri.parse(ApiConstants.refreshToken),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'refreshToken': _refreshToken}),
      );
      
      print("Refresh response status: ${response.statusCode}");
      print("Refresh response body: ${response.body}");
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        
        if (data['token'] != null && data['refreshToken'] != null) {
          _accessToken = data['token'];
          _refreshToken = data['refreshToken'];
          
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('access_token', _accessToken!);
          await prefs.setString('refresh_token', _refreshToken!);
          
          print("Token refreshed successfully");
          notifyListeners();
          return true;
        }
      }
      
      print("Token refresh failed");
      return false;
    } catch (e) {
      print('Error refreshing token: $e');
      return false;
    }
  }

  void updateCurrentUser(User updatedUser) {
    _currentUser = updatedUser;
    _saveUserData(updatedUser);
    notifyListeners();
  }

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
      
      if (socketService != null) {
        socketService.disconnect();
        print("Socket desconectado");
      }
      
      _currentUser = null;
      _accessToken = null;
      _refreshToken = null;
      _isLoggedIn = false;
      
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

  bool isTokenExpired() {
    if (_accessToken == null) return true;
    
    try {
      return JwtDecoder.isExpired(_accessToken!);
    } catch (e) {
      print('Error al verificar expiración del token: $e');
      return true;
    }
  }

  Map<String, String> getAuthHeaders() {
    if (_accessToken == null) return {};
    return {'Authorization': 'Bearer $_accessToken'};
  }

  void clearError() {
    _error = '';
    notifyListeners();
  }
}