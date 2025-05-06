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
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    _initializeServices();
  }

  Future<void> _initializeServices() async {
    _authService = AuthService();
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

    await _authService.initialize();
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
      ],
      child: MaterialApp(
        navigatorKey: _navigatorKey,
        title: 'Sport Activity App',
        theme: ThemeData(
          primarySwatch: Colors.deepPurple,
          scaffoldBackgroundColor: Colors.grey[100],
        ),
        initialRoute: AppRoutes.login,
        onGenerateRoute: AppRoutes.generateRoute,
      ),
    );
  }

  @override
  void dispose() {
    _socketService.dispose();
    _locationService.dispose();
    _activityTrackingProvider.dispose();
    _chatService.dispose();
    super.dispose();
  }
}
