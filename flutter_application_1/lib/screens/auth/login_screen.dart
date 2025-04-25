// lib/screens/auth/login_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_application_1/config/routes.dart';
import 'package:flutter_application_1/services/auth_service.dart';
import 'package:flutter_application_1/services/socket_service.dart';

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
          // Navegar según el rol del usuario
          if (authService.isAdmin == true) {
            Navigator.pushReplacementNamed(context, AppRoutes.admin);
          } else {
            Navigator.pushReplacementNamed(context, AppRoutes.userHome);
          }
        } else {
          setState(() {
            _errorMessage = authService.error.isNotEmpty 
                ? authService.error 
                : 'Login failed. Please check your credentials.';
          });
        }
      } catch (e) {
        setState(() {
          _errorMessage = 'An error occurred during login';
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
                      const Text(
                        'Iniciar Sesión',
                        style: TextStyle(
                          fontSize: 24.0,
                          fontWeight: FontWeight.bold,
                          color: Colors.deepPurple,
                        ),
                      ),
                      const SizedBox(height: 24.0),
                      TextFormField(
                        controller: _usernameController,
                        decoration: const InputDecoration(
                          labelText: 'Email',
                          prefixIcon: Icon(Icons.email),
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: TextInputType.emailAddress,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Por favor ingresa tu email';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16.0),
                      TextFormField(
                        controller: _passwordController,
                        decoration: const InputDecoration(
                          labelText: 'Contraseña',
                          prefixIcon: Icon(Icons.lock),
                          border: OutlineInputBorder(),
                        ),
                        obscureText: true,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Por favor ingresa tu contraseña';
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
                          onPressed: _isLoading ? null : _login,
                          style: ElevatedButton.styleFrom(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8.0),
                            ),
                          ),
                          child: _isLoading
                              ? const CircularProgressIndicator(
                                  color: Colors.white,
                                )
                              : const Text(
                                  'Iniciar Sesión',
                                  style: TextStyle(fontSize: 16.0),
                                ),
                        ),
                      ),
                      const SizedBox(height: 16.0),
                      TextButton(
                        onPressed: () {
                          Navigator.pushNamed(context, AppRoutes.register);
                        },
                        child: const Text(
                          '¿No tienes una cuenta? Regístrate',
                          style: TextStyle(color: Colors.deepPurple),
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

