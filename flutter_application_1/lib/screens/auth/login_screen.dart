// lib/screens/auth/login_screen.dart - ARCHIVO COMPLETO FLUTTER CON BRANDING TRAZER
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_application_1/config/routes.dart';
import 'package:flutter_application_1/services/auth_service.dart';
import 'package:flutter_application_1/services/socket_service.dart';
import 'package:flutter_application_1/extensions/string_extensions.dart';
import 'dart:html' as html;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:math' as math;

class LoginScreen extends StatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);

  Widget _buildGoogleIcon() {
    // Primero intentar cargar la imagen local
    return Image.asset(
      'assets/images/google_logo.png',
      width: 24,
      height: 24,
      errorBuilder: (context, error, stackTrace) {
        // Si no puede cargar la imagen, crear el logo de Google con widgets
        return Container(
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
          ),
          child: CustomPaint(
            painter: GoogleLogoPainter(),
            size: const Size(24, 24),
          ),
        );
      },
    );
  }

  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  
  bool _isLoading = false;
  bool _isGoogleLoading = false;
  String _errorMessage = '';
  
  // Controladores de animación
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _scaleAnimation;
  
  @override
  void initState() {
    super.initState();
    
    // Inicializar animaciones
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeInOut,
    ));
    
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOutBack,
    ));
    
    _scaleAnimation = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fadeController,
      curve: Curves.elasticOut,
    ));
    
    // Iniciar animaciones
    _startAnimations();
  }
  
  void _startAnimations() {
    _fadeController.forward();
    Future.delayed(const Duration(milliseconds: 300), () {
      _slideController.forward();
    });
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    _fadeController.dispose();
    _slideController.dispose();
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
        // Capa 1: Fondo con gradiente mejorado
        Positioned.fill(
          child: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFF667eea),
                  Color(0xFF764ba2),
                  Color(0xFF8b5cf6),
                ],
                stops: [0.0, 0.5, 1.0],
              ),
            ),
          ),
        ),
        
        // Capa 2: Patrón de fondo sutil
        Positioned.fill(
          child: Container(
            decoration: BoxDecoration(
              image: DecorationImage(
                image: AssetImage('assets/images/background2.png'),
                fit: BoxFit.cover,
                opacity: 0.1,
              ),
            ),
          ),
        ),
        
        // Capa 3: Contenido principal
        Scaffold(
          backgroundColor: Colors.transparent,
          body: SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: FadeTransition(
                  opacity: _fadeAnimation,
                  child: SlideTransition(
                    position: _slideAnimation,
                    child: ScaleTransition(
                      scale: _scaleAnimation,
                      child: Container(
                        constraints: const BoxConstraints(maxWidth: 400),
                        child: Card(
                          elevation: 20.0,
                          color: Colors.white.withOpacity(0.95),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(24.0),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(32.0),
                            child: Form(
                              key: _formKey,
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  // LOGO Y BRANDING TRAZER
                                  Column(
                                    children: [
                                      // Logo/Icono de la app con animación
                                      Hero(
                                        tag: 'app_logo',
                                        child: Container(
                                          padding: const EdgeInsets.all(20.0),
                                          decoration: BoxDecoration(
                                            gradient: const LinearGradient(
                                              begin: Alignment.topLeft,
                                              end: Alignment.bottomRight,
                                              colors: [
                                                Color(0xFF667eea),
                                                Color(0xFF764ba2),
                                              ],
                                            ),
                                            shape: BoxShape.circle,
                                            boxShadow: [
                                              BoxShadow(
                                                color: const Color(0xFF667eea).withOpacity(0.3),
                                                spreadRadius: 2,
                                                blurRadius: 15,
                                                offset: const Offset(0, 5),
                                              ),
                                            ],
                                          ),
                                          child: const Icon(
                                            Icons.terrain,
                                            size: 60.0,
                                            color: Colors.white,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(height: 24.0),
                                      
                                      // Nombre de la app TRAZER
                                      ShaderMask(
                                        shaderCallback: (bounds) => const LinearGradient(
                                          colors: [
                                            Color(0xFF667eea),
                                            Color(0xFF764ba2),
                                          ],
                                        ).createShader(bounds),
                                        child: const Text(
                                          'TRAZER',
                                          style: TextStyle(
                                            fontSize: 42.0,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.white,
                                            letterSpacing: 3.0,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(height: 8.0),
                                      
                                      // Subtítulo elegante
                                      Text(
                                        'login'.tr(context),
                                        style: TextStyle(
                                          fontSize: 20.0,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.grey[700],
                                        ),
                                      ),
                                      const SizedBox(height: 6.0),
                                    ],
                                  ),
                                  const SizedBox(height: 40.0),
                                  
                                  // CAMPOS DE FORMULARIO MEJORADOS
                                  
                                  // Campo Email con diseño moderno
                                  Container(
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(12.0),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.grey.withOpacity(0.1),
                                          spreadRadius: 1,
                                          blurRadius: 5,
                                          offset: const Offset(0, 2),
                                        ),
                                      ],
                                    ),
                                    child: TextFormField(
                                      controller: _usernameController,
                                      decoration: InputDecoration(
                                        labelText: 'email'.tr(context),
                                        prefixIcon: Container(
                                          margin: const EdgeInsets.all(8.0),
                                          decoration: BoxDecoration(
                                            color: const Color(0xFF667eea).withOpacity(0.1),
                                            borderRadius: BorderRadius.circular(8.0),
                                          ),
                                          child: const Icon(
                                            Icons.email_outlined,
                                            color: Color(0xFF667eea),
                                          ),
                                        ),
                                        border: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(12.0),
                                          borderSide: BorderSide.none,
                                        ),
                                        filled: true,
                                        fillColor: Colors.grey[50],
                                        focusedBorder: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(12.0),
                                          borderSide: const BorderSide(
                                            color: Color(0xFF667eea),
                                            width: 2.0,
                                          ),
                                        ),
                                      ),
                                      keyboardType: TextInputType.emailAddress,
                                      validator: (value) {
                                        if (value == null || value.isEmpty) {
                                          return 'email_required'.tr(context);
                                        }
                                        return null;
                                      },
                                    ),
                                  ),
                                  const SizedBox(height: 20.0),
                                  
                                  // Campo Contraseña con diseño moderno
                                  Container(
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(12.0),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.grey.withOpacity(0.1),
                                          spreadRadius: 1,
                                          blurRadius: 5,
                                          offset: const Offset(0, 2),
                                        ),
                                      ],
                                    ),
                                    child: TextFormField(
                                      controller: _passwordController,
                                      decoration: InputDecoration(
                                        labelText: 'password'.tr(context),
                                        prefixIcon: Container(
                                          margin: const EdgeInsets.all(8.0),
                                          decoration: BoxDecoration(
                                            color: const Color(0xFF667eea).withOpacity(0.1),
                                            borderRadius: BorderRadius.circular(8.0),
                                          ),
                                          child: const Icon(
                                            Icons.lock_outline,
                                            color: Color(0xFF667eea),
                                          ),
                                        ),
                                        border: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(12.0),
                                          borderSide: BorderSide.none,
                                        ),
                                        filled: true,
                                        fillColor: Colors.grey[50],
                                        focusedBorder: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(12.0),
                                          borderSide: const BorderSide(
                                            color: Color(0xFF667eea),
                                            width: 2.0,
                                          ),
                                        ),
                                      ),
                                      obscureText: true,
                                      validator: (value) {
                                        if (value == null || value.isEmpty) {
                                          return 'password_required'.tr(context);
                                        }
                                        return null;
                                      },
                                    ),
                                  ),
                                  const SizedBox(height: 24.0),
                                  
                                  // MENSAJE DE ERROR MEJORADO
                                  if (_errorMessage.isNotEmpty)
                                    Container(
                                      margin: const EdgeInsets.only(bottom: 20.0),
                                      padding: const EdgeInsets.all(16.0),
                                      decoration: BoxDecoration(
                                        color: Colors.red[50],
                                        border: Border.all(color: Colors.red[200]!),
                                        borderRadius: BorderRadius.circular(12.0),
                                      ),
                                      child: Row(
                                        children: [
                                          Icon(
                                            Icons.error_outline,
                                            color: Colors.red[700],
                                            size: 24,
                                          ),
                                          const SizedBox(width: 12),
                                          Expanded(
                                            child: Text(
                                              _errorMessage,
                                              style: TextStyle(
                                                color: Colors.red[700],
                                                fontSize: 14.0,
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  
                                  // BOTÓN LOGIN PRINCIPAL MEJORADO
                                  Container(
                                    width: double.infinity,
                                    height: 56.0,
                                    decoration: BoxDecoration(
                                      gradient: const LinearGradient(
                                        begin: Alignment.centerLeft,
                                        end: Alignment.centerRight,
                                        colors: [
                                          Color(0xFF667eea),
                                          Color(0xFF764ba2),
                                        ],
                                      ),
                                      borderRadius: BorderRadius.circular(12.0),
                                      boxShadow: [
                                        BoxShadow(
                                          color: const Color(0xFF667eea).withOpacity(0.3),
                                          spreadRadius: 1,
                                          blurRadius: 8,
                                          offset: const Offset(0, 4),
                                        ),
                                      ],
                                    ),
                                    child: ElevatedButton(
                                      onPressed: _isLoading ? null : _login,
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.transparent,
                                        shadowColor: Colors.transparent,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(12.0),
                                        ),
                                      ),
                                      child: _isLoading
                                          ? const SizedBox(
                                              width: 24,
                                              height: 24,
                                              child: CircularProgressIndicator(
                                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                                strokeWidth: 2.5,
                                              ),
                                            )
                                          : Text(
                                              'login'.tr(context),
                                              style: const TextStyle(
                                                fontSize: 18.0,
                                                fontWeight: FontWeight.bold,
                                                color: Colors.white,
                                              ),
                                            ),
                                    ),
                                  ),
                                  
                                  const SizedBox(height: 24.0),
                                  
                                  // DIVISOR MODERNO
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Container(
                                          height: 1,
                                          decoration: BoxDecoration(
                                            gradient: LinearGradient(
                                              colors: [
                                                Colors.transparent,
                                                Colors.grey[400]!,
                                              ],
                                            ),
                                          ),
                                        ),
                                      ),
                                      Padding(
                                        padding: const EdgeInsets.symmetric(horizontal: 16.0),
                                        child: Text(
                                          'O',
                                          style: TextStyle(
                                            color: Colors.grey[600],
                                            fontWeight: FontWeight.bold,
                                            fontSize: 16,
                                          ),
                                        ),
                                      ),
                                      Expanded(
                                        child: Container(
                                          height: 1,
                                          decoration: BoxDecoration(
                                            gradient: LinearGradient(
                                              colors: [
                                                Colors.grey[400]!,
                                                Colors.transparent,
                                              ],
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  
                                  const SizedBox(height: 24.0),
                                  
                                  // BOTÓN GOOGLE OAUTH MEJORADO
                                  Container(
                                    width: double.infinity,
                                    height: 56.0,
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(12.0),
                                      border: Border.all(color: Colors.grey[300]!),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.grey.withOpacity(0.1),
                                          spreadRadius: 1,
                                          blurRadius: 5,
                                          offset: const Offset(0, 2),
                                        ),
                                      ],
                                    ),
                                    child: ElevatedButton.icon(
                                      onPressed: _isGoogleLoading ? null : _loginWithGoogle,
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.white,
                                        foregroundColor: Colors.grey[700],
                                        shadowColor: Colors.transparent,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(12.0),
                                        ),
                                      ),
                                      
                                      label: Text(
                                        _isGoogleLoading 
                                            ? 'Conectando con Google...' 
                                            : 'Continuar con Google',
                                        style: const TextStyle(
                                          fontSize: 16.0,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                  ),
                                  
                                  const SizedBox(height: 32.0),
                                  
                                  // LINK A REGISTRO MEJORADO
                                  Container(
                                    padding: const EdgeInsets.symmetric(vertical: 8.0),
                                    child: TextButton(
                                      onPressed: () {
                                        Navigator.pushNamed(context, AppRoutes.register);
                                      },
                                      style: TextButton.styleFrom(
                                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                                      ),
                                      child: RichText(
                                        text: TextSpan(
                                          style: TextStyle(
                                            fontSize: 14.0,
                                            color: Colors.grey[600],
                                          ),
                                          children: [
                                            const TextSpan(text: '¿No tienes cuenta? '),
                                            TextSpan(
                                              text: 'Regístrate',
                                              style: TextStyle(
                                                color: const Color(0xFF667eea),
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
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
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// Custom Painter para dibujar el logo de Google
class GoogleLogoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;
    
    // Fondo blanco
    paint.color = Colors.white;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(0, 0, size.width, size.height),
        const Radius.circular(4),
      ),
      paint,
    );
    
    // Letra "G" de Google simplificada
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width * 0.35;
    
    // Círculo azul (parte de la G)
    paint.color = const Color(0xFF4285F4);
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2, // Comenzar desde arriba
      math.pi, // Medio círculo
      false,
      paint..strokeWidth = size.width * 0.15..style = PaintingStyle.stroke,
    );
    
    // Línea horizontal roja
    paint.color = const Color(0xFFEA4335);
    paint.style = PaintingStyle.fill;
    canvas.drawRect(
      Rect.fromLTWH(
        center.dx - radius * 0.3,
        center.dy - size.height * 0.08,
        radius * 0.8,
        size.height * 0.16,
      ),
      paint,
    );
    
    // Punto verde
    paint.color = const Color(0xFF34A853);
    canvas.drawCircle(
      Offset(center.dx + radius * 0.5, center.dy),
      size.width * 0.08,
      paint,
    );
  }
  
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}