// flutter_application_1/lib/services/socket_service.dart
import 'package:flutter/material.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'package:flutter_application_1/models/user.dart';
import 'package:flutter_application_1/config/api_constants.dart';
import 'package:flutter_application_1/services/auth_service.dart';

enum SocketStatus { connecting, connected, disconnected }

class SocketService with ChangeNotifier {
  late IO.Socket _socket;
  SocketStatus _socketStatus = SocketStatus.disconnected;
  
  // Updated: Changed to store user objects instead of just IDs
  List<Map<String, dynamic>> _onlineUsers = [];
  List<Map<String, dynamic>> _notifications = [];
  int _unreadNotifications = 0;
  String? _userTyping;
  
  // Add a debounce timer for typing events
  DateTime? _lastTypingEvent;
  int _reconnectAttempts = 0;
  static const int MAX_RECONNECT_ATTEMPTS = 5;
  
  // Almacenamiento del token actual
  String? _currentToken;
  AuthService? _authService;

  // Getters
  SocketStatus get socketStatus => _socketStatus;
  // Updated: Return the list of online user objects
  List<Map<String, dynamic>> get onlineUsers => _onlineUsers;
  List<Map<String, dynamic>> get notifications => _notifications;
  int get unreadNotifications => _unreadNotifications;
  IO.Socket get socket => _socket;
  String? get userTyping => _userTyping;

  // Constructor
  SocketService({AuthService? authService}) {
    _authService = authService;
    _initSocket();
  }

  // Set auth service después de la inicialización
  void setAuthService(AuthService authService) {
    _authService = authService;
  }

  // Inicializar Socket.IO
  void _initSocket() {
    print('Inicializando servicio Socket.IO');
    _socketStatus = SocketStatus.connecting;
    notifyListeners();

    try {
      // IMPORTANTE: La URL debe coincidir exactamente con tu backend
      final Uri apiUri = Uri.parse(ApiConstants.baseUrl);
      // Nota: Socket.IO normalmente se conecta al puerto base, no a /api
      final String socketUrl = '${apiUri.scheme}://${apiUri.host}:${apiUri.port}';
      
      print('Intentando conectar a Socket.IO en: $socketUrl');

      _socket = IO.io(
        socketUrl,
        IO.OptionBuilder()
            .setTransports(['websocket', 'polling']) // Usar ambos transportes para mayor compatibilidad
            .disableAutoConnect()
            .enableForceNew()
            .enableForceNewConnection() // Forzar nueva conexión
            .enableReconnection() // Habilitar reconexión automática
            .setTimeout(15000) // Aumentar timeout a 15 segundos
            .build(),
      );

      // Configurar listeners de forma explícita
      _setupSocketListeners();
      
      // Intentar conectar
      _socket.connect();
    } catch (e) {
      print('Error inicializando Socket.IO: $e');
      _socketStatus = SocketStatus.disconnected;
      notifyListeners();
    }
  }

  // Configurar listeners de Socket.IO
  void _setupSocketListeners() {
    _socket.onConnect((_) {
      print('Connected to Socket.IO - Socket ID: ${_socket.id}');
      _socketStatus = SocketStatus.connected;
      _reconnectAttempts = 0;
      notifyListeners();
    });

    _socket.onDisconnect((_) {
      print('Disconnected from Socket.IO');
      _socketStatus = SocketStatus.disconnected;
      _userTyping = null;
      
      // Si se desconecta y teníamos un token, puede ser que expiró
      if (_currentToken != null) {
        _handlePossibleTokenExpiration();
      }
      
      notifyListeners();
      
      // Intentar reconectar automáticamente si tenemos auth data
      if (_socket.auth != null && _reconnectAttempts < MAX_RECONNECT_ATTEMPTS) {
        _reconnectAttempts++;
        print('Intentando reconexión automática (intento $_reconnectAttempts de $MAX_RECONNECT_ATTEMPTS)...');
        Future.delayed(Duration(seconds: 2 * _reconnectAttempts), () {
          if (_socketStatus == SocketStatus.disconnected) {
            _socket.connect();
            _socketStatus = SocketStatus.connecting;
            notifyListeners();
          }
        });
      }
    });

    _socket.onConnectError((data) {
      print('Socket.IO connection error: $data');
      _socketStatus = SocketStatus.disconnected;
      notifyListeners();
      
      // Intento de reconexión automática después de un error
      if (_reconnectAttempts < MAX_RECONNECT_ATTEMPTS) {
        _reconnectAttempts++;
        print('Intentando reconexión después de error (intento $_reconnectAttempts de $MAX_RECONNECT_ATTEMPTS)...');
        Future.delayed(Duration(seconds: 2 * _reconnectAttempts), () {
          if (_socketStatus == SocketStatus.disconnected) {
            _socket.connect();
            _socketStatus = SocketStatus.connecting;
            notifyListeners();
          }
        });
      }
    });

    _socket.on('connect_timeout', (_) {
      print('Socket.IO connection timeout');
      _socketStatus = SocketStatus.disconnected;
      notifyListeners();
    });
    
    _socket.onError((data) {
      print('Socket.IO error: $data');
    });

    // Updated: Handle improved user status with usernames
    _socket.on('online_users', (data) {
      print('User status updated: $data');
      if (data != null) {
        try {
          // Parse the new format that includes usernames
          _onlineUsers = List<Map<String, dynamic>>.from(data);
          print('Online users updated: $_onlineUsers');
          notifyListeners();
        } catch (e) {
          print('Error parsing online users: $e');
        }
      }
    });

    _socket.on('notification', (data) {
      print('New notification received: $data');
      if (data != null) {
        _notifications.insert(0, data);
        _unreadNotifications++;
        notifyListeners();
      }
    });
    
    _socket.on('user_typing', (data) {
      if (data != null && data['username'] != null) {
        _userTyping = data['username'];
        notifyListeners();
        
        // Limpiar el estado de escritura después de 3 segundos
        Future.delayed(Duration(seconds: 3), () {
          if (_userTyping == data['username']) {
            _userTyping = null;
            notifyListeners();
          }
        });
      }
    });
    
    // Agregar un evento de reconexión para manejar reconexiones
    _socket.on('reconnect', (_) {
      print('Socket.IO reconnected');
      
      // Volver a unirse a todas las salas anteriores si es necesario
      // (Esto requeriría mantener un registro de las salas activas)
    });
    
    // Agregar eventos adicionales para depuración
    _socket.on('connect_error', (error) {
      print('Socket.IO connect_error: $error');
    });
    
    _socket.on('reconnect_attempt', (attempt) {
      print('Socket.IO reconnect attempt: $attempt');
    });
    
    _socket.on('reconnect_failed', (_) {
      print('Socket.IO reconnect failed');
    });

    // Eventos específicos para salas de chat
    _socket.on('new_message', (data) {
      print('Nuevo mensaje recibido: $data');
    });

    _socket.on('user_joined', (data) {
      print('Usuario unido a sala: $data');
    });
    
    // Evento para cuando el token es inválido
    _socket.on('token_expired', (_) {
      print('Token JWT expirado. Intentando renovar...');
      _handlePossibleTokenExpiration();
    });
  }

  // Manejo de posible expiración de token
  Future<void> _handlePossibleTokenExpiration() async {
    // Verificar si la desconexión fue por token expirado (podría haber otros motivos)
    if (_socket.auth != null && _currentToken != null && _authService != null) {
      try {
        print('Intentando renovar token para Socket.IO');
        final tokenRefreshed = await _authService!.refreshAuthToken();
        
        if (tokenRefreshed) {
          // Si se refrescó el token, actualizamos el token almacenado
          _currentToken = _authService!.accessToken;
          
          if (_currentToken != null) {
            print('Token renovado exitosamente. Reconectando Socket.IO');
            
            // Actualizar el token en la configuración de auth
            _socket.auth = {
              ..._socket.auth as Map<String, dynamic>,
              'token': _currentToken,
              'timestamp': DateTime.now().toIso8601String(),
            };
            
            // Intentar reconectar con el nuevo token
            if (_socketStatus == SocketStatus.disconnected) {
              _socket.connect();
              _socketStatus = SocketStatus.connecting;
              notifyListeners();
            }
          }
        } else {
          print('No se pudo renovar el token para Socket.IO');
        }
      } catch (e) {
        print('Error refrescando token para Socket.IO: $e');
      }
    }
  }

  // Actualiza la función connect para incluir el token JWT
  void connect(User? user, {String? accessToken}) {
    if (user == null || user.id.isEmpty) {
      print('No se puede conectar sin ID de usuario');
      return;
    }

    // Desconectar primero si ya estaba conectado
    if (_socketStatus != SocketStatus.disconnected) {
      print('Ya conectado, desconectando primero');
      _socket.disconnect();
      // Esperar un momento para la desconexión
      Future.delayed(Duration(milliseconds: 500), () {
        _connectWithUser(user, accessToken);
      });
    } else {
      _connectWithUser(user, accessToken);
    }
  }

  // Nueva función auxiliar que incluye el token JWT
  void _connectWithUser(User user, String? accessToken) {
    print('Conectando con ID de usuario: ${user.id}, username: ${user.username}');
    
    // Guardar el token actual
    _currentToken = accessToken;
    
    // Configurar datos de autenticación con el token JWT
    _socket.auth = {
      'userId': user.id,
      'username': user.username,
      'role': user.role,
      'timestamp': DateTime.now().toIso8601String(),
      'token': accessToken,  // Incluir el token JWT
    };

    try {
      // Intentar conectar
      _socket.connect();
      print('Conexión Socket.IO iniciada con token JWT: ${accessToken != null ? "${accessToken.substring(0, 15)}..." : "no token"}');
      _socketStatus = SocketStatus.connecting;
      notifyListeners();
      
      // Definir un timeout por si la conexión no se establece
      Future.delayed(Duration(seconds: 10), () {
        if (_socketStatus == SocketStatus.connecting) {
          print('Timeout de conexión Socket.IO');
          _socketStatus = SocketStatus.disconnected;
          
          // Intento adicional de reconexión después del timeout
          if (_reconnectAttempts < MAX_RECONNECT_ATTEMPTS) {
            _reconnectAttempts++;
            print('Intentando reconexión después de timeout...');
            _socket.connect();
            notifyListeners();
          } else {
            notifyListeners();
          }
        }
      });
    } catch (e) {
      print('Error conectando Socket.IO: $e');
      _socketStatus = SocketStatus.disconnected;
      notifyListeners();
    }
  }

  // Actualizar el token JWT en la conexión socket existente
  void updateToken(String token) {
    _currentToken = token;
    
    if (_socket.connected && _socket.auth != null) {
      print('Actualizando token JWT en conexión Socket.IO existente');
      
      // Actualizar el token en la configuración de auth
      _socket.auth = {
        ..._socket.auth as Map<String, dynamic>,
        'token': token,
        'timestamp': DateTime.now().toIso8601String(),
      };
      
      // Emitir un evento de actualización de token al servidor
      try {
        _socket.emit('token_updated', { 'token': token });
      } catch (e) {
        print('Error emitiendo evento de actualización de token: $e');
      }
    }
  }

  // Desconectar del servidor
  void disconnect() {
    try {
      if (_socketStatus != SocketStatus.disconnected) {
        print('Disconnecting from Socket.IO');
        _socket.disconnect();
        _socketStatus = SocketStatus.disconnected;
        _userTyping = null;
        _currentToken = null;
        notifyListeners();
      }
    } catch (e) {
      print('Error disconnecting from Socket.IO: $e');
      _socketStatus = SocketStatus.disconnected;
      notifyListeners();
    }
  }

  // Unirse a una sala de chat
  void joinChatRoom(String roomId) {
    if (roomId.isEmpty) {
      print('ID de sala vacío, no se puede unir');
      return;
    }
    
    if (_socketStatus != SocketStatus.connected) {
      print('Cannot join room: not connected (current status: $_socketStatus)');
      
      // Intentar reconectar si no está conectado
      if (_socketStatus == SocketStatus.disconnected && _socket.auth != null) {
        print('Intentando reconectar antes de unirse a la sala...');
        _socket.connect();
        
        // Intentar unirse después de una reconexión exitosa
        Future.delayed(Duration(seconds: 2), () {
          if (_socketStatus == SocketStatus.connected) {
            _emit_join_room(roomId);
          } else {
            print('No se pudo unir a la sala $roomId - sin conexión');
          }
        });
      }
      return;
    }

    _emit_join_room(roomId);
  }
  
  // Método auxiliar para emitir join_room
  void _emit_join_room(String roomId) {
    try {
      print('Joining chat room: $roomId');
      _socket.emit('join_room', roomId);
    } catch (e) {
      print('Error joining chat room: $e');
    }
  }

  // Enviar mensaje con mejor manejo de errores
  void sendMessage(String roomId, String content, [String? messageId]) {
    if (roomId.isEmpty || content.isEmpty) {
      print('RoomID o contenido vacío, no se puede enviar mensaje');
      return;
    }
    
    if (_socketStatus != SocketStatus.connected) {
      print('No se puede enviar mensaje: no conectado (estado: $_socketStatus)');
      
      // Intentar reconectar si no está conectado
      if (_socketStatus == SocketStatus.disconnected && _socket.auth != null) {
        print('Intentando reconectar antes de enviar mensaje...');
        _socket.connect();
      }
      return;
    }

    try {
      // Generar un ID único para el mensaje si no se proporciona
      final id = messageId ?? 'msg_${DateTime.now().millisecondsSinceEpoch}_${_socket.id ?? 'nodeid'}';
      
      if (_socket.auth == null) {
        print('Error: Socket auth es null, no se puede identificar el remitente');
        return;
      }
      
      final userId = _socket.auth['userId'] as String? ?? '';
      final username = _socket.auth['username'] as String? ?? 'Usuario';
      
      if (userId.isEmpty) {
        print('Error: userId es vacío, no se puede identificar el remitente');
        return;
      }
      
      // Crear objeto de mensaje completo
      final message = {
        'id': id,
        'roomId': roomId,
        'senderId': userId,
        'senderName': username,
        'content': content,
        'timestamp': DateTime.now().toIso8601String(),
      };

      print('Enviando mensaje a través de Socket.IO - Sala: $roomId, Contenido: $content');
      _socket.emit('send_message', message);
    } catch (e) {
      print('Error al enviar mensaje por Socket.IO: $e');
    }
  }

  // Enviar estado "escribiendo..." (con debounce)
  void sendTyping(String roomId) {
    if (_socketStatus != SocketStatus.connected) return;
    
    // Debounce typing events - only send once every 2 seconds
    final now = DateTime.now();
    if (_lastTypingEvent != null) {
      final difference = now.difference(_lastTypingEvent!);
      if (difference.inSeconds < 2) {
        return; // Skip if less than 2 seconds since last event
      }
    }
    
    try {
      _lastTypingEvent = now;
      _socket.emit('typing', roomId);
    } catch (e) {
      print('Error sending typing event: $e');
    }
  }

  // Marcar notificaciones como leídas
  void markNotificationsAsRead() {
    _unreadNotifications = 0;
    notifyListeners();
  }

  // Limpiar notificaciones
  void clearNotifications() {
    _notifications.clear();
    _unreadNotifications = 0;
    notifyListeners();
  }

  // Verificar si está conectado
  bool isConnected() {
    return _socketStatus == SocketStatus.connected;
  }

  // Limpiar todo al cerrar sesión
  @override
  void dispose() {
    try {
      _socket.disconnect();
      _socket.dispose();
    } catch (e) {
      print('Error disposing Socket.IO: $e');
    }
    super.dispose();
  }
}