import 'package:flutter/material.dart';
import 'package:flutter_application_1/models/notification.dart' as app;

class NotificationTile extends StatelessWidget {
  final app.Notification notification;
  final VoidCallback? onTap;
  
  const NotificationTile({
    Key? key,
    required this.notification,
    this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: _getColor().withOpacity(0.2),
        child: Icon(
          _getIcon(),
          color: _getColor(),
        ),
      ),
      title: Text(
        _getSenderName(),
        style: TextStyle(
          fontWeight: notification.isRead ? FontWeight.normal : FontWeight.bold,
        ),
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            notification.content,
            style: TextStyle(
              color: notification.isRead ? Colors.grey[600] : Colors.black87,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Text(
            _formatTimeAgo(notification.createdAt),
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 16.0,
        vertical: 8.0,
      ),
      onTap: onTap,
      tileColor: notification.isRead ? null : Colors.blue.withOpacity(0.05),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(0),
        side: BorderSide(
          color: Colors.grey.withOpacity(0.2),
          width: 0.5,
        ),
      ),
    );
  }
  
  Color _getColor() {
    switch (notification.type) {
      case 'chat':
        return Colors.blue;
      case 'activity':
        return Colors.green;
      case 'challenge':
        return Colors.orange;
      case 'achievement':
        return Colors.purple;
      case 'follow':
        return Colors.pink;
      default:
        return Colors.grey;
    }
  }
  
  IconData _getIcon() {
    switch (notification.type) {
      case 'chat':
        return Icons.chat;
      case 'activity':
        return Icons.directions_run;
      case 'challenge':
        return Icons.flag;
      case 'achievement':
        return Icons.emoji_events;
      case 'follow':
        return Icons.person_add;
      default:
        return Icons.notifications;
    }
  }
  
  String _getSenderName() {
    if (notification.sender.username != null && notification.sender.username!.isNotEmpty) {
      return notification.sender.username!;
    }
    
    // Determinar un nombre según el tipo
    switch (notification.type) {
      case 'system':
        return 'Sistema';
      case 'achievement':
        return '¡Nuevo logro!';
      default:
        return 'Usuario';
    }
  }
  
  String _formatTimeAgo(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);
    
    if (difference.inDays > 365) {
      return '${(difference.inDays / 365).floor()} año(s) atrás';
    } else if (difference.inDays > 30) {
      return '${(difference.inDays / 30).floor()} mes(es) atrás';
    } else if (difference.inDays > 0) {
      return '${difference.inDays} día(s) atrás';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} hora(s) atrás';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} minuto(s) atrás';
    } else {
      return 'Ahora';
    }
  }
}