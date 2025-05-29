// lib/screens/auth/login_screen.dart - VERSIÓN COMPLETA
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_application_1/config/routes.dart';
import 'package:flutter_application_1/services/auth_service.dart';
import 'package:flutter_application_1/services/socket_service.dart';
import 'package:flutter_application_1/extensions/string_extensions.dart';

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
  bool _isGoogleLoading = false;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    // Verificar si hay autenticación pendiente al cargar
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkPendingGoogleAuth();
    });
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // Verificar autenticación pendiente de Google
  Future<void> _checkPendingGoogleAuth() async {
    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      final pendingAuth = await authService.checkAndHandleGoogleAuth();
      
      if (pendingAuth) {
        print('✅ Autenticación Google detectada, redirigiendo...');
        
        if (mounted) {
          // Mostrar mensaje de éxito
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('¡Bienvenido! Autenticación completada.'),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 2),
            ),
          );
          
          // Redirigir después de un breve delay
          await Future.delayed(const Duration(milliseconds: 500));
          Navigator.pushReplacementNamed(context, AppRoutes.userHome);
        }
      }
    } catch (e) {
      print('Error verificando auth pendiente: $e');
    }
  }

  // Login tradicional con email y contraseña
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

  // Login con Google simplificado
  void _loginWithGoogle() async {
    setState(() {
      _isGoogleLoading = true;
      _errorMessage = '';
    });

    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      final socketService = Provider.of<SocketService>(context, listen: false);
      
      print('🚀 Iniciando login con Google...');
      
      // Primero verificar si ya hay datos pendientes
      final hasPendingAuth = await authService.checkAndHandleGoogleAuth();
      if (hasPendingAuth) {
        print('✅ Login con Google completado');
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('¡Autenticación con Google exitosa!'),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 2),
            ),
          );
          
          Navigator.pushReplacementNamed(context, AppRoutes.userHome);
        }
        return;
      }
      
      // Si no hay datos pendientes, iniciar el flujo (esto hará redirect)
      await authService.loginWithGoogle(socketService);
      
      // Este código no se ejecutará porque hay redirect
      
    } catch (e) {
      setState(() {
        _errorMessage = 'Error en autenticación con Google: $e';
      });
      print('❌ Error en login con Google: $e');
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
              // Si falla la imagen, usar un degradado
              return Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.deepPurple.shade400,
                      Colors.deepPurple.shade100,
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
          backgroundColor: Colors.transparent,
          body: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Card(
                elevation: 4.0,
                color: Colors.white.withOpacity(0.95),
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
                        // Logo o título
                        const Icon(
                          Icons.terrain,
                          size: 64,
                          color: Colors.deepPurple,
                        ),
                        const SizedBox(height: 16.0),
                        Text(
                          'TRAKER',
                          style: TextStyle(
                            fontSize: 28.0,
                            fontWeight: FontWeight.bold,
                            color: Colors.deepPurple.shade700,
                            letterSpacing: 2.0,
                          ),
                        ),
                        const SizedBox(height: 8.0),
                        Text(
                          'login'.tr(context),
                          style: const TextStyle(
                            fontSize: 20.0,
                            fontWeight: FontWeight.w500,
                            color: Colors.grey,
                          ),
                        ),
                        const SizedBox(height: 32.0),
                        
                        // Botón de Google Sign-In
                        SizedBox(
                          width: double.infinity,
                          height: 50.0,
                          child: OutlinedButton.icon(
                            onPressed: (_isGoogleLoading || _isLoading) ? null : _loginWithGoogle,
                            icon: _isGoogleLoading 
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.red,
                                    ),
                                  )
                                : const Icon(
                                    Icons.g_mobiledata,
                                    color: Colors.red,
                                    size: 28,
                                  ),
                            label: Text(
                              _isGoogleLoading 
                                  ? 'Conectando con Google...' 
                                  : 'Continuar con Google',
                              style: const TextStyle(
                                fontSize: 16.0,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.grey.shade700,
                              side: BorderSide(color: Colors.grey.shade300, width: 1.5),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12.0),
                              ),
                              elevation: 2,
                            ),
                          ),
                        ),
                        
                        const SizedBox(height: 24.0),
                        
                        // Divider con "O"
                        Row(
                          children: [
                            Expanded(
                              child: Divider(color: Colors.grey.shade400),
                            ),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 16.0),
                              child: Text(
                                'O',
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16.0,
                                ),
                              ),
                            ),
                            Expanded(
                              child: Divider(color: Colors.grey.shade400),
                            ),
                          ],
                        ),
                        
                        const SizedBox(height: 24.0),
                        
                        // Campo de email
                        TextFormField(
                          controller: _usernameController,
                          enabled: !_isLoading && !_isGoogleLoading,
                          decoration: InputDecoration(
                            labelText: 'email'.tr(context),
                            prefixIcon: const Icon(Icons.email_outlined),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12.0),
                            ),
                            filled: true,
                            fillColor: Colors.grey.shade50,
                          ),
                          keyboardType: TextInputType.emailAddress,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'email_required'.tr(context);
                            }
                            if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
                              return 'valid_email_required'.tr(context);
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16.0),
                        
                        // Campo de contraseña
                        TextFormField(
                          controller: _passwordController,
                          enabled: !_isLoading && !_isGoogleLoading,
                          decoration: InputDecoration(
                            labelText: 'password'.tr(context),
                            prefixIcon: const Icon(Icons.lock_outline),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12.0),
                            ),
                            filled: true,
                            fillColor: Colors.grey.shade50,
                          ),
                          obscureText: true,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'password_required'.tr(context);
                            }
                            return null;
                          },
                        ),
                        
                        // Mostrar errores con mejor estilo
                        if (_errorMessage.isNotEmpty)
                          Container(
                            margin: const EdgeInsets.only(top: 16.0),
                            padding: const EdgeInsets.all(12.0),
                            decoration: BoxDecoration(
                              color: Colors.red.shade50,
                              borderRadius: BorderRadius.circular(8.0),
                              border: Border.all(color: Colors.red.shade200),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.error_outline, 
                                  color: Colors.red.shade700, 
                                  size: 20
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    _errorMessage,
                                    style: TextStyle(
                                      color: Colors.red.shade700,
                                      fontSize: 14.0,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        
                        const SizedBox(height: 24.0),
                        
                        // Botón de login tradicional
                        SizedBox(
                          width: double.infinity,
                          height: 50.0,
                          child: ElevatedButton(
                            onPressed: (_isLoading || _isGoogleLoading) ? null : _login,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.deepPurple,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12.0),
                              ),
                              elevation: 3,
                            ),
                            child: _isLoading
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 2,
                                    ),
                                  )
                                : Text(
                                    'login_button'.tr(context),
                                    style: const TextStyle(
                                      fontSize: 16.0,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                          ),
                        ),
                        
                        const SizedBox(height: 20.0),
                        
                        // Enlace a registro
                        TextButton(
                          onPressed: (_isLoading || _isGoogleLoading) ? null : () {
                            Navigator.pushNamed(context, AppRoutes.register);
                          },
                          child: RichText(
                            text: TextSpan(
                              style: const TextStyle(color: Colors.grey),
                              children: [
                                const TextSpan(text: '¿No tienes cuenta? '),
                                TextSpan(
                                  text: 'Regístrate aquí',
                                  style: TextStyle(
                                    color: Colors.deepPurple.shade600,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        
                        // Indicador de estado de carga
                        if (_isLoading || _isGoogleLoading)
                          Container(
                            margin: const EdgeInsets.only(top: 16.0),
                            padding: const EdgeInsets.all(12.0),
                            decoration: BoxDecoration(
                              color: Colors.blue.shade50,
                              borderRadius: BorderRadius.circular(8.0),
                              border: Border.all(color: Colors.blue.shade200),
                            ),
                            child: Row(
                              children: [
                                const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                ),
                                const SizedBox(width: 12),
                                Text(
                                  _isGoogleLoading 
                                      ? 'Autenticando con Google...' 
                                      : 'Iniciando sesión...',
                                  style: TextStyle(
                                    color: Colors.blue.shade700,
                                    fontSize: 14.0,
                                  ),
                                ),
                              ],
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