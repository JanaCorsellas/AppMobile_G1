// lib/screens/auth/login_screen.dart - Con botón de Google
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
  bool _isGoogleLoading = false; // NUEVO
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

  void _loginWithGoogle() async {
  setState(() {
    _isGoogleLoading = true;
    _errorMessage = '';
  });

  try {
    if (kIsWeb) {
      // Para web: redirigir directamente al backend
      const String googleAuthUrl = 'http://localhost:3000/api/auth/google';
      
      // Guardar estado para saber de dónde venimos
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('auth_source', 'google_login');
      
      print('Redirigiendo a Google Auth: $googleAuthUrl');
      
      // Redirigir directamente
      html.window.location.href = googleAuthUrl;
      
    } else {
      // Para móvil (futuro)
      final authService = Provider.of<AuthService>(context, listen: false);
      final socketService = Provider.of<SocketService>(context, listen: false);
      
      final user = await authService.loginWithGoogle(socketService);
      
      if (user != null) {
        Navigator.pushReplacementNamed(context, AppRoutes.userHome);
      } else {
        setState(() {
          _errorMessage = authService.error.isNotEmpty 
              ? authService.error 
              : 'Error en autenticación con Google';
        });
      }
    }
  } catch (e) {
    setState(() {
      _errorMessage = 'Error en autenticación con Google: $e';
    });
    print('Error: $e');
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
        backgroundColor: Colors.transparent,
        body: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Card(
              elevation: 4.0,
              color: Colors.white.withOpacity(0.85),
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
                      Text(
                        'login'.tr(context),
                        style: const TextStyle(
                          fontSize: 24.0,
                          fontWeight: FontWeight.bold,
                          color: Colors.deepPurple,
                        ),
                      ),
                      const SizedBox(height: 24.0),
                      
                      // NUEVO: Botón de Google Sign-In
                      SizedBox(
                        width: double.infinity,
                        height: 50.0,
                        child: OutlinedButton.icon(
                          onPressed: _isGoogleLoading || _isLoading ? null : _loginWithGoogle,
                          icon: _isGoogleLoading 
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                )
                              : Image.asset(
                                  'assets/images/', 
                                  height: 24,
                                  width: 24,
                                  errorBuilder: (context, error, stackTrace) {
                                    return const Icon(Icons.account_circle, color: Colors.red);
                                  },
                                ),
                          label: Text(
                            _isGoogleLoading 
                                ? 'Conectando con Google...' 
                                : 'Continuar con Google',
                            style: const TextStyle(fontSize: 16.0),
                          ),
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: Colors.grey),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8.0),
                            ),
                          ),
                        ),
                      ),
                      
                      const SizedBox(height: 16.0),
                      
                      // Divider con "O"
                      Row(
                        children: [
                          const Expanded(child: Divider()),
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
                          const Expanded(child: Divider()),
                        ],
                      ),
                      
                      const SizedBox(height: 16.0),
                      
                      // Campos de login tradicional
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
                      if (_errorMessage.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 16.0),
                          child: Text(
                            _errorMessage,
                            style: const TextStyle(
                              color: Colors.red,
                              fontSize: 14.0,
                            ),
                          ),
                        ),
                      const SizedBox(height: 24.0),
                      SizedBox(
                        width: double.infinity,
                        height: 50.0,
                        child: ElevatedButton(
                          onPressed: _isLoading || _isGoogleLoading ? null : _login,
                          style: ElevatedButton.styleFrom(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8.0),
                            ),
                          ),
                          child: _isLoading
                              ? const CircularProgressIndicator(
                                  color: Colors.white,
                                )
                              : Text(
                                  'login_button'.tr(context),
                                  style: const TextStyle(fontSize: 16.0),
                                ),
                        ),
                      ),
                      const SizedBox(height: 16.0),
                      TextButton(
                        onPressed: () {
                          Navigator.pushNamed(context, AppRoutes.register);
                        },
                        child: Text(
                          'no_account'.tr(context),
                          style: const TextStyle(color: Colors.deepPurple),
                        ),
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