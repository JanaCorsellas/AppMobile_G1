// lib/screens/user/user_profile.dart - Versión con sistema de seguimiento integrado
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart'; // Para kIsWeb
import 'package:flutter_application_1/services/http_service.dart';
import 'package:flutter_application_1/services/follow_service.dart'; // ✅ NUEVO
import 'package:flutter_application_1/widgets/custom_drawer.dart';
import 'package:provider/provider.dart';
import 'package:flutter_application_1/config/routes.dart';
import 'package:flutter_application_1/models/user.dart';
import 'package:flutter_application_1/services/auth_service.dart';
import 'package:flutter_application_1/services/user_service.dart';
import 'package:flutter_application_1/extensions/string_extensions.dart';
import 'package:flutter_application_1/services/socket_service.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart'; // ✅ NUEVO IMPORT CACHE
import 'dart:io';

class UserProfileScreen extends StatefulWidget {
  final String? userId; // ✅ NUEVO: Para permitir ver otros perfiles
  
  const UserProfileScreen({Key? key, this.userId}) : super(key: key);

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

  // ✅ NUEVAS VARIABLES PARA SISTEMA DE SEGUIMIENTO
  bool _isFollowing = false;
  bool _isFollowingLoading = false;
  int _followersCount = 0;
  int _followingCount = 0;
  bool _followStatsLoaded = false;

  Key _profileImageKey = UniqueKey();

  // ✅ NUEVAS VARIABLES PARA CONTROL DE CACHE
  bool _imageRefreshMode = false;
  int _imageRefreshCounter = 0;
  String? _lastImageUrl; // Para trackear cambios de URL

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
    // ✅ NUEVO: Cargar datos de seguimiento
    _loadFollowData();
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _emailController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  // ✅ NUEVO: Getter para determinar si es el perfil propio
  bool get _isOwnProfile => widget.userId == null || widget.userId == Provider.of<AuthService>(context, listen: false).currentUser?.id;

  Future<void> _loadUserData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      
      User? user;
      
      if (_isOwnProfile) {
        // Cargar perfil propio
        if (authService.currentUser != null) {
          user = authService.currentUser;
          print("Usando usuario del auth service con ID: ${user?.id}");
          print("ProfilePicture: ${user?.profilePicture}");
        } else {
          print("No se encontró usuario en auth service, intentando con API...");
          user = await _userService.getUserById(authService.currentUser?.id ?? '');
          print("Usuario obtenido de API con ID: ${user?.id}");
        }
      } else {
        // ✅ NUEVO: Cargar perfil de otro usuario
        user = await _userService.getUserById(widget.userId!);
        print("Usuario externo obtenido de API con ID: ${user?.id}");
      }
      
      if (user != null) {
        setState(() {
          _user = user;
          _usernameController.text = user!.username;
          _emailController.text = user.email;
          _bioController.text = user.bio ?? '';
          
          _profileImageKey = UniqueKey();
          
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

  // ✅ NUEVO: Cargar datos de seguimiento
  Future<void> _loadFollowData() async {
    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      final followService = Provider.of<FollowService>(context, listen: false);
      
      final currentUser = authService.currentUser;
      if (currentUser == null) return;

      final targetUserId = widget.userId ?? currentUser.id;
      
      // Cargar estadísticas de seguimiento
      final stats = await followService.getFollowStats(
        targetUserId,
        authService.accessToken,
      );

      if (stats != null && mounted) {
        setState(() {
          _followersCount = stats['followersCount'] ?? 0;
          _followingCount = stats['followingCount'] ?? 0;
          _followStatsLoaded = true;
        });
      }

      // Si no es el perfil propio, verificar si lo seguimos
      if (!_isOwnProfile) {
        final status = await followService.checkFollowStatus(
          currentUser.id,
          targetUserId,
          authService.accessToken,
        );

        if (mounted) {
          setState(() {
            _isFollowing = status['isFollowing'] ?? false;
          });
        }
      }
    } catch (e) {
      print('Error cargando datos de seguimiento: $e');
      setState(() {
        _followStatsLoaded = true; // Marcar como cargado aunque falle
      });
    }
  }

  // ✅ NUEVO: Toggle follow/unfollow
  Future<void> _toggleFollow() async {
    if (widget.userId == null || _isOwnProfile) return;

    setState(() {
      _isFollowingLoading = true;
    });

    final authService = Provider.of<AuthService>(context, listen: false);
    final followService = Provider.of<FollowService>(context, listen: false);
    
    try {
      bool success;
      if (_isFollowing) {
        success = await followService.unfollowUser(
          authService.currentUser!.id,
          widget.userId!,
          authService.accessToken,
        );
      } else {
        success = await followService.followUser(
          authService.currentUser!.id,
          widget.userId!,
          authService.accessToken,
        );
      }

      if (success) {
        setState(() {
          _isFollowing = !_isFollowing;
          if (_isFollowing) {
            _followersCount++;
          } else {
            _followersCount--;
          }
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _isFollowing
                  ? 'user_followed_successfully'.tr(context)
                  : 'user_unfollowed_successfully'.tr(context),
            ),
            backgroundColor: _isFollowing ? Colors.green : Colors.orange,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isFollowingLoading = false;
      });
    }
  }

  // ✅ NUEVO: Navegar a pantalla de seguidores
  void _navigateToFollowers() {
    if (_user != null) {
      Navigator.pushNamed(
        context,
        AppRoutes.followers,
        arguments: {
          'userId': _user!.id,
          'userName': _user!.username,
        },
      );
    }
  }

  // ✅ NUEVO: Navegar a pantalla de seguidos
  void _navigateToFollowing() {
    if (_user != null) {
      Navigator.pushNamed(
        context,
        AppRoutes.following,
        arguments: {
          'userId': _user!.id,
          'userName': _user!.username,
        },
      );
    }
  }

  // ✅ NUEVO: Widget para mostrar estadísticas de seguimiento
  Widget _buildFollowStats() {
    if (!_followStatsLoaded) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Center(
            child: CircularProgressIndicator(),
          ),
        ),
      );
    }

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12.0),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildStatItem(
              label: 'followers'.tr(context),
              value: _followersCount.toString(),
              icon: Icons.people,
              color: Colors.blue,
              onTap: _navigateToFollowers,
            ),
            Container(
              height: 40,
              width: 1,
              color: Colors.grey[300],
            ),
            _buildStatItem(
              label: 'following'.tr(context),
              value: _followingCount.toString(),
              icon: Icons.person_add,
              color: Colors.green,
              onTap: _navigateToFollowing,
            ),
            Container(
              height: 40,
              width: 1,
              color: Colors.grey[300],
            ),
            _buildStatItem(
              label: 'level'.tr(context),
              value: _user?.level.toString() ?? '0',
              icon: Icons.star,
              color: Colors.amber,
            ),
          ],
        ),
      ),
    );
  }

  // ✅ NUEVO: Widget para un item de estadística
  Widget _buildStatItem({
    required String label,
    required String value,
    required IconData icon,
    required Color color,
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Icon(
            icon,
            color: color,
            size: 24,
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  // ✅ NUEVO: Widget para botón de seguir/no seguir
  Widget _buildFollowButton() {
    if (_isOwnProfile) return const SizedBox.shrink();

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      child: ElevatedButton.icon(
        onPressed: _isFollowingLoading ? null : _toggleFollow,
        icon: _isFollowingLoading
            ? const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
              )
            : Icon(_isFollowing ? Icons.person_remove : Icons.person_add),
        label: Text(
          _isFollowing ? 'unfollow'.tr(context) : 'follow'.tr(context),
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: _isFollowing ? Colors.grey[400] : Colors.blue,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),
    );
  }

  // ✅ MÉTODOS NUEVOS DE CACHE

  /// ✅ MÉTODO MEJORADO: Limpiar cache específico de usuario
  Future<void> _clearUserImageCache() async {
    try {
      print('🧹 Limpiando cache específico del usuario...');
      
      // Obtener posibles URLs del usuario
      final urlsToClean = <String>[];
      
      if (_user?.profilePictureUrl != null) {
        urlsToClean.add(_user!.profilePictureUrl!);
      }
      
      if (_user?.profilePicture != null) {
        urlsToClean.add(_user!.profilePicture!);
      }
      
      if (_lastImageUrl != null) {
        urlsToClean.add(_lastImageUrl!);
      }
      
      // Limpiar cada URL y sus variaciones
      for (final url in urlsToClean) {
        await _clearUrlVariations(url);
      }
      
      print('✅ Cache específico del usuario limpiado');
    } catch (e) {
      print('❌ Error limpiando cache específico: $e');
    }
  }

  /// ✅ MÉTODO NUEVO: Limpiar variaciones de una URL
  Future<void> _clearUrlVariations(String baseUrl) async {
    try {
      // URL base
      await CachedNetworkImage.evictFromCache(baseUrl);
      await DefaultCacheManager().removeFile(baseUrl);
      
      // URL sin parámetros de query
      final urlWithoutParams = baseUrl.split('?')[0];
      await CachedNetworkImage.evictFromCache(urlWithoutParams);
      await DefaultCacheManager().removeFile(urlWithoutParams);
      
      // Variaciones con timestamps
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final urlsWithTimestamp = [
        '$urlWithoutParams?t=$timestamp',
        '$baseUrl&t=$timestamp',
        '$baseUrl?t=$timestamp',
      ];
      
      for (final url in urlsWithTimestamp) {
        await CachedNetworkImage.evictFromCache(url);
        await DefaultCacheManager().removeFile(url);
      }
      
      print('🧹 Variaciones de URL limpiadas: $baseUrl');
    } catch (e) {
      print('❌ Error limpiando variaciones de URL: $e');
    }
  }

  /// ✅ MÉTODO NUEVO: Generar URL con cache-busting
  String _buildCacheBustingUrl(String originalUrl) {
    if (originalUrl.isEmpty) return originalUrl;
    
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final separator = originalUrl.contains('?') ? '&' : '?';
    return '$originalUrl${separator}t=$timestamp&refresh=$_imageRefreshCounter';
  }

  /// ✅ MÉTODO NUEVO: Activar modo refresh temporal
  void _activateRefreshMode() {
    setState(() {
      _imageRefreshMode = true;
      _imageRefreshCounter++;
    });
    
    // Desactivar después de 3 segundos
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        setState(() {
          _imageRefreshMode = false;
        });
      }
    });
  }

  /// ✅ MÉTODO NUEVO: Pre-limpiar cache antes de operaciones
  Future<void> _preClearCache() async {
    try {
      // Guardar URL actual para limpieza
      _lastImageUrl = _user?.profilePictureUrl;
      
      // Limpiar cache específico
      await _clearUserImageCache();
      
      // Limpiar cache general si es necesario
      if (_imageRefreshMode) {
        await CachedNetworkImage.evictFromCache('');
      }
      
      print('✅ Pre-limpieza de cache completada');
    } catch (e) {
      print('❌ Error en pre-limpieza: $e');
    }
  }

  /// ✅ MÉTODO NUEVO: Post-procesar después de cambios de imagen
  Future<void> _postProcessImageChange(String? newImageUrl) async {
    try {
      print('🔄 Post-procesando cambio de imagen...');
      
      // Limpiar cache de la URL anterior
      if (_lastImageUrl != null && _lastImageUrl != newImageUrl) {
        await _clearUrlVariations(_lastImageUrl!);
      }
      
      // Activar modo refresh
      _activateRefreshMode();
      
      // Forzar reconstrucción del widget de imagen
      setState(() {
        _profileImageKey = UniqueKey();
      });
      
      // Actualizar última URL conocida
      _lastImageUrl = newImageUrl;
      
      print('✅ Post-procesamiento completado');
    } catch (e) {
      print('❌ Error en post-procesamiento: $e');
    }
  }

  /// ✅ MÉTODO NUEVO: Obtener URL de imagen optimizada para cache
  String? _getOptimizedImageUrl() {
    if (_user?.profilePictureUrl == null) return null;
    
    String imageUrl = _user!.profilePictureUrl!;
    
    // Si estamos en modo refresh, agregar cache-busting
    if (_imageRefreshMode || _imageRefreshCounter > 0) {
      imageUrl = _buildCacheBustingUrl(imageUrl);
    }
    
    return imageUrl;
  }

  Future<void> _pickAndUploadImage() async {
    // Solo permitir en perfil propio
    if (!_isOwnProfile) return;
    
    try {
      ImageSource? source;
      
      if (kIsWeb) {
        source = ImageSource.gallery;
      } else {
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

      // ✅ PRE-LIMPIAR CACHE
      await _preClearCache();

      dynamic imageFile;
      if (kIsWeb) {
        imageFile = pickedFile; // XFile para web
      } else {
        imageFile = File(pickedFile.path); // File para móvil
      }

      // Upload image
      final result = await _userService.uploadProfilePicture(_user!.id, imageFile);

      final updatedUser = _user!.copyWith(
        profilePicture: result['profilePicture'],
      );

      setState(() {
        _user = updatedUser;
        _successMessage = 'profile_picture_updated'.tr(context);
      });

      // ✅ POST-PROCESAR CAMBIO DE IMAGEN
      await _postProcessImageChange(updatedUser.profilePictureUrl);

      // Update auth service with new user data
      final authService = Provider.of<AuthService>(context, listen: false);
      authService.updateCurrentUser(updatedUser);

      // Save updated user data to persistent storage
      await _userService.saveUserToCache(updatedUser);

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

  Future<ImageSource?> _showImageSourceDialog() async {
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

  Future<void> _clearImageCache([String? imageUrl]) async {
    try {
      // Limpiar caché específico si se proporciona URL
      if (imageUrl != null && imageUrl.isNotEmpty) {
        await CachedNetworkImage.evictFromCache(imageUrl);
        print('Caché limpiado para: $imageUrl');
      }
      
      // También limpiar la URL anterior si existe
      if (_user?.profilePictureUrl != null) {
        await CachedNetworkImage.evictFromCache(_user!.profilePictureUrl!);
        print('Caché limpiado para URL anterior: ${_user!.profilePictureUrl}');
      }
    } catch (e) {
      print('Error limpiando caché de imágenes: $e');
    }
  }

  Future<void> _deleteProfilePicture() async {
    // Solo permitir en perfil propio
    if (!_isOwnProfile) return;
    
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

      final oldImageUrl = _user?.profilePictureUrl;
      
      print('🗑️ Deleting profile picture for user: ${_user!.id}');
      print('🗑️ Current image URL: $oldImageUrl');

      // ✅ PRE-LIMPIAR CACHE
      await _preClearCache();

      final success = await _userService.deleteProfilePicture(_user!.id);

      if (success) {
        print('✅ Delete API call successful');
        
        final updatedUser = _user!.copyWith(
          profilePicture: null,
          clearProfilePicture: true, // Flag explícito para limpiar
        );
        
        setState(() {
          _user = updatedUser;
          _successMessage = 'profile_picture_deleted'.tr(context);
        });

        // ✅ POST-PROCESAR CAMBIO DE IMAGEN (eliminación)
        await _postProcessImageChange(null);

        final authService = Provider.of<AuthService>(context, listen: false);
        authService.updateCurrentUser(updatedUser);

        await _userService.saveUserToCache(updatedUser);

        print('✅ Profile picture deletion completed successfully');

      } else {
        setState(() {
          _errorMessage = 'profile_picture_delete_error'.tr(context);
        });
      }

    } catch (e) {
      setState(() {
        _errorMessage = 'profile_picture_delete_error'.tr(context) + ': $e';
      });
      print('❌ Error deleting profile picture: $e');
    } finally {
      setState(() {
        _isUploadingImage = false;
      });
    }
  }

  Future<void> _clearImageCacheCompletely([String? specificUrl]) async {
    try {
      print('🧹 Starting complete image cache cleanup...');
      
      // 1. Limpiar URL específica si se proporciona
      if (specificUrl != null && specificUrl.isNotEmpty) {
        await CachedNetworkImage.evictFromCache(specificUrl);
        print('🧹 Cleared specific URL: $specificUrl');
        
        // También limpiar posibles variaciones de la URL
        final variations = [
          specificUrl,
          '$specificUrl?t=${DateTime.now().millisecondsSinceEpoch}',
          specificUrl.split('?')[0], // URL sin parámetros
        ];
        
        for (final variation in variations) {
          await CachedNetworkImage.evictFromCache(variation);
        }
      }
      
      // 2. Limpiar todas las posibles URLs del usuario actual
      if (_user != null) {
        final possibleUrls = [
          _user!.profilePicture,
          _user!.profilePictureUrl,
          // También URLs con timestamps anteriores
        ].where((url) => url != null && url.isNotEmpty).toList();
        
        for (final url in possibleUrls) {
          await CachedNetworkImage.evictFromCache(url!);
          print('🧹 Cleared user URL: $url');
        }
      }
      
      // 3. Limpiar caché general (método agresivo)
      await CachedNetworkImage.evictFromCache('');
      
      print('✅ Complete image cache cleanup finished');
      
    } catch (e) {
      print('❌ Error during cache cleanup: $e');
      // No fallar por errores de caché
    }
  }

  Future<void> _refreshProfile() async {
    print('🔄 Starting profile refresh...');
    
    // Limpiar caché del usuario
    _userService.clearCache();
    
    // ✅ LIMPIAR CACHE MEJORADO
    await _clearUserImageCache();
    
    await _loadUserData();
    // ✅ NUEVO: También refrescar datos de seguimiento
    await _loadFollowData();
    
    setState(() {
      _successMessage = 'Perfil actualizado';
    });

    // ✅ ACTIVAR MODO REFRESH
    _activateRefreshMode();
    
    // Limpiar mensaje después de 3 segundos
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        setState(() {
          _successMessage = '';
        });
      }
    });
  }

  Future<void> _saveProfile() async {
    // Solo permitir en perfil propio
    if (!_isOwnProfile) return;
    
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

  Widget _buildProfilePicture() {
    return Stack(
      alignment: Alignment.center,
      children: [
        Container(
          key: ValueKey('profile_${_user?.id}_${_imageRefreshCounter}'), // ✅ KEY ÚNICO MEJORADA
          child: CircleAvatar(
            radius: 50.0,
            backgroundColor: Colors.grey.shade200,
            child: _user!.hasProfilePicture 
                ? ClipOval(
                    child: CachedNetworkImage(
                      imageUrl: _getOptimizedImageUrl() ?? _user!.profilePictureUrl!, // ✅ URL OPTIMIZADA
                      width: 100,
                      height: 100,
                      fit: BoxFit.cover,
                      placeholder: (context, url) => Container(
                        width: 100,
                        height: 100,
                        color: Colors.grey.shade200,
                        child: const Center(
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.grey,
                          ),
                        ),
                      ),
                      errorWidget: (context, url, error) {
                        print('Error cargando imagen: $error');
                        return Container(
                          width: 100,
                          height: 100,
                          color: Colors.grey.shade200,
                          child: const Icon(
                            Icons.person,
                            size: 50.0,
                            color: Colors.grey,
                          ),
                        );
                      },
                      httpHeaders: const {
                        'Cache-Control': 'no-cache, no-store, must-revalidate',
                        'Pragma': 'no-cache',
                        'Expires': '0',
                      },
                      // ✅ CONFIGURACIONES ANTI-CACHE MEJORADAS
                      useOldImageOnUrlChange: false,
                      fadeInDuration: const Duration(milliseconds: 300),
                      fadeOutDuration: const Duration(milliseconds: 100),
                    ),
                  )
                : const Icon(
                    Icons.person,
                    size: 50.0,
                    color: Colors.grey,
                  ),
          ),
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
        // Solo mostrar botones de edición en perfil propio
        if (_isOwnProfile && !_isEditing)
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
        if (_isOwnProfile && !_isEditing && _user!.hasProfilePicture)
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
      drawer: _isOwnProfile ? const CustomDrawer(currentRoute: AppRoutes.userProfile) : null,
      appBar: AppBar(
        title: Text(_isOwnProfile ? 'my_profile'.tr(context) : _user?.username ?? 'profile'.tr(context)),
        leading: !_isOwnProfile ? IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ) : null,
        automaticallyImplyLeading: _isOwnProfile,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _refreshProfile,
            tooltip: 'Actualizar perfil',
          ),
          if (kDebugMode)
            Chip(
              label: Text(kIsWeb ? 'WEB' : 'MOBILE'),
              backgroundColor: kIsWeb ? Colors.blue : Colors.green,
              labelStyle: const TextStyle(color: Colors.white, fontSize: 10),
            ),
          // ✅ BOTÓN DEBUG PARA LIMPIAR CACHE (solo en debug)
          if (kDebugMode)
            IconButton(
              icon: const Icon(Icons.clear_all),
              onPressed: () async {
                await _clearUserImageCache();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('🧹 Cache limpiado manualmente')),
                );
              },
              tooltip: 'Limpiar cache',
            ),
          if (_isOwnProfile) ...[
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
                      
                      // ✅ NUEVO: Estadísticas de seguimiento
                      _buildFollowStats(),
                      const SizedBox(height: 16.0),
                      
                      // ✅ NUEVO: Botón de seguir/no seguir
                      _buildFollowButton(),
                      
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
                                  // Solo mostrar botón editar en perfil propio
                                  if (_isOwnProfile && !_isEditing)
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
                              ] else if (_isOwnProfile) ...[
                                // Solo mostrar formulario de edición en perfil propio
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