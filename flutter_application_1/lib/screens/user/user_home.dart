import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_application_1/config/routes.dart';
import 'package:flutter_application_1/services/auth_service.dart';
import 'package:flutter_application_1/services/socket_service.dart';
import 'package:flutter_application_1/services/follow_service.dart'; // ✅ NUEVA IMPORTACIÓN
import 'package:flutter_application_1/providers/activity_provider_tracking.dart';
import 'package:flutter_application_1/models/activity.dart';
import 'package:flutter_application_1/models/user.dart'; // ✅ NUEVA IMPORTACIÓN
import 'package:flutter_application_1/services/activity_service.dart';
import 'package:flutter_application_1/services/http_service.dart';
import 'package:intl/intl.dart';
import 'package:flutter_application_1/screens/activity/activity_detail_screen.dart';
import 'package:flutter_application_1/widgets/custom_drawer.dart';
import 'package:flutter_application_1/widgets/user_list_title.dart'; // ✅ NUEVA IMPORTACIÓN
import 'package:flutter_application_1/extensions/string_extensions.dart';
import 'package:flutter_application_1/widgets/achievement_progress_widget.dart';
import 'dart:async'; // ✅ NUEVA IMPORTACIÓN para debouncing

class UserHomeScreen extends StatefulWidget {
  const UserHomeScreen({Key? key}) : super(key: key);

  @override
  _UserHomeScreenState createState() => _UserHomeScreenState();
}

class _UserHomeScreenState extends State<UserHomeScreen> {
  bool _isCheckingTrackings = false; // Tracks if tracking check is in progress
  bool _isLoadingActivities = false;
  List<Activity> _userActivities = [];
  bool _showAllActivities = false;
  
  // ✅ NUEVAS VARIABLES PARA BÚSQUEDA
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  List<User> _searchResults = [];
  bool _isSearching = false;
  bool _isSearchExpanded = false;
  Timer? _debounceTimer;
  
  @override
  void initState() {
    super.initState();
    
    // ✅ NUEVO: Listener para búsqueda con debouncing
    _searchController.addListener(_onSearchChanged);
    
    // Verificar si hay actividades de tracking activas cuando se carga la pantalla
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkActiveTrackings();
      _loadUserActivities();
    });
  }

  // ✅ NUEVO: Limpiar recursos en dispose
  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    _debounceTimer?.cancel();
    super.dispose();
  }

  // ✅ NUEVO: Manejo de cambios en búsqueda con debouncing
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

  // ✅ NUEVO: Búsqueda de usuarios
  Future<void> _searchUsers(String query) async {
    if (query.isEmpty) return;

    setState(() {
      _isSearching = true;
    });

    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      final followService = Provider.of<FollowService>(context, listen: false);
      
      final results = await followService.searchUsers(query, authService.accessToken);
      
      // Filtrar usuario actual de los resultados
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

  // ✅ NUEVO: Expandir/contraer búsqueda
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

  // ✅ NUEVO: Navegar al perfil de usuario
  void _navigateToUserProfile(User user) {
    Navigator.pushNamed(
      context,
      AppRoutes.userProfile,
      arguments: {'userId': user.id},
    );
  }

  // ✅ NUEVO: Widget de búsqueda
  Widget _buildUserSearch() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16.0),
      ),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header con botón expandir/contraer
            Row(
              children: [
                Icon(
                  Icons.search,
                  color: Colors.blue[600],
                  size: 24,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'search_users'.tr(context),
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                IconButton(
                  icon: Icon(
                    _isSearchExpanded ? Icons.expand_less : Icons.expand_more,
                    color: Colors.grey[600],
                  ),
                  onPressed: _toggleSearchExpansion,
                  tooltip: _isSearchExpanded ? 'Contraer' : 'Expandir',
                ),
              ],
            ),
            
            // Campo de búsqueda (expandible)
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
                      hintText: 'search_users_hint'.tr(context),
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
                  
                  // Resultados de búsqueda
                  if (_isSearching || _searchResults.isNotEmpty || (_searchController.text.isNotEmpty && _searchResults.isEmpty)) ...[
                    const SizedBox(height: 16),
                    _buildSearchResults(),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ✅ NUEVO: Widget de resultados de búsqueda
  Widget _buildSearchResults() {
    if (_isSearching) {
      return Container(
        height: 100,
        decoration: BoxDecoration(
          color: Colors.grey[50],
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 8),
              Text('Buscando usuarios...'),
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
                'no_users_found'.tr(context),
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

  // Verificar si hay actividades de tracking activas
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

  // Load user activities
  Future<void> _loadUserActivities() async {
    final authService = Provider.of<AuthService>(context, listen: false);
    if (authService.currentUser == null) return;

    setState(() {
      _isLoadingActivities = true;
    });

    try {
      // Create activity service
      final httpService = HttpService(authService);
      final activityService = ActivityService(httpService);
      
      // Get user activities
      final activities = await activityService.getActivitiesByUserId(
        authService.currentUser!.id
      );
      
      // Sort by date - most recent first
      activities.sort((a, b) => b.startTime.compareTo(a.startTime));
      
      if (mounted) {
        setState(() {
          _userActivities = activities;
          _isLoadingActivities = false;
        });
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

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);
    final socketService = Provider.of<SocketService>(context);
    final user = authService.currentUser;
    

    // Mostrar estado de la conexión de Socket.IO
    Widget connectionIndicator() {
      Color color;
      String status;
      
      switch (socketService.socketStatus) {
        case SocketStatus.connected:
          color = Colors.green;
          status = 'connected'.tr(context);
          break;
        case SocketStatus.connecting:
          color = Colors.amber;
          status = 'connecting'.tr(context);
          break;
        case SocketStatus.disconnected:
          color = Colors.red;
          status = 'disconnected'.tr(context);
          break;
      }
      
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: color.withOpacity(0.2),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 4),
            Text(
              status,
              style: TextStyle(
                color: color,
                fontSize: 12,
              ),
            ),
          ],
        ),
      );
    }

    return Scaffold(
      drawer: const CustomDrawer(currentRoute: AppRoutes.userHome),
      appBar: AppBar(
        title: const Text('Trazer'),
        actions: [
          // Indicador de notificaciones
          
          // Botón de chat
          IconButton(
            icon: const Icon(Icons.notifications),
            onPressed: () {
              Navigator.pushNamed(context, AppRoutes.notifications);
            },
            tooltip: 'notifications'.tr(context),
          ),
          
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await _loadUserActivities();
        },
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Indicador de conexión
                Center(
                  child: connectionIndicator(),
                ),
                const SizedBox(height: 16),
                
                Center(
                  child: Container(
                    padding: const EdgeInsets.all(24.0),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16.0),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withOpacity(0.2),
                          spreadRadius: 1,
                          blurRadius: 6,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        Text(
                          'welcome_user'.trParams(context, {'username': user?.username ?? 'Usuario'}),
                          style: const TextStyle(
                            fontSize: 24.0,
                            fontWeight: FontWeight.bold,
                            color: Colors.deepPurple,
                          ),
                        ),
                        const SizedBox(height: 16.0),
                        Text(
                          'activity_management'.tr(context),
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 16.0,
                            color: Colors.black54,
                          ),
                        ),
                        const SizedBox(height: 24.0),
                        ElevatedButton.icon(
                          onPressed: () {
                            Navigator.pushNamed(context, AppRoutes.userProfile);
                          },
                          icon: const Icon(Icons.person),
                          label: Text('view_profile'.tr(context)),
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 24.0,
                              vertical: 12.0,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8.0),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24.0), // ✅ CAMBIO MENOR: reducido de 32 a 24
                
                // ✅ NUEVO: Buscador de usuarios - INSERTADO AQUÍ
                _buildUserSearch(),
                const SizedBox(height: 24.0),
                
                _buildQuickStats(context, user),
                const SizedBox(height: 32.0),
                const AchievementProgressWidget(),
                _buildRecentActivities(context),
                
                // Usuarios conectados (Updated section)
                const SizedBox(height: 32.0),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'users_online'.tr(context),
                      style: const TextStyle(
                        fontSize: 20.0,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8.0),
                    Text(
                      '${('total_online').tr(context)} ${socketService.onlineUsers.length} ${('users').tr(context)}',
                      style: TextStyle(
                        color: Colors.grey[600],
                      ),
                    ),
                    const SizedBox(height: 16.0),
                    
                    // IMPROVED: Display usernames instead of IDs
                    socketService.onlineUsers.isEmpty
                        ? Text(
                            'no_users_online'.tr(context),
                            style: TextStyle(
                              color: Colors.grey[500],
                              fontStyle: FontStyle.italic,
                            ),
                          )
                        : Wrap(
                            spacing: 8.0,
                            runSpacing: 8.0,
                            children: socketService.onlineUsers.map((userInfo) {
                              final username = userInfo['username'] ?? 'Usuario';
                              return Chip(
                                avatar: CircleAvatar(
                                  backgroundColor: Colors.green,
                                  radius: 4,
                                ),
                                label: Text(username),
                                backgroundColor: Colors.green.withOpacity(0.1),
                              );
                            }).toList(),
                          ),
                  ],
                ),
                
                // Altura adicional para evitar que el botón flotante tape contenido
                const SizedBox(height: 80),
              ],
            ),
          ),
        ),
      ),
      // Botón flotante para iniciar actividad
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.pushNamed(context, AppRoutes.activitySelection);
        },
        icon: const Icon(Icons.add),
        label: Text('start_activity'.tr(context)),
        backgroundColor: const Color.fromARGB(255, 180, 153, 225),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }

  Widget _buildQuickStats(BuildContext context, user) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'quick_stats'.tr(context),
          style: const TextStyle(
            fontSize: 20.0,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16.0),
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                context,
                'level'.tr(context),
                '${user?.level ?? 1}',
                Icons.star,
                Colors.amber,
              ),
            ),
            const SizedBox(width: 16.0),
            Expanded(
              child: _buildStatCard(
                context,
                'distance'.tr(context),
                '${((user?.totalDistance ?? 0) / 1000).toStringAsFixed(2)} km',
                Icons.directions_run,
                Colors.green,
              ),
            ),
            const SizedBox(width: 16.0),
            Expanded(
              child: _buildStatCard(
                context,
                'time'.tr(context),
                '${user?.totalTime ?? 0} min',
                Icons.timer,
                Colors.blue,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatCard(
    BuildContext context,
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.0),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2),
            spreadRadius: 1,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(
            icon,
            color: color,
            size: 32.0,
          ),
          const SizedBox(height: 8.0),
          Text(
            title,
            style: const TextStyle(
              fontSize: 14.0,
              color: Colors.black54,
            ),
          ),
          const SizedBox(height: 4.0),
          Text(
            value,
            style: const TextStyle(
              fontSize: 18.0,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentActivities(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'recent_activities'.tr(context),
              style: const TextStyle(
                fontSize: 20.0,
                fontWeight: FontWeight.bold,
              ),
            ),
            TextButton(
              onPressed: () {
                setState(() {
                  _showAllActivities = !_showAllActivities;
                });
              },
              child: Text(_showAllActivities 
                ? 'view_less'.tr(context) 
                : 'view_all'.tr(context)),
            ),
          ],
        ),
        const SizedBox(height: 8.0),
        
        _isLoadingActivities
            ? const Center(child: CircularProgressIndicator())
            : _userActivities.isEmpty
                ? Center(
                    child: Column(
                      children: [
                        Icon(
                          Icons.directions_run_outlined,
                          size: 48,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'no_activities'.tr(context),
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'start_new_activity'.tr(context),
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.grey[500],
                          ),
                        ),
                      ],
                    ),
                  )
                : Column(
                    children: [
                      ...(_showAllActivities
                          ? _userActivities
                          : _userActivities.take(3))
                          .map((activity) => _buildActivityCard(context, activity)),
                      if (_userActivities.length > 3 && !_showAllActivities)
                        Center(
                          child: TextButton.icon(
                            onPressed: () {
                              setState(() {
                                _showAllActivities = true;
                              });
                            },
                            icon: const Icon(Icons.expand_more),
                            label: Text(
                              '${('view_all').tr(context)} (${_userActivities.length})',
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                    ],
                  ),
      ],
    );
  }

  Widget _buildActivityCard(BuildContext context, Activity activity) {
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

    // Format the date based on how recent it is
    String formattedDate;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = DateTime(now.year, now.month, now.day - 1);
    final activityDate = DateTime(
        activity.startTime.year, activity.startTime.month, activity.startTime.day);

    if (activityDate == today) {
      formattedDate = 'Hoy, ${DateFormat('HH:mm').format(activity.startTime)}';
    } else if (activityDate == yesterday) {
      formattedDate = 'Ayer, ${DateFormat('HH:mm').format(activity.startTime)}';
    } else {
      formattedDate =
          'Hace ${now.difference(activityDate).inDays} días, ${DateFormat('HH:mm').format(activity.startTime)}';
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12.0),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12.0),
      ),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: activityColor.withOpacity(0.2),
          child: Icon(
            activityIcon,
            color: activityColor,
          ),
        ),
        title: Text(
          activity.name,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: Text(
          formattedDate,
          style: const TextStyle(
            fontSize: 12.0,
          ),
        ),
        trailing: Text(
          activity.formatDistance(),
          style: const TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ActivityDetailScreen(activity: activity),
            ),
          );
        },
      ),
    );
  }
}