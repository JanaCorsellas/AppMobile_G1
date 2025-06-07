// lib/screens/auth/register_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_application_1/config/routes.dart';
import 'package:flutter_application_1/services/auth_service.dart';
import 'package:flutter_application_1/extensions/string_extensions.dart';

enum PasswordStrength { weak, medium, strong }

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({Key? key}) : super(key: key);

  @override
  _RegisterScreenState createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();
  
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  String _errorMessage = '';
  String _successMessage = '';
  
  // Variables para validación de contraseña
  PasswordStrength _passwordStrength = PasswordStrength.weak;
  bool _passwordsMatch = true;

  @override
  void initState() {
    super.initState();
    _passwordController.addListener(_validatePassword);
    _confirmPasswordController.addListener(_validatePasswordMatch);
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _validatePassword() {
    setState(() {
      _passwordStrength = _calculatePasswordStrength(_passwordController.text);
      _validatePasswordMatch();
    });
  }

  void _validatePasswordMatch() {
    setState(() {
      _passwordsMatch = _passwordController.text == _confirmPasswordController.text ||
          _confirmPasswordController.text.isEmpty;
    });
  }

  PasswordStrength _calculatePasswordStrength(String password) {
    if (password.isEmpty) return PasswordStrength.weak;

    int score = 0;
    
    // Longitud mínima
    if (password.length >= 8) score++;
    if (password.length >= 12) score++;
    
    // Contiene números
    if (password.contains(RegExp(r'[0-9]'))) score++;
    
    // Contiene minúsculas
    if (password.contains(RegExp(r'[a-z]'))) score++;
    
    // Contiene mayúsculas
    if (password.contains(RegExp(r'[A-Z]'))) score++;
    
    // Contiene caracteres especiales
    if (password.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'))) score++;
    
    // No contiene patrones comunes
    if (!_hasCommonPatterns(password)) score++;

    if (score <= 2) return PasswordStrength.weak;
    if (score <= 4) return PasswordStrength.medium;
    return PasswordStrength.strong;
  }

  bool _hasCommonPatterns(String password) {
    final commonPatterns = ['123456', 'password', 'qwerty', 'abc123', '111111'];
    return commonPatterns.any((pattern) => 
        password.toLowerCase().contains(pattern.toLowerCase()));
  }

  Color _getStrengthColor() {
    switch (_passwordStrength) {
      case PasswordStrength.weak:
        return Colors.red;
      case PasswordStrength.medium:
        return Colors.orange;
      case PasswordStrength.strong:
        return Colors.green;
    }
  }

  String _getStrengthText() {
    switch (_passwordStrength) {
      case PasswordStrength.weak:
        return 'Poco segura';
      case PasswordStrength.medium:
        return 'Segura';
      case PasswordStrength.strong:
        return 'Muy segura';
    }
  }

  double _getStrengthProgress() {
    switch (_passwordStrength) {
      case PasswordStrength.weak:
        return 0.33;
      case PasswordStrength.medium:
        return 0.66;
      case PasswordStrength.strong:
        return 1.0;
    }
  }

  List<String> _getPasswordRequirements() {
    final requirements = <String>[];
    final password = _passwordController.text;
    
    if (password.length < 8) {
      requirements.add('• Mínimo 8 caracteres');
    }
    if (!password.contains(RegExp(r'[a-z]'))) {
      requirements.add('• Al menos una letra minúscula');
    }
    if (!password.contains(RegExp(r'[A-Z]'))) {
      requirements.add('• Al menos una letra mayúscula');
    }
    if (!password.contains(RegExp(r'[0-9]'))) {
      requirements.add('• Al menos un número');
    }
    if (!password.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'))) {
      requirements.add('• Al menos un carácter especial');
    }
    
    return requirements;
  }

  void _register() async {
    if (_formKey.currentState!.validate()) {
      // Validación adicional para contraseñas
      if (!_passwordsMatch) {
        setState(() {
          _errorMessage = 'Las contraseñas no coinciden';
        });
        return;
      }
      
      if (_passwordStrength == PasswordStrength.weak) {
        setState(() {
          _errorMessage = 'La contraseña es demasiado débil. Por favor, mejórala.';
        });
        return;
      }

      setState(() {
        _isLoading = true;
        _errorMessage = '';
        _successMessage = '';
      });

      try {
        final authService = Provider.of<AuthService>(context, listen: false);
        final success = await authService.register(
          _usernameController.text,
          _emailController.text,
          _passwordController.text,
        );

        if (success) {
          setState(() {
            _successMessage = 'register_success'.tr(context);
          });
          
          // Clear the form
          _usernameController.clear();
          _emailController.clear();
          _passwordController.clear();
          _confirmPasswordController.clear();
          
          // Navigate directly to user home
          Future.delayed(const Duration(seconds: 1), () {
            if (mounted) {
              Navigator.pushReplacementNamed(context, AppRoutes.userHome);
            }
          });
        } else {
          setState(() {
            _errorMessage = authService.error.isNotEmpty 
                ? authService.error 
                : 'register_failed'.tr(context);
          });
        }
      } catch (e) {
        setState(() {
          _errorMessage = 'register_error'.tr(context);
        });
        print('Registration error: $e');
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
    return Scaffold(
      appBar: AppBar(
        title: Text('register'.tr(context)),
        elevation: 0,
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Card(
            elevation: 4.0,
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
                      'create_account'.tr(context),
                      style: const TextStyle(
                        fontSize: 24.0,
                        fontWeight: FontWeight.bold,
                        color: Colors.deepPurple,
                      ),
                    ),
                    const SizedBox(height: 24.0),
                    
                    // Campo Username
                    TextFormField(
                      controller: _usernameController,
                      decoration: InputDecoration(
                        labelText: 'username'.tr(context),
                        prefixIcon: const Icon(Icons.person),
                        border: const OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'username_required'.tr(context);
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16.0),
                    
                    // Campo Email
                    TextFormField(
                      controller: _emailController,
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
                        if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$')
                            .hasMatch(value)) {
                          return 'valid_email_required'.tr(context);
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16.0),
                    
                    // Campo Contraseña con indicador de seguridad
                    TextFormField(
                      controller: _passwordController,
                      decoration: InputDecoration(
                        labelText: 'password'.tr(context),
                        prefixIcon: const Icon(Icons.lock),
                        border: const OutlineInputBorder(),
                        suffixIcon: IconButton(
                          icon: Icon(_obscurePassword ? Icons.visibility : Icons.visibility_off),
                          onPressed: () {
                            setState(() {
                              _obscurePassword = !_obscurePassword;
                            });
                          },
                        ),
                      ),
                      obscureText: _obscurePassword,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'password_required'.tr(context);
                        }
                        if (value.length < 6) {
                          return 'password_length'.tr(context);
                        }
                        return null;
                      },
                    ),
                    
                    // Indicador de seguridad de contraseña
                    if (_passwordController.text.isNotEmpty) ...[
                      const SizedBox(height: 12.0),
                      Row(
                        children: [
                          Expanded(
                            child: LinearProgressIndicator(
                              value: _getStrengthProgress(),
                              backgroundColor: Colors.grey[300],
                              valueColor: AlwaysStoppedAnimation<Color>(_getStrengthColor()),
                              minHeight: 6,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            _getStrengthText(),
                            style: TextStyle(
                              color: _getStrengthColor(),
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                      
                      // Requisitos de contraseña
                      if (_getPasswordRequirements().isNotEmpty) ...[
                        const SizedBox(height: 8.0),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(8.0),
                          decoration: BoxDecoration(
                            color: Colors.grey[100],
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: Colors.grey[300]!),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Requisitos faltantes:',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 11,
                                ),
                              ),
                              const SizedBox(height: 2),
                              ..._getPasswordRequirements().map((req) => Padding(
                                padding: const EdgeInsets.symmetric(vertical: 1),
                                child: Text(
                                  req,
                                  style: const TextStyle(
                                    fontSize: 10,
                                    color: Colors.grey,
                                  ),
                                ),
                              )),
                            ],
                          ),
                        ),
                      ],
                    ],
                    
                    const SizedBox(height: 16.0),
                    
                    // Campo Confirmar Contraseña
                    TextFormField(
                      controller: _confirmPasswordController,
                      decoration: InputDecoration(
                        labelText: 'Confirmar contraseña',
                        prefixIcon: const Icon(Icons.lock_outline),
                        border: const OutlineInputBorder(),
                        errorText: !_passwordsMatch ? 'Las contraseñas no coinciden' : null,
                        suffixIcon: IconButton(
                          icon: Icon(_obscureConfirmPassword ? Icons.visibility : Icons.visibility_off),
                          onPressed: () {
                            setState(() {
                              _obscureConfirmPassword = !_obscureConfirmPassword;
                            });
                          },
                        ),
                      ),
                      obscureText: _obscureConfirmPassword,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Por favor confirma tu contraseña';
                        }
                        if (value != _passwordController.text) {
                          return 'Las contraseñas no coinciden';
                        }
                        return null;
                      },
                    ),
                    
                    // Indicador de coincidencia
                    if (_confirmPasswordController.text.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(
                            _passwordsMatch ? Icons.check_circle : Icons.error,
                            color: _passwordsMatch ? Colors.green : Colors.red,
                            size: 16,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            _passwordsMatch ? 'Las contraseñas coinciden' : 'Las contraseñas no coinciden',
                            style: TextStyle(
                              color: _passwordsMatch ? Colors.green : Colors.red,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ],
                    
                    // Mensajes de error y éxito
                    if (_errorMessage.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 16.0),
                        child: Container(
                          padding: const EdgeInsets.all(8.0),
                          decoration: BoxDecoration(
                            color: Colors.red[50],
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: Colors.red[200]!),
                          ),
                          child: Text(
                            _errorMessage,
                            style: const TextStyle(
                              color: Colors.red,
                              fontSize: 14.0,
                            ),
                          ),
                        ),
                      ),
                    if (_successMessage.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 16.0),
                        child: Container(
                          padding: const EdgeInsets.all(8.0),
                          decoration: BoxDecoration(
                            color: Colors.green[50],
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: Colors.green[200]!),
                          ),
                          child: Text(
                            _successMessage,
                            style: const TextStyle(
                              color: Colors.green,
                              fontSize: 14.0,
                            ),
                          ),
                        ),
                      ),
                    
                    const SizedBox(height: 24.0),
                    
                    // Botón de registro
                    SizedBox(
                      width: double.infinity,
                      height: 50.0,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _register,
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
                                'register_button'.tr(context),
                                style: const TextStyle(fontSize: 16.0),
                              ),
                      ),
                    ),
                    const SizedBox(height: 16.0),
                    
                    // Enlace para ir al login
                    TextButton(
                      onPressed: () {
                        Navigator.pushReplacementNamed(context, AppRoutes.login);
                      },
                      child: Text(
                        'have_account'.tr(context),
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
    );
  }
}