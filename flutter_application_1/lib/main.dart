// lib/main.dart
import 'package:flutter/material.dart';
import 'package:flutter_application_1/config/routes.dart';
import 'package:provider/provider.dart';
import 'package:flutter_application_1/services/auth_service.dart';
import 'package:flutter_application_1/services/socket_service.dart';
import 'package:flutter_application_1/services/chat_service.dart';
import 'package:flutter_application_1/services/http_service.dart';
import 'package:flutter_application_1/services/notification_service.dart';

void main() {
  // Deshabilitar la comprobación de tipo del Provider (solución temporal)
  Provider.debugCheckInvalidValueType = null;
  
  runApp(
    MultiProvider(
      providers: [
        // Proveedores base
        ChangeNotifierProvider(create: (_) => AuthService()),
        ChangeNotifierProvider(create: (_) => SocketService()),
        
        // Provider de HTTP
        Provider<HttpService>(
          create: (context) => HttpService(context.read<AuthService>()),
        ),
        
        // Provider de NotificationService usando ChangeNotifierProvider
        ChangeNotifierProvider<NotificationService>(
          create: (context) => NotificationService(
            context.read<HttpService>(), 
            context.read<SocketService>()
          ),
        ),
        
        // Provider de chat
        ChangeNotifierProxyProvider<SocketService, ChatService>(
          create: (context) => ChatService(context.read<SocketService>()),
          update: (context, socketService, previous) => 
            previous ?? ChatService(socketService),
        ),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatefulWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
  
  @override
  void initState() {
    super.initState();
    _initializeServices();
  }
  
  Future<void> _initializeServices() async {
    // Inicializar servicios
    final authService = Provider.of<AuthService>(context, listen: false);
    await authService.initialize();
    
    // Si el usuario está autenticado, conectar Socket.IO
    if (authService.isLoggedIn && authService.currentUser != null) {
      final socketService = Provider.of<SocketService>(context, listen: false);
      socketService.connect(authService.currentUser);
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Sport Activity App',
      navigatorKey: navigatorKey,
      theme: ThemeData(
        primarySwatch: Colors.deepPurple,
        scaffoldBackgroundColor: Colors.grey[100],
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.deepPurple,
          foregroundColor: Colors.white,
          elevation: 0,
        ),
      ),
      debugShowCheckedModeBanner: false,
      initialRoute: AppRoutes.login,
      onGenerateRoute: AppRoutes.generateRoute,
    );
  }
}