// lib/services/http_service.dart
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_application_1/services/auth_service.dart';

class HttpService {
  final AuthService _authService;
  
  HttpService(this._authService);

  /// Get authentication headers for JSON requests
  Map<String, String> getAuthHeaders() {
    final headers = <String, String>{
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };
    
    if (_authService.accessToken != null && _authService.accessToken!.isNotEmpty) {
      headers['Authorization'] = 'Bearer ${_authService.accessToken}';
      print('Adding Authorization header: Bearer ${_authService.accessToken!.substring(0, 20)}...');
    } else {
      print('No access token available for request');
    }
    
    return headers;
  }

  /// Get authentication headers for multipart requests (no Content-Type)
  Map<String, String> getAuthHeadersForMultipart() {
    final headers = <String, String>{
      'Accept': 'application/json',
    };
    
    if (_authService.accessToken != null && _authService.accessToken!.isNotEmpty) {
      headers['Authorization'] = 'Bearer ${_authService.accessToken}';
      print('Adding Authorization header for multipart: Bearer ${_authService.accessToken!.substring(0, 20)}...');
    } else {
      print('No access token available for multipart request');
    }
    
    return headers;
  }

  /// HTTP GET request
  Future<http.Response> get(String url) async {
    try {
      print('HTTP GET: $url');
      
      final response = await http.get(
        Uri.parse(url),
        headers: getAuthHeaders(),
      ).timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          throw Exception('Request timeout after 30 seconds');
        },
      );
      
      print('GET Response: ${response.statusCode} - ${response.body.length} chars');
      
      if (response.statusCode == 401) {
        await _handleUnauthorized();
        throw Exception('Unauthorized - Token expired or invalid');
      }
      
      return response;
    } on SocketException {
      throw Exception('No internet connection');
    } on HttpException {
      throw Exception('HTTP error occurred');
    } on FormatException {
      throw Exception('Bad response format');
    } catch (e) {
      print('HTTP GET Error: $e');
      rethrow;
    }
  }

  /// HTTP POST request
  Future<http.Response> post(String url, {Map<String, dynamic>? body}) async {
    try {
      print('HTTP POST: $url');
      if (body != null) {
        print('POST Body: ${json.encode(body)}');
      }
      
      final response = await http.post(
        Uri.parse(url),
        headers: getAuthHeaders(),
        body: body != null ? json.encode(body) : null,
      ).timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          throw Exception('Request timeout after 30 seconds');
        },
      );
      
      print('POST Response: ${response.statusCode} - ${response.body}');
      
      if (response.statusCode == 401) {
        await _handleUnauthorized();
        throw Exception('Unauthorized - Token expired or invalid');
      }
      
      return response;
    } on SocketException {
      throw Exception('No internet connection');
    } on HttpException {
      throw Exception('HTTP error occurred');
    } on FormatException {
      throw Exception('Bad response format');
    } catch (e) {
      print('HTTP POST Error: $e');
      rethrow;
    }
  }

  /// HTTP PUT request
  Future<http.Response> put(String url, {Map<String, dynamic>? body}) async {
    try {
      print('HTTP PUT: $url');
      if (body != null) {
        print('PUT Body: ${json.encode(body)}');
      }
      
      final response = await http.put(
        Uri.parse(url),
        headers: getAuthHeaders(),
        body: body != null ? json.encode(body) : null,
      ).timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          throw Exception('Request timeout after 30 seconds');
        },
      );
      
      print('PUT Response: ${response.statusCode} - ${response.body}');
      
      if (response.statusCode == 401) {
        await _handleUnauthorized();
        throw Exception('Unauthorized - Token expired or invalid');
      }
      
      return response;
    } on SocketException {
      throw Exception('No internet connection');
    } on HttpException {
      throw Exception('HTTP error occurred');
    } on FormatException {
      throw Exception('Bad response format');
    } catch (e) {
      print('HTTP PUT Error: $e');
      rethrow;
    }
  }

  /// HTTP DELETE request
  Future<http.Response> delete(String url) async {
    try {
      print('HTTP DELETE: $url');
      
      final response = await http.delete(
        Uri.parse(url),
        headers: getAuthHeaders(),
      ).timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          throw Exception('Request timeout after 30 seconds');
        },
      );
      
      print('DELETE Response: ${response.statusCode} - ${response.body}');
      
      if (response.statusCode == 401) {
        await _handleUnauthorized();
        throw Exception('Unauthorized - Token expired or invalid');
      }
      
      return response;
    } on SocketException {
      throw Exception('No internet connection');
    } on HttpException {
      throw Exception('HTTP error occurred');
    } on FormatException {
      throw Exception('Bad response format');
    } catch (e) {
      print('HTTP DELETE Error: $e');
      rethrow;
    }
  }

  /// HTTP PATCH request
  Future<http.Response> patch(String url, {Map<String, dynamic>? body}) async {
    try {
      print('HTTP PATCH: $url');
      if (body != null) {
        print('PATCH Body: ${json.encode(body)}');
      }
      
      final response = await http.patch(
        Uri.parse(url),
        headers: getAuthHeaders(),
        body: body != null ? json.encode(body) : null,
      ).timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          throw Exception('Request timeout after 30 seconds');
        },
      );
      
      print('PATCH Response: ${response.statusCode} - ${response.body}');
      
      if (response.statusCode == 401) {
        await _handleUnauthorized();
        throw Exception('Unauthorized - Token expired or invalid');
      }
      
      return response;
    } on SocketException {
      throw Exception('No internet connection');
    } on HttpException {
      throw Exception('HTTP error occurred');
    } on FormatException {
      throw Exception('Bad response format');
    } catch (e) {
      print('HTTP PATCH Error: $e');
      rethrow;
    }
  }

  /// Multipart request for file uploads
  Future<http.StreamedResponse> multipartRequest(
    String method,
    String url, {
    Map<String, String>? fields,
    List<http.MultipartFile>? files,
  }) async {
    try {
      print('HTTP $method (Multipart): $url');
      
      final request = http.MultipartRequest(method, Uri.parse(url));
      
      // Add authentication headers
      request.headers.addAll(getAuthHeadersForMultipart());
      
      // Add fields
      if (fields != null) {
        request.fields.addAll(fields);
        print('Multipart fields: $fields');
      }
      
      // Add files
      if (files != null) {
        request.files.addAll(files);
        print('Multipart files: ${files.length} file(s)');
        for (var file in files) {
          print('  - ${file.field}: ${file.filename} (${file.length} bytes)');
        }
      }
      
      final streamedResponse = await request.send().timeout(
        const Duration(seconds: 60), // Longer timeout for file uploads
        onTimeout: () {
          throw Exception('Upload timeout after 60 seconds');
        },
      );
      
      print('Multipart Response: ${streamedResponse.statusCode}');
      
      if (streamedResponse.statusCode == 401) {
        await _handleUnauthorized();
        throw Exception('Unauthorized - Token expired or invalid');
      }
      
      return streamedResponse;
    } on SocketException {
      throw Exception('No internet connection');
    } on HttpException {
      throw Exception('HTTP error occurred');
    } catch (e) {
      print('HTTP Multipart Error: $e');
      rethrow;
    }
  }

  /// Parse JSON response with comprehensive error handling
  Future<dynamic> parseJsonResponse(http.Response response) async {
    try {
      print('Parsing response: ${response.statusCode} - ${response.body.substring(0, response.body.length > 200 ? 200 : response.body.length)}...');
      
      if (response.statusCode >= 200 && response.statusCode < 300) {
        if (response.body.isEmpty) {
          return {};
        }
        return json.decode(response.body);
      } else {
        // Handle error responses
        String errorMessage = 'HTTP Error ${response.statusCode}';
        
        try {
          final errorData = json.decode(response.body);
          if (errorData is Map<String, dynamic> && errorData.containsKey('message')) {
            errorMessage = errorData['message'];
          } else if (errorData is String) {
            errorMessage = errorData;
          }
        } catch (e) {
          // If error response is not JSON, use the raw body
          if (response.body.isNotEmpty) {
            errorMessage = response.body;
          }
        }
        
        print('HTTP Error: $errorMessage');
        throw Exception(errorMessage);
      }
    } catch (e) {
      if (e is FormatException) {
        print('JSON Parse Error: Invalid JSON format - ${response.body}');
        throw Exception('Invalid JSON response');
      }
      rethrow;
    }
  }

  /// Parse streamed response (for multipart requests)
  Future<dynamic> parseStreamedResponse(http.StreamedResponse streamedResponse) async {
    try {
      final response = await http.Response.fromStream(streamedResponse);
      return await parseJsonResponse(response);
    } catch (e) {
      print('Streamed Response Parse Error: $e');
      rethrow;
    }
  }

  /// Handle 401 unauthorized responses
  Future<void> _handleUnauthorized() async {
    try {
      print('Handling unauthorized response - attempting token refresh');
      
      // Try to refresh the token
      final refreshed = await _authService.refreshAuthToken();
      
      if (!refreshed) {
        print('Token refresh failed - logging out user');
        // If refresh fails, logout the user
        await _authService.logout();
      } else {
        print('Token refreshed successfully');
      }
    } catch (e) {
      print('Error handling unauthorized response: $e');
      await _authService.logout();
    }
  }

  // ═══════════════════════════════════════════════════════════════
  // CACHE MANAGEMENT METHODS
  // ═══════════════════════════════════════════════════════════════

  /// Save data to local cache
  Future<void> saveToCache(String key, dynamic data) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = json.encode(data);
      await prefs.setString(key, jsonString);
      print('✅ Data saved to cache with key: $key');
    } catch (e) {
      print('❌ Error saving to cache: $e');
    }
  }

  /// Get data from local cache
  Future<dynamic> getFromCache(String key) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString(key);
      if (jsonString != null) {
        print('✅ Data retrieved from cache with key: $key');
        return json.decode(jsonString);
      }
      print('⚠️ No data found in cache for key: $key');
      return null;
    } catch (e) {
      print('❌ Error getting from cache: $e');
      return null;
    }
  }

  /// Remove specific data from cache
  Future<void> removeFromCache(String key) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(key);
      print('✅ Data removed from cache with key: $key');
    } catch (e) {
      print('❌ Error removing from cache: $e');
    }
  }

  /// Clear all cache data
  Future<void> clearCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();
      print('✅ All cache cleared');
    } catch (e) {
      print('❌ Error clearing cache: $e');
    }
  }

  /// Check if data exists in cache
  Future<bool> hasCache(String key) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.containsKey(key);
    } catch (e) {
      print('❌ Error checking cache: $e');
      return false;
    }
  }

  /// Get all cache keys
  Future<Set<String>> getCacheKeys() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getKeys();
    } catch (e) {
      print('❌ Error getting cache keys: $e');
      return <String>{};
    }
  }

  // ═══════════════════════════════════════════════════════════════
  // UTILITY METHODS
  // ═══════════════════════════════════════════════════════════════

  /// Check internet connectivity
  Future<bool> hasInternetConnection() async {
    try {
      final result = await InternetAddress.lookup('google.com');
      return result.isNotEmpty && result[0].rawAddress.isNotEmpty;
    } on SocketException catch (_) {
      return false;
    }
  }

  /// Build query parameters string
  String buildQueryString(Map<String, dynamic> params) {
    if (params.isEmpty) return '';
    
    final queryParams = params.entries
        .where((entry) => entry.value != null)
        .map((entry) => '${Uri.encodeComponent(entry.key)}=${Uri.encodeComponent(entry.value.toString())}')
        .join('&');
    
    return queryParams.isNotEmpty ? '?$queryParams' : '';
  }

  /// Add query parameters to URL
  String addQueryParams(String url, Map<String, dynamic> params) {
    final queryString = buildQueryString(params);
    return url + queryString;
  }

  /// Get file size in human readable format
  String getFileSizeString(int bytes) {
    const suffixes = ['B', 'KB', 'MB', 'GB'];
    var i = 0;
    double size = bytes.toDouble();
    
    while (size >= 1024 && i < suffixes.length - 1) {
      size /= 1024;
      i++;
    }
    
    return '${size.toStringAsFixed(1)} ${suffixes[i]}';
  }

  /// Validate response status code
  bool isSuccessStatusCode(int statusCode) {
    return statusCode >= 200 && statusCode < 300;
  }

  /// Get error message from response
  String getErrorMessage(http.Response response) {
    try {
      final data = json.decode(response.body);
      if (data is Map<String, dynamic> && data.containsKey('message')) {
        return data['message'];
      }
      return 'HTTP Error ${response.statusCode}';
    } catch (e) {
      return 'HTTP Error ${response.statusCode}';
    }
  }

  // ═══════════════════════════════════════════════════════════════
  // DEBUG METHODS
  // ═══════════════════════════════════════════════════════════════

  /// Print detailed request information (for debugging)
  void debugRequest(String method, String url, {Map<String, String>? headers, String? body}) {
    print('🌐 HTTP Request Debug:');
    print('   Method: $method');
    print('   URL: $url');
    if (headers != null) {
      print('   Headers:');
      headers.forEach((key, value) {
        // Hide sensitive information
        final displayValue = key.toLowerCase() == 'authorization' 
            ? 'Bearer ${value.substring(7, 27)}...' 
            : value;
        print('     $key: $displayValue');
      });
    }
    if (body != null) {
      print('   Body: ${body.length > 500 ? body.substring(0, 500) + '...' : body}');
    }
  }

  /// Print detailed response information (for debugging)
  void debugResponse(http.Response response) {
    print('📡 HTTP Response Debug:');
    print('   Status: ${response.statusCode}');
    print('   Headers: ${response.headers}');
    print('   Body: ${response.body.length > 500 ? response.body.substring(0, 500) + '...' : response.body}');
  }

  /// Get service status information
  Map<String, dynamic> getServiceStatus() {
    return {
      'hasAuthToken': _authService.accessToken != null && _authService.accessToken!.isNotEmpty,
      'isAuthenticated': _authService.isLoggedIn,
      'currentUser': _authService.currentUser?.username ?? 'None',
      'tokenExpired': _authService.isTokenExpired(),
    };
  }
}