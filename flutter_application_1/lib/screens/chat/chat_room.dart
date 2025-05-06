// flutter_application_1/lib/screens/chat/chat_room.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_application_1/services/notification_services.dart';
import 'package:provider/provider.dart';
import 'package:flutter_application_1/models/message.dart';
import 'package:flutter_application_1/models/chat_room_model.dart';
import 'package:flutter_application_1/services/auth_service.dart';
import 'package:flutter_application_1/services/chat_service.dart';
import 'package:flutter_application_1/services/socket_service.dart';
import 'package:flutter_application_1/services/user_service.dart';
import 'package:flutter_application_1/services/http_service.dart';

class ChatRoomScreen extends StatefulWidget {
  final String roomId;

  const ChatRoomScreen({
    Key? key,
    required this.roomId,
  }) : super(key: key);

  @override
  _ChatRoomScreenState createState() => _ChatRoomScreenState();
}

class _ChatRoomScreenState extends State<ChatRoomScreen> with WidgetsBindingObserver {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _isAtBottom = true;
  Timer? _typingTimeout;
  ChatRoom? _currentRoom;
  bool _isLoadingMessages = false;
  bool _showLoadingError = false;
  String _errorMessage = '';
  String _chatTitle = 'Chat';

  @override
  void initState() {
    super.initState();
    _loadRoom();
    WidgetsBinding.instance.addObserver(this);
    _markChatNotificationsAsRead();
    
    _scrollController.addListener(() {
      setState(() {
        _isAtBottom = _scrollController.position.pixels == 
                     _scrollController.position.maxScrollExtent;
      });
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _messageController.dispose();
    _scrollController.dispose();
    _typingTimeout?.cancel();
    super.dispose();
  }

  void _markChatNotificationsAsRead() {
    try {
      final notificationService = Provider.of<NotificationService>(context, listen: false);
      
      // Marca como leídas todas las notificaciones de tipo chat_message para esta sala
      for (var notification in notificationService.notifications) {
        if (notification.type == 'chat_message' && 
            notification.data != null && 
            notification.data!['roomId'] == widget.roomId &&
            !notification.read) {
          notificationService.markAsRead(notification.id);
        }
      }
    } catch (e) {
      print('Error al marcar notificaciones como leídas: $e');
    }
  }

  Future<void> _loadRoom() async {
    final chatService = Provider.of<ChatService>(context, listen: false);
    final authService = Provider.of<AuthService>(context, listen: false);
    final currentUserId = authService.currentUser?.id ?? '';
    
    setState(() {
      _isLoadingMessages = true;
      _showLoadingError = false;
      _errorMessage = '';
    });
    
    try {
      print("Intentando cargar mensajes para sala: ${widget.roomId}");
      await chatService.loadMessages(widget.roomId);
      
      // Buscar la sala actual en la lista de salas
      try {
        _currentRoom = chatService.chatRooms
            .firstWhere((room) => room.id == widget.roomId);
        print("Sala cargada correctamente: ${_currentRoom?.name}");
        
        // Actualizar título de chat para salas 1:1
        if (_currentRoom != null && !_currentRoom!.isGroup && _currentRoom!.participants.length == 2) {
          String otherUserId = _currentRoom!.participants
              .firstWhere((id) => id != currentUserId, orElse: () => '');
              
          if (otherUserId.isNotEmpty) {
            // Intentar obtener nombre del otro usuario
            final httpService = HttpService(authService);
            final userService = UserService(httpService);
            
            try {
              final otherUser = await userService.getUserById(otherUserId);
              if (otherUser != null && mounted) {
                setState(() {
                  _chatTitle = otherUser.username;
                });
              } else {
                setState(() {
                  _chatTitle = _currentRoom!.name;
                });
              }
            } catch (e) {
              print("Error al obtener datos del otro usuario: $e");
              setState(() {
                _chatTitle = _currentRoom!.name;
              });
            }
          } else {
            setState(() {
              _chatTitle = _currentRoom!.name;
            });
          }
        } else {
          setState(() {
            _chatTitle = _currentRoom?.name ?? 'Chat';
          });
        }
      } catch (e) {
        print("No se encontró la sala en la lista: $e");
        // Si no encontramos la sala, intentamos cargar todas las salas
        if (authService.currentUser != null) {
          await chatService.loadChatRooms(authService.currentUser!.id);
          // Intentamos encontrar la sala de nuevo
          try {
            _currentRoom = chatService.chatRooms
                .firstWhere((room) => room.id == widget.roomId);
                
            // Actualizar título de chat para salas 1:1
            if (_currentRoom != null && !_currentRoom!.isGroup && _currentRoom!.participants.length == 2) {
              String otherUserId = _currentRoom!.participants
                  .firstWhere((id) => id != currentUserId, orElse: () => '');
                  
              if (otherUserId.isNotEmpty) {
                // Intentar obtener nombre del otro usuario
                final httpService = HttpService(authService);
                final userService = UserService(httpService);
                
                try {
                  final otherUser = await userService.getUserById(otherUserId);
                  if (otherUser != null && mounted) {
                    setState(() {
                      _chatTitle = otherUser.username;
                    });
                  } else {
                    setState(() {
                      _chatTitle = _currentRoom!.name;
                    });
                  }
                } catch (e) {
                  print("Error al obtener datos del otro usuario: $e");
                  setState(() {
                    _chatTitle = _currentRoom!.name;
                  });
                }
              } else {
                setState(() {
                  _chatTitle = _currentRoom!.name;
                });
              }
            } else {
              setState(() {
                _chatTitle = _currentRoom?.name ?? 'Chat';
              });
            }
          } catch (e) {
            print("Todavía no se encontró la sala después de recargar: $e");
          }
        }
      }
      
      if (_isAtBottom) {
        _scrollToBottom();
      }
    } catch (e) {
      print('Error cargando sala de chat: $e');
      setState(() {
        _showLoadingError = true;
        _errorMessage = 'Error al cargar los mensajes: $e';
      });
    } finally {
      if (mounted) {
        setState(() => _isLoadingMessages = false);
      }
    }
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        try {
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        } catch (e) {
          print('Error al desplazarse al fondo: $e');
        }
      });
    }
  }

  void _sendMessage() {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    try {
      final chatService = Provider.of<ChatService>(context, listen: false);
      print('Enviando mensaje a sala ${widget.roomId}: $text');
      chatService.sendMessage(widget.roomId, text);
      
      _messageController.clear();
      setState(() => _isAtBottom = true);
      _scrollToBottom();
    } catch (e) {
      print('Error al enviar mensaje: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al enviar el mensaje: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // Verificar el estado de la conexión del socket
    final socketService = Provider.of<SocketService>(context);
    final isConnected = socketService.socketStatus == SocketStatus.connected;
    
    return Scaffold(
      appBar: AppBar(
        title: Text(_chatTitle),
        actions: [
          // Se quitó el indicador de conexión (icono WiFi)
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadRoom,
            tooltip: 'Recargar mensajes',
          ),
        ],
      ),
      body: Column(
        children: [
          // Mensajes o indicador de carga
          Expanded(
            child: _buildMessageArea(),
          ),
          // Área de entrada de mensajes
          _buildMessageInput(),
        ],
      ),
    );
  }

  Widget _buildMessageArea() {
    if (_isLoadingMessages) {
      return const Center(child: CircularProgressIndicator());
    }
    
    if (_showLoadingError) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 48, color: Colors.red),
            const SizedBox(height: 16),
            Text(
              _errorMessage,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.red),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _loadRoom,
              icon: const Icon(Icons.refresh),
              label: const Text('Reintentar'),
            ),
          ],
        ),
      );
    }
    
    return Consumer<ChatService>(
      builder: (context, chatService, child) {
        final messages = chatService.getMessages(widget.roomId);
        
        if (messages.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.chat_bubble_outline,
                  size: 48,
                  color: Colors.grey,
                ),
                SizedBox(height: 16),
                Text(
                  'No hay mensajes en esta conversación',
                  style: TextStyle(color: Colors.grey),
                ),
                SizedBox(height: 8),
                Text(
                  'Sé el primero en enviar un mensaje',
                  style: TextStyle(color: Colors.grey),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          controller: _scrollController,
          padding: const EdgeInsets.all(8),
          itemCount: messages.length,
          itemBuilder: (context, index) {
            final message = messages[index];
            final isMyMessage = message.senderId ==
                Provider.of<AuthService>(context, listen: false)
                    .currentUser
                    ?.id;

            return MessageBubble(
              message: message,
              isMyMessage: isMyMessage,
            );
          },
        );
      },
    );
  }

  Widget _buildMessageInput() {
    // Verificar si el socket está conectado
    final socketService = Provider.of<SocketService>(context);
    final isConnected = socketService.socketStatus == SocketStatus.connected;
    
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.3),
            blurRadius: 4,
            offset: const Offset(0, -1),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _messageController,
              decoration: InputDecoration(
                hintText: isConnected 
                    ? 'Escribe un mensaje...' 
                    : 'Conectando...',
                border: const OutlineInputBorder(),
                filled: true,
                fillColor: Colors.grey[100],
                enabled: isConnected,
              ),
              keyboardType: TextInputType.multiline,
              textCapitalization: TextCapitalization.sentences,
              maxLines: null,
              onSubmitted: isConnected ? (_) => _sendMessage() : null,
            ),
          ),
          const SizedBox(width: 8),
          FloatingActionButton(
            onPressed: isConnected ? _sendMessage : null,
            mini: true,
            child: Icon(
              Icons.send,
              color: isConnected ? Colors.white : Colors.grey[400],
            ),
            backgroundColor: isConnected ? Colors.blue : Colors.grey[300],
          ),
        ],
      ),
    );
  }
}

class MessageBubble extends StatelessWidget {
  final Message message;
  final bool isMyMessage;

  const MessageBubble({
    Key? key,
    required this.message,
    required this.isMyMessage,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: isMyMessage ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: EdgeInsets.only(
          left: isMyMessage ? 64 : 8,
          right: isMyMessage ? 8 : 64,
          top: 4,
          bottom: 4,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isMyMessage ? Colors.blue : Colors.grey[300],
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (!isMyMessage)
              Text(
                message.senderName,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                  color: isMyMessage ? Colors.white70 : Colors.black87,
                ),
              ),
            Text(
              message.content,
              style: TextStyle(
                color: isMyMessage ? Colors.white : Colors.black87,
              ),
            ),
            Text(
              _formatTime(message.timestamp),
              style: TextStyle(
                fontSize: 10,
                color: isMyMessage ? Colors.white70 : Colors.black54,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatTime(DateTime time) {
    final localTime = time.toLocal();
    return '${localTime.hour.toString().padLeft(2, '0')}:${localTime.minute.toString().padLeft(2, '0')}';
  }
}