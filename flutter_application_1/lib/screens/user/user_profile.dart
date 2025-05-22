// lib/screens/user/user_profile.dart - Versión compatible con Web
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart'; // Para kIsWeb
import 'package:flutter_application_1/services/http_service.dart';
import 'package:flutter_application_1/widgets/custom_drawer.dart';
import 'package:provider/provider.dart';
import 'package:flutter_application_1/config/routes.dart';
import 'package:flutter_application_1/models/user.dart';
import 'package:flutter_application_1/services/auth_service.dart';
import 'package:flutter_application_1/services/user_service.dart';
import 'package:flutter_application_1/extensions/string_extensions.dart';
import 'package:flutter_application_1/services/socket_service.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

class UserProfileScreen extends StatefulWidget {
  const UserProfileScreen({Key? key}) : super(key: key);

  @override
  _UserProfileScreenState createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends State<UserProfileScreen> {
  late final UserService _userService;
  final _formKey = GlobalKey<FormState>();
  final ImagePicker _imagePicker = ImagePicker();
  
  late TextEditingController _usernameController;
  late TextEditingController _emailController;
  late TextEditingController _bioController;
  
  bool _isLoading = false;
  bool _isEditing = false;
  bool _isUploadingImage = false;
  String _errorMessage = '';
  String _successMessage = '';
  User? _user;

  @override
  void initState() {
    super.initState();
    _usernameController = TextEditingController();
    _emailController = TextEditingController();
    _bioController = TextEditingController();

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
    super.dispose();
  }

  Future<void> _loadUserData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      
      User? user;
      
      if (authService.currentUser != null) {
        user = authService.currentUser;
        print("Usando usuario del auth service con ID: ${user?.id}");
        print("ProfilePicture: ${user?.profilePicture}");
      } else {
        print("No se encontró usuario en auth service, intentando con API...");
        user = await _userService.getUserById(authService.currentUser?.id ?? '');
        print("Usuario obtenido de API con ID: ${user?.id}");
      }
      
      if (user != null) {
        setState(() {
          _user = user;
          _usernameController.text = user!.username;
          _emailController.text = user.email;
          _bioController.text = user.bio ?? '';
          
          print("Datos cargados en controladores:");
          print("Username: ${_usernameController.text}");
          print("Email: ${_emailController.text}");
          print("Bio: ${_bioController.text}");
          print("ProfilePicture URL: ${user.profilePictureUrl}");
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

  // ✅ ACTUALIZADO: Compatible con Web
  Future<void> _pickAndUploadImage() async {
    try {
      ImageSource? source;
      
      // ✅ En Web: Solo mostrar galería (file picker)
      if (kIsWeb) {
        source = ImageSource.gallery;
      } else {
        // ✅ En móvil: Mostrar opciones de cámara y galería
        source = await _showImageSourceDialog();
        if (source == null) return;
      }

      // Pick image
      final XFile? pickedFile = await _imagePicker.pickImage(
        source: source,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );

      if (pickedFile == null) return;

      setState(() {
        _isUploadingImage = true;
        _errorMessage = '';
        _successMessage = '';
      });

      // ✅ En Web: Usar XFile directamente
      // ✅ En móvil: Convertir a File
      dynamic imageFile;
      if (kIsWeb) {
        imageFile = pickedFile; // XFile para web
      } else {
        imageFile = File(pickedFile.path); // File para móvil
      }

      // Upload image
      final result = await _userService.uploadProfilePicture(_user!.id, imageFile);

      // Update user data
      setState(() {
        _user = _user!.copyWith(
          profilePicture: result['profilePicture'],
        );
        _successMessage = 'profile_picture_updated'.tr(context);
      });

      // Update auth service with new user data
      final authService = Provider.of<AuthService>(context, listen: false);
      authService.updateCurrentUser(_user!);

      // Save updated user data to persistent storage
      await _userService.saveUserToCache(_user!);

      print('Profile picture uploaded successfully: ${result['profilePicture']}');

    } catch (e) {
      setState(() {
        _errorMessage = 'profile_picture_upload_error'.tr(context) + ': $e';
      });
      print('Error uploading profile picture: $e');
    } finally {
      setState(() {
        _isUploadingImage = false;
      });
    }
  }

  // ✅ ACTUALIZADO: Solo mostrar en móvil
  Future<ImageSource?> _showImageSourceDialog() async {
    // ✅ En Web: No mostrar este diálogo
    if (kIsWeb) return ImageSource.gallery;
    
    return await showDialog<ImageSource?>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('select_image_source'.tr(context)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.camera_alt),
                title: Text('camera'.tr(context)),
                onTap: () => Navigator.of(context).pop(ImageSource.camera),
              ),
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: Text('gallery'.tr(context)),
                onTap: () => Navigator.of(context).pop(ImageSource.gallery),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _deleteProfilePicture() async {
    try {
      // Show confirmation dialog
      final bool? confirm = await showDialog<bool>(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text('delete_profile_picture'.tr(context)),
            content: Text('delete_profile_picture_confirmation'.tr(context)),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: Text('cancel'.tr(context)),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: Text('delete'.tr(context)),
                style: TextButton.styleFrom(foregroundColor: Colors.red),
              ),
            ],
          );
        },
      );

      if (confirm != true) return;

      setState(() {
        _isUploadingImage = true;
        _errorMessage = '';
        _successMessage = '';
      });

      // Delete image
      final success = await _userService.deleteProfilePicture(_user!.id);

      if (success) {
        // Update user data
        setState(() {
          _user = _user!.copyWith(profilePicture: null);
          _successMessage = 'profile_picture_deleted'.tr(context);
        });

        // Update auth service
        final authService = Provider.of<AuthService>(context, listen: false);
        authService.updateCurrentUser(_user!);

        // Save to cache
        await _userService.saveUserToCache(_user!);

        print('Profile picture deleted successfully');
      } else {
        setState(() {
          _errorMessage = 'profile_picture_delete_error'.tr(context);
        });
      }

    } catch (e) {
      setState(() {
        _errorMessage = 'profile_picture_delete_error'.tr(context) + ': $e';
      });
      print('Error deleting profile picture: $e');
    } finally {
      setState(() {
        _isUploadingImage = false;
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
        };

        final updatedUser = await _userService.updateUser(_user!.id, userData);
        
        setState(() {
          _user = updatedUser;
          _successMessage = 'profile_updated'.tr(context);
          _isEditing = false;
        });
        
        final authService = Provider.of<AuthService>(context, listen: false);
        authService.updateCurrentUser(updatedUser);
        
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

  // ✅ ACTUALIZADO: Texto del botón según plataforma
  Widget _buildProfilePicture() {
    return Stack(
      alignment: Alignment.center,
      children: [
        CircleAvatar(
          radius: 50.0,
          backgroundColor: Colors.grey.shade200,
          backgroundImage: _user!.hasProfilePicture 
              ? NetworkImage(_user!.profilePictureUrl!)
              : null,
          child: !_user!.hasProfilePicture
              ? const Icon(
                  Icons.person,
                  size: 50.0,
                  color: Colors.grey,
                )
              : null,
        ),
        if (_isUploadingImage)
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              color: Colors.black54,
              borderRadius: BorderRadius.circular(50),
            ),
            child: const Center(
              child: CircularProgressIndicator(
                color: Colors.white,
              ),
            ),
          ),
        if (!_isEditing)
          Positioned(
            bottom: 0,
            right: 0,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.blue,
                borderRadius: BorderRadius.circular(15),
              ),
              child: IconButton(
                icon: Icon(
                  // ✅ Icono diferente según plataforma
                  kIsWeb ? Icons.upload_file : Icons.camera_alt, 
                  color: Colors.white, 
                  size: 20
                ),
                onPressed: _isUploadingImage ? null : _pickAndUploadImage,
                padding: const EdgeInsets.all(8),
                constraints: const BoxConstraints(),
                tooltip: kIsWeb ? 'Subir archivo' : 'Tomar foto',
              ),
            ),
          ),
        if (!_isEditing && _user!.hasProfilePicture)
          Positioned(
            top: 0,
            right: 0,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.red,
                borderRadius: BorderRadius.circular(15),
              ),
              child: IconButton(
                icon: const Icon(Icons.delete, color: Colors.white, size: 16),
                onPressed: _isUploadingImage ? null : _deleteProfilePicture,
                padding: const EdgeInsets.all(6),
                constraints: const BoxConstraints(),
              ),
            ),
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: const CustomDrawer(currentRoute: AppRoutes.userProfile),
      appBar: AppBar(
        title: Text('my_profile'.tr(context)),
        leading: null,
        automaticallyImplyLeading: true,
        // ✅ Mostrar indicador de plataforma en debug
        actions: [
          if (kDebugMode)
            Chip(
              label: Text(kIsWeb ? 'WEB' : 'MOBILE'),
              backgroundColor: kIsWeb ? Colors.blue : Colors.green,
              labelStyle: const TextStyle(color: Colors.white, fontSize: 10),
            ),
          const SizedBox(width: 8),
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
                      // ✅ Mostrar nota informativa en Web
                      if (kIsWeb)
                        Container(
                          padding: const EdgeInsets.all(12.0),
                          margin: const EdgeInsets.only(bottom: 16.0),
                          decoration: BoxDecoration(
                            color: Colors.blue.shade50,
                            borderRadius: BorderRadius.circular(8.0),
                            border: Border.all(color: Colors.blue.shade200),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.info, color: Colors.blue.shade600),
                              const SizedBox(width: 8.0),
                              Expanded(
                                child: Text(
                                  '💻 Modo Web: Solo selector de archivos disponible',
                                  style: TextStyle(color: Colors.blue.shade800),
                                ),
                              ),
                            ],
                          ),
                        ),
                      
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
                                  _buildProfilePicture(),
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
                              // Resto del código igual...
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