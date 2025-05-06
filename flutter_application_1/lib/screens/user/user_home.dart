import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_application_1/config/routes.dart';
import 'package:flutter_application_1/services/auth_service.dart';
import 'package:flutter_application_1/services/socket_service.dart';
import 'package:flutter_application_1/screens/chat/chat_list.dart';
import 'package:flutter_application_1/providers/activity_provider_tracking.dart';
import 'package:flutter_application_1/models/activity.dart';
import 'package:flutter_application_1/services/activity_service.dart';
import 'package:flutter_application_1/services/http_service.dart';
import 'package:intl/intl.dart';
import 'package:flutter_application_1/screens/activity/activity_detail_screen.dart';

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
  
  @override
  void initState() {
    super.initState();
    
    // Verificar si hay actividades de tracking activas cuando se carga la pantalla
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkActiveTrackings();
      _loadUserActivities();
    });
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
          status = 'Conectado';
          break;
        case SocketStatus.connecting:
          color = Colors.amber;
          status = 'Conectando...';
          break;
        case SocketStatus.disconnected:
          color = Colors.red;
          status = 'Desconectado';
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
      appBar: AppBar(
        title: const Text('EA Grup 1'),
        actions: [
          // Indicador de notificaciones
          
          // Botón de chat
          IconButton(
            icon: const Icon(Icons.chat),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const ChatListScreen()),
              );
            },
            tooltip: 'Chat',
          ),
          
          // Botón de cerrar sesión
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await authService.logout(socketService);
              Navigator.pushReplacementNamed(context, AppRoutes.login);
            },
            tooltip: 'Cerrar sesión',
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
                          'Bienvenido, ${user?.username ?? "Usuario"}',
                          style: const TextStyle(
                            fontSize: 24.0,
                            fontWeight: FontWeight.bold,
                            color: Colors.deepPurple,
                          ),
                        ),
                        const SizedBox(height: 16.0),
                        const Text(
                          'Aquí puedes gestionar tus actividades deportivas y seguir tu progreso.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
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
                          label: const Text('Ver Perfil'),
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
                const SizedBox(height: 32.0),
                _buildQuickStats(context, user),
                const SizedBox(height: 32.0),
                _buildRecentActivities(context),
                
                // Usuarios conectados (Updated section)
                const SizedBox(height: 32.0),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Usuarios conectados',
                      style: TextStyle(
                        fontSize: 20.0,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8.0),
                    Text(
                      'Total: ${socketService.onlineUsers.length} usuarios en línea',
                      style: TextStyle(
                        color: Colors.grey[600],
                      ),
                    ),
                    const SizedBox(height: 16.0),
                    
                    // IMPROVED: Display usernames instead of IDs
                    socketService.onlineUsers.isEmpty
                        ? Text(
                            'No hay usuarios conectados',
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
        label: const Text('Iniciar Actividad'),
        backgroundColor: const Color.fromARGB(255, 180, 153, 225),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }

  Widget _buildQuickStats(BuildContext context, user) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Estadísticas rápidas',
          style: TextStyle(
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
                'Nivel',
                '${user?.level ?? 1}',
                Icons.star,
                Colors.amber,
              ),
            ),
            const SizedBox(width: 16.0),
            Expanded(
              child: _buildStatCard(
                context,
                'Distancia',
                '${((user?.totalDistance ?? 0) / 1000).toStringAsFixed(2)} km',
                Icons.directions_run,
                Colors.green,
              ),
            ),
            const SizedBox(width: 16.0),
            Expanded(
              child: _buildStatCard(
                context,
                'Tiempo',
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
            const Text(
              'Actividades recientes',
              style: TextStyle(
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
              child: Text(_showAllActivities ? 'Ver menos' : 'Ver todas'),
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
                          'No tienes actividades registradas',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Comienza una nueva actividad con el botón "Iniciar Actividad"',
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
                              'Ver todas (${_userActivities.length})',
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