import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_application_1/config/routes.dart';
import 'package:flutter_application_1/services/auth_service.dart';
import 'package:flutter_application_1/services/socket_service.dart';
import 'package:flutter_application_1/services/follow_service.dart';
import 'package:flutter_application_1/providers/activity_provider_tracking.dart';
import 'package:flutter_application_1/models/activity.dart';
import 'package:flutter_application_1/models/user.dart';
import 'package:flutter_application_1/services/activity_service.dart';
import 'package:flutter_application_1/services/http_service.dart';
import 'package:intl/intl.dart';
import 'package:flutter_application_1/screens/activity/activity_detail_screen.dart';
import 'package:flutter_application_1/widgets/custom_drawer.dart';
import 'package:flutter_application_1/widgets/user_list_title.dart';
import 'package:flutter_application_1/extensions/string_extensions.dart';
import 'package:flutter_application_1/widgets/achievement_progress_widget.dart';
import 'dart:async';
import 'dart:math' as math;

class UserHomeScreen extends StatefulWidget {
  const UserHomeScreen({Key? key}) : super(key: key);

  @override
  _UserHomeScreenState createState() => _UserHomeScreenState();
}

class _UserHomeScreenState extends State<UserHomeScreen> with TickerProviderStateMixin {
  bool _isCheckingTrackings = false;
  bool _isLoadingActivities = false;
  List<Activity> _userActivities = [];
  bool _showAllActivities = false;
  
  // Variables para búsqueda
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  List<User> _searchResults = [];
  bool _isSearching = false;
  bool _isSearchExpanded = false;
  Timer? _debounceTimer;
  
  // Variables para animaciones
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  
  // Variables para métricas y gráficos
  Map<String, int> _weeklyActivityCount = {};
  Map<ActivityType, double> _activityTypeDistribution = {};
  List<double> _last7DaysDistance = [];
  
  @override
  void initState() {
    super.initState();
    
    // Inicializar controladores de animación
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _slideController = AnimationController(
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
      parent: _slideController,
      curve: Curves.easeOutBack,
    ));
    
    _searchController.addListener(_onSearchChanged);
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkActiveTrackings();
      _loadUserActivities();
      _startAnimations();
    });
  }
  
  void _startAnimations() {
    _fadeController.forward();
    Future.delayed(const Duration(milliseconds: 200), () {
      _slideController.forward();
    });
  }
  
  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    _debounceTimer?.cancel();
    _fadeController.dispose();
    _slideController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    if (_debounceTimer?.isActive ?? false) _debounceTimer!.cancel();
    
    _debounceTimer = Timer(const Duration(milliseconds: 500), () {
      final query = _searchController.text.trim();
      if (query.isNotEmpty) {
        _searchUsers(query);
      } else {
        setState(() {
          _searchResults = [];
          _isSearching = false;
        });
      }
    });
  }

  Future<void> _searchUsers(String query) async {
    if (query.isEmpty) return;

    setState(() {
      _isSearching = true;
    });

    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      final followService = Provider.of<FollowService>(context, listen: false);
      
      final results = await followService.searchUsers(query, authService.accessToken);
      final currentUserId = authService.currentUser?.id;
      final filteredResults = results.where((user) => user.id != currentUserId).toList();
      
      if (mounted) {
        setState(() {
          _searchResults = filteredResults;
          _isSearching = false;
        });
      }
    } catch (e) {
      print('Error buscando usuarios: $e');
      if (mounted) {
        setState(() {
          _searchResults = [];
          _isSearching = false;
        });
      }
    }
  }

  void _toggleSearchExpansion() {
    setState(() {
      _isSearchExpanded = !_isSearchExpanded;
      if (!_isSearchExpanded) {
        _searchController.clear();
        _searchResults = [];
        _searchFocusNode.unfocus();
      } else {
        Future.delayed(const Duration(milliseconds: 100), () {
          _searchFocusNode.requestFocus();
        });
      }
    });
  }

  void _navigateToUserProfile(User user) {
    Navigator.pushNamed(
      context,
      AppRoutes.userProfile,
      arguments: {'userId': user.id},
    );
  }

  Future<void> _checkActiveTrackings() async {
    if (_isCheckingTrackings) return;
    
    setState(() {
      _isCheckingTrackings = true;
    });

    try {
      final trackingProvider = Provider.of<ActivityTrackingProvider>(context, listen: false);
      final authService = Provider.of<AuthService>(context, listen: false);

      if (authService.currentUser != null) {
        await trackingProvider.checkActiveTrackings();
        
        if (trackingProvider.currentTracking != null && mounted) {
          Navigator.pushNamed(
            context,
            AppRoutes.tracking,
            arguments: {
              'activityType': trackingProvider.currentTracking!.activityType,
              'resuming': true,
            },
          );
        }
      }
    } catch (e) {
      print('Error checking active trackings: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isCheckingTrackings = false;
        });
      }
    }
  }

  Future<void> _loadUserActivities() async {
    final authService = Provider.of<AuthService>(context, listen: false);
    if (authService.currentUser == null) return;

    setState(() {
      _isLoadingActivities = true;
    });

    try {
      final httpService = HttpService(authService);
      final activityService = ActivityService(httpService);
      
      final activities = await activityService.getActivitiesByUserId(
        authService.currentUser!.id
      );
      
      activities.sort((a, b) => b.startTime.compareTo(a.startTime));
      
      if (mounted) {
        setState(() {
          _userActivities = activities;
          _isLoadingActivities = false;
        });
        _calculateMetrics();
      }
    } catch (e) {
      print('Error loading user activities: $e');
      if (mounted) {
        setState(() {
          _isLoadingActivities = false;
        });
      }
    }
  }
  
  void _calculateMetrics() {
    // Calcular actividades por día de la semana
    _weeklyActivityCount = {};
    for (int i = 1; i <= 7; i++) {
      _weeklyActivityCount[_getDayName(i)] = 0;
    }
    
    // Calcular distribución por tipo de actividad
    _activityTypeDistribution = {};
    
    // Calcular distancia de los últimos 7 días
    _last7DaysDistance = List.filled(7, 0.0);
    final now = DateTime.now();
    
    for (final activity in _userActivities) {
      // Actividades por día de la semana
      final dayName = _getDayName(activity.startTime.weekday);
      _weeklyActivityCount[dayName] = (_weeklyActivityCount[dayName] ?? 0) + 1;
      
      // Distribución por tipo
      _activityTypeDistribution[activity.type] = 
          (_activityTypeDistribution[activity.type] ?? 0) + (activity.distance ?? 0);
      
      // Últimos 7 días
      final daysDiff = now.difference(activity.startTime).inDays;
      if (daysDiff >= 0 && daysDiff < 7) {
        _last7DaysDistance[6 - daysDiff] += (activity.distance ?? 0) / 1000; // km
      }
    }
  }
  
  String _getDayName(int weekday) {
    switch (weekday) {
      case 1: return 'monday'.tr(context);
      case 2: return 'tuesday'.tr(context);
      case 3: return 'wednesday'.tr(context);
      case 4: return 'thursday'.tr(context);
      case 5: return 'friday'.tr(context);
      case 6: return 'saturday'.tr(context);
      case 7: return 'sunday'.tr(context);
      default: return 'monday'.tr(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);
    final socketService = Provider.of<SocketService>(context);
    final user = authService.currentUser;

    return Scaffold(
      drawer: const CustomDrawer(currentRoute: AppRoutes.userHome),
      body: CustomScrollView(
        slivers: [
          // App Bar moderno con gradiente
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
                            'welcome_user'.trParams(context, {'username': user?.username ?? 'user'.tr(context)}),
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
                          child: Text(
                            'welcome_back'.tr(context),
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 16,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.notifications_outlined, color: Colors.white),
                onPressed: () {
                  Navigator.pushNamed(context, AppRoutes.notifications);
                },
              ),
            ],
          ),
          
          // Contenido principal
          SliverToBoxAdapter(
            child: SlideTransition(
              position: _slideAnimation,
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Indicador de conexión mejorado
                      _buildConnectionIndicator(socketService),
                      const SizedBox(height: 20),
                      
                      // Estadísticas principales mejoradas
                      _buildEnhancedQuickStats(user),
                      const SizedBox(height: 24),
                      
                      // Gráfico de actividad semanal
                      _buildWeeklyActivityChart(),
                      const SizedBox(height: 24),
                      
                      // Gráfico de progreso de los últimos 7 días
                      _buildProgressChart(),
                      const SizedBox(height: 24),
                      
                      // Distribución de tipos de actividad
                      _buildActivityTypeDistribution(),
                      const SizedBox(height: 24),
                      
                      // Búsqueda de usuarios
                      _buildUserSearch(),
                      const SizedBox(height: 24),
                      
                      // Logros con mejor diseño
                      _buildAchievementsSection(),
                      const SizedBox(height: 24),
                      
                      // Actividades recientes mejoradas
                      _buildEnhancedRecentActivities(context),
                      const SizedBox(height: 24),
                      
                      // Usuarios online mejorado
                      _buildEnhancedOnlineUsers(socketService),
                      
                      const SizedBox(height: 100), // Espacio para FAB
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.pushNamed(context, AppRoutes.activitySelection);
        },
        icon: const Icon(Icons.add, color: Colors.white),
        label: Text(
          'start_activity'.tr(context),
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color(0xFF667eea),
        elevation: 8,
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }
  
  Widget _buildConnectionIndicator(SocketService socketService) {
    Color color;
    String status;
    IconData icon;
    
    switch (socketService.socketStatus) {
      case SocketStatus.connected:
        color = Colors.green;
        status = 'connected'.tr(context);
        icon = Icons.wifi;
        break;
      case SocketStatus.connecting:
        color = Colors.amber;
        status = 'connecting'.tr(context);
        icon = Icons.wifi_protected_setup;
        break;
      case SocketStatus.disconnected:
        color = Colors.red;
        status = 'disconnected'.tr(context);
        icon = Icons.wifi_off;
        break;
    }
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 8),
          Text(
            status,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(width: 8),
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildEnhancedQuickStats(User? user) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'quick_summary'.tr(context),
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildEnhancedStatCard(
                title: 'level'.tr(context),
                value: '${user?.level ?? 1}',
                icon: Icons.star,
                color: Colors.amber,
                progress: ((user?.level ?? 1) % 10) / 10,
                subtitle: '${'next'.tr(context)}: ${((user?.level ?? 1) + 1)}',
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildEnhancedStatCard(
                title: 'distance'.tr(context),
                value: '${((user?.totalDistance ?? 0) / 1000).toStringAsFixed(1)}',
                unit: 'km',
                icon: Icons.directions_run,
                color: Colors.green,
                progress: math.min(((user?.totalDistance ?? 0) / 1000) / 100, 1.0),
                subtitle: '${'goal'.tr(context)}: 100km',
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildEnhancedStatCard(
                title: 'time'.tr(context),
                value: '${user?.totalTime ?? 0}',
                unit: 'min'.tr(context),
                icon: Icons.timer,
                color: Colors.blue,
                progress: math.min((user?.totalTime ?? 0) / 1000, 1.0),
                subtitle: '${'goal'.tr(context)}: 1000${'min'.tr(context)}',
              ),
            ),
          ],
        ),
      ],
    );
  }
  
  Widget _buildEnhancedStatCard({
    required String title,
    required String value,
    String? unit,
    required IconData icon,
    required Color color,
    required double progress,
    String? subtitle,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.1),
            spreadRadius: 2,
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                value,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (unit != null) ...[
                const SizedBox(width: 4),
                Text(
                  unit,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          // Barra de progreso
          Container(
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(2),
            ),
            child: FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: progress,
              child: Container(
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 10,
                color: Colors.grey[500],
              ),
            ),
          ],
        ],
      ),
    );
  }
  
  Widget _buildWeeklyActivityChart() {
    return Container(
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'weekly_activity'.tr(context),
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 120,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: _weeklyActivityCount.entries.map((entry) {
                final count = entry.value;
                final maxCount = _weeklyActivityCount.values.isEmpty ? 1 : 
                    _weeklyActivityCount.values.reduce(math.max);
                final height = maxCount == 0 ? 0.0 : (count / maxCount) * 80;
                
                return Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Text(
                      count.toString(),
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      width: 24,
                      height: math.max(height, count > 0 ? 8 : 0),
                      decoration: BoxDecoration(
                        color: count > 0 ? const Color(0xFF667eea) : Colors.grey[300],
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      entry.key,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildProgressChart() {
    return Container(
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'last_7_days_km'.tr(context),
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 100,
            child: CustomPaint(
              size: const Size(double.infinity, 100),
              painter: LineChartPainter(_last7DaysDistance),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(7, (index) {
              final date = DateTime.now().subtract(Duration(days: 6 - index));
              return Text(
                DateFormat('dd/MM').format(date),
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              );
            }),
          ),
        ],
      ),
    );
  }
  
  Widget _buildActivityTypeDistribution() {
    if (_activityTypeDistribution.isEmpty) {
      return const SizedBox.shrink();
    }
    
    return Container(
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'activity_types'.tr(context),
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          ..._activityTypeDistribution.entries.map((entry) {
            IconData icon;
            Color color;
            String name;
            
            switch (entry.key) {
              case ActivityType.running:
                icon = Icons.directions_run;
                color = Colors.green;
                name = 'running'.tr(context);
                break;
              case ActivityType.cycling:
                icon = Icons.directions_bike;
                color = Colors.blue;
                name = 'cycling'.tr(context);
                break;
              case ActivityType.walking:
                icon = Icons.directions_walk;
                color = Colors.purple;
                name = 'walking'.tr(context);
                break;
              case ActivityType.hiking:
                icon = Icons.terrain;
                color = Colors.orange;
                name = 'hiking'.tr(context);
                break;
            }
            
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(icon, color: color, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              name,
                              style: const TextStyle(fontWeight: FontWeight.w600),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Container(
                          height: 6,
                          decoration: BoxDecoration(
                            color: Colors.grey[200],
                            borderRadius: BorderRadius.circular(3),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ],
      ),
    );
  }
  
  Widget _buildAchievementsSection() {
    return Container(
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'achievements_section'.tr(context),
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              TextButton(
                onPressed: () {
                  Navigator.pushNamed(context, AppRoutes.achievements);
                },
                child: Text('view_all_achievements'.tr(context)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const AchievementProgressWidget(),
        ],
      ),
    );
  }
  
  Widget _buildEnhancedRecentActivities(BuildContext context) {
    return Container(
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'recent_activities_section'.tr(context),
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              TextButton(
                onPressed: () {
                  setState(() {
                    _showAllActivities = !_showAllActivities;
                  });
                },
                child: Text(_showAllActivities ? 'view_less'.tr(context) : 'view_all'.tr(context)),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          _isLoadingActivities
              ? const Center(child: CircularProgressIndicator())
              : _userActivities.isEmpty
                  ? _buildEmptyState()
                  : Column(
                      children: [
                        ...(_showAllActivities
                            ? _userActivities
                            : _userActivities.take(3))
                            .map((activity) => _buildEnhancedActivityCard(context, activity)),
                      ],
                    ),
        ],
      ),
    );
  }
  
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.directions_run_outlined,
              size: 48,
              color: Colors.grey[400],
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'no_activities_yet'.tr(context),
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'start_first_activity'.tr(context),
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildEnhancedActivityCard(BuildContext context, Activity activity) {
    IconData activityIcon;
    Color activityColor;

    switch (activity.type) {
      case ActivityType.running:
        activityIcon = Icons.directions_run;
        activityColor = Colors.green;
        break;
      case ActivityType.cycling:
        activityIcon = Icons.directions_bike;
        activityColor = Colors.blue;
        break;
      case ActivityType.walking:
        activityIcon = Icons.directions_walk;
        activityColor = Colors.purple;
        break;
      case ActivityType.hiking:
        activityIcon = Icons.terrain;
        activityColor = Colors.orange;
        break;
      default:
        activityIcon = Icons.directions_run;
        activityColor = Colors.green;
    }

    final now = DateTime.now();
    final difference = now.difference(activity.startTime);
    String timeAgo;
    
    if (difference.inDays > 0) {
      timeAgo = '${difference.inDays} ${'days'.tr(context)} ${'ago'.tr(context)}';
    } else if (difference.inHours > 0) {
      timeAgo = '${difference.inHours} ${'hours'.tr(context)} ${'ago'.tr(context)}';
    } else {
      timeAgo = '${difference.inMinutes} ${'min'.tr(context)} ${'ago'.tr(context)}';
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: activityColor.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: activityColor.withOpacity(0.2)),
      ),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ActivityDetailScreen(activity: activity),
            ),
          );
        },
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: activityColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                activityIcon,
                color: activityColor,
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    activity.name,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    timeAgo,
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  activity.formatDistance(),
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                Text(
                  '${activity.duration ?? 0} ${'min'.tr(context)}',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildEnhancedOnlineUsers(SocketService socketService) {
    return Container(
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'online_users_section'.tr(context),
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${socketService.onlineUsers.length}',
                  style: const TextStyle(
                    color: Colors.green,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          socketService.onlineUsers.isEmpty
              ? Text(
                  'no_users_online'.tr(context),
                  style: TextStyle(
                    color: Colors.grey[500],
                    fontStyle: FontStyle.italic,
                  ),
                )
              : Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: socketService.onlineUsers.map((userInfo) {
                    final username = userInfo['username'] ?? 'user'.tr(context);
                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.green.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.green.withOpacity(0.3)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 8,
                            height: 8,
                            decoration: const BoxDecoration(
                              color: Colors.green,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            username,
                            style: const TextStyle(
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
        ],
      ),
    );
  }
  
  Widget _buildUserSearch() {
    return Container(
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'search_users_section'.tr(context),
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              IconButton(
                icon: Icon(
                  _isSearchExpanded ? Icons.expand_less : Icons.expand_more,
                  color: Colors.grey[600],
                ),
                onPressed: _toggleSearchExpansion,
              ),
            ],
          ),
          
          AnimatedCrossFade(
            duration: const Duration(milliseconds: 300),
            crossFadeState: _isSearchExpanded 
                ? CrossFadeState.showSecond 
                : CrossFadeState.showFirst,
            firstChild: const SizedBox.shrink(),
            secondChild: Column(
              children: [
                const SizedBox(height: 16),
                TextField(
                  controller: _searchController,
                  focusNode: _searchFocusNode,
                  decoration: InputDecoration(
                    hintText: 'search_by_username'.tr(context),
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              _searchController.clear();
                              setState(() {
                                _searchResults = [];
                              });
                            },
                          )
                        : null,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                    fillColor: Colors.grey[50],
                  ),
                ),
                
                if (_isSearching || _searchResults.isNotEmpty || (_searchController.text.isNotEmpty && _searchResults.isEmpty)) ...[
                  const SizedBox(height: 16),
                  _buildSearchResults(),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildSearchResults() {
    if (_isSearching) {
      return Container(
        height: 100,
        decoration: BoxDecoration(
          color: Colors.grey[50],
          borderRadius: BorderRadius.circular(12),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CircularProgressIndicator(),
              const SizedBox(height: 8),
              Text('searching_users_loading'.tr(context)),
            ],
          ),
        ),
      );
    }

    if (_searchController.text.isNotEmpty && _searchResults.isEmpty) {
      return Container(
        height: 100,
        decoration: BoxDecoration(
          color: Colors.grey[50],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey[200]!),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.search_off,
                size: 32,
                color: Colors.grey[400],
              ),
              const SizedBox(height: 8),
              Text(
                'no_users_found_search'.tr(context),
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Container(
      constraints: const BoxConstraints(maxHeight: 300),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: ListView.separated(
        shrinkWrap: true,
        padding: const EdgeInsets.all(8),
        itemCount: _searchResults.length,
        separatorBuilder: (context, index) => const Divider(height: 1),
        itemBuilder: (context, index) {
          final user = _searchResults[index];
          return UserListTile(
            user: user,
            showFollowButton: true,
            onUserTap: () => _navigateToUserProfile(user),
            onFollowChanged: () {
              print('Usuario ${user.username} seguido/no seguido');
            },
          );
        },
      ),
    );
  }
}

// Painter personalizado para el gráfico de líneas
class LineChartPainter extends CustomPainter {
  final List<double> data;
  
  LineChartPainter(this.data);
  
  @override
  void paint(Canvas canvas, Size size) {
    if (data.isEmpty) return;
    
    final paint = Paint()
      ..color = const Color(0xFF667eea)
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
      
    final fillPaint = Paint()
      ..color = const Color(0xFF667eea).withOpacity(0.1)
      ..style = PaintingStyle.fill;
    
    final maxValue = data.isEmpty ? 1.0 : data.reduce(math.max);
    final minValue = data.isEmpty ? 0.0 : data.reduce(math.min);
    final range = maxValue - minValue;
    
    final path = Path();
    final fillPath = Path();
    
    for (int i = 0; i < data.length; i++) {
      final x = (i / (data.length - 1)) * size.width;
      final normalizedValue = range > 0 ? (data[i] - minValue) / range : 0;
      final y = size.height - (normalizedValue * size.height * 0.8) - (size.height * 0.1);
      
      if (i == 0) {
        path.moveTo(x, y);
        fillPath.moveTo(x, size.height);
        fillPath.lineTo(x, y);
      } else {
        path.lineTo(x, y);
        fillPath.lineTo(x, y);
      }
    }
    
    fillPath.lineTo(size.width, size.height);
    fillPath.close();
    
    canvas.drawPath(fillPath, fillPaint);
    canvas.drawPath(path, paint);
    
    // Dibujar puntos
    final pointPaint = Paint()
      ..color = const Color(0xFF667eea)
      ..style = PaintingStyle.fill;
      
    for (int i = 0; i < data.length; i++) {
      final x = (i / (data.length - 1)) * size.width;
      final normalizedValue = range > 0 ? (data[i] - minValue) / range : 0;
      final y = size.height - (normalizedValue * size.height * 0.8) - (size.height * 0.1);
      
      canvas.drawCircle(Offset(x, y), 4, pointPaint);
      canvas.drawCircle(Offset(x, y), 2, Paint()..color = Colors.white);
    }
  }
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}