import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:flutter_application_1/models/notification_models.dart';
import 'package:flutter_application_1/services/notification_services.dart';
import 'package:flutter_application_1/screens/chat/chat_room.dart';
import 'package:flutter_application_1/config/routes.dart';
import 'package:flutter_application_1/widgets/translated_text.dart';

class NotificationDetailScreen extends StatelessWidget {
  final String notificationId;
  
  const NotificationDetailScreen({
    Key? key,
    required this.notificationId,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final notificationService = Provider.of<NotificationService>(context);
    final notification = notificationService.getNotificationById(notificationId);
    
    if (notification == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Notificación')),
        body: const Center(
          child: TranslatedText('Notificación no encontrada'),
        ),
      );
    }
    
    return Scaffold(
      appBar: AppBar(
        title: const TranslatedText('Detalles de la notificación'),
        actions: [
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
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12.0),
                  decoration: BoxDecoration(
                    color: notification.getColor().withOpacity(0.2),
                    shape: BoxShape.circle,
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
                      TranslatedText(
                        notification.title,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      TranslatedText(
                        timeago.format(notification.createdAt, locale: 'es'),
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 24),
            
            // Message
            const TranslatedText(
              'Mensaje',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(16.0),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                notification.message,
                style: const TextStyle(
                  fontSize: 16,
                ),
              ),
            ),

            if (notification.type == 'activity_update') ...[
              _buildActivityInfo(notification),
            ],

            _buildActionButtons(context, notification),
          ],
        ),
      ),
    );
  }

   // Widget específico para información de actividades
  Widget _buildActivityInfo(NotificationModel notification) {
    final data = notification.data;
    if (data == null) return const SizedBox.shrink();
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 24),
        const Text(
          'Información de la Actividad',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.grey,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(16.0),
          decoration: BoxDecoration(
            color: Colors.blue[50],
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.blue[200]!),
          ),
          child: Column(
            children: [
              if (data['senderUsername'] != null) ...[
                Row(
                  children: [
                    const Icon(Icons.person, color: Colors.blue, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      'Usuario: ${data['senderUsername']}',
                      style: const TextStyle(fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
              ],
              if (data['activityType'] != null) ...[
                Row(
                  children: [
                    _getActivityTypeIcon(data['activityType']),
                    const SizedBox(width: 8),
                    Text(
                      'Tipo: ${_getActivityTypeName(data['activityType'])}',
                      style: const TextStyle(fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
              ],
              if (data['distance'] != null) ...[
                Row(
                  children: [
                    const Icon(Icons.straighten, color: Colors.green, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      'Distancia: ${_formatDistance(data['distance'])}',
                      style: const TextStyle(fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
              ],
              if (data['duration'] != null) ...[
                Row(
                  children: [
                    const Icon(Icons.timer, color: Colors.orange, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      'Duración: ${_formatDuration(data['duration'])}',
                      style: const TextStyle(fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
  
  // Métodos helper para actividades
  String _formatDistance(dynamic distance) {
    try {
      final distanceNum = double.parse(distance.toString());
      if (distanceNum < 1000) {
        return '${distanceNum.toStringAsFixed(0)} m';
      } else {
        return '${(distanceNum / 1000).toStringAsFixed(2)} km';
      }
    } catch (e) {
      return distance.toString();
    }
  }
  
  String _formatDuration(dynamic duration) {
    try {
      final durationNum = double.parse(duration.toString());
      final minutes = (durationNum / 60).round();
      if (minutes < 60) {
        return '$minutes min';
      } else {
        final hours = (minutes / 60).floor();
        final remainingMinutes = minutes % 60;
        return '${hours}h ${remainingMinutes}min';
      }
    } catch (e) {
      return duration.toString();
    }
  }
  
  String _getActivityTypeName(String type) {
    switch (type.toLowerCase()) {
      case 'running': return 'Correr';
      case 'cycling': return 'Ciclismo';
      case 'walking': return 'Caminar';
      case 'hiking': return 'Senderismo';
      default: return type;
    }
  }
  
  Icon _getActivityTypeIcon(String type) {
    switch (type.toLowerCase()) {
      case 'running': return const Icon(Icons.directions_run, color: Colors.orange, size: 20);
      case 'cycling': return const Icon(Icons.directions_bike, color: Colors.green, size: 20);
      case 'walking': return const Icon(Icons.directions_walk, color: Colors.blue, size: 20);
      case 'hiking': return const Icon(Icons.terrain, color: Colors.brown, size: 20);
      default: return const Icon(Icons.fitness_center, color: Colors.purple, size: 20);
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
    notificationService.markAsRead(notification.id);
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