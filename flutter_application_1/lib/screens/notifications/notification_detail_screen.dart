// flutter_application_1/lib/screens/notifications/notification_detail_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:flutter_application_1/models/notification_models.dart';
import 'package:flutter_application_1/services/notification_services.dart';
import 'package:flutter_application_1/screens/chat/chat_room.dart';
import 'package:flutter_application_1/config/routes.dart';

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
          child: Text('Notificación no encontrada'),
        ),
      );
    }
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Detalles de la notificación'),
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
                      Text(
                        notification.title,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
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
            const Text(
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
            
            // Show data if available
            if (notification.data != null && notification.data!.isNotEmpty) ...[
              const SizedBox(height: 24),
              const Text(
                'Detalles adicionales',
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
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: notification.data!.entries.map((entry) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8.0),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${entry.key}: ',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Expanded(
                            child: Text(
                              entry.value?.toString() ?? 'N/A',
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],
            
            const SizedBox(height: 32),
            
            // Especial para notificaciones de chat
            if (notification.type == 'chat_message' && notification.data != null && notification.data!['roomId'] != null) ...[
              Center(
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
              ),
            ]
            // Action buttons for notification types that require action
            else if (notificationService.notificationRequiresAction(notification)) ...[
              Center(
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
              ),
            ] else ...[
              Center(
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Volver'),
                ),
              ),
            ],
          ],
        ),
      ),
    );
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