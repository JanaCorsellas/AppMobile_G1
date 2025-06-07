// lib/screens/auth/login_screen.dart - ARCHIVO COMPLETO FLUTTER
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_application_1/config/routes.dart';
import 'package:flutter_application_1/services/auth_service.dart';
import 'package:flutter_application_1/services/socket_service.dart';
import 'package:flutter_application_1/extensions/string_extensions.dart';
import 'dart:html' as html;
import 'package:shared_preferences/shared_preferences.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  
  bool _isLoading = false;
  bool _isGoogleLoading = false; // AÑADIDO PARA GOOGLE OAUTH
  String _errorMessage = '';

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _login() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
        _errorMessage = '';
      });

      try {
        final authService = Provider.of<AuthService>(context, listen: false);
        final socketService = Provider.of<SocketService>(context, listen: false);
        
        final user = await authService.login(
          _usernameController.text,
          _passwordController.text,
          socketService
        );

        if (user != null) {
          if (authService.isAdmin == true) {
            Navigator.pushReplacementNamed(context, AppRoutes.admin);
          } else {
            Navigator.pushReplacementNamed(context, AppRoutes.userHome);
          }
        } else {
          setState(() {
            _errorMessage = authService.error.isNotEmpty 
                ? authService.error 
                : 'login_failed'.tr(context);
          });
        }
      } catch (e) {
        setState(() {
          _errorMessage = 'login_error'.tr(context);
        });
        print('Login error: $e');
      } finally {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    }
  }

  // MÉTODO AÑADIDO PARA GOOGLE OAUTH
  void _loginWithGoogle() async {
    print('🚀 Iniciando Google OAuth desde UI...');
    setState(() {
      _isGoogleLoading = true;
      _errorMessage = '';
    });

    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      
      print('📞 Llamando a authService.loginWithGoogle()...');
      final success = await authService.loginWithGoogle();
      
      if (!success) {
        setState(() {
          _errorMessage = 'Error al conectar con Google';
        });
        print('❌ loginWithGoogle devolvió false');
      } else {
        print('✅ loginWithGoogle exitoso, redirigiendo...');
      }
      // Si success es true, la redirección ya ocurrió
      
    } catch (e) {
      setState(() {
        _errorMessage = 'Error de conexión con Google';
      });
      print('❌ Error Google login: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isGoogleLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Capa 1: Imagen de fondo
        Positioned.fill(
          child: Image.asset(
            'assets/images/background2.png',
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) {
              // Si no encuentra la imagen, mostrar color de fondo
              return Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.deepPurple.withOpacity(0.8),
                      Colors.white.withOpacity(0.9),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        // Capa 2: Capa de opacidad con degradado
        Positioned.fill(
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.deepPurple.withOpacity(0.6),
                  Colors.white.withOpacity(0.85),
                ],
              ),
            ),
          ),
        ),
        // Capa 3: Contenido de la pantalla
        Scaffold(
          backgroundColor: Colors.transparent, // Importante para ver la imagen de fondo
          body: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Card(
                elevation: 4.0,
                color: Colors.white.withOpacity(0.85), // Tarjeta semitransparente
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16.0),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // TÍTULO
                        Text(
                          'login'.tr(context),
                          style: const TextStyle(
                            fontSize: 24.0,
                            fontWeight: FontWeight.bold,
                            color: Colors.deepPurple,
                          ),
                        ),
                        const SizedBox(height: 24.0),
                        
                        // CAMPO EMAIL
                        TextFormField(
                          controller: _usernameController,
                          decoration: InputDecoration(
                            labelText: 'email'.tr(context),
                            prefixIcon: const Icon(Icons.email),
                            border: const OutlineInputBorder(),
                          ),
                          keyboardType: TextInputType.emailAddress,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'email_required'.tr(context);
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16.0),
                        
                        // CAMPO CONTRASEÑA
                        TextFormField(
                          controller: _passwordController,
                          decoration: InputDecoration(
                            labelText: 'password'.tr(context),
                            prefixIcon: const Icon(Icons.lock),
                            border: const OutlineInputBorder(),
                          ),
                          obscureText: true,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'password_required'.tr(context);
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 24.0),
                        
                        // MENSAJE DE ERROR
                        if (_errorMessage.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 16.0),
                            child: Container(
                              padding: const EdgeInsets.all(12.0),
                              decoration: BoxDecoration(
                                color: Colors.red[50],
                                border: Border.all(color: Colors.red[300]!),
                                borderRadius: BorderRadius.circular(8.0),
                              ),
                              child: Row(
                                children: [
                                  Icon(Icons.error_outline, color: Colors.red[700], size: 20),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      _errorMessage,
                                      style: TextStyle(
                                        color: Colors.red[700],
                                        fontSize: 14.0,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        
                        // BOTÓN LOGIN NORMAL
                        SizedBox(
                          width: double.infinity,
                          height: 50.0,
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : _login,
                            child: _isLoading
                                ? const CircularProgressIndicator(
                                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                  )
                                : Text('login'.tr(context)),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.deepPurple,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8.0),
                              ),
                            ),
                          ),
                        ),
                        
                        const SizedBox(height: 16.0),
                        
                        // DIVISOR "O"
                        Row(
                          children: [
                            Expanded(child: Divider(color: Colors.grey[400])),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 16.0),
                              child: Text(
                                'O',
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            Expanded(child: Divider(color: Colors.grey[400])),
                          ],
                        ),
                        
                        const SizedBox(height: 16.0),
                        
                        // BOTÓN DE GOOGLE OAUTH AÑADIDO
                        SizedBox(
                          width: double.infinity,
                          height: 50.0,
                          child: ElevatedButton.icon(
                            onPressed: _isGoogleLoading ? null : _loginWithGoogle,
                            icon: _isGoogleLoading
                                ? SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                    ),
                                  )
                                : Icon(Icons.login, color: Colors.white),
                            label: Text(
                              _isGoogleLoading 
                                  ? 'Conectando con Google...' 
                                  : 'Continuar con Google',
                              style: TextStyle(fontSize: 16.0, color: Colors.white),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red[600],
                              elevation: 2,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8.0),
                              ),
                            ),
                          ),
                        ),
                        // FIN BOTÓN GOOGLE OAUTH
                        
                        const SizedBox(height: 24.0),
                        
                        // LINK A REGISTRO
                        TextButton(
                          onPressed: () {
                            Navigator.pushNamed(context, AppRoutes.register);
                          },
                          child: Text('no_account'.tr(context)),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}