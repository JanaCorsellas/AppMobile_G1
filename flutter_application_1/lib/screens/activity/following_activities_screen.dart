// lib/screens/activity/following_activities_screen.dart - VERSIÓN MEJORADA CON BRANDING TRAZER
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

class _FollowingActivitiesScreenState extends State<FollowingActivitiesScreen> 
    with TickerProviderStateMixin {
  late ActivityService _activityService;
  List<Activity> _activities = [];
  Map<String, Map<String, dynamic>> _userDataMap = {};
  bool _isLoading = true;
  bool _isLoadingMore = false;
  String _errorMessage = '';
  int _currentPage = 1;
  bool _hasMore = true;
  int _followingCount = 0;
  final ScrollController _scrollController = ScrollController();
  
  // Animaciones
  late AnimationController _fadeController;
  late AnimationController _listController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    
    // Inicializar animaciones
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _listController = AnimationController(
      duration: const Duration(milliseconds: 600),
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
      parent: _listController,
      curve: Curves.easeOutBack,
    ));
    
    _activityService = ActivityService(Provider.of<HttpService>(context, listen: false));
    _loadFollowingActivities();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _fadeController.dispose();
    _listController.dispose();
    super.dispose();
  }

  void _startAnimations() {
    _fadeController.forward();
    Future.delayed(const Duration(milliseconds: 200), () {
      _listController.forward();
    });
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
        throw Exception('no_auth_user'.tr(context));
      }

      final result = await _activityService.getFollowingActivities(
        currentUser.id,
        page: 1,
        limit: 10,
      );

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
          _userDataMap = result['userDataMap'] ?? {};
          _hasMore = result['hasMore'] ?? false;
          _followingCount = result['followingCount'] ?? 0;
          _currentPage = 1;
          _isLoading = false;
        });
        _startAnimations();
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
        return Colors.green;
      case ActivityType.cycling:
        return Colors.blue;
      case ActivityType.hiking:
        return Colors.orange;
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
        return Icons.terrain;
      case ActivityType.walking:
        return Icons.directions_walk;
      default:
        return Icons.fitness_center;
    }
  }

  String _getActivityTypeString(ActivityType type) {
    switch (type) {
      case ActivityType.running:
        return 'running_caps'.tr(context);
      case ActivityType.cycling:
        return 'cycling_caps'.tr(context);
      case ActivityType.hiking:
        return 'hiking_caps'.tr(context);
      case ActivityType.walking:
        return 'walking_caps'.tr(context);
      default:
        return 'activity_caps'.tr(context);
    }
  }

  String _getUserDisplayName(Activity activity) {
    final userData = _userDataMap[activity.id];
    if (userData != null && userData['username'] != null) {
      return userData['username'] as String;
    }
    return activity.authorName ?? 'user'.tr(context);
  }

  String? _getUserProfilePicture(Activity activity) {
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
    
    print('🖼️ Building avatar for ${displayName}: profilePicture = $profilePicture');
    
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: const Color(0xFF667eea).withOpacity(0.3),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF667eea).withOpacity(0.2),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: profilePicture != null && profilePicture.isNotEmpty
            ? Image.network(
                profilePicture,
                fit: BoxFit.cover,
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.grey[200]!,
                          Colors.grey[300]!,
                        ],
                      ),
                    ),
                    child: Center(
                      child: SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            const Color(0xFF667eea),
                          ),
                        ),
                      ),
                    ),
                  );
                },
                errorBuilder: (context, error, stackTrace) {
                  print('❌ Error loading image $profilePicture: $error');
                  return Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          _getAvatarBackgroundColor(displayName),
                          _getAvatarBackgroundColor(displayName).withOpacity(0.8),
                        ],
                      ),
                    ),
                    child: Center(
                      child: Text(
                        initial,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  );
                },
              )
            : Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      _getAvatarBackgroundColor(displayName),
                      _getAvatarBackgroundColor(displayName).withOpacity(0.8),
                    ],
                  ),
                ),
                child: Center(
                  child: Text(
                    initial,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
      ),
    );
  }

  Color _getAvatarBackgroundColor(String name) {
    final colors = [
      const Color(0xFF667eea), // Azul TRAZER
      const Color(0xFF764ba2), // Púrpura TRAZER
      const Color(0xFF8b5cf6), // Violeta
      const Color(0xFF06b6d4), // Cyan
      const Color(0xFF10b981), // Esmeralda
      const Color(0xFFf59e0b), // Ámbar
      const Color(0xFFef4444), // Rojo
      const Color(0xFFec4899), // Rosa
      const Color(0xFF8b5cf6), // Violeta
      const Color(0xFF6366f1), // Índigo
    ];
    
    final hash = name.hashCode.abs();
    return colors[hash % colors.length];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: CustomDrawer(currentRoute: AppRoutes.followingActivities),
      body: CustomScrollView(
        controller: _scrollController,
        slivers: [
          // AppBar moderna con gradiente TRAZER
          SliverAppBar(
            expandedHeight: 120,
            floating: false,
            pinned: true,
            elevation: 0,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Color(0xFF667eea),
                      Color(0xFF764ba2),
                    ],
                  ),
                ),
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 20),
                        FadeTransition(
                          opacity: _fadeAnimation,
                          child: Text(
                            'friends_activities'.tr(context),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        FadeTransition(
                          opacity: _fadeAnimation,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.refresh, color: Colors.white),
                onPressed: _refreshActivities,
              ),
            ],
          ),
          
          // Contenido principal
          SliverToBoxAdapter(
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: _buildBody(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return Container(
        height: 400,
        child: const Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF667eea)),
          ),
        ),
      );
    }

    if (_errorMessage.isNotEmpty) {
      return _buildErrorView();
    }

    if (_activities.isEmpty) {
      return _buildEmptyState();
    }

    final activitiesForDisplay = _activities.reversed.toList();

    return Column(
      children: [
        // Header con información de seguidos mejorado
        _buildStatsHeader(),
        
        // Lista de actividades
        SlideTransition(
          position: _slideAnimation,
          child: ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
            itemCount: activitiesForDisplay.length + (_isLoadingMore ? 1 : 0),
            itemBuilder: (context, index) {
              if (index == activitiesForDisplay.length) {
                return Container(
                  padding: const EdgeInsets.all(16),
                  child: const Center(
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF667eea)),
                    ),
                  ),
                );
              }

              final activity = activitiesForDisplay[index];
              return AnimatedContainer(
                duration: Duration(milliseconds: 300 + (index * 100)),
                curve: Curves.easeOutBack,
                child: _buildActivityCard(activity),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildStatsHeader() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 2,
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF667eea).withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.people,
              color: Color(0xFF667eea),
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'following_people_count'.trParams(context, {'count': _followingCount.toString()}),
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'activities_found'.trParams(context, {'count': _activities.length.toString()}),
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF667eea), Color(0xFF764ba2)],
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              '${_activities.length}',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      height: 500,
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF667eea), Color(0xFF764ba2)],
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
              Icons.people_outline,
              size: 64,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'feed_empty'.tr(context),
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            _followingCount == 0 
                ? 'not_following_anyone_yet'.tr(context)
                : 'people_no_activities'.tr(context),
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 32),
          Container(
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF667eea), Color(0xFF764ba2)],
              ),
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF667eea).withOpacity(0.3),
                  spreadRadius: 1,
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: ElevatedButton.icon(
              onPressed: () {
                Navigator.pushNamed(context, AppRoutes.userHome);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                shadowColor: Colors.transparent,
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24),
                ),
              ),
              icon: const Icon(Icons.person_add, color: Colors.white),
              label: Text(
                'find_users'.tr(context),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorView() {
    return Container(
      height: 400,
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.red.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.error_outline,
              size: 64,
              color: Colors.red,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'error_loading_activities'.tr(context),
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.red,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            _errorMessage,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 32),
          ElevatedButton.icon(
            onPressed: _refreshActivities,
            icon: const Icon(Icons.refresh),
            label: Text('retry'.tr(context)),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
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
    
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: typeColor.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _navigateToActivityDetail(activity),
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header con usuario mejorado
                Row(
                  children: [
                    _buildUserAvatar(activity),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _getUserDisplayName(activity),
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                              color: Color(0xFF2C3E50),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Icon(
                                Icons.access_time,
                                size: 14,
                                color: Colors.grey[600],
                              ),
                              const SizedBox(width: 6),
                              Text(
                                _formatRelativeTime(activity.startTime),
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: typeColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        typeIcon,
                        size: 20,
                        color: typeColor,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                
                // Nombre de la actividad con diseño mejorado
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        typeColor.withOpacity(0.08),
                        typeColor.withOpacity(0.04),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: typeColor.withOpacity(0.2),
                      width: 1,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: typeColor.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              typeString,
                              style: TextStyle(
                                color: typeColor,
                                fontWeight: FontWeight.bold,
                                fontSize: 10,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        activity.name,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                          color: Color(0xFF2C3E50),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                
                // Estadísticas mejoradas
                Container(
                  padding: const EdgeInsets.all(16),
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
                          'distance'.tr(context),
                          _formatDistance(activity.distance),
                          const Color(0xFF667eea),
                        ),
                      ),
                      Container(
                        width: 1,
                        height: 40,
                        color: Colors.grey[300],
                        margin: const EdgeInsets.symmetric(horizontal: 12),
                      ),
                      Expanded(
                        child: _buildEnhancedStatChip(
                          Icons.timer,
                          'time'.tr(context),
                         activity.formatDuration(),
                          const Color(0xFF764ba2),
                        ),
                      ),
                      if (activity.averageSpeed > 0) ...[
                        Container(
                          width: 1,
                          height: 40,
                          color: Colors.grey[300],
                          margin: const EdgeInsets.symmetric(horizontal: 12),
                        ),
                        Expanded(
                          child: _buildEnhancedStatChip(
                            Icons.speed,
                            'speed'.tr(context),
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

  Widget _buildEnhancedStatChip(IconData icon, String label, String value, Color color) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: TextStyle(
            color: color,
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(
            color: Colors.grey[600],
            fontSize: 11,
            fontWeight: FontWeight.w500,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  String _formatRelativeTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);
    
    if (difference.inDays > 0) {
      if (difference.inDays == 1) {
        return 'yesterday'.tr(context);
      } else if (difference.inDays < 7) {
        return '${difference.inDays} ${'days_ago'.tr(context)}';
      } else {
        return DateFormat('dd/MM/yyyy').format(dateTime);
      }
    } else if (difference.inHours > 0) {
      return '${difference.inHours}${'hours'.tr(context)} ${'ago'.tr(context)}';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}${'min'.tr(context)} ${'ago'.tr(context)}';
    } else {
      return 'now'.tr(context);
    }
  }
}