// lib/screens/auth/oauth_success_screen.dart - ARCHIVO COMPLETO
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_application_1/services/auth_service.dart';
import 'package:flutter_application_1/services/socket_service.dart';
import 'package:flutter_application_1/config/routes.dart';

class OAuthSuccessScreen extends StatefulWidget {
  @override
  _OAuthSuccessScreenState createState() => _OAuthSuccessScreenState();
}

class _OAuthSuccessScreenState extends State<OAuthSuccessScreen> {
  bool _isProcessing = true;
  String _statusMessage = 'Completando autenticación...';

  @override
  void initState() {
    super.initState();
    print('🎯 OAuthSuccessScreen iniciado');
    _handleOAuthCallback();
  }

  Future<void> _handleOAuthCallback() async {
    try {
      print('🔄 Iniciando procesamiento de OAuth callback...');
      
      final authService = Provider.of<AuthService>(context, listen: false);
      final socketService = Provider.of<SocketService>(context, listen: false);
      
      // Obtener tokens de la URL
      final uri = Uri.base;
      print('📍 URL actual: ${uri.toString()}');
      print('📝 Query parameters: ${uri.queryParameters}');
      
      final token = uri.queryParameters['token'];
      final refreshToken = uri.queryParameters['refreshToken'];
      
      print('🔐 Token presente: ${token != null ? "SÍ" : "NO"}');
      print('🔄 RefreshToken presente: ${refreshToken != null ? "SÍ" : "NO"}');
      
      if (token != null && refreshToken != null) {
        setState(() {
          _statusMessage = 'Procesando tokens...';
        });
        
        print('✅ Tokens encontrados, procesando...');
        
        // Procesar el callback de Google
        final success = await authService.handleGoogleCallback(token, refreshToken);
        
        if (success) {
          setState(() {
            _statusMessage = 'Conectando...';
          });
          
          print('✅ Callback procesado exitosamente');
          print('👤 Usuario: ${authService.currentUser?.email}');
          print('🔑 Admin: ${authService.isAdmin}');
          
          // Conectar socket si es necesario
          try {
            socketService.connect(authService.currentUser, accessToken: authService.accessToken);
            print('🔌 Socket conectado');
          } catch (socketError) {
            print('⚠️ Error conectando socket: $socketError');
            // Continuar sin socket
          }
          
          // Pequeña pausa para que se procese todo
          await Future.delayed(Duration(milliseconds: 500));
          
          setState(() {
            _statusMessage = 'Redirigiendo...';
          });
          
          // Redirigir según el rol del usuario
          if (authService.isAdmin == true) {
            print('🔄 Redirigiendo a admin...');
            Navigator.pushReplacementNamed(context, AppRoutes.admin);
          } else {
            print('🔄 Redirigiendo a user home...');
            Navigator.pushReplacementNamed(context, AppRoutes.userHome);
          }
        } else {
          // Error en la autenticación
          print('❌ Error procesando callback');
          _showErrorAndRedirect('Error procesando autenticación de Google');
        }
      } else {
        // Error: no se encontraron los tokens
        print('❌ No se encontraron tokens en la URL');
        _showErrorAndRedirect('Error: no se recibieron los tokens de autenticación');
      }
    } catch (e, stackTrace) {
      print('❌ Error en OAuth callback: $e');
      print('📄 Stack trace: $stackTrace');
      _showErrorAndRedirect('Error procesando autenticación: $e');
    }
  }

  void _showErrorAndRedirect(String message) {
    print('🚨 Mostrando error: $message');
    
    setState(() {
      _isProcessing = false;
      _statusMessage = message;
    });

    // Mostrar snackbar con el error
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 5),
          action: SnackBarAction(
            label: 'Cerrar',
            textColor: Colors.white,
            onPressed: () {
              ScaffoldMessenger.of(context).hideCurrentSnackBar();
            },
          ),
        ),
      );
    }
    
    // Redirigir a login después de 3 segundos
    Future.delayed(Duration(seconds: 3), () {
      if (mounted) {
        print('🔄 Redirigiendo a login por error...');
        Navigator.pushReplacementNamed(context, AppRoutes.login);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.deepPurple.withOpacity(0.8),
              Colors.white,
            ],
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Logo o icono
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(40),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 10,
                      offset: Offset(0, 5),
                    ),
                  ],
                ),
                child: Icon(
                  Icons.check_circle_outline,
                  color: Colors.green,
                  size: 40,
                ),
              ),
              
              SizedBox(height: 30),
              
              // Indicador de carga
              if (_isProcessing) ...[
                CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.deepPurple),
                  strokeWidth: 3,
                ),
                SizedBox(height: 20),
              ],
              
              // Mensaje de estado
              Container(
                padding: EdgeInsets.symmetric(horizontal: 40),
                child: Text(
                  _statusMessage,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 18,
                    color: _isProcessing ? Colors.deepPurple : Colors.red,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              
              SizedBox(height: 10),
              
              // Mensaje adicional
              if (_isProcessing) 
                Text(
                  'Por favor espera...',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                )
              else
                Text(
                  'Redirigiendo al login...',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
              
              SizedBox(height: 40),
              
              // Botón de acción manual (solo si hay error)
              if (!_isProcessing)
                ElevatedButton(
                  onPressed: () {
                    Navigator.pushReplacementNamed(context, AppRoutes.login);
                  },
                  child: Text('Volver al Login'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.deepPurple,
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}