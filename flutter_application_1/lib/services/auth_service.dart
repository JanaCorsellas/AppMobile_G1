// lib/services/auth_service.dart - Versión actualizada con Google OAuth
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_application_1/config/api_constants.dart';
import 'package:flutter_application_1/models/user.dart';
import 'package:flutter_application_1/services/socket_service.dart';
import 'package:flutter_application_1/services/google_auth_service.dart'; // NUEVO
import 'package:jwt_decoder/jwt_decoder.dart';

class AuthService with ChangeNotifier {
  User? _currentUser;
  String? _accessToken;
  String? _refreshToken;
  bool _isLoggedIn = false;
  bool _isLoading = false;
  String _error = '';

  // NUEVO: Instancia de Google Auth Service
  final GoogleAuthService _googleAuthService = GoogleAuthService();

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
    
    // NUEVO: Inicializar Google Auth Service
    await _googleAuthService.initialize();
    
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
          print("Using stored valid access token");
        }
        
        try {
          final parsedJson = json.decode(userData);
          print("Attempting to parse stored user data: $parsedJson");
          
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
  // Agregar a AuthService:
void updateTokensAndUser(String token, String refreshToken, String userDataJson) {
  try {
    _accessToken = token;
    _refreshToken = refreshToken;
    _currentUser = User.fromJson(json.decode(userDataJson));
    _isLoggedIn = true;
    
    print('Tokens y usuario actualizados desde Google Auth');
    notifyListeners();
  } catch (e) {
    print('Error actualizando tokens y usuario: $e');
    rethrow;
  }
}

  // NUEVO: Login con Google
  Future<User?> loginWithGoogle(SocketService socketService) async {
    _isLoading = true;
    _error = '';
    notifyListeners();

    try {
      print("Iniciando login con Google");
      
      final result = await _googleAuthService.signInWithGoogle();
      
      if (result == null) {
        _isLoading = false;
        notifyListeners();
        return null; // Usuario canceló
      }

      // Extraer datos del resultado
      _accessToken = result['token'];
      _refreshToken = result['refreshToken'];
      final userData = result['user'];

      if (_accessToken == null || _refreshToken == null || userData == null) {
        throw Exception('Datos incompletos del servidor');
      }

      // Crear objeto User
      _currentUser = User.fromJson(userData);
      _isLoggedIn = true;

      // Guardar en SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('access_token', _accessToken!);
      await prefs.setString('refresh_token', _refreshToken!);
      await prefs.setString('user', json.encode(userData));

      // Conectar socket
      socketService.disconnect();
      await Future.delayed(Duration(milliseconds: 500));
      socketService.connect(_currentUser, accessToken: _accessToken);

      print("Login con Google exitoso para: ${_currentUser!.email}");

      _isLoading = false;
      notifyListeners();
      return _currentUser;

    } catch (e) {
      print('Error en login con Google: $e');
      _error = 'Error en autenticación con Google: $e';
      _isLoading = false;
      notifyListeners();
      return null;
    }
  }

  // Login tradicional (mantener existente)
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
          
          socketService.disconnect();
          await Future.delayed(Duration(milliseconds: 500));
          socketService.connect(user, accessToken: _accessToken);
          
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

  // Resto del código mantener igual...
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
          
          if (data['refreshToken'] != null) {
            _refreshToken = data['refreshToken'];
            
            final prefs = await SharedPreferences.getInstance();
            await prefs.setString('refresh_token', _refreshToken!);
          }
          
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
  Future<bool> checkAndHandleGoogleAuth() async {
  try {
    final response = await http.get(
      Uri.parse('${ApiConstants.baseUrl}/api/auth/google/data'),
      headers: {'Content-Type': 'application/json'},
    );
    
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      
      if (data['success'] == true) {
        _accessToken = data['token'];
        _refreshToken = data['refreshToken'];
        _currentUser = User.fromJson(data['user']);
        _isLoggedIn = true;
        
        // Guardar en SharedPreferences
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('access_token', _accessToken!);
        await prefs.setString('refresh_token', _refreshToken!);
        await prefs.setString('user', json.encode(data['user']));
        
        print('Google auth data retrieved successfully');
        notifyListeners();
        return true;
      }
    }
    
    return false;
  } catch (e) {
    print('Error checking Google auth: $e');
    return false;
  }
}
  
  Future<void> logout([SocketService? socketService]) async {
    try {
      // NUEVO: Cerrar sesión de Google también
      await _googleAuthService.signOut();
      
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