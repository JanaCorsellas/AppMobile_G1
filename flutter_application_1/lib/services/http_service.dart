// lib/services/http_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_application_1/services/auth_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class HttpService {
  final AuthService _authService;
  
  // Habilitar logs detallados para depuración
  final bool _enableLogging = true;
  
  HttpService(this._authService);
  
  // Helper method para imprimir logs
  void _log(String message) {
    if (_enableLogging) {
      print('HttpService: $message');
    }
  }
  
  // GET request mejorado
  Future<http.Response> get(String url, {Map<String, String>? headers}) async {
    try {
      final Map<String, String> allHeaders = _getHeaders();
      
      if (headers != null) {
        allHeaders.addAll(headers);
      }
      
      // Log detallado
      _log('GET $url');
      _log('Headers: $allHeaders');
      
      final response = await http.get(
        Uri.parse(url),
        headers: allHeaders,
      );
      
      // Log de la respuesta
      _log('Response status: ${response.statusCode}');
      _log('Response body: ${response.body.substring(0, response.body.length > 100 ? 100 : response.body.length)}...');
      
      // Si token expirado, intentar refresh
      if (response.statusCode == 401 && _authService.refreshToken != null) {
        _log('Recibido 401, intentando refrescar token...');
        final refreshed = await _authService.refreshAuthToken();
        
        if (refreshed) {
          _log('Token refrescado, reintentando solicitud');
          return await http.get(
            Uri.parse(url),
            headers: _getHeaders(),
          );
        }
      }
      
      return response;
    } catch (e) {
      _log('Error en GET request: $e');
      throw Exception('Error de conexión: $e');
    }
  }
  
  // POST request mejorado
  Future<http.Response> post(String url, {Map<String, dynamic>? body, Map<String, String>? headers}) async {
    try {
      final Map<String, String> allHeaders = _getHeaders();
      
      if (headers != null) {
        allHeaders.addAll(headers);
      }
      
      // Log detallado
      _log('POST $url');
      _log('Headers: $allHeaders');
      _log('Body: ${body != null ? json.encode(body) : "null"}');
      
      final response = await http.post(
        Uri.parse(url),
        headers: allHeaders,
        body: body != null ? json.encode(body) : null,
      );
      
      // Log de la respuesta
      _log('Response status: ${response.statusCode}');
      _log('Response body: ${response.body.substring(0, response.body.length > 100 ? 100 : response.body.length)}...');
      
      // Si token expirado, intentar refresh
      if (response.statusCode == 401 && _authService.refreshToken != null) {
        _log('Recibido 401, intentando refrescar token...');
        final refreshed = await _authService.refreshAuthToken();
        
        if (refreshed) {
          _log('Token refrescado, reintentando solicitud');
          return await http.post(
            Uri.parse(url),
            headers: _getHeaders(),
            body: body != null ? json.encode(body) : null,
          );
        }
      }
      
      return response;
    } catch (e) {
      _log('Error en POST request: $e');
      throw Exception('Error de conexión: $e');
    }
  }
  
  // PUT request mejorado
  Future<http.Response> put(String url, {Map<String, dynamic>? body, Map<String, String>? headers}) async {
    try {
      final Map<String, String> allHeaders = _getHeaders();
      
      if (headers != null) {
        allHeaders.addAll(headers);
      }
      
      // Log detallado
      _log('PUT $url');
      _log('Headers: $allHeaders');
      _log('Body: ${body != null ? json.encode(body) : "null"}');
      
      final response = await http.put(
        Uri.parse(url),
        headers: allHeaders,
        body: body != null ? json.encode(body) : null,
      );
      
      // Log de la respuesta
      _log('Response status: ${response.statusCode}');
      _log('Response body: ${response.body.substring(0, response.body.length > 100 ? 100 : response.body.length)}...');
      
      // Si token expirado, intentar refresh
      if (response.statusCode == 401 && _authService.refreshToken != null) {
        _log('Recibido 401, intentando refrescar token...');
        final refreshed = await _authService.refreshAuthToken();
        
        if (refreshed) {
          _log('Token refrescado, reintentando solicitud');
          return await http.put(
            Uri.parse(url),
            headers: _getHeaders(),
            body: body != null ? json.encode(body) : null,
          );
        }
      }
      
      return response;
    } catch (e) {
      _log('Error en PUT request: $e');
      throw Exception('Error de conexión: $e');
    }
  }
  
  // DELETE request mejorado
  Future<http.Response> delete(String url, {Map<String, dynamic>? body, Map<String, String>? headers}) async {
    try {
      final Map<String, String> allHeaders = _getHeaders();
      
      if (headers != null) {
        allHeaders.addAll(headers);
      }
      
      // Log detallado
      _log('DELETE $url');
      _log('Headers: $allHeaders');
      
      final response = await http.delete(
        Uri.parse(url),
        headers: allHeaders,
        body: body != null ? json.encode(body) : null,
      );
      
      // Log de la respuesta
      _log('Response status: ${response.statusCode}');
      _log('Response body: ${response.body.substring(0, response.body.length > 100 ? 100 : response.body.length)}...');
      
      // Si token expirado, intentar refresh
      if (response.statusCode == 401 && _authService.refreshToken != null) {
        _log('Recibido 401, intentando refrescar token...');
        final refreshed = await _authService.refreshAuthToken();
        
        if (refreshed) {
          _log('Token refrescado, reintentando solicitud');
          return await http.delete(
            Uri.parse(url),
            headers: _getHeaders(),
          );
        }
      }
      
      return response;
    } catch (e) {
      _log('Error en DELETE request: $e');
      throw Exception('Error de conexión: $e');
    }
  }
  
  // Construir headers incluyendo el token JWT
  Map<String, String> _getHeaders() {
    final Map<String, String> headers = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };
    
    // Añadir token de autenticación si está disponible
    final authToken = _authService.accessToken;
    if (authToken != null && authToken.isNotEmpty) {
      headers['Authorization'] = 'Bearer $authToken';
    }
    
    return headers;
  }
  
  // Helper para procesar respuestas JSON
  Future<dynamic> parseJsonResponse(http.Response response) async {
    try {
      if (response.statusCode >= 200 && response.statusCode < 300) {
        if (response.body.isEmpty) {
          return null;
        }
        return json.decode(response.body);
      } else {
        _log('Error de respuesta HTTP: ${response.statusCode}');
        _log('Cuerpo de respuesta: ${response.body}');
        
        String errorMessage;
        try {
          final errorData = json.decode(response.body);
          errorMessage = errorData['message'] ?? 'Error del servidor: ${response.statusCode}';
        } catch (_) {
          errorMessage = 'Error del servidor: ${response.statusCode}';
        }
        
        throw Exception(errorMessage);
      }
    } catch (e) {
      _log('Error procesando respuesta JSON: $e');
      throw e;
    }
  }
  
  // Helper para guardar en caché
  Future<void> saveToCache(String key, dynamic data) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(key, json.encode(data));
    } catch (e) {
      _log('Error guardando en caché: $e');
    }
  }
  
  // Helper para obtener de caché
  Future<dynamic> getFromCache(String key) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final data = prefs.getString(key);
      
      if (data != null) {
        return json.decode(data);
      }
    } catch (e) {
      _log('Error obteniendo de caché: $e');
    }
    
    return null;
  }
}