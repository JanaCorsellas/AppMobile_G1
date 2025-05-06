import 'package:flutter/material.dart';
import 'package:flutter_application_1/screens/auth/login_screen.dart';
import 'package:flutter_application_1/screens/auth/register_screen.dart';
import 'package:flutter_application_1/screens/user/user_home.dart';
import 'package:flutter_application_1/screens/user/user_profile.dart';
import 'package:flutter_application_1/screens/chat/chat_list.dart';
import 'package:flutter_application_1/screens/chat/chat_room.dart';
import 'package:flutter_application_1/screens/tracking/activity_selection_screen.dart';
import 'package:flutter_application_1/screens/tracking/tracking_screen.dart';
import 'package:flutter_application_1/screens/notifications/notifications_screen.dart';

class AppRoutes {
  static const String login = '/login';
  static const String register = '/register';
  static const String userHome = '/user-home';
  static const String userProfile = '/user-profile';
  static const String admin = '/admin';
  static const String chatList = '/chat-list';
  static const String chatRoom = '/chat-room';
  static const String notifications = '/notifications';
  static const String activitySelection = '/activity-selection';
  static const String tracking = '/tracking';

  static Route<dynamic> generateRoute(RouteSettings settings) {
    try {
      switch (settings.name) {
        case login:
          return MaterialPageRoute(builder: (_) => const LoginScreen());
        case register:
          return MaterialPageRoute(builder: (_) => const RegisterScreen());
        case userHome:
          return MaterialPageRoute(builder: (_) => const UserHomeScreen());
        case userProfile:
          return MaterialPageRoute(builder: (_) => const UserProfileScreen());
        case chatList:
          return MaterialPageRoute(builder: (_) => const ChatListScreen());
        case chatRoom:
          final args = settings.arguments as Map<String, dynamic>?;
          final roomId = args?['roomId'] as String? ?? '';
          return MaterialPageRoute(
            builder: (_) => ChatRoomScreen(roomId: roomId),
          );
        case notifications:
          return MaterialPageRoute(builder: (_) => const NotificationsScreen());
        case activitySelection:
          return MaterialPageRoute(builder: (_) => const ActivitySelectionScreen());
        case tracking:
          final args = settings.arguments as Map<String, dynamic>?;
          final activityType = args?['activityType'] as String? ?? 'running';
          final resuming = args?['resuming'] as bool? ?? false;
          return MaterialPageRoute(
            builder: (_) => TrackingScreen(
              activityType: activityType,
              resuming: resuming,
            ),
          );
        default:
          return _errorRoute(settings.name);
      }
    } catch (e) {
      print('Error generating route: $e');
      return _errorRoute(settings.name);
    }
  }

  static Route<dynamic> _errorRoute(String? routeName) {
    return MaterialPageRoute(
      builder: (_) => Scaffold(
        appBar: AppBar(
          title: const Text('Error'),
        ),
        body: Center(
          child: Text(
            'No hay ruta definida para ${routeName ?? "desconocida"}',
            style: const TextStyle(color: Colors.red),
          ),
        ),
      ),
    );
  }
}