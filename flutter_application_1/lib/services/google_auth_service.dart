// lib/services/google_auth_service.dart - Versión SIMPLE
import 'dart:convert';
import 'dart:html' as html;
import 'dart:js' as js;
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_application_1/config/api_constants.dart';

class GoogleAuthService {
  static final GoogleAuthService _instance = GoogleAuthService._internal();
  factory GoogleAuthService() => _instance;
  GoogleAuthService._internal();

  static const String _clientId = '732241276462-ual5nsaiq2bcdr7odgesci6badrobpu8.apps.googleusercontent.com';
  bool _initialized = false;

  Future<void> initialize() async {
    if (_initialized) return;
    
    if (kIsWeb) {
      // Para web, esperar a que se cargue Google
      await _waitForGoogle();
    }
    
    _initialized = true;
    print('GoogleAuthService inicializado');
  }

  Future<void> _waitForGoogle() async {
    int attempts = 0;
    while (attempts < 50) {
      try {
        if (js.context.hasProperty('google')) {
          print('Google API cargada');
          return;
        }
      } catch (e) {
        // Continuar esperando
      }
      await Future.delayed(const Duration(milliseconds: 100));
      attempts++;
    }
    print('Google API no se cargó, pero continuando...');
  }

  Future<Map<String, dynamic>?> signInWithGoogle() async {
    try {
      if (!_initialized) {
        await initialize();
      }

      if (kIsWeb) {
        return await _webSignIn();
      } else {
        throw Exception('Móvil no implementado en versión simple');
      }
    } catch (e) {
      print('Error en signInWithGoogle: $e');
      rethrow;
    }
  }

  Future<Map<String, dynamic>?> _webSignIn() async {
    try {
      print('Iniciando autenticación web con popup...');
      
      // URL de autorización de Google
      final authUrl = 'https://accounts.google.com/o/oauth2/v2/auth?' +
          'client_id=$_clientId&' +
          'redirect_uri=${Uri.encodeComponent('${html.window.location.origin}/oauth_callback.html')}&' +
          'response_type=code&' +
          'scope=${Uri.encodeComponent('openid email profile')}&' +
          'access_type=offline&' +
          'prompt=select_account';
      
      print('Abriendo popup: $authUrl');
      
      // Abrir popup
      final popup = html.window.open(
        authUrl,
        'google_auth',
        'width=500,height=600,left=100,top=100'
      );
      
      if (popup == null) {
        throw Exception('No se pudo abrir popup. Habilita los popups.');
      }
      
      // Esperar el código
      String? code;
      
      await for (final event in html.window.onMessage) {
        if (event.data is String) {
          final data = event.data as String;
          if (data.startsWith('auth_code:')) {
            code = data.substring('auth_code:'.length);
            popup.close();
            break;
          } else if (data == 'auth_error') {
            popup.close();
            throw Exception('Error en autenticación');
          }
        }
        
        // Verificar si el popup se cerró
        try {
          if (popup.closed == true) {
            print('Popup cerrado por el usuario');
            return null;
          }
        } catch (e) {
          break;
        }
      }
      
      if (code == null) {
        return null;
      }
      
      // Enviar código al backend
      return await _sendCodeToBackend(code);
      
    } catch (e) {
      print('Error en _webSignIn: $e');
      rethrow;
    }
  }

  Future<Map<String, dynamic>?> _sendCodeToBackend(String code) async {
    try {
      final response = await http.post(
        Uri.parse('${ApiConstants.baseUrl}/api/auth/google/web'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'code': code}),
      );
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          return {
            'token': data['token'],
            'refreshToken': data['refreshToken'],
            'user': data['user'],
          };
        }
      }
      
      throw Exception('Error del servidor: ${response.body}');
    } catch (e) {
      print('Error enviando código al backend: $e');
      rethrow;
    }
  }

  Future<void> signOut() async {
    print('Sign out');
  }
}