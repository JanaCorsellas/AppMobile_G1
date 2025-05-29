// lib/services/google_auth_service.dart - VERSIÓN FINAL SIMPLE
import 'dart:convert';
import 'dart:html' as html;
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_application_1/config/api_constants.dart';

class GoogleAuthService {
  static final GoogleAuthService _instance = GoogleAuthService._internal();
  factory GoogleAuthService() => _instance;
  GoogleAuthService._internal();

  bool _initialized = false;

  Future<void> initialize() async {
    if (_initialized) return;
    _initialized = true;
    print('GoogleAuthService inicializado');
  }

  Future<Map<String, dynamic>?> signInWithGoogle() async {
    try {
      if (!_initialized) {
        await initialize();
      }

      if (kIsWeb) {
        return await _webSignIn();
      } else {
        throw Exception('Móvil no implementado');
      }
    } catch (e) {
      print('Error en signInWithGoogle: $e');
      rethrow;
    }
  }

  Future<Map<String, dynamic>?> _webSignIn() async {
    try {
      print('🚀 Iniciando autenticación con Google');
      
      // Guardar estado antes del redirect
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('auth_source', 'google_login');
      
      // Usar la URL que ya funciona en tu backend
      const String googleAuthUrl = '${ApiConstants.baseUrl}/api/auth/google';
      
      print('🔗 Redirigiendo a: $googleAuthUrl');
      
      // Redirigir directamente
      html.window.location.href = googleAuthUrl;
      
      // Esta función no retornará porque hay redirect
      return null;
      
    } catch (e) {
      print('❌ Error en _webSignIn: $e');
      rethrow;
    }
  }

  // Verificar si hay autenticación completada después del redirect
  Future<Map<String, dynamic>?> checkPendingAuth() async {
    try {
      print('🔍 Verificando autenticación pendiente...');
      
      // Método 1: Verificar localStorage (si el backend guarda ahí)
      final storageAuth = await _checkLocalStorageAuth();
      if (storageAuth != null) {
        return storageAuth;
      }
      
      // Método 2: Verificar URL parameters (si el backend pasa datos por URL)
      final urlAuth = await _checkUrlAuth();
      if (urlAuth != null) {
        return urlAuth;
      }
      
      // Método 3: Verificar SharedPreferences (datos previos)
      final prefsAuth = await _checkSharedPreferencesAuth();
      if (prefsAuth != null) {
        return prefsAuth;
      }
      
      return null;
    } catch (e) {
      print('Error verificando auth pendiente: $e');
      return null;
    }
  }

  Future<Map<String, dynamic>?> _checkLocalStorageAuth() async {
    try {
      final storage = html.window.localStorage;
      final authSuccess = storage['google_auth_success'];
      final authData = storage['google_auth_data'];
      
      if (authSuccess == 'true' && authData != null) {
        print('✅ Datos encontrados en localStorage');
        
        // Limpiar localStorage
        storage.remove('google_auth_success');
        storage.remove('google_auth_data');
        
        final data = json.decode(authData);
        return {
          'token': data['token'],
          'refreshToken': data['refreshToken'],
          'user': data['user'],
        };
      }
    } catch (e) {
      print('Error verificando localStorage: $e');
    }
    return null;
  }

  Future<Map<String, dynamic>?> _checkUrlAuth() async {
    try {
      final uri = Uri.parse(html.window.location.href);
      final googleAuthParam = uri.queryParameters['google_auth'];
      
      if (googleAuthParam != null) {
        print('✅ Datos encontrados en URL parameters');
        
        // Decodificar los datos
        final decodedData = utf8.decode(base64.decode(googleAuthParam));
        final data = json.decode(decodedData);
        
        // Limpiar la URL
        html.window.history.replaceState(null, '', uri.path);
        
        return {
          'token': data['token'],
          'refreshToken': data['refreshToken'],
          'user': data['user'],
        };
      }
    } catch (e) {
      print('Error verificando URL parameters: $e');
    }
    return null;
  }

  Future<Map<String, dynamic>?> _checkSharedPreferencesAuth() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final authSource = prefs.getString('auth_source');
      
      if (authSource == 'google_login') {
        print('🔍 Verificando datos guardados...');
        
        final token = prefs.getString('access_token');
        final refreshToken = prefs.getString('refresh_token');
        final userJson = prefs.getString('user');
        
        if (token != null && refreshToken != null && userJson != null) {
          print('✅ Datos encontrados en SharedPreferences');
          
          // Limpiar flag
          await prefs.remove('auth_source');
          
          return {
            'token': token,
            'refreshToken': refreshToken,
            'user': json.decode(userJson),
          };
        }
      }
    } catch (e) {
      print('Error verificando SharedPreferences: $e');
    }
    return null;
  }

  Future<void> signOut() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('auth_source');
      
      // Limpiar localStorage también
      if (kIsWeb) {
        final storage = html.window.localStorage;
        storage.remove('google_auth_success');
        storage.remove('google_auth_data');
      }
      
      print('✅ Google sign out completado');
    } catch (e) {
      print('Error en sign out: $e');
    }
  }
}