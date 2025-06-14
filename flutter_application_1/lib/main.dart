import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_application_1/config/routes.dart';
import 'package:flutter_application_1/services/auth_service.dart';
import 'package:flutter_application_1/services/socket_service.dart';
import 'package:flutter_application_1/services/chat_service.dart';
import 'package:flutter_application_1/services/http_service.dart';
import 'package:flutter_application_1/services/notification_services.dart';
import 'package:flutter_application_1/services/location_service.dart';
import 'package:flutter_application_1/services/activity_tracking_service.dart';
import 'package:flutter_application_1/providers/activity_provider_tracking.dart';
import 'package:flutter_application_1/providers/theme_provider.dart';
import 'package:flutter_application_1/providers/language_provider.dart';
import 'package:flutter_application_1/extensions/string_extensions.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_application_1/services/achievementService.dart';
import 'package:flutter_application_1/services/follow_service.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

// Handler para mensajes en segundo plano
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Inicializar Firebase para el contexto de segundo plano
  await Firebase.initializeApp();
  
  print("=== Mensaje FCM en segundo plano ===");
  print("Message ID: ${message.messageId}");
  print("Título: ${message.notification?.title}");
  print("Cuerpo: ${message.notification?.body}");
  print("Datos: ${message.data}");
  print("===============================");
}



Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await _initializerFirebase();
  await _setupFirebaseMessaging();
  runApp(const MyApp());
}

Future<void> _initializerFirebase() async {
  try {
    if (kIsWeb) {
      await Firebase.initializeApp(
        options: const FirebaseOptions(
          apiKey: "AIzaSyAVGap3-2Tk9_Y_zW4gA-860n3z4f1i2qU",
          authDomain: "trazer-e4cb2.firebaseapp.com",
          projectId: "trazer-e4cb2",
          storageBucket: "trazer-e4cb2.firebasestorage.app",
          messagingSenderId: "782085531087",
          appId: "1:782085531087:web:fbc005500d06279a4f5eba",
          measurementId: "G-YKZ1SH85QD",
        ),
      );
    } else {
      await Firebase.initializeApp();
    }
    print ("Firebase inicializado correctamente");
  } catch (e) {
    print("Error inicializando Firebase: $e");
  }
}

Future<void> _setupFirebaseMessaging() async {
  try {
    final messaging = FirebaseMessaging.instance;
    
    // Solicitar permisos de notificación
    final NotificationSettings settings = await messaging.requestPermission(
      alert: true,
      badge: true,
      provisional: false,
      sound: true,
      announcement: false,
      carPlay: false,
      criticalAlert: false,
    );

    print('Estado de permisos: ${settings.authorizationStatus}');
    
    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      print('Usuario otorgó permisos de notificación');
    } else if (settings.authorizationStatus == AuthorizationStatus.provisional) {
      print('Usuario otorgó permisos provisionales');
    } else {
      print('Usuario denegó permisos de notificación');
    }

    // Configurar el manejador de mensajes en segundo plano
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
    
    // Obtener el token FCM inicial
    final token = await messaging.getToken();
    print("Token FCM inicial: $token");
    
    // Configurar foreground notification presentation para iOS
    if (!kIsWeb) {
      await messaging.setForegroundNotificationPresentationOptions(
        alert: true,
        badge: true,
        sound: true,
      );
    }
    
  } catch (e) {
    print("Error configurando Firebase Messaging: $e");
  }
}

class MyApp extends StatefulWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> with WidgetsBindingObserver{
  final _navigatorKey = GlobalKey<NavigatorState>();
  late final AuthService _authService;
  late final SocketService _socketService;
  late final LocationService _locationService;
  late final HttpService _httpService;
  late final ActivityTrackingService _activityTrackingService;
  late final ActivityTrackingProvider _activityTrackingProvider;
  late final ChatService _chatService;
  late final NotificationService _notificationService;
  late final ThemeProvider _themeProvider;
  late final LanguageProvider _languageProvider;
  late final AchievementService _achievementService;
  final _scaffoldMessengerKey = GlobalKey<ScaffoldMessengerState>();
  
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initializeServices();
    _setupAppLifecycleNotifications();
  }
  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    
    switch (state) {
      case AppLifecycleState.resumed:
        print("App resumed - actualizando notificaciones");
        _refreshNotificationsWhenAppResumes();
        break;
      case AppLifecycleState.paused:
        print("App paused");
        break;
      case AppLifecycleState.detached:
        print("App detached");
        break;
      case AppLifecycleState.inactive:
        print("App inactive");
        break;
      case AppLifecycleState.hidden:
        print("App hidden");
        break;
    }
  }

  void _setupAppLifecycleNotifications() {
    // Verificar si la app se abrió desde una notificación
    FirebaseMessaging.instance.getInitialMessage().then((RemoteMessage? message) {
      if (message != null) {
        print("App abierta desde notificación: ${message.notification?.title}");
        _handleNotificationTap(message);
      }
    });

    // Listener para cuando se toca una notificación mientras la app está en background
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      print("Notificación tocada (app en background): ${message.notification?.title}");
      _handleNotificationTap(message);
    });
  }

  /// Maneja cuando el usuario toca una notificación
  void _handleNotificationTap(RemoteMessage message) {
    final data = message.data;
    final type = data['type'] as String?;
    
    // Navegar según el tipo de notificación
    switch (type) {
      case 'friend_request':
        _navigateToFriendRequests();
        break;
      case 'activity_update':
        final activityId = data['activityId'] as String?;
        if (activityId != null) {
          _navigateToActivity(activityId);
        } else {
          _navigateToActivityFeed();
        }
        break;
      case 'achievement_unlocked':
        final achievementId = data['achievementId'] as String?;
        if (achievementId != null) {
          _navigateToAchievement(achievementId);
        }
        break;
      case 'challenge_completed':
        final challengeId = data['challengeId'] as String?;
        if (challengeId != null) {
          _navigateToChallenge(challengeId);
        }
        break;
      case 'chat_message':
        final roomId = data['roomId'] as String?;
        if (roomId != null) {
          _navigateToChat(roomId);
        }
        break;
    }
  }

  /// Actualiza notificaciones cuando la app vuelve al primer plano
  void _refreshNotificationsWhenAppResumes() {
    if (_initialized && _authService.isLoggedIn && _authService.currentUser != null) {
      // Refrescar notificaciones después de un pequeño delay
      Future.delayed(const Duration(milliseconds: 500), () {
        _notificationService.fetchNotifications(_authService.currentUser!.id);
      });
    }
  }

  Future<void> _initializeServices() async {
    // Creamos los servicios en el orden correcto
    _themeProvider = ThemeProvider();
    _languageProvider = LanguageProvider();
    _authService = AuthService();
    _socketService = SocketService();
    _locationService = LocationService();
    
    // Create HTTP service before other services that depend on it
    _httpService = HttpService(_authService);
    
    // Now we can create services that depend on HttpService
    _achievementService = AchievementService(_httpService);
    _activityTrackingService = ActivityTrackingService(_httpService);
    
    _activityTrackingProvider = ActivityTrackingProvider(
      _activityTrackingService,
      _locationService,
      _authService,
    );
    
    _chatService = ChatService(_socketService);
    _notificationService = NotificationService(_httpService, _socketService);

    _authService.setNotificationService(_notificationService);
    
    // Establecer referencias cruzadas para gestión del token
    _socketService.setAuthService(_authService);

    // Inicializar servicios
    await _authService.initialize();
    
    // Si hay un usuario autenticado, conectar el socket con el token JWT
    if (_authService.isLoggedIn && _authService.currentUser != null) {
      _socketService.connect(
        _authService.currentUser, 
        accessToken: _authService.accessToken
      );
      
      // Inicializar notificaciones para el usuario actual
      if (_authService.currentUser != null) {
        await _notificationService.initialize(_authService.currentUser!.id);
      }
    }
    _notificationService.setupFirebaseMessaging();
    
    setState(() {
      _initialized = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!_initialized) {
      return MaterialApp(
        home: Scaffold(
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const CircularProgressIndicator(),
                const SizedBox(height: 16),
                Text(
                  'Inicializando aplicación...',
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
              ],
            ),
          ),
        ),
      );
    }
    //NotificationService.setScaffoldMessengerKey(_scaffoldMessengerKey);
    //NotificationService.setNavigatorKey(_navigatorKey);

    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: _authService),
        ChangeNotifierProvider.value(value: _socketService),
        ChangeNotifierProvider.value(value: _locationService),
        Provider.value(value: _httpService),
        Provider.value(value: _activityTrackingService),
        ChangeNotifierProvider.value(value: _activityTrackingProvider),
        ChangeNotifierProvider.value(value: _chatService),
        ChangeNotifierProvider.value(value: _notificationService),
        ChangeNotifierProvider.value(value: _themeProvider),
        ChangeNotifierProvider.value(value: _languageProvider),
        ChangeNotifierProvider(create: (_) => FollowService()),
        Provider.value(value: _achievementService),
      ],
      child: Consumer2<ThemeProvider, LanguageProvider>(
        builder: (context, themeProvider, languageProvider, child) {
          return MaterialApp(
            navigatorKey: _navigatorKey,
            scaffoldMessengerKey: _scaffoldMessengerKey,
            title: 'app_title'.tr(context),
            theme: themeProvider.theme,
            locale: languageProvider.locale,
            initialRoute:  AppRoutes.splash,
            onGenerateRoute: AppRoutes.generateRoute,
            localizationsDelegates: const [
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            supportedLocales: const [
              Locale('en', 'US'),
              Locale('es', 'ES'),
              Locale('ca', 'ES'),
            ],
            debugShowCheckedModeBanner: false,
          );
        },
      ),
    );
  }
  // Métodos de navegación para manejar notificaciones
  void _navigateToFriendRequests() {
    if (_navigatorKey.currentState != null) {
      _navigatorKey.currentState!.pushNamed('/friends');
    }
  }

  void _navigateToActivity(String activityId) {
    if (_navigatorKey.currentState != null) {
      _navigatorKey.currentState!.pushNamed('/activity_detail', arguments: activityId);
    }
  }

  void _navigateToChat(String roomId) {
    if (_navigatorKey.currentState != null) {
      _navigatorKey.currentState!.pushNamed('/chat', arguments: roomId);
    }
  }

  void _navigateToActivityFeed() {
    if (_navigatorKey.currentState != null) {
      _navigatorKey.currentState!.pushNamed('/home'); // O la ruta de tu feed
    }
  }

  void _navigateToAchievement(String achievementId) {
    if (_navigatorKey.currentState != null) {
      _navigatorKey.currentState!.pushNamed('/achievement_detail', arguments: achievementId);
    }
  }

  void _navigateToChallenge(String challengeId) {
    if (_navigatorKey.currentState != null) {
      _navigatorKey.currentState!.pushNamed('/challenge_detail', arguments: challengeId);
    }
  }

}