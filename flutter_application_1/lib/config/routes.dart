// lib/config/routes.dart - TU VERSIÓN + DEBUG
import 'package:flutter/material.dart';
import 'package:flutter_application_1/screens/achievements/achievements_screen.dart';
import 'package:flutter_application_1/screens/activity/activity_detail_screen.dart';
import 'package:flutter_application_1/screens/activity/activity_list_screen.dart';
import 'package:flutter_application_1/screens/auth/login_screen.dart';
import 'package:flutter_application_1/screens/auth/register_screen.dart';
import 'package:flutter_application_1/screens/auth/oauth_success_screen.dart'; 
import 'package:flutter_application_1/screens/user/user_home.dart';
import 'package:flutter_application_1/screens/user/user_profile.dart';
import 'package:flutter_application_1/screens/chat/chat_list.dart';
import 'package:flutter_application_1/screens/chat/chat_room.dart';
import 'package:flutter_application_1/screens/tracking/activity_selection_screen.dart';
import 'package:flutter_application_1/screens/tracking/tracking_screen.dart';
import 'package:flutter_application_1/screens/notifications/notifications_screen.dart';
import 'package:flutter_application_1/screens/settings/settings_screen.dart';
import 'package:flutter_application_1/screens/user/followers_screen.dart';
import 'package:flutter_application_1/screens/user/following_screen.dart';

class AppRoutes {
  static const String login = '/login';
  static const String register = '/register';
  static const String oauthSuccess = '/oauth-success'; 
  static const String userHome = '/user-home';
  static const String userProfile = '/user-profile';
  static const String admin = '/admin';
  static const String chatList = '/chat-list';
  static const String chatRoom = '/chat-room';
  static const String notifications = '/notifications';
  static const String activitySelection = '/activity-selection';
  static const String tracking = '/tracking';
  static const String achievements = '/achievements';
  static const String activities = '/activities';
  static const String settingsRoute = '/settings';
  static const String followers = '/followers';
  static const String following = '/following';

  static Route<dynamic> generateRoute(RouteSettings settings) {
    // ===== DEBUG LOGS =====
    print('🔍 ROUTE DEBUG: Ruta solicitada: "${settings.name}"');
    print('🔍 ROUTE DEBUG: oauthSuccess constante: "$oauthSuccess"');
    print('🔍 ROUTE DEBUG: ¿Son iguales? ${settings.name == oauthSuccess}');
    print('🔍 ROUTE DEBUG: Tipo de settings.name: ${settings.name.runtimeType}');
    
    try {
      switch (settings.name) {
        case '/':  // ← SOLUCIÓN PARA RUTA RAÍZ
          print('📱 ROUTE DEBUG: Ruta raíz detectada - verificando URL real...');
          // Verificar si la URL del navegador contiene oauth-success
          print('📱 ROUTE DEBUG: URL del navegador: ${Uri.base.toString()}');
          if (Uri.base.toString().contains('oauth-success')) {
            print('📱 ROUTE DEBUG: Detectado oauth-success en URL, redirigiendo...');
            return MaterialPageRoute(builder: (_) => OAuthSuccessScreen());
          } else {
            print('📱 ROUTE DEBUG: Ruta raíz normal, redirigiendo a login...');
            return MaterialPageRoute(builder: (_) => const LoginScreen());
          }
        case login:
          print('📱 ROUTE DEBUG: Cargando LoginScreen');
          return MaterialPageRoute(builder: (_) => const LoginScreen());
        case register:
          print('📱 ROUTE DEBUG: Cargando RegisterScreen');
          return MaterialPageRoute(builder: (_) => const RegisterScreen());
        case oauthSuccess: 
          print('📱 ROUTE DEBUG: ¡CARGANDO OAUTH SUCCESS SCREEN!');
          try {
            return MaterialPageRoute(builder: (_) {
              print('📱 ROUTE DEBUG: Creando OAuthSuccessScreen...');
              return OAuthSuccessScreen();
            });
          } catch (e) {
            print('❌ ROUTE DEBUG: Error creando OAuthSuccessScreen: $e');
            return MaterialPageRoute(builder: (_) => Scaffold(
              appBar: AppBar(title: Text('Error OAuth')),
              body: Center(child: Text('Error: $e')),
            ));
          }
        case userHome:
          print('📱 ROUTE DEBUG: Cargando UserHomeScreen');
          return MaterialPageRoute(builder: (_) => const UserHomeScreen());
        case userProfile:
          print('📱 ROUTE DEBUG: Cargando UserProfileScreen');
          return MaterialPageRoute(builder: (_) => const UserProfileScreen());
         case followers:
          print('📱 ROUTE DEBUG: Cargando FollowersScreen');
          final args = settings.arguments as Map<String, dynamic>?;
          final userId = args?['userId'] as String? ?? '';
          final userName = args?['userName'] as String? ?? '';
          return MaterialPageRoute(
            builder: (_) => FollowersScreen(
              userId: userId,
              userName: userName,
            ),
          );
        case following:
          print('📱 ROUTE DEBUG: Cargando FollowingScreen');
          final args = settings.arguments as Map<String, dynamic>?;
          final userId = args?['userId'] as String? ?? '';
          final userName = args?['userName'] as String? ?? '';
          return MaterialPageRoute(
            builder: (_) => FollowingScreen(
              userId: userId,
              userName: userName,
            ),
          );
        case chatList:
          print('📱 ROUTE DEBUG: Cargando ChatListScreen');
          return MaterialPageRoute(builder: (_) => const ChatListScreen());
        case chatRoom:
          print('📱 ROUTE DEBUG: Cargando ChatRoomScreen');
          final args = settings.arguments as Map<String, dynamic>?;
          final roomId = args?['roomId'] as String? ?? '';
          return MaterialPageRoute(
            builder: (_) => ChatRoomScreen(roomId: roomId),
          );
        case notifications:
          print('📱 ROUTE DEBUG: Cargando NotificationsScreen');
          return MaterialPageRoute(builder: (_) => const NotificationsScreen());
        case activitySelection:
          print('📱 ROUTE DEBUG: Cargando ActivitySelectionScreen');
          return MaterialPageRoute(builder: (_) => const ActivitySelectionScreen());
        case tracking:
          print('📱 ROUTE DEBUG: Cargando TrackingScreen');
          final args = settings.arguments as Map<String, dynamic>?;
          final activityType = args?['activityType'] as String? ?? 'running';
          final resuming = args?['resuming'] as bool? ?? false;
          return MaterialPageRoute(
            builder: (_) => TrackingScreen(
              activityType: activityType,
              resuming: resuming,
            ),
          );
        case achievements:
          print('📱 ROUTE DEBUG: Cargando AchievementsScreen');
          return MaterialPageRoute(builder: (_) => const AchievementsScreen());
        case activities:
          print('📱 ROUTE DEBUG: Cargando ActivitiesListScreen');
          return MaterialPageRoute(builder: (_) => const ActivitiesListScreen());
        case settingsRoute:
          print('📱 ROUTE DEBUG: Cargando SettingsScreen');
          return MaterialPageRoute(builder: (_) => const SettingsScreen());
        default:
          print('❌ ROUTE DEBUG: Ruta NO encontrada, yendo a default');
          print('❌ ROUTE DEBUG: Ruta recibida: "${settings.name}"');
          print('❌ ROUTE DEBUG: Rutas disponibles: $login, $register, $oauthSuccess, $userHome');
          return _errorRoute(settings.name);
      }
    } catch (e) {
      print('❌ ROUTE DEBUG: Error general en generateRoute: $e');
      return _errorRoute(settings.name);
    }
  }

  static Route<dynamic> _errorRoute(String? routeName) {
    print('❌ ROUTE DEBUG: Mostrando pantalla de error para: "$routeName"');
    return MaterialPageRoute(
      builder: (context) => Scaffold(
        appBar: AppBar(
          title: const Text('Error de Ruta'),
          backgroundColor: Colors.red,
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error, size: 64, color: Colors.red),
              SizedBox(height: 20),
              Text(
                'No hay ruta definida para "${routeName ?? "desconocida"}"',
                style: const TextStyle(color: Colors.red, fontSize: 18),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 20),
              Text('Ruta solicitada: "$routeName"'),
              Text('Ruta oauth esperada: "/oauth-success"'),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  Navigator.pushReplacementNamed(context, login);
                },
                child: Text('Ir al Login'),
              ),
              SizedBox(height: 10),
              ElevatedButton(
                onPressed: () {
                  print('🔧 DEBUG: Intentando navegar a /oauth-success manualmente');
                  Navigator.pushReplacementNamed(context, '/oauth-success');
                },
                child: Text('Probar OAuth Success'),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
              ),
            ],
          ),
        ),
      ),
    );
  }
}