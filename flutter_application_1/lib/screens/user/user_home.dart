import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_application_1/config/routes.dart';
import 'package:flutter_application_1/services/auth_service.dart';
import 'package:flutter_application_1/services/socket_service.dart';
import 'package:flutter_application_1/screens/chat/chat_list.dart';

class UserHomeScreen extends StatelessWidget {
  const UserHomeScreen({Key? key}) : super(key: key);

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
      body: SingleChildScrollView(
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
            ],
          ),
        ),
      ),
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
    // Datos de muestra para actividades recientes
    final List<Map<String, dynamic>> recentActivities = [
      {
        'name': 'Carrera matutina',
        'date': 'Hoy, 08:00 AM',
        'type': 'running',
        'distance': '5.2 km',
      },
      {
        'name': 'Vuelta en bicicleta',
        'date': 'Ayer, 10:30 AM',
        'type': 'cycling',
        'distance': '15.7 km',
      },
      {
        'name': 'Paseo por la tarde',
        'date': 'Hace 2 días, 06:00 PM',
        'type': 'walking',
        'distance': '3.1 km',
      },
    ];

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
                // Navegar a todas las actividades
              },
              child: const Text('Ver todas'),
            ),
          ],
        ),
        const SizedBox(height: 8.0),
        ...recentActivities.map((activity) => _buildActivityCard(context, activity)),
      ],
    );
  }

  Widget _buildActivityCard(BuildContext context, Map<String, dynamic> activity) {
    IconData activityIcon;
    Color activityColor;

    switch (activity['type']) {
      case 'running':
        activityIcon = Icons.directions_run;
        activityColor = Colors.green;
        break;
      case 'cycling':
        activityIcon = Icons.directions_bike;
        activityColor = Colors.blue;
        break;
      case 'walking':
        activityIcon = Icons.directions_walk;
        activityColor = Colors.purple;
        break;
      case 'hiking':
        activityIcon = Icons.terrain;
        activityColor = Colors.orange;
        break;
      default:
        activityIcon = Icons.directions_run;
        activityColor = Colors.green;
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
          activity['name'],
          style: const TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: Text(
          activity['date'],
          style: const TextStyle(
            fontSize: 12.0,
          ),
        ),
        trailing: Text(
          activity['distance'],
          style: const TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        onTap: () {
          // Navegar a detalles de actividad
        },
      ),
    );
  }
}