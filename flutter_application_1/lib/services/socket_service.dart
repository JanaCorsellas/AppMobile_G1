import 'package:flutter/material.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'package:flutter_application_1/models/user.dart';
import 'package:flutter_application_1/config/api_constants.dart';

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

  // Getters
  SocketStatus get socketStatus => _socketStatus;
  // Updated: Return the list of online user objects
  List<Map<String, dynamic>> get onlineUsers => _onlineUsers;
  List<Map<String, dynamic>> get notifications => _notifications;
  int get unreadNotifications => _unreadNotifications;
  IO.Socket get socket => _socket;
  String? get userTyping => _userTyping;

  // Constructor
  SocketService() {
    _initSocket();
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
            .setTransports(['websocket']) // Usar solo websocket, más estable
            .disableAutoConnect()
            .enableForceNew()
            .enableForceNewConnection() // Forzar nueva conexión
            .enableReconnection() // Habilitar reconexión automática
            .setTimeout(10000) // Aumentar timeout a 10 segundos
            .build(),
      );

      // Configurar listeners de forma explícita
      _setupSocketListeners();
    } catch (e) {
      print('Error inicializando Socket.IO: $e');
      _socketStatus = SocketStatus.disconnected;
      notifyListeners();
    }
  }

  // Configurar listeners de Socket.IO
  void _setupSocketListeners() {
    _socket.onConnect((_) {
      print('Connected to Socket.IO');
      _socketStatus = SocketStatus.connected;
      notifyListeners();
    });

    _socket.onDisconnect((_) {
      print('Disconnected from Socket.IO');
      _socketStatus = SocketStatus.disconnected;
      _userTyping = null;
      notifyListeners();
    });

    _socket.onConnectError((data) {
      print('Socket.IO connection error: $data');
      _socketStatus = SocketStatus.disconnected;
      notifyListeners();
      
      // Intento de reconexión automática después de un error
      Future.delayed(Duration(seconds: 3), () {
        if (_socketStatus == SocketStatus.disconnected) {
          print('Intentando reconexión automática...');
          _socket.connect();
        }
      });
    });

    _socket.onConnectTimeout((_) {
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
  }

  // Actualiza la función connect para incluir más información
  void connect(User? user) {
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
        _connectWithUser(user);
      });
    } else {
      _connectWithUser(user);
    }
  }

  // Nueva función auxiliar para separar la lógica
  void _connectWithUser(User user) {
    print('Conectando con ID de usuario: ${user.id}, username: ${user.username}');
    
    // Configurar datos de autenticación con más detalles
    _socket.auth = {
      'userId': user.id,
      'username': user.username,
      'role': user.role,
      'timestamp': DateTime.now().toIso8601String(),
    };

    try {
      // Intentar conectar
      _socket.connect();
      print('Conexión Socket.IO iniciada...');
      _socketStatus = SocketStatus.connecting;
      notifyListeners();
      
      // Definir un timeout por si la conexión no se establece
      Future.delayed(Duration(seconds: 10), () {
        if (_socketStatus == SocketStatus.connecting) {
          print('Timeout de conexión Socket.IO');
          _socketStatus = SocketStatus.disconnected;
          
          // Intento adicional de reconexión después del timeout
          print('Intentando reconexión después de timeout...');
          _socket.connect();
          
          notifyListeners();
        }
      });
    } catch (e) {
      print('Error conectando Socket.IO: $e');
      _socketStatus = SocketStatus.disconnected;
      notifyListeners();
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
      
      final userId = _socket.auth['userId'] as String? ?? '';
      final username = _socket.auth['username'] as String? ?? 'Usuario';
      
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