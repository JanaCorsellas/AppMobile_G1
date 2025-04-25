import 'package:flutter/material.dart';
import 'package:flutter_application_1/services/http_service.dart';
import 'package:provider/provider.dart';
import 'package:flutter_application_1/config/routes.dart';
import 'package:flutter_application_1/models/user.dart';
import 'package:flutter_application_1/services/auth_service.dart';
import 'package:flutter_application_1/services/user_service.dart';

import '../../services/socket_service.dart';

class UserProfileScreen extends StatefulWidget {
  const UserProfileScreen({Key? key}) : super(key: key);

  @override
  _UserProfileScreenState createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends State<UserProfileScreen> {
  late final UserService _userService;
  final _formKey = GlobalKey<FormState>();
  
  late TextEditingController _usernameController;
  late TextEditingController _emailController;
  late TextEditingController _bioController;
  late TextEditingController _profilePictureController;
  
  bool _isLoading = false;
  bool _isEditing = false;
  String _errorMessage = '';
  String _successMessage = '';
  User? _user;

  @override
  void initState() {
    super.initState();
    _usernameController = TextEditingController();
    _emailController = TextEditingController();
    _bioController = TextEditingController();
    _profilePictureController = TextEditingController();

    // Create a new HttpService with the AuthService
    final authService = Provider.of<AuthService>(context, listen: false);
    final httpService = HttpService(authService);
    
    // Initialize UserService with the proper HttpService
    _userService = UserService(httpService);
    
    // Load user data
    _loadUserData();
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _emailController.dispose();
    _bioController.dispose();
    _profilePictureController.dispose();
    super.dispose();
  }

  Future<void> _loadUserData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      // First try to get the user from the auth service
      final authService = Provider.of<AuthService>(context, listen: false);
      
      // Agregado: Log para depuración
      print("Cargando datos de usuario...");
      
      User? user;
      
      // If we have a current user, use that directly
      if (authService.currentUser != null) {
        user = authService.currentUser;
        // Agregado: Log para depuración
        print("Usando usuario del auth service con ID: ${user?.id}");
        print("Bio: ${user?.bio}, ProfilePicture: ${user?.profilePicture != null}");
      } else {
        // Fallback to fetch from API if needed
        print("No se encontró usuario en auth service, intentando con API...");
        user = await _userService.getUserById(authService.currentUser?.id ?? '');
        // Agregado: Log para depuración
        print("Usuario obtenido de API con ID: ${user?.id}");
      }
      
      if (user != null) {
        setState(() {
          _user = user;
          _usernameController.text = user!.username;
          _emailController.text = user.email;
          _bioController.text = user.bio ?? '';
          _profilePictureController.text = user.profilePicture ?? '';
          
          // Agregado: Log para depuración
          print("Datos cargados en controladores:");
          print("Username: ${_usernameController.text}");
          print("Email: ${_emailController.text}");
          print("Bio: ${_bioController.text}");
          print("ProfilePicture: ${_profilePictureController.text}");
        });
      } else {
        setState(() {
          _errorMessage = 'No se pudieron cargar los datos del usuario';
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error al cargar datos del usuario: $e';
      });
      print('Error al cargar datos del usuario: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _saveProfile() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
        _errorMessage = '';
        _successMessage = '';
      });

      try {
        final userData = {
          'username': _usernameController.text,
          'email': _emailController.text,
          'bio': _bioController.text,
          'profilePicture': _profilePictureController.text,
        };

        final updatedUser = await _userService.updateUser(_user!.id, userData);
        
        // Update local user data
        setState(() {
          _user = updatedUser;
          _successMessage = 'Perfil actualizado con éxito';
          _isEditing = false;
        });
        
        // Update auth service with new user data - THIS IS THE KEY FIX
        final authService = Provider.of<AuthService>(context, listen: false);
        authService.updateCurrentUser(updatedUser);
        
        // Save updated user data to persistent storage
        await _userService.saveUserToCache(updatedUser);
        
      } catch (e) {
        setState(() {
          _errorMessage = 'Error al actualizar perfil: $e';
        });
        print('Error al actualizar perfil: $e');
      } finally {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mi Perfil'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pushReplacementNamed(context, AppRoutes.userHome);
          },
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              final authService = Provider.of<AuthService>(context, listen: false);
              final socketService = Provider.of<SocketService>(context, listen: false);
              await authService.logout(socketService);
              Navigator.pushReplacementNamed(context, AppRoutes.login);
            },
            tooltip: 'Cerrar sesión',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _user == null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text('No se encontraron datos de usuario'),
                      if (_errorMessage.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Text(
                            _errorMessage,
                            style: const TextStyle(color: Colors.red),
                          ),
                        ),
                      ElevatedButton(
                        onPressed: _loadUserData,
                        child: const Text('Reintentar'),
                      ),
                    ],
                  ),
                )
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (_errorMessage.isNotEmpty)
                        Container(
                          padding: const EdgeInsets.all(12.0),
                          margin: const EdgeInsets.only(bottom: 16.0),
                          decoration: BoxDecoration(
                            color: Colors.red.shade100,
                            borderRadius: BorderRadius.circular(8.0),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.error, color: Colors.red.shade800),
                              const SizedBox(width: 8.0),
                              Expanded(
                                child: Text(
                                  _errorMessage,
                                  style: TextStyle(color: Colors.red.shade800),
                                ),
                              ),
                            ],
                          ),
                        ),
                      if (_successMessage.isNotEmpty)
                        Container(
                          padding: const EdgeInsets.all(12.0),
                          margin: const EdgeInsets.only(bottom: 16.0),
                          decoration: BoxDecoration(
                            color: Colors.green.shade100,
                            borderRadius: BorderRadius.circular(8.0),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.check_circle, color: Colors.green.shade800),
                              const SizedBox(width: 8.0),
                              Expanded(
                                child: Text(
                                  _successMessage,
                                  style: TextStyle(color: Colors.green.shade800),
                                ),
                              ),
                            ],
                          ),
                        ),
                      Card(
                        elevation: 4.0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16.0),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            children: [
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  CircleAvatar(
                                    radius: 40.0,
                                    backgroundColor: Colors.grey.shade200,
                                    backgroundImage: _user!.profilePicture != null && _user!.profilePicture!.isNotEmpty
                                        ? NetworkImage(_user!.profilePicture!)
                                        : null,
                                    child: _user!.profilePicture == null || _user!.profilePicture!.isEmpty
                                        ? const Icon(
                                            Icons.person,
                                            size: 40.0,
                                            color: Colors.grey,
                                          )
                                        : null,
                                  ),
                                  const SizedBox(width: 16.0),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          _user!.username,
                                          style: const TextStyle(
                                            fontSize: 24.0,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        Text(
                                          _user!.email,
                                          style: const TextStyle(
                                            fontSize: 16.0,
                                            color: Colors.black54,
                                          ),
                                        ),
                                        const SizedBox(height: 8.0),
                                        Text(
                                          'Nivel: ${_user!.level}',
                                          style: const TextStyle(
                                            fontSize: 16.0,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.deepPurple,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  if (!_isEditing)
                                    IconButton(
                                      icon: const Icon(Icons.edit),
                                      onPressed: () {
                                        setState(() {
                                          _isEditing = true;
                                        });
                                      },
                                    ),
                                ],
                              ),
                              const SizedBox(height: 16.0),
                              if (!_isEditing) ...[
                                const Divider(),
                                ListTile(
                                  leading: const Icon(Icons.info_outline),
                                  title: const Text('Biografía'),
                                  subtitle: Text(
                                    _user!.bio ?? 'No hay biografía disponible',
                                    style: const TextStyle(fontSize: 14.0),
                                  ),
                                ),
                                ListTile(
                                  leading: const Icon(Icons.directions_run),
                                  title: const Text('Distancia Total'),
                                  subtitle: Text(
                                    '${(_user!.totalDistance / 1000).toStringAsFixed(2)} km',
                                    style: const TextStyle(fontSize: 14.0),
                                  ),
                                ),
                                ListTile(
                                  leading: const Icon(Icons.timer),
                                  title: const Text('Tiempo Total'),
                                  subtitle: Text(
                                    '${_user!.totalTime} minutos',
                                    style: const TextStyle(fontSize: 14.0),
                                  ),
                                ),
                                ListTile(
                                  leading: const Icon(Icons.event_note),
                                  title: const Text('Actividades'),
                                  subtitle: Text(
                                    '${_user!.activities?.length ?? 0} actividades',
                                    style: const TextStyle(fontSize: 14.0),
                                  ),
                                ),
                                ListTile(
                                  leading: const Icon(Icons.emoji_events),
                                  title: const Text('Logros'),
                                  subtitle: Text(
                                    '${_user!.achievements?.length ?? 0} logros',
                                    style: const TextStyle(fontSize: 14.0),
                                  ),
                                ),
                                ListTile(
                                  leading: const Icon(Icons.flag),
                                  title: const Text('Retos Completados'),
                                  subtitle: Text(
                                    '${_user!.challengesCompleted?.length ?? 0} retos',
                                    style: const TextStyle(fontSize: 14.0),
                                  ),
                                ),
                              ] else ...[
                                const SizedBox(height: 16.0),
                                Form(
                                  key: _formKey,
                                  child: Column(
                                    children: [
                                      TextFormField(
                                        controller: _usernameController,
                                        decoration: const InputDecoration(
                                          labelText: 'Nombre de usuario',
                                          border: OutlineInputBorder(),
                                        ),
                                        validator: (value) {
                                          if (value == null || value.isEmpty) {
                                            return 'El nombre de usuario es obligatorio';
                                          }
                                          if (value.length < 4) {
                                            return 'El nombre debe tener al menos 4 caracteres';
                                          }
                                          return null;
                                        },
                                      ),
                                      const SizedBox(height: 16.0),
                                      TextFormField(
                                        controller: _emailController,
                                        decoration: const InputDecoration(
                                          labelText: 'Email',
                                          border: OutlineInputBorder(),
                                        ),
                                        validator: (value) {
                                          if (value == null || value.isEmpty) {
                                            return 'El email es obligatorio';
                                          }
                                          if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$')
                                              .hasMatch(value)) {
                                            return 'Por favor, introduce un email válido';
                                          }
                                          return null;
                                        },
                                      ),
                                      const SizedBox(height: 16.0),
                                      TextFormField(
                                        controller: _profilePictureController,
                                        decoration: const InputDecoration(
                                          labelText: 'URL de imagen de perfil',
                                          border: OutlineInputBorder(),
                                        ),
                                      ),
                                      const SizedBox(height: 16.0),
                                      TextFormField(
                                        controller: _bioController,
                                        decoration: const InputDecoration(
                                          labelText: 'Biografía',
                                          border: OutlineInputBorder(),
                                        ),
                                        maxLines: 3,
                                      ),
                                      const SizedBox(height: 24.0),
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.end,
                                        children: [
                                          TextButton(
                                            onPressed: () {
                                              setState(() {
                                                _isEditing = false;
                                                
                                                // Reset form data
                                                _usernameController.text = _user!.username;
                                                _emailController.text = _user!.email;
                                                _bioController.text = _user!.bio ?? '';
                                                _profilePictureController.text = _user!.profilePicture ?? '';
                                              });
                                            },
                                            child: const Text('Cancelar'),
                                          ),
                                          const SizedBox(width: 16.0),
                                          ElevatedButton(
                                            onPressed: _isLoading ? null : _saveProfile,
                                            child: _isLoading
                                                ? const SizedBox(
                                                    width: 20,
                                                    height: 20,
                                                    child: CircularProgressIndicator(
                                                      strokeWidth: 2.0,
                                                      color: Colors.white,
                                                    ),
                                                  )
                                                : const Text('Guardar Cambios'),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
    );
  }
}