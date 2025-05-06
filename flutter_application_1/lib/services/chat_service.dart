// flutter_application_1/lib/services/chat_service.dart
import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_application_1/models/chat_room_model.dart';
import 'package:flutter_application_1/models/message.dart';
import 'package:flutter_application_1/config/api_constants.dart';
import 'package:flutter_application_1/services/socket_service.dart';

class ChatService with ChangeNotifier {
  final SocketService _socketService;
  
  List<ChatRoom> _chatRooms = [];
  Map<String, List<Message>> _messages = {};
  String? _currentRoomId;
  bool _isLoading = false;
  Set<String> _processedMessageIds = {};

  ChatService(this._socketService) {
    _setupSocketListeners();
    _loadPersistedData();
  }

  // Getters
  List<ChatRoom> get chatRooms => _chatRooms;
  List<Message> getMessages(String roomId) => _messages[roomId] ?? [];
  String? get currentRoomId => _currentRoomId;
  bool get isLoading => _isLoading;
  List<Message> get currentMessages => _messages[_currentRoomId ?? ''] ?? [];

  Future<void> _loadPersistedData() async {
    print("Cargando datos persistentes de chat");
    await _loadSavedRooms();
    await _loadAllSavedMessages();
  }

  Future<void> loadChatRooms(String userId) async {
    if (userId.isEmpty) return;

    try {
      _isLoading = true;
      notifyListeners();

      print("Solicitando salas de chat para usuario: $userId");
      final response = await http.get(
        Uri.parse(ApiConstants.userChatRooms(userId)),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        print("Respuesta del servidor (salas): ${response.body}");
        final List<dynamic> data = json.decode(response.body);
        print("Salas recibidas del servidor: ${data.length}");
        
        _chatRooms = data.map((roomData) => ChatRoom.fromJson(roomData)).toList();
        
        // Ordenar salas por último mensaje
        _chatRooms.sort((a, b) {
          if (a.lastMessageTime == null && b.lastMessageTime == null) return 0;
          if (a.lastMessageTime == null) return 1;
          if (b.lastMessageTime == null) return -1;
          return b.lastMessageTime!.compareTo(a.lastMessageTime!);
        });
        
        await _saveRooms();
        
        // Unirse a todas las salas a través de Socket.IO
        for (var room in _chatRooms) {
          print("Joining chat room: ${room.id}");
          _socketService.joinChatRoom(room.id);
        }
      } else {
        print("Error al obtener salas: ${response.statusCode}");
        print("Respuesta: ${response.body}");
      }
    } catch (e) {
      print('Error loading chat rooms: $e');
      // Intentar cargar desde almacenamiento local
      await _loadSavedRooms();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadMessages(String roomId) async {
    if (roomId.isEmpty) return;

    try {
      print("Cargando mensajes para sala: $roomId");
      _currentRoomId = roomId;
      
      // Mostrar un loading sólo para la primera carga
      if (!_messages.containsKey(roomId)) {
        _isLoading = true;
        notifyListeners();
      }

      final response = await http.get(
        Uri.parse(ApiConstants.chatMessages(roomId)),
        headers: {'Content-Type': 'application/json'},
      );

      print("Respuesta del servidor (mensajes): ${response.statusCode}");
      
      if (response.statusCode == 200) {
        try {
          final List<dynamic> data = json.decode(response.body);
          print("Mensajes recibidos del servidor para sala $roomId: ${data.length}");
          
          // Limpiar los mensajes existentes para esta sala
          _messages[roomId] = [];
          _processedMessageIds.removeWhere((id) => id.startsWith('${roomId}_'));
          
          final List<Message> messages = [];
          
          for (var m in data) {
            try {
              final message = Message.fromJson(m);
              final messageId = '${roomId}_${message.id}';
              
              if (!_processedMessageIds.contains(messageId)) {
                messages.add(message);
                _processedMessageIds.add(messageId);
              }
            } catch (e) {
              print("Error parseando mensaje individual: $e");
            }
          }
          
          // Ordenar mensajes por timestamp (los más antiguos primero)
          messages.sort((a, b) => a.timestamp.compareTo(b.timestamp));
          
          _messages[roomId] = messages;
          
          await _saveLocalMessages(roomId, messages);
        } catch (parseError) {
          print("Error parseando respuesta de mensajes: $parseError");
          print("Respuesta del servidor: ${response.body}");
          
          // Intentar cargar desde almacenamiento local en caso de error
          final localMessages = await _loadLocalMessages(roomId);
          if (localMessages.isNotEmpty) {
            _messages[roomId] = localMessages;
          } else {
            _messages[roomId] = [];
          }
        }
      } else {
        print("Error al cargar mensajes para sala $roomId: código ${response.statusCode}");
        print("Respuesta: ${response.body}");
        // Intentar cargar desde almacenamiento local
        final localMessages = await _loadLocalMessages(roomId);
        if (localMessages.isNotEmpty) {
          _messages[roomId] = localMessages;
        } else {
          _messages[roomId] = [];
        }
      }
    } catch (e) {
      print('Error loading messages for room $roomId: $e');
      // Intentar cargar desde almacenamiento local
      final localMessages = await _loadLocalMessages(roomId);
      if (localMessages.isNotEmpty) {
        _messages[roomId] = localMessages;
      } else {
        _messages[roomId] = [];
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<ChatRoom?> createChatRoom(String name, List<String> participants, [String? description]) async {
    try {
      print("Creando sala de chat: $name - Participantes: $participants");
      final isGroup = participants.length > 2;
      
      final response = await http.post(
        Uri.parse(ApiConstants.chatRooms),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'name': name,
          'participants': participants,
          'description': description,
          'isGroup': isGroup,
        }),
      );

      if (response.statusCode == 201) {
        final data = json.decode(response.body);
        final newRoom = ChatRoom.fromJson(data);
        print("Sala creada/recuperada con ID: ${newRoom.id}");
        
        // Verificar si ya teníamos esta sala
        final existingIndex = _chatRooms.indexWhere((room) => room.id == newRoom.id);
        
        if (existingIndex >= 0) {
          print("Sala existente actualizada: ${newRoom.id}");
          // Actualizar la sala existente
          _chatRooms[existingIndex] = newRoom;
        } else {
          print("Nueva sala añadida: ${newRoom.id}");
          // Añadir la nueva sala
          _chatRooms.add(newRoom);
          _messages[newRoom.id] = [];
        }
        
        await _saveRooms();
        
        // Unirse a la sala a través de Socket.IO
        print("Joining chat room: ${newRoom.id}");
        _socketService.joinChatRoom(newRoom.id);
        
        // Cargar mensajes (si hay previos)
        await loadMessages(newRoom.id);
        
        notifyListeners();
        return newRoom;
      } else {
        print("Error al crear sala: código ${response.statusCode}");
        print("Respuesta del servidor: ${response.body}");
      }
      return null;
    } catch (e) {
      print('Error creating chat room: $e');
      return null;
    }
  }

  void sendMessage(String roomId, String content) {
    if (roomId.isEmpty || content.trim().isEmpty) return;

    try {
      final messageId = 'msg_${DateTime.now().millisecondsSinceEpoch}_${_socketService.socket.id ?? 'local'}';
      final senderId = _socketService.socket.auth?['userId']?.toString() ?? '';
      final senderName = _socketService.socket.auth?['username']?.toString() ?? 'Usuario';

      if (senderId.isEmpty) {
        print("No se puede enviar mensaje: senderId está vacío");
        return;
      }

      print('Enviando mensaje a través de Socket.IO - Sala: $roomId, Contenido: $content');

      // Verificar que este mensaje no esté ya procesado
      final messageKey = '${roomId}_${messageId}';
      if (_processedMessageIds.contains(messageKey)) {
        print("Mensaje ya procesado, ignorando envío: $messageId");
        return;
      }

      final message = Message(
        id: messageId,
        roomId: roomId,
        senderId: senderId,
        senderName: senderName,
        content: content,
        timestamp: DateTime.now(),
        isRead: false,
      );

      if (!_messages.containsKey(roomId)) {
        _messages[roomId] = [];
      }

      // Añadir mensaje localmente
      _messages[roomId]!.add(message);
      // Ordenar mensajes por timestamp (los más antiguos primero)
      _messages[roomId]!.sort((a, b) => a.timestamp.compareTo(b.timestamp));
      _processedMessageIds.add(messageKey);
      
      // Guardar mensaje localmente
      _saveLocalMessages(roomId, _messages[roomId]!);
      
      // Actualizar información de último mensaje
      _updateLastMessageForRoom(roomId, content, message.timestamp);
      
      notifyListeners();
      
      // Enviar mensaje a través de Socket.IO
      _socketService.sendMessage(roomId, content, messageId);
      
      // También enviar usando HTTP para asegurar persistencia
      _sendMessageHttp(roomId, senderId, content);
    } catch (e) {
      print('Error sending message: $e');
    }
  }
  
  Future<void> _sendMessageHttp(String roomId, String senderId, String content) async {
    try {
      final response = await http.post(
        Uri.parse(ApiConstants.sendMessage),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'roomId': roomId,
          'senderId': senderId,
          'content': content,
        }),
      );
      
      if (response.statusCode != 201) {
        print("Error enviando mensaje por HTTP: código ${response.statusCode}");
        print("Respuesta: ${response.body}");
      } else {
        print("Mensaje enviado y persistido exitosamente por HTTP");
      }
    } catch (e) {
      print('Error enviando mensaje por HTTP: $e');
    }
  }

  void _handleNewMessage(dynamic data) {
    try {
      print("Nuevo mensaje recibido via Socket.IO: $data");
      
      // Protección ante formatos inesperados
      if (data == null) {
        print("Datos de mensaje nulos, ignorando");
        return;
      }
      
      Message message;
      try {
        // Convertir data a un Map si no lo es ya
        final Map<String, dynamic> messageData = 
            data is Map<String, dynamic> ? data : json.decode(json.encode(data));
        message = Message.fromJson(messageData);
      } catch (parseError) {
        print("Error parseando mensaje: $parseError");
        print("Datos recibidos: $data");
        return;
      }
      
      final messageKey = '${message.roomId}_${message.id}';
      
      if (_processedMessageIds.contains(messageKey)) {
        print("Mensaje ya procesado, ignorando: ${message.id}");
        return;
      }
      
      if (!_messages.containsKey(message.roomId)) {
        _messages[message.roomId] = [];
      }
      
      // Verificar duplicados adicionales por contenido y timestamp
      bool isDuplicate = _messages[message.roomId]!.any((m) => 
          m.senderId == message.senderId && 
          m.content == message.content &&
          (m.timestamp.difference(message.timestamp).inSeconds.abs() < 2));
          
      if (isDuplicate) {
        print("Mensaje duplicado detectado por contenido y timestamp, ignorando");
        _processedMessageIds.add(messageKey); // Marcar como procesado
        return;
      }
      
      _messages[message.roomId]!.add(message);
      // Ordenar mensajes por timestamp (los más antiguos primero)
      _messages[message.roomId]!.sort((a, b) => a.timestamp.compareTo(b.timestamp));
      _processedMessageIds.add(messageKey);
      
      _saveLocalMessages(message.roomId, _messages[message.roomId]!);
      _updateLastMessageForRoom(message.roomId, message.content, message.timestamp);
      
      notifyListeners();
    } catch (e) {
      print('Error handling new message: $e');
    }
  }

  Future<void> _loadSavedRooms() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final roomsJson = prefs.getStringList('chat_rooms');
      if (roomsJson != null && roomsJson.isNotEmpty) {
        print("Cargando ${roomsJson.length} salas desde almacenamiento local");
        
        _chatRooms = roomsJson
            .map((data) => ChatRoom.fromJson(json.decode(data)))
            .toList();
            
        // Ordenar por último mensaje
        _chatRooms.sort((a, b) {
          if (a.lastMessageTime == null && b.lastMessageTime == null) return 0;
          if (a.lastMessageTime == null) return 1;
          if (b.lastMessageTime == null) return -1;
          return b.lastMessageTime!.compareTo(a.lastMessageTime!);
        });
        
        for (var room in _chatRooms) {
          print("Room loaded from local storage: ${room.id}");
        }
            
        notifyListeners();
      } else {
        print("No hay salas guardadas localmente");
      }
    } catch (e) {
      print('Error loading saved rooms: $e');
    }
  }

  Future<void> _saveRooms() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final roomsJson = _chatRooms
          .map((room) => json.encode(room.toJson()))
          .toList();
      
      print("Guardando ${roomsJson.length} salas en almacenamiento local");
      await prefs.setStringList('chat_rooms', roomsJson);
    } catch (e) {
      print('Error saving rooms: $e');
    }
  }

  Future<void> _loadAllSavedMessages() async {
    try {
      print("Cargando mensajes de todas las salas desde almacenamiento local");
      for (var room in _chatRooms) {
        final localMessages = await _loadLocalMessages(room.id);
        if (localMessages.isNotEmpty) {
          _messages[room.id] = localMessages;
          print("Cargados ${localMessages.length} mensajes para sala ${room.id}");
        } else {
          print("No hay mensajes guardados para sala ${room.id}");
        }
      }
    } catch (e) {
      print('Error loading all saved messages: $e');
    }
  }
  
  Future<List<Message>> _loadLocalMessages(String roomId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final messagesJson = prefs.getStringList('messages_$roomId');
      
      if (messagesJson != null && messagesJson.isNotEmpty) {
        print("Cargando ${messagesJson.length} mensajes desde almacenamiento local para sala $roomId");
        
        final Set<String> localProcessed = {};
        final messages = <Message>[];
        
        for (var msgJson in messagesJson) {
          try {
            final msg = Message.fromJson(json.decode(msgJson));
            final msgKey = '${roomId}_${msg.id}';
            
            if (!localProcessed.contains(msgKey)) {
              messages.add(msg);
              _processedMessageIds.add(msgKey);
              localProcessed.add(msgKey);
            }
          } catch (e) {
            print("Error cargando mensaje local: $e");
          }
        }
        
        // Ordenar mensajes por timestamp (los más antiguos primero)
        messages.sort((a, b) => a.timestamp.compareTo(b.timestamp));
        
        return messages;
      }
    } catch (e) {
      print('Error loading saved messages for room $roomId: $e');
    }
    return [];
  }

  Future<void> _saveLocalMessages(String roomId, List<Message> messages) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final messagesJson = messages
          .map((msg) => json.encode(msg.toJson()))
          .toList();
      
      print("Guardando ${messagesJson.length} mensajes en almacenamiento local para sala $roomId");
      await prefs.setStringList('messages_$roomId', messagesJson);
    } catch (e) {
      print('Error saving messages: $e');
    }
  }

  void _setupSocketListeners() {
    // Remover listeners anteriores para evitar duplicación
    _socketService.socket.off('new_message');
    _socketService.socket.off('user_joined');
    _socketService.socket.off('room_deleted');
    
    // Configurar nuevos listeners
    _socketService.socket.on('new_message', _handleNewMessage);
    _socketService.socket.on('user_joined', (data) {
      print("Usuario unido a sala: $data");
    });
    
    // Listener para eliminación de salas
    _socketService.socket.on('room_deleted', (data) {
      print("Sala eliminada notificación recibida: $data");
      if (data != null && data['roomId'] != null) {
        _handleRoomDeleted(data['roomId']);
      }
    });
  }

  void _handleRoomDeleted(String roomId) {
    print("Procesando eliminación de sala: $roomId");
    
    // Eliminar la sala localmente
    _chatRooms.removeWhere((room) => room.id == roomId);
    _messages.remove(roomId);
    _processedMessageIds.removeWhere((key) => key.startsWith('${roomId}_'));
    
    // Actualizar almacenamiento local
    _saveRooms();
    
    // Eliminar mensajes locales
    _removeLocalMessages(roomId);
    
    notifyListeners();
  }
  
  Future<void> _removeLocalMessages(String roomId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('messages_$roomId');
      print("Mensajes eliminados de almacenamiento local para sala $roomId");
    } catch (e) {
      print('Error removing local messages: $e');
    }
  }

  void _updateLastMessageForRoom(String roomId, String content, DateTime timestamp) {
    final index = _chatRooms.indexWhere((room) => room.id == roomId);
    if (index != -1) {
      _chatRooms[index] = _chatRooms[index].copyWith(
        lastMessage: content,
        lastMessageTime: timestamp,
      );
      
      // Reordenar salas por último mensaje
      _chatRooms.sort((a, b) {
        if (a.lastMessageTime == null && b.lastMessageTime == null) return 0;
        if (a.lastMessageTime == null) return 1;
        if (b.lastMessageTime == null) return -1;
        return b.lastMessageTime!.compareTo(a.lastMessageTime!);
      });
      
      _saveRooms();
      notifyListeners();
    }
  }

  Future<bool> deleteChatRoom(String roomId) async {
    if (roomId.isEmpty) return false;

    try {
      print("Intentando eliminar sala: $roomId");
      final response = await http.delete(
        Uri.parse(ApiConstants.deleteChatRoom(roomId)),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        print("Sala $roomId eliminada en el servidor");
        
        // Eliminar datos locales
        await _removeLocalMessages(roomId);
        _chatRooms.removeWhere((room) => room.id == roomId);
        _messages.remove(roomId);
        _processedMessageIds.removeWhere((key) => key.startsWith('${roomId}_'));

        // Salir de la sala en Socket.IO
        _socketService.socket.emit('leave_room', roomId);

        // Actualizar almacenamiento local
        await _saveRooms();
        notifyListeners();
        
        return true;
      } else {
        print("Error al eliminar sala $roomId: código ${response.statusCode}");
        return false;
      }
    } catch (e) {
      print('Error deleting chat room: $e');
      return false;
    }
  }

  void clearMessages(String roomId) {
    if (_messages.containsKey(roomId)) {
      _messages[roomId] = [];
      _processedMessageIds.removeWhere((id) => id.startsWith('${roomId}_'));
      _saveLocalMessages(roomId, []);
      notifyListeners();
    }
  }

  @override
  void dispose() {
    print("Disposing ChatService");
    _socketService.socket.off('new_message');
    _socketService.socket.off('user_joined');
    _socketService.socket.off('room_deleted');
    _messages.clear();
    _processedMessageIds.clear();
    super.dispose();
  }
}