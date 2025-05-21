// lib/screens/user/user_profile.dart
import 'package:flutter/material.dart';
import 'package:flutter_application_1/services/http_service.dart';
import 'package:flutter_application_1/widgets/custom_drawer.dart';
import 'package:provider/provider.dart';
import 'package:flutter_application_1/config/routes.dart';
import 'package:flutter_application_1/models/user.dart';
import 'package:flutter_application_1/services/auth_service.dart';
import 'package:flutter_application_1/services/user_service.dart';
import 'package:flutter_application_1/extensions/string_extensions.dart';

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
          _errorMessage = 'user_data_not_found'.tr(context);
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'user_data_load_error'.tr(context) + ': $e';
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
          _successMessage = 'profile_updated'.tr(context);
          _isEditing = false;
        });
        
        // Update auth service with new user data - THIS IS THE KEY FIX
        final authService = Provider.of<AuthService>(context, listen: false);
        authService.updateCurrentUser(updatedUser);
        
        // Save updated user data to persistent storage
        await _userService.saveUserToCache(updatedUser);
        
      } catch (e) {
        setState(() {
          _errorMessage = 'profile_update_error'.tr(context) + ': $e';
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
      drawer: const CustomDrawer(currentRoute: AppRoutes.userProfile),
      appBar: AppBar(
        title: Text('my_profile'.tr(context)),
        leading: null,
        automaticallyImplyLeading: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              final authService = Provider.of<AuthService>(context, listen: false);
              final socketService = Provider.of<SocketService>(context, listen: false);
              await authService.logout(socketService);
              Navigator.pushReplacementNamed(context, AppRoutes.login);
            },
            tooltip: 'logout'.tr(context),
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
                      Text('no_user_data'.tr(context)),
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
                        child: Text('retry'.tr(context)),
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
                                          'user_level'.tr(context).replaceFirst('{level}', _user!.level.toString()),
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
                                  title: Text('biography'.tr(context)),
                                  subtitle: Text(
                                    _user!.bio ?? 'no_biography'.tr(context),
                                    style: const TextStyle(fontSize: 14.0),
                                  ),
                                ),
                                ListTile(
                                  leading: const Icon(Icons.directions_run),
                                  title: Text('total_distance'.tr(context)),
                                  subtitle: Text(
                                    '${(_user!.totalDistance / 1000).toStringAsFixed(2)} km',
                                    style: const TextStyle(fontSize: 14.0),
                                  ),
                                ),
                                ListTile(
                                  leading: const Icon(Icons.timer),
                                  title: Text('total_time'.tr(context)),
                                  subtitle: Text(
                                    '${_user!.totalTime} ' + 'minutes'.tr(context),
                                    style: const TextStyle(fontSize: 14.0),
                                  ),
                                ),
                                ListTile(
                                  leading: const Icon(Icons.event_note),
                                  title: Text('activities'.tr(context)),
                                  subtitle: Text(
                                    '${_user!.activities?.length ?? 0} ' + 'activities'.tr(context),
                                    style: const TextStyle(fontSize: 14.0),
                                  ),
                                ),
                                ListTile(
                                  leading: const Icon(Icons.emoji_events),
                                  title: Text('achievements'.tr(context)),
                                  subtitle: Text(
                                    '${_user!.achievements?.length ?? 0} ' + 'achievements'.tr(context),
                                    style: const TextStyle(fontSize: 14.0),
                                  ),
                                ),
                                ListTile(
                                  leading: const Icon(Icons.flag),
                                  title: Text('completed_challenges'.tr(context)),
                                  subtitle: Text(
                                    '${_user!.challengesCompleted?.length ?? 0} ' + 'challenges'.tr(context),
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
                                        decoration: InputDecoration(
                                          labelText: 'username'.tr(context),
                                          border: const OutlineInputBorder(),
                                        ),
                                        validator: (value) {
                                          if (value == null || value.isEmpty) {
                                            return 'username_required'.tr(context);
                                          }
                                          if (value.length < 4) {
                                            return 'username_too_short'.tr(context);
                                          }
                                          return null;
                                        },
                                      ),
                                      const SizedBox(height: 16.0),
                                      TextFormField(
                                        controller: _emailController,
                                        decoration: InputDecoration(
                                          labelText: 'email'.tr(context),
                                          border: const OutlineInputBorder(),
                                        ),
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
                                      TextFormField(
                                        controller: _profilePictureController,
                                        decoration: InputDecoration(
                                          labelText: 'profile_picture_url'.tr(context),
                                          border: const OutlineInputBorder(),
                                        ),
                                      ),
                                      const SizedBox(height: 16.0),
                                      TextFormField(
                                        controller: _bioController,
                                        decoration: InputDecoration(
                                          labelText: 'biography'.tr(context),
                                          border: const OutlineInputBorder(),
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
                                            child: Text('cancel'.tr(context)),
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
                                                : Text('save_changes'.tr(context)),
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