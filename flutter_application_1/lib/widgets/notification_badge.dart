// flutter_application_1/lib/widgets/notification_badge.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_application_1/services/notification_services.dart';
import 'package:flutter_application_1/screens/notifications/notifications_screen.dart';

class NotificationBadge extends StatelessWidget {
  final Color? color;
  
  const NotificationBadge({
    Key? key,
    this.color,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer<NotificationService>(
      builder: (context, notificationService, child) {
        return Stack(
          children: [
            IconButton(
              icon: Icon(
                Icons.notifications,
                color: color,
              ),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const NotificationsScreen(),
                  ),
                );
              },
            ),
            if (notificationService.unreadCount > 0)
              Positioned(
                right: 8,
                top: 8,
                child: Container(
                  padding: const EdgeInsets.all(2.0),
                  decoration: BoxDecoration(
                    color: Colors.red,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  constraints: const BoxConstraints(
                    minWidth: 16,
                    minHeight: 16,
                  ),
                  child: Text(
                    notificationService.unreadCount > 9 
                        ? '9+' 
                        : notificationService.unreadCount.toString(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}