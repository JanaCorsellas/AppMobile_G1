import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:flutter_application_1/models/notification_models.dart';
import 'package:flutter_application_1/services/notification_services.dart';
import 'package:flutter_application_1/services/auth_service.dart';
import 'package:flutter_application_1/screens/chat/chat_room.dart';
import 'package:flutter_application_1/config/routes.dart';
import 'package:flutter_application_1/widgets/translated_text.dart';

class NotificationDetailScreen extends StatefulWidget {
  final String notificationId;
  
  const NotificationDetailScreen({
    Key? key,
    required this.notificationId,
  }) : super(key: key);

  @override
  State<NotificationDetailScreen> createState() => _NotificationDetailScreenState();
}

class _NotificationDetailScreenState extends State<NotificationDetailScreen> {
  bool _isMarkedAsRead = false;

  @override
  void initState() {
    super.initState();
    // Marcar com a llegida automàticament a l'obrir la pantalla
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _markAsReadOnOpen();
    });
  }

  // Marcar la notificació com a llegida quan s'obre la pantalla
  Future<void> _markAsReadOnOpen() async {
    if (_isMarkedAsRead) return;
    
    final notificationService = Provider.of<NotificationService>(context, listen: false);
    final authService = Provider.of<AuthService>(context, listen: false);
    final notification = notificationService.getNotificationById(widget.notificationId);
    
    if (notification != null && !notification.read) {
      final userId = authService.currentUser?.id;
      if (userId == null) {
        print('Error: No hay usuario autenticado para marcar notificación como leída');
        return;
      }

      _isMarkedAsRead = true;
      final success = await notificationService.markAsRead(widget.notificationId, userId: userId);
      
      if (!success) {
        // Si falla, permetre intentar-ho de nou
        _isMarkedAsRead = false;
        print('Error al marcar automáticamente la notificación como leída');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<NotificationService>(
      builder: (context, notificationService, child) {
        final notification = notificationService.getNotificationById(widget.notificationId);
    
        if (notification == null) {
          return Scaffold(
            appBar: AppBar(title: const Text('Notificación')),
            body: const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  TranslatedText('Notificación no encontrada'),
                ],
              )
            ),
          );
        }
        
        return Scaffold(
          appBar: AppBar(
            title: const TranslatedText('Detalles de la notificación'),
            actions: [
              Container(
                margin: const EdgeInsets.only(right: 8),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: notification.read ? Colors.green : Colors.orange,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      notification.read ? Icons.check_circle : Icons.circle,
                      color: Colors.white,
                      size: 16,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      notification.read ? 'Leída' : 'No leída',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.delete),
                onPressed: () => _deleteNotification(context, notification),
              ),
            ],
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header with icon and title
                Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          notification.getColor().withOpacity(0.1),
                          notification.getColor().withOpacity(0.05),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: notification.getColor().withOpacity(0.2),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(16.0),
                          decoration: BoxDecoration(
                            color: notification.getColor().withOpacity(0.2),
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: notification.getColor().withOpacity(0.3),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Icon(
                            notification.getIcon(),
                            color: notification.getColor(),
                            size: 32,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                notification.title,
                                style: const TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Row(
                                  children: [
                                    Icon(
                                      Icons.access_time,
                                      size: 16,
                                      color: Colors.grey[600],
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      timeago.format(notification.createdAt, locale: 'es'),
                                      style: TextStyle(
                                        color: Colors.grey[600],
                                        fontSize: 14,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                
                    const SizedBox(height: 24),
                  
                    // Message
                    _buildSection(
                    title: 'Mensaje',
                    icon: Icons.message,
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16.0),
                      decoration: BoxDecoration(
                        color: Colors.grey[50],
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey[200]!),
                      ),
                      child: Text(
                        notification.message,
                        style: const TextStyle(
                          fontSize: 16,
                          height: 1.5,
                        ),
                      ),
                    ),
                  ),
                  

                  if (notification.type == 'activity_update') ...[
                    const SizedBox(height: 24),
                    _buildActivityInfo(notification),
                  ],
                  if (notification.type == 'chat_message') ...[
                    const SizedBox(height: 24),
                    _buildChatInfo(notification),
                  ],
                  if (notification.type == 'achievement_unlocked') ...[
                    const SizedBox(height: 24),
                    _buildAchievementInfo(notification),
                  ],
                  const SizedBox(height: 32),
                  _buildActionButtons(context, notification),
                ],
              ),
            ),
          );
        }
      );
    }

    Widget _buildSection({
      required String title,
      required IconData icon,
      required Widget child,
    }) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 20, color: Colors.grey[700]),
              const SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[700],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          child,
        ],
      );
    }

   // Widget específico para información de actividades
  Widget _buildActivityInfo(NotificationModel notification) {
    try {
      print('DEBUG _buildActivityInfo: INICIO');
      
      final data = notification.data;
      if (data == null){
        print('DEBUG: notification.data es null');
        return const SizedBox.shrink();
      }
      
      print('DEBUG _buildActivityInfo: Todos los datos = $data');
      
      // Verificar cada campo individualmente
      final senderUsername = data['senderUsername'];
      final activityType = data['activityType'];
      final distance = data['distance'];
      final duration = data['duration'];
      
      print('DEBUG: senderUsername = $senderUsername (${senderUsername.runtimeType})');
      print('DEBUG: activityType = $activityType (${activityType.runtimeType})');
      print('DEBUG: distance = $distance (${distance.runtimeType})');
      print('DEBUG: duration = $duration (${duration.runtimeType})');
      
      List<Widget> infoWidgets = [];

      // Usuario que hizo la actividad
      if (data.containsKey('senderUsername') && data['senderUsername'] != null) {
        try {
          print('DEBUG: Creando fila de senderUsername...');
          final userWidget = _buildInfoRow(
            icon: Icons.person,
            label: 'Usuario',
            value: data['senderUsername'].toString(),
            color: Colors.blue,
          );
          infoWidgets.add(userWidget);
          print('DEBUG: Fila de senderUsername creada exitosamente');
        } catch (e) {
          print('ERROR creando fila de senderUsername: $e');
          infoWidgets.add(Text('Error en usuario: $e', style: const TextStyle(color: Colors.red, fontSize: 12)));
        }
      }
      
      // Tipo de actividad
      if (data.containsKey('activityType') && data['activityType'] != null) {
        try {
          print('DEBUG: Creando fila de activityType...');
          final typeIcon = _getActivityTypeIconData(data['activityType']);
          final typeName = _getActivityTypeName(data['activityType']);
          final typeColor = _getActivityTypeColor(data['activityType']);
          print('DEBUG: typeIcon=$typeIcon, typeName=$typeName, typeColor=$typeColor');
          
          final typeWidget = _buildInfoRow(
            icon: typeIcon,
            label: 'Tipo',
            value: typeName,
            color: typeColor,
          );
          infoWidgets.add(typeWidget);
          print('DEBUG: Fila de activityType creada exitosamente');
        } catch (e) {
          print('ERROR creando fila de activityType: $e');
          infoWidgets.add(Text('Error en tipo: $e', style: const TextStyle(color: Colors.red, fontSize: 12)));
        }
      }
      
      // Distancia
      if (data.containsKey('distance') && data['distance'] != null) {
        try {
          print('DEBUG: Creando fila de distance...');
          final distanceFormatted = _formatDistance(data['distance']);
          print('DEBUG: distanceFormatted=$distanceFormatted');
          
          final distanceWidget = _buildInfoRow(
            icon: Icons.straighten,
            label: 'Distancia',
            value: distanceFormatted,
            color: Colors.green,
          );
          infoWidgets.add(distanceWidget);
          print('DEBUG: Fila de distance creada exitosamente');
        } catch (e) {
          print('ERROR creando fila de distance: $e');
          infoWidgets.add(Text('Error en distancia: $e', style: const TextStyle(color: Colors.red, fontSize: 12)));
        }
      }
      
      // Duración
      if (data.containsKey('duration') && data['duration'] != null) {
        try {
          print('DEBUG: Creando fila de duration...');
          final durationFormatted = _formatDuration(data['duration']);
          print('DEBUG: durationFormatted=$durationFormatted');
          
          final durationWidget = _buildInfoRow(
            icon: Icons.timer,
            label: 'Duración',
            value: durationFormatted,
            color: Colors.orange,
          );
          infoWidgets.add(durationWidget);
          print('DEBUG: Fila de duration creada exitosamente');
        } catch (e) {
          print('ERROR creando fila de duration: $e');
          infoWidgets.add(Text('Error en duración: $e', style: const TextStyle(color: Colors.red, fontSize: 12)));
        }
      }

      print('DEBUG: Construyendo container con ${infoWidgets.length} widgets');

      return _buildSection(
        title: 'Información de la Actividad',
        icon: Icons.fitness_center,
        child: Container(
          padding: const EdgeInsets.all(16.0),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFFE3F2FD),
                Color(0xFFF3E5F5),
              ],
            ),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Color(0xFF90CAF9)),
          ),
          child: Column(
            children: infoWidgets.isNotEmpty 
              ? infoWidgets
              :[
                const Padding(
                      padding: EdgeInsets.all(16.0),
                      child: Text(
                        'No hay información adicional disponible',
                        style: TextStyle(
                          fontStyle: FontStyle.italic,
                          color: Colors.grey,
                        ),
                      ),
                    ),
                  ],
          ),
        ),
      );
      
    } catch (e) {
      print('ERROR GENERAL en _buildActivityInfo: $e');
      return Container(
        padding: const EdgeInsets.all(16.0),
        decoration: BoxDecoration(
          color: Colors.red[50],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.red),
        ),
        child: Column(
          children: [
            const Icon(Icons.error, color: Colors.red),
            const SizedBox(height: 8),
            Text(
              'Error construyendo información de actividad: $e',
              style: const TextStyle(color: Colors.red),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }
  }
  Widget _buildChatInfo(NotificationModel notification) {
    final data = notification.data;
    if (data == null) return const SizedBox.shrink();
    
    return _buildSection(
      title: 'Información del Chat',
      icon: Icons.chat,
      child: Container(
        padding: const EdgeInsets.all(16.0),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.teal[50]!,
              Colors.teal[25]!,
            ],
          ),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.teal[200]!),
        ),
        child: Column(
          children: [
            if (data['senderUsername'] != null) ...[
              _buildInfoRow(
                icon: Icons.person,
                label: 'Remitente',
                value: data['senderUsername'],
                color: Colors.teal,
              ),
            ],
            if (data['roomName'] != null) ...[
              _buildInfoRow(
                icon: Icons.chat_bubble,
                label: 'Sala',
                value: data['roomName'],
                color: Colors.teal,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildAchievementInfo(NotificationModel notification) {
    final data = notification.data;
    if (data == null) return const SizedBox.shrink();
    
    return _buildSection(
      title: 'Información del Logro',
      icon: Icons.emoji_events,
      child: Container(
        padding: const EdgeInsets.all(16.0),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.amber[50]!,
              Colors.amber[25]!,
            ],
          ),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.amber[300]!),
        ),
        child: Column(
          children: [
            if (data['achievementName'] != null) ...[
              _buildInfoRow(
                icon: Icons.emoji_events,
                label: 'Logro',
                value: data['achievementName'],
                color: Colors.amber[700]!,
              ),
            ],
            if (data['description'] != null) ...[
              _buildInfoRow(
                icon: Icons.description,
                label: 'Descripción',
                value: data['description'],
                color: Colors.amber[700]!,
              ),
            ],
            if (data['points'] != null) ...[
              _buildInfoRow(
                icon: Icons.stars,
                label: 'Puntos',
                value: '${data['points']} pts',
                color: Colors.amber[700]!,
              ),
            ],
          ],
        ),
      ),
    );
  }

Widget _buildInfoRow({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    try {
      print('DEBUG _buildInfoRow INICIO: icon=$icon, label=$label, value=$value, color=$color');
      
      // Verificar que ningún parámetro sea null
      if (icon == null) {
        print('ERROR: icon es null');
        return const SizedBox.shrink();
      }
      if (label == null) {
        print('ERROR: label es null');
        return const SizedBox.shrink();
      }
      if (value == null) {
        print('ERROR: value es null');
        return const SizedBox.shrink();
      }
      if (color == null) {
        print('ERROR: color es null');
        return const SizedBox.shrink();
      }
      
      print('DEBUG _buildInfoRow: Creando widget...');
      
      final widget = Padding(
        padding: const EdgeInsets.symmetric(vertical: 6.0),
        child: Row(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(width: 12),
            Text(
              '$label: ',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            Expanded(
              child: Text(
                value,
                style: const TextStyle(fontWeight: FontWeight.w500),
              ),
            ),
          ],
        ),
      );
      
      print('DEBUG _buildInfoRow: Widget creado exitosamente');
      return widget;
      
    } catch (e) {
      print('ERROR en _buildInfoRow: $e');
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 6.0),
        child: Text('Error: $e', style: const TextStyle(color: Colors.red)),
      );
    }
  }
  // Métodos helper para actividades
  String _formatDistance(dynamic distance) {
    try {
      if (distance == null) return '0 m';
      final distanceNum = double.parse(distance.toString());
      if (distanceNum < 1000) {
        return '${distanceNum.toStringAsFixed(0)} m';
      } else {
        return '${(distanceNum / 1000).toStringAsFixed(2)} km';
      }
    } catch (e) {
      return distance?.toString() ?? '0 m';
    }
  }
  
  String _formatDuration(dynamic duration) {
    try {
      if (duration == null) return '0 min';
      final durationNum = double.parse(duration.toString());
      if (durationNum < 60) {
        return '0 min';
      } else if (durationNum < 3600) {
        // Menos de 1 hora: mostrar en minutos
        final minutes = (durationNum / 60).round();
        return '$minutes min';
      } else {
        final hours = (durationNum / 3600).floor();
        final remainingMinutes = ((durationNum % 3600) / 60).round();
        if (remainingMinutes == 0) {
          return '${hours}h';
        } else {
          return '${hours}h ${remainingMinutes}min';
        }
      }
    } catch (e) {
      print('Error en _formatDuration: $e');
      return '0 min';
    }
  }
  
  String _getActivityTypeName(dynamic type) {
    try {
      if (type == null) return 'Actividad';
      final typeStr = type.toString().toLowerCase();
      switch (typeStr) {
        case 'running': return 'Correr';
        case 'cycling': return 'Ciclismo';
        case 'walking': return 'Caminar';
        case 'hiking': return 'Senderismo';
        default: return type.toString();
      }
    } catch (e) {
      print('Error en _getActivityTypeNameSafe: $e');
      return 'Actividad';
    }
  }
  
  IconData _getActivityTypeIconData(dynamic type) {
    try {
      if (type == null) return Icons.fitness_center;
      final typeStr = type.toString().toLowerCase();
      switch (typeStr) {
        case 'running': return Icons.directions_run;
        case 'cycling': return Icons.directions_bike;
        case 'walking': return Icons.directions_walk;
        case 'hiking': return Icons.terrain;
        default: return Icons.fitness_center;
      }
    } catch (e) {
      print('Error en _getActivityTypeIconDataSafe: $e');
      return Icons.fitness_center;
    }
  }
  Color _getActivityTypeColor(dynamic type) {
    try {
      if (type == null) return Colors.purple;
      final typeStr = type.toString().toLowerCase();
      switch (typeStr) {
        case 'running': return Colors.orange;
        case 'cycling': return Colors.green;
        case 'walking': return Colors.blue;
        case 'hiking': return Colors.brown;
        default: return Colors.purple;
      }
    } catch (e) {
      print('Error en _getActivityTypeColorSafe: $e');
      return Colors.purple;
    }
  }
  
  // Iconos y colores mejorados por tipo
  IconData _getNotificationIcon(NotificationModel notification) {
    switch (notification.type) {
      case 'activity_update':
        final activityType = notification.data?['activityType'] as String?;
        switch (activityType?.toLowerCase()) {
          case 'running': return Icons.directions_run;
          case 'cycling': return Icons.directions_bike;
          case 'walking': return Icons.directions_walk;
          case 'hiking': return Icons.terrain;
          default: return Icons.fitness_center;
        }
      case 'achievement_unlocked': return Icons.emoji_events;
      case 'friend_request': return Icons.person_add;
      case 'chat_message': return Icons.chat;
      case 'new_follower': return Icons.person_add;
      default: return notification.getIcon();
    }
  }
  
  Color _getNotificationColor(NotificationModel notification) {
    switch (notification.type) {
      case 'activity_update':
        final activityType = notification.data?['activityType'] as String?;
        switch (activityType?.toLowerCase()) {
          case 'running': return Colors.orange;
          case 'cycling': return Colors.green;
          case 'walking': return Colors.blue;
          case 'hiking': return Colors.brown;
          default: return Colors.purple;
        }
      default: return notification.getColor();
    }
  }
  
   
  // Botones de acción específicos por tipo
  Widget _buildActionButtons(BuildContext context, NotificationModel notification) {
    final notificationService = Provider.of<NotificationService>(context, listen: false);
    
    // Especial para notificaciones de chat
    if (notification.type == 'chat_message' && notification.data != null && notification.data!['roomId'] != null) {
      return Center(
        child: ElevatedButton.icon(
          icon: const Icon(Icons.chat),
          label: const Text('Ir al chat'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.teal,
            foregroundColor: Colors.white,
            minimumSize: const Size(200, 48),
          ),
          onPressed: () => _navigateToChat(context, notification),
        ),
      );
    }
    
    // Para notificaciones de actividad
    /*if (notification.type == 'activity_update' && notification.data != null) {
      return Center(
        child: ElevatedButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Volver'),
        ),
      );
    }*/
    
    // Botones de acción para notificaciones que requieren acción
    if (notificationService.notificationRequiresAction(notification)) {
      return Center(
        child: Column(
          children: [
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
                minimumSize: const Size(200, 48),
              ),
              onPressed: () => _handleAction(context, notification, true),
              child: const Text('Aceptar'),
            ),
            const SizedBox(height: 12),
            TextButton(
              style: TextButton.styleFrom(
                foregroundColor: Colors.red,
                minimumSize: const Size(200, 48),
              ),
              onPressed: () => _handleAction(context, notification, false),
              child: const Text('Rechazar'),
            ),
          ],
        ),
      );
    }
    
    // Botón por defecto
    return Center(
      child: ElevatedButton(
        onPressed: () => Navigator.pop(context),
        child: const Text('Volver'),
      ),
    );
  }
  
  // Navegar al detalle completo de la actividad
  void _navigateToActivityDetail(BuildContext context, String activityId) {
    // Aquí navegarías a TU pantalla existente de detalle de actividad
    // Por ejemplo:
    Navigator.pushNamed(
      context,
      '/notification_detail',
      arguments: {'activityId': activityId},
    );
    
    // O si usas Navigator.push:
    // Navigator.push(
    //   context,
    //   MaterialPageRoute(
    //     builder: (context) => TuPantallaDeActividad(activityId: activityId),
    //   ),
    // );
  }
  
  // Navegar a la sala de chat
  void _navigateToChat(BuildContext context, NotificationModel notification) {
    if (notification.data != null && notification.data!['roomId'] != null) {
      final roomId = notification.data!['roomId'].toString();
      
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ChatRoomScreen(roomId: roomId),
        ),
      );
      
      // Marcar la notificación como leída
      _markAsRead(context, notification);
    }
  }

  void _handleAction(BuildContext context, NotificationModel notification, bool accept) {
    // Handle specific notification actions
    if (notification.type == 'friend_request') {
      _handleFriendRequest(context, notification, accept);
    } else if (notification.type == 'challenge_invitation') {
      _handleChallengeInvitation(context, notification, accept);
    } else {
      Navigator.pop(context);
    }
  }

  void _handleFriendRequest(BuildContext context, NotificationModel notification, bool accept) {
    // TODO: Implement friend request acceptance/rejection logic
    // This would make an API call to your backend
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(accept 
          ? 'Solicitud de amistad aceptada' 
          : 'Solicitud de amistad rechazada'
        ),
        backgroundColor: accept ? Colors.green : Colors.red,
      ),
    );
    
    // Delete the notification after handling
    _deleteNotification(context, notification);
    
    Navigator.pop(context);
  }

  void _handleChallengeInvitation(BuildContext context, NotificationModel notification, bool accept) {
    // TODO: Implement challenge invitation acceptance/rejection logic
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(accept 
          ? 'Invitación a reto aceptada' 
          : 'Invitación a reto rechazada'
        ),
        backgroundColor: accept ? Colors.green : Colors.red,
      ),
    );
    
    // Delete the notification after handling
    _deleteNotification(context, notification);
    
    Navigator.pop(context);
  }

  // Marcar notificación como leída
  void _markAsRead(BuildContext context, NotificationModel notification) {
    final notificationService = Provider.of<NotificationService>(context, listen: false);
    final authService = Provider.of<AuthService>(context, listen: false);
    final userId = authService.currentUser?.id;

    if (userId != null) {
    notificationService.markAsRead(notification.id, userId: userId);
  }
  }

  Future<void> _deleteNotification(BuildContext context, NotificationModel notification) async {
    final notificationService = Provider.of<NotificationService>(context, listen: false);
    
    try {
      final success = await notificationService.deleteNotification(notification.id);
      
      if (success && Navigator.canPop(context)) {
        Navigator.pop(context);
      } else if (!success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error al eliminar la notificación'))
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'))
      );
    }
  }
}