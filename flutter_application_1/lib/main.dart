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
import 'package:flutter_localizations/flutter_localizations.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
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
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    _initializeServices();
  }

  Future<void> _initializeServices() async {
    // Creamos los servicios en el orden correcto
    _themeProvider = ThemeProvider();
    _languageProvider = LanguageProvider();
    _authService = AuthService();
    
    // Crear SocketService pasando AuthService
    _socketService = SocketService();
    
    _locationService = LocationService();
    _httpService = HttpService(_authService);
    _activityTrackingService = ActivityTrackingService(_httpService);
    _activityTrackingProvider = ActivityTrackingProvider(
      _activityTrackingService,
      _locationService,
      _authService,
    );
    _chatService = ChatService(_socketService);
    _notificationService = NotificationService(_httpService, _socketService);

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
    
    setState(() {
      _initialized = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!_initialized) {
      return const MaterialApp(
        home: Scaffold(
          body: Center(
            child: CircularProgressIndicator(),
          ),
        ),
      );
    }

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
      ],
      child: Consumer2<ThemeProvider, LanguageProvider>(
        builder: (context, themeProvider, languageProvider, _) {
          return MaterialApp(
            navigatorKey: _navigatorKey,
            title: 'Sport Activity App',
            theme: themeProvider.theme,
            locale: languageProvider.locale,
            initialRoute: _authService.isLoggedIn ? AppRoutes.userHome : AppRoutes.login,
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
          );
        },
      ),
    );
  }

  @override
  void dispose() {
    _socketService.dispose();
    _locationService.dispose();
    _activityTrackingProvider.dispose();
    _chatService.dispose();
    _notificationService.dispose();
    super.dispose();
  }
}