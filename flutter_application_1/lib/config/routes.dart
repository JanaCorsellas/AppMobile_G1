import 'package:flutter/material.dart';
import 'package:flutter_application_1/screens/auth/login_screen.dart';
import 'package:flutter_application_1/screens/auth/register_screen.dart';
import 'package:flutter_application_1/screens/user/user_home.dart';
import 'package:flutter_application_1/screens/user/user_profile.dart';
import 'package:flutter_application_1/screens/chat/chat_list.dart';
import 'package:flutter_application_1/screens/chat/chat_room.dart';


class AppRoutes {
  static const String login = '/login';
  static const String register = '/register';
  static const String userHome = '/user-home';
  static const String userProfile = '/user-profile';
  static const String admin = '/admin';
  static const String chatList = '/chat-list';
  static const String chatRoom = '/chat-room';
  static const String notifications = '/notifications';

  static Route<dynamic> generateRoute(RouteSettings settings) {
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
        // Extraer roomId de los argumentos
        final args = settings.arguments as Map<String, dynamic>?;
        final roomId = args?['roomId'] as String? ?? '';
        return MaterialPageRoute(builder: (_) => ChatRoomScreen(roomId: roomId));
      default:
        return MaterialPageRoute(
          builder: (_) => Scaffold(
            body: Center(
              child: Text('No hay ruta definida para ${settings.name}'),
            ),
          ),
        );
    }
  }
}