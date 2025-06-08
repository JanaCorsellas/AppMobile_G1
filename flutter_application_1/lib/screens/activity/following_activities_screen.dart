// lib/screens/activity/following_activities_screen.dart - CORREGIDO
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_application_1/widgets/custom_drawer.dart';
import 'package:flutter_application_1/config/routes.dart';
import 'package:flutter_application_1/services/auth_service.dart';
import 'package:flutter_application_1/services/activity_service.dart';
import 'package:flutter_application_1/services/http_service.dart';
import 'package:flutter_application_1/models/activity.dart';
import 'package:flutter_application_1/extensions/string_extensions.dart';
import 'package:flutter_application_1/screens/activity/activity_detail_screen.dart';
import 'package:intl/intl.dart';

class FollowingActivitiesScreen extends StatefulWidget {
  const FollowingActivitiesScreen({Key? key}) : super(key: key);

  @override
  _FollowingActivitiesScreenState createState() => _FollowingActivitiesScreenState();
}

class _FollowingActivitiesScreenState extends State<FollowingActivitiesScreen> {
  late ActivityService _activityService;
  List<Activity> _activities = [];
  Map<String, Map<String, dynamic>> _userDataMap = {}; // ✅ NUEVO: Mapa de datos de usuario
  bool _isLoading = true;
  bool _isLoadingMore = false;
  String _errorMessage = '';
  int _currentPage = 1;
  bool _hasMore = true;
  int _followingCount = 0;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _activityService = ActivityService(Provider.of<HttpService>(context, listen: false));
    _loadFollowingActivities();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200) {
      if (!_isLoadingMore && _hasMore) {
        _loadMoreActivities();
      }
    }
  }

  Future<void> _loadFollowingActivities() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = '';
      });

      final authService = Provider.of<AuthService>(context, listen: false);
      final currentUser = authService.currentUser;

      if (currentUser == null) {
        throw Exception('Usuario no autenticado');
      }

      final result = await _activityService.getFollowingActivities(
        currentUser.id,
        page: 1,
        limit: 10,
      );

      // ✅ DEBUG: Ver qué datos estamos recibiendo
      print('🎯 Received ${result['activities']?.length ?? 0} activities');
      print('🎯 UserDataMap keys: ${result['userDataMap']?.keys.toList() ?? []}');
      if (result['userDataMap'] != null) {
        result['userDataMap'].forEach((key, value) {
          print('🎯 User data for $key: $value');
        });
      }

      if (mounted) {
        setState(() {
          _activities = result['activities'] ?? [];
          _userDataMap = result['userDataMap'] ?? {}; // ✅ NUEVO: Guardar datos de usuario
          _hasMore = result['hasMore'] ?? false;
          _followingCount = result['followingCount'] ?? 0;
          _currentPage = 1;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _loadMoreActivities() async {
    if (_isLoadingMore || !_hasMore) return;

    try {
      setState(() {
        _isLoadingMore = true;
      });

      final authService = Provider.of<AuthService>(context, listen: false);
      final currentUser = authService.currentUser;

      if (currentUser == null) return;

      final result = await _activityService.getFollowingActivities(
        currentUser.id,
        page: _currentPage + 1,
        limit: 10,
      );

      if (mounted) {
        setState(() {
          _activities.addAll(result['activities'] ?? []);
          // ✅ NUEVO: Combinar mapas de datos de usuario
          final newUserDataMap = result['userDataMap'] ?? <String, Map<String, dynamic>>{};
          _userDataMap.addAll(newUserDataMap);
          _hasMore = result['hasMore'] ?? false;
          _currentPage = _currentPage + 1;
          _isLoadingMore = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingMore = false;
        });
      }
    }
  }

  Future<void> _refreshActivities() async {
    await _loadFollowingActivities();
  }

  void _navigateToActivityDetail(Activity activity) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ActivityDetailScreen(activity: activity),
      ),
    );
  }

  String _formatDuration(int durationMinutes) {
    final hours = durationMinutes ~/ 60;
    final minutes = durationMinutes % 60;
    
    if (hours > 0) {
      return '${hours}h ${minutes}m';
    } else {
      return '${minutes}m';
    }
  }

  String _formatDistance(double distance) {
    if (distance >= 1000) {
      return '${(distance / 1000).toStringAsFixed(1)} km';
    } else {
      return '${distance.toStringAsFixed(0)} m';
    }
  }

  Color _getActivityTypeColor(ActivityType type) {
    switch (type) {
      case ActivityType.running:
        return Colors.orange;
      case ActivityType.cycling:
        return Colors.blue;
      case ActivityType.hiking:
        return Colors.green;
      case ActivityType.walking:
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }

  IconData _getActivityTypeIcon(ActivityType type) {
    switch (type) {
      case ActivityType.running:
        return Icons.directions_run;
      case ActivityType.cycling:
        return Icons.directions_bike;
      case ActivityType.hiking:
        return Icons.hiking;
      case ActivityType.walking:
        return Icons.directions_walk;
      default:
        return Icons.fitness_center;
    }
  }

  String _getActivityTypeString(ActivityType type) {
    switch (type) {
      case ActivityType.running:
        return 'RUNNING';
      case ActivityType.cycling:
        return 'CYCLING';
      case ActivityType.hiking:
        return 'HIKING';
      case ActivityType.walking:
        return 'WALKING';
      default:
        return 'ACTIVITY';
    }
  }

  // ✅ Helpers para manejar información de usuario con campos existentes
  String _getUserDisplayName(Activity activity) {
    // Primero intentar obtener el nombre de los datos adicionales
    final userData = _userDataMap[activity.id];
    if (userData != null && userData['username'] != null) {
      return userData['username'] as String;
    }
    // Fallback al campo original
    return activity.authorName ?? 'Unknown User';
  }

  String? _getUserProfilePicture(Activity activity) {
    // ✅ AHORA SÍ: Obtener la imagen de perfil real de los datos del backend
    final userData = _userDataMap[activity.id];
    if (userData != null && userData['profilePicture'] != null) {
      final profilePicture = userData['profilePicture'] as String?;
      if (profilePicture != null && profilePicture.isNotEmpty) {
        return profilePicture;
      }
    }
    return null;
  }

  Widget _buildUserAvatar(Activity activity) {
    final displayName = _getUserDisplayName(activity);
    final initial = displayName.isNotEmpty ? displayName.substring(0, 1).toUpperCase() : 'U';
    final profilePicture = _getUserProfilePicture(activity);
    
    // ✅ DEBUG: Mostrar información sobre la imagen
    print('🖼️ Building avatar for ${displayName}: profilePicture = $profilePicture');
    
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: Colors.grey[300]!,
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: profilePicture != null && profilePicture.isNotEmpty
            ? Image.network(
                profilePicture,
                fit: BoxFit.cover,
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return Container(
                    color: Colors.grey[200],
                    child: Center(
                      child: SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Colors.grey[400]!,
                          ),
                        ),
                      ),
                    ),
                  );
                },
                errorBuilder: (context, error, stackTrace) {
                  print('❌ Error loading image $profilePicture: $error');
                  return Container(
                    color: _getAvatarBackgroundColor(displayName),
                    child: Center(
                      child: Text(
                        initial,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  );
                },
              )
            : Container(
                color: _getAvatarBackgroundColor(displayName),
                child: Center(
                  child: Text(
                    initial,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
      ),
    );
  }

  // ✅ Colores de avatar basados en el nombre para mayor variedad visual
  Color _getAvatarBackgroundColor(String name) {
    final colors = [
      const Color(0xFF6B73FF), // Azul
      const Color(0xFF9C88FF), // Púrpura
      const Color(0xFFFF8A80), // Rosa
      const Color(0xFF81C784), // Verde
      const Color(0xFFFFB74D), // Naranja
      const Color(0xFF64B5F6), // Azul claro
      const Color(0xFFAED581), // Verde claro
      const Color(0xFFFFD54F), // Amarillo
      const Color(0xFFE57373), // Rojo claro
      const Color(0xFFBA68C8), // Púrpura claro
    ];
    
    final hash = name.hashCode.abs();
    return colors[hash % colors.length];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('activities_feed'.tr(context)),
        backgroundColor: const Color.fromARGB(255, 21, 95, 51),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _refreshActivities,
          ),
        ],
      ),
      drawer: CustomDrawer(currentRoute: AppRoutes.followingActivities),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (_errorMessage.isNotEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: Colors.red[300],
            ),
            const SizedBox(height: 16),
            Text(
              'Error: $_errorMessage',
              style: const TextStyle(fontSize: 16),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _refreshActivities,
              child: Text('retry'.tr(context)),
            ),
          ],
        ),
      );
    }

    if (_activities.isEmpty) {
      return _buildEmptyState();
    }

    return RefreshIndicator(
      onRefresh: _refreshActivities,
      child: Column(
        children: [
          // Header con información de seguidos
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            color: Colors.grey[100],
            child: Row(
              children: [
                Icon(Icons.people, color: Colors.blue),
                const SizedBox(width: 8),
                Text(
                  'following_count'.tr(context).replaceFirst('{count}', _followingCount.toString()),
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const Spacer(),
                if (_activities.isNotEmpty)
                  Text(
                    'activities_found'.tr(context).replaceFirst('{count}', _activities.length.toString()),
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
              ],
            ),
          ),
          // Lista de actividades
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(8),
              itemCount: _activities.length + (_isLoadingMore ? 1 : 0),
              itemBuilder: (context, index) {
                if (index == _activities.length) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(16),
                      child: CircularProgressIndicator(),
                    ),
                  );
                }

                final activity = _activities[index];
                return _buildActivityCard(activity);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.people_outline,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'no_following_activities'.tr(context),
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            _followingCount == 0 
                ? 'not_following_anyone'.tr(context)
                : 'following_no_activities'.tr(context),
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.pushNamed(context, AppRoutes.userProfile);
            },
            icon: const Icon(Icons.person_add),
            label: Text('find_users'.tr(context)),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color.fromARGB(255, 21, 95, 51),
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActivityCard(Activity activity) {
    final typeColor = _getActivityTypeColor(activity.type);
    final typeIcon = _getActivityTypeIcon(activity.type);
    final typeString = _getActivityTypeString(activity.type);
    
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      elevation: 3,
      shadowColor: Colors.black.withOpacity(0.1),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: InkWell(
        onTap: () => _navigateToActivityDetail(activity),
        borderRadius: BorderRadius.circular(16),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.white,
                Colors.grey[50]!,
              ],
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header con usuario
                Row(
                  children: [
                    _buildUserAvatar(activity),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _getUserDisplayName(activity),
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                              color: Color(0xFF2C3E50),
                            ),
                          ),
                          const SizedBox(height: 2),
                          Row(
                            children: [
                              Icon(
                                Icons.access_time,
                                size: 12,
                                color: Colors.grey[600],
                              ),
                              const SizedBox(width: 4),
                              Text(
                                DateFormat('MMM d, y • HH:mm').format(activity.startTime),
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    // ✅ Agregar un indicador del tipo de actividad en el header
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                      decoration: BoxDecoration(
                        color: _getActivityTypeColor(activity.type).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        _getActivityTypeIcon(activity.type),
                        size: 16,
                        color: _getActivityTypeColor(activity.type),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                
                // Nombre de la actividad con mejor diseño
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: typeColor.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: typeColor.withOpacity(0.2),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: typeColor.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Icon(
                          typeIcon, 
                          color: typeColor, 
                          size: 16,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              typeString,
                              style: TextStyle(
                                color: typeColor,
                                fontWeight: FontWeight.bold,
                                fontSize: 11,
                                letterSpacing: 0.5,
                              ),
                            ),
                            Text(
                              activity.name,
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 15,
                                color: Color(0xFF2C3E50),
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                
                // Stats mejoradas con mejor diseño
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Colors.grey[200]!,
                      width: 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: _buildEnhancedStatChip(
                          Icons.straighten,
                          'Distancia',
                          _formatDistance(activity.distance),
                          Colors.blue,
                        ),
                      ),
                      Container(
                        width: 1,
                        height: 30,
                        color: Colors.grey[300],
                        margin: const EdgeInsets.symmetric(horizontal: 8),
                      ),
                      Expanded(
                        child: _buildEnhancedStatChip(
                          Icons.timer,
                          'Tiempo',
                          _formatDuration(activity.duration),
                          Colors.orange,
                        ),
                      ),
                      if (activity.averageSpeed > 0) ...[
                        Container(
                          width: 1,
                          height: 30,
                          color: Colors.grey[300],
                          margin: const EdgeInsets.symmetric(horizontal: 8),
                        ),
                        Expanded(
                          child: _buildEnhancedStatChip(
                            Icons.speed,
                            'Velocidad',
                            '${activity.averageSpeed.toStringAsFixed(1)} km/h',
                            Colors.green,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ✅ Nuevo widget para estadísticas mejoradas
  Widget _buildEnhancedStatChip(IconData icon, String label, String value, Color color) {
    return Column(
      children: [
        Icon(icon, color: color, size: 18),
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(
            color: color,
            fontWeight: FontWeight.bold,
            fontSize: 13,
          ),
          textAlign: TextAlign.center,
        ),
        Text(
          label,
          style: TextStyle(
            color: Colors.grey[600],
            fontSize: 10,
            fontWeight: FontWeight.w500,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildStatChip(IconData icon, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 14),
          const SizedBox(width: 4),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w600,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}