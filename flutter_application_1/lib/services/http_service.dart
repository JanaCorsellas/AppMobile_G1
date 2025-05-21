// lib/services/http_service.dart
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:flutter_application_1/services/auth_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http_parser/http_parser.dart';
import 'package:path/path.dart' as path;

class HttpService {
  final AuthService _authService;
  
  // Set up logging
  final bool _enableLogging;
  
  HttpService(this._authService, {bool enableLogging = true}) 
      : _enableLogging = enableLogging;
  
  // Helper method to print logs
  void _log(String message) {
    if (_enableLogging) {
      print('HttpService: $message');
    }
  }
  
  // Enhanced GET request with proper error handling and logging
  Future<http.Response> get(String url, {Map<String, String>? additionalHeaders}) async {
    return _request(() {
      _log('GET $url');
      return http.get(
        Uri.parse(url),
        headers: _getHeaders(additionalHeaders),
      );
    });
  }
  
  // Enhanced POST request
  Future<http.Response> post(String url, {Map<String, dynamic>? body, Map<String, String>? additionalHeaders}) async {
    return _request(() {
      _log('POST $url');
      _log('Body: ${body != null ? json.encode(body) : 'null'}');
      return http.post(
        Uri.parse(url),
        headers: _getHeaders(additionalHeaders),
        body: body != null ? json.encode(body) : null,
      );
    });
  }
  
  // Enhanced PUT request
  Future<http.Response> put(String url, {Map<String, dynamic>? body, Map<String, String>? additionalHeaders}) async {
    return _request(() {
      _log('PUT $url');
      _log('Body: ${body != null ? json.encode(body) : 'null'}');
      return http.put(
        Uri.parse(url),
        headers: _getHeaders(additionalHeaders),
        body: body != null ? json.encode(body) : null,
      );
    });
  }
  
  // Enhanced DELETE request
  Future<http.Response> delete(String url, {Map<String, String>? additionalHeaders}) async {
    return _request(() {
      _log('DELETE $url');
      return http.delete(
        Uri.parse(url),
        headers: _getHeaders(additionalHeaders),
      );
    });
  }

  // Método para enviar peticiones multipart (para subir archivos)
  Future<http.Response> postMultipart(
    String url, {
    Map<String, String>? fields,
    File? imageFile,
    String? imageFieldName = 'profilePicture',
    Map<String, String>? additionalHeaders,
  }) async {
    try {
      final request = http.MultipartRequest('POST', Uri.parse(url));
      
      // Añadir los headers
      final headers = _getHeaders(additionalHeaders);
      request.headers.addAll(headers);
      
      // Añadir campos de texto
      if (fields != null) {
        request.fields.addAll(fields);
      }
      
      // Añadir archivo si existe
      if (imageFile != null && imageFieldName != null) {
        final fileName = path.basename(imageFile.path);
        final mimeType = _getMimeType(fileName);
        
        _log('Añadiendo archivo: $fileName, tipo $mimeType');
        
        request.files.add(await http.MultipartFile.fromPath(
          imageFieldName,
          imageFile.path,
          contentType: mimeType,
        ));
      }
      
      // Enviar la petición
      _log('Enviando petición multipart a $url');
      final streamedResponse = await request.send();
      
      // Convertir a una respuesta normal
      final response = await http.Response.fromStream(streamedResponse);
      _log('Respuesta recibida: ${response.statusCode}');
      
      return response;
    } catch (e) {
      _log('Error en solicitud multipart: $e');
      rethrow;
    }
  }

  // Método para enviar peticiones PUT con multipart (para actualizar con archivos)
  Future<http.Response> putMultipart(
    String url, {
    Map<String, String>? fields,
    File? imageFile,
    String? imageFieldName = 'profilePicture',
    Map<String, String>? additionalHeaders,
  }) async {
    try {
      final request = http.MultipartRequest('PUT', Uri.parse(url));
      
      // Añadir los headers
      final headers = _getHeaders(additionalHeaders);
      request.headers.addAll(headers);
      
      // Añadir campos de texto
      if (fields != null) {
        request.fields.addAll(fields);
      }
      
      // Añadir archivo si existe
      if (imageFile != null && imageFieldName != null) {
        final fileName = path.basename(imageFile.path);
        final mimeType = _getMimeType(fileName);
        
        _log('Añadiendo archivo: $fileName, tipo $mimeType');
        
        request.files.add(await http.MultipartFile.fromPath(
          imageFieldName,
          imageFile.path,
          contentType: mimeType,
        ));
      }
      
      // Enviar la petición
      _log('Enviando petición multipart PUT a $url');
      final streamedResponse = await request.send();
      
      // Convertir a una respuesta normal
      final response = await http.Response.fromStream(streamedResponse);
      _log('Respuesta recibida: ${response.statusCode}');
      
      return response;
    } catch (e) {
      _log('Error en solicitud multipart PUT: $e');
      rethrow;
    }
  }

  // Método auxiliar para determinar el tipo MIME basado en la extensión del archivo
  MediaType _getMimeType(String fileName) {
    final ext = path.extension(fileName).toLowerCase();
    
    switch (ext) {
      case '.jpg':
      case '.jpeg':
        return MediaType('image', 'jpeg');
      case '.png':
        return MediaType('image', 'png');
      default:
        return MediaType('image', 'jpeg'); // Por defecto
    }
  }
  
  // Enhanced request wrapper with token refresh
  Future<http.Response> _request(Future<http.Response> Function() requestFunction) async {
    try {
      // Check if token is expired and refresh if needed
      if (_authService.isTokenExpired() && _authService.refreshToken != null) {
        _log('Access token expired, attempting refresh');
        final refreshed = await _authService.refreshAuthToken();
        if (!refreshed) {
          _log('Token refresh failed');
          throw Exception('Failed to refresh authentication token');
        }
        _log('Token refresh successful');
      }
      
      // Make the request
      final response = await requestFunction();
      
      // Log response code
      _log('Response status: ${response.statusCode}');
      
      // If unauthorized and we have a refresh token, try to refresh and retry
      if (response.statusCode == 401 && _authService.refreshToken != null) {
        _log('Received 401, attempting token refresh');
        final refreshed = await _authService.refreshAuthToken();
        if (refreshed) {
          _log('Token refreshed, retrying request');
          // Retry with new token
          return await requestFunction();
        } else {
          _log('Token refresh failed after 401 response');
          throw Exception('Authentication failed and token refresh unsuccessful');
        }
      }
      
      // Check for server errors
      if (response.statusCode >= 500) {
        _log('Server error: ${response.statusCode}');
        _log('Response body: ${response.body}');
        throw Exception('Server error: ${response.statusCode}');
      }
      
      return response;
    } catch (e) {
      _log('HTTP request error: $e');
      
      // Check if it's a connectivity issue
      if (e.toString().contains('SocketException') || 
          e.toString().contains('Connection refused')) {
        throw Exception('Network error: Please check your internet connection');
      }
      
      rethrow;
    }
  }
  
  // Generate headers for requests
  Map<String, String> _getHeaders([Map<String, String>? additionalHeaders]) {
    final headers = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };
    
    // Add auth header if we have a token
    final authHeaders = _authService.getAuthHeaders();
    headers.addAll(authHeaders);
    
    // Add any additional headers
    if (additionalHeaders != null) {
      headers.addAll(additionalHeaders);
    }
    
    _log('Request headers: $headers');
    
    return headers;
  }
  
  // Helper method to parse JSON responses with error handling
  Future<dynamic> parseJsonResponse(http.Response response) async {
    try {
      if (response.statusCode >= 200 && response.statusCode < 300) {
        if (response.body.isEmpty) {
          return null;
        }
        return json.decode(response.body);
      } else {
        // Try to parse error message from response
        String errorMessage = 'HTTP Error: ${response.statusCode}';
        try {
          final errorData = json.decode(response.body);
          if (errorData['message'] != null) {
            errorMessage = errorData['message'];
          }
        } catch (_) {
          // If parsing fails, use the body as is
          if (response.body.isNotEmpty) {
            errorMessage += ' - ${response.body}';
          }
        }
        throw Exception(errorMessage);
      }
    } catch (e) {
      _log('Error parsing response: $e');
      throw Exception('Failed to parse server response: $e');
    }
  }
  
  // Helper method to save response to cache
  Future<void> saveToCache(String key, dynamic data) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(key, json.encode(data));
    } catch (e) {
      _log('Error saving to cache: $e');
    }
  }
  
  // Helper method to get from cache
  Future<dynamic> getFromCache(String key) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cachedData = prefs.getString(key);
      if (cachedData != null) {
        return json.decode(cachedData);
      }
    } catch (e) {
      _log('Error retrieving from cache: $e');
    }
    return null;
  }
}