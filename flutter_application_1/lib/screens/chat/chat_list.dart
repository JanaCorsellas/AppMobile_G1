import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_application_1/models/chat_room_model.dart';
import 'package:flutter_application_1/services/auth_service.dart';
import 'package:flutter_application_1/services/chat_service.dart';
import 'package:flutter_application_1/services/user_service.dart';
import 'package:flutter_application_1/screens/chat/chat_room.dart';
import 'package:flutter_application_1/services/socket_service.dart';
import 'package:flutter_application_1/services/http_service.dart';

class ChatListScreen extends StatefulWidget {
  const ChatListScreen({Key? key}) : super(key: key);

  @override
  _ChatListScreenState createState() => _ChatListScreenState();
}

class _ChatListScreenState extends State<ChatListScreen> {
  late UserService _userService;
  List<Map<String, dynamic>> _users = [];
  bool _isLoadingUsers = false;
  bool _isLoading = false;
  bool _isInitialized = false;
  bool _isCreatingChat = false;
  bool _showCreateForm = false;

  @override
  void initState() {
    super.initState();
    // La carga real se realizará en didChangeDependencies
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    
    // Create the correct UserService
    final authService = Provider.of<AuthService>(context, listen: false);
    final httpService = HttpService(authService);
    _userService = UserService(httpService);
    
    // Solo inicializar una vez
    if (!_isInitialized) {
      _isInitialized = true;
      // Usar Future.microtask para evitar setState durante build
      Future.microtask(() {
        _loadChatRooms();
        _loadUsers();
      });
    }
  }

  // Cargar usuarios disponibles para crear chats
  Future<void> _loadUsers() async {
    setState(() {
      _isLoadingUsers = true;
    });

    try {
      final response = await _userService.getUsers(limit: 100);
      final currentUserId = Provider.of<AuthService>(context, listen: false).currentUser?.id;
      
      setState(() {
        // Filtrar para no incluir al usuario actual
        _users = response['users']
            .where((user) => user.id != currentUserId)
            .map<Map<String, dynamic>>((user) => {
                  'id': user.id,
                  'username': user.username,
                })
            .toList();
        _isLoadingUsers = false;
      });
    } catch (e) {
      print('Error cargando usuarios: $e');
      setState(() {
        _isLoadingUsers = false;
      });
    }
  }

  // Cargar salas de chat
  Future<void> _loadChatRooms() async {
    setState(() {
      _isLoading = true;
    });
    
    final authService = Provider.of<AuthService>(context, listen: false);
    final chatService = Provider.of<ChatService>(context, listen: false);
    
    if (authService.currentUser != null) {
      await chatService.loadChatRooms(authService.currentUser!.id);
    }
    
    setState(() {
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final chatService = Provider.of<ChatService>(context);
    final socketService = Provider.of<SocketService>(context);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Chats'),
        actions: [
          // Estado de conexión
          _buildConnectionStatus(socketService),
          // Botón de actualizar
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _isLoading ? null : _loadChatRooms,
            tooltip: 'Actualizar',
          ),
        ],
      ),
      body: _isLoading || chatService.isLoading
          ? const Center(child: CircularProgressIndicator())
          : _showCreateForm
              ? _buildCreateChatForm()
              : chatService.chatRooms.isEmpty
                  ? _buildEmptyState()
                  : _buildChatRoomsList(chatService.chatRooms),
      floatingActionButton: FloatingActionButton(
        onPressed: _isLoading ? null : () => _showNewChatDialog(context),
        child: const Icon(Icons.add),
        tooltip: 'Nuevo chat',
      ),
    );
  }

  // Widget de estado de conexión
  Widget _buildConnectionStatus(SocketService socketService) {
    Color statusColor;
    IconData statusIcon;
    
    switch (socketService.socketStatus) {
      case SocketStatus.connected:
        statusColor = Colors.green;
        statusIcon = Icons.check_circle;
        break;
      case SocketStatus.connecting:
        statusColor = Colors.amber;
        statusIcon = Icons.pending;
        break;
      case SocketStatus.disconnected:
        statusColor = Colors.red;
        statusIcon = Icons.error;
        break;
    }
    
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0),
      child: Icon(statusIcon, color: statusColor),
    );
  }

  // Formulario para crear chat (placeholder, se puede implementar posteriormente)
  Widget _buildCreateChatForm() {
    return const Center(
      child: Text('Formulario de creación de chat'),
    );
  }

  // Estado cuando no hay chats
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.chat_bubble_outline,
            size: 80,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'No tienes conversaciones',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Inicia un nuevo chat con el botón +',
            style: TextStyle(
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }

  // Lista de salas de chat
  Widget _buildChatRoomsList(List<ChatRoom> chatRooms) {
    return RefreshIndicator(
      onRefresh: _loadChatRooms,
      child: ListView.builder(
        itemCount: chatRooms.length,
        itemBuilder: (context, index) {
          final room = chatRooms[index];
          return _buildChatRoomItem(room);
        },
      ),
    );
  }

  // Item de sala de chat
  Widget _buildChatRoomItem(ChatRoom room) {
    // Icono según tipo de chat
    IconData chatIcon = room.isGroup ? Icons.group : Icons.person;
    Color chatColor = room.isGroup ? Colors.blue : Colors.deepPurple;
    
    return Dismissible(
      key: Key('room_${room.id}'), // Usar un Key único que incluya el tipo
      background: Container(
        color: Colors.red,
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20.0),
        child: const Icon(
          Icons.delete,
          color: Colors.white,
        ),
      ),
      direction: DismissDirection.endToStart,
      confirmDismiss: (direction) async {
        return await showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: const Text("Confirmar eliminación"),
              content: const Text("¿Estás seguro de que quieres eliminar este chat? Esta acción no se puede deshacer y se perderán todos los mensajes."),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: const Text("Cancelar"),
                ),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  child: const Text("Eliminar", style: TextStyle(color: Colors.red)),
                ),
              ],
            );
          },
        );
      },
      onDismissed: (direction) async {
        final chatService = Provider.of<ChatService>(context, listen: false);
        final success = await chatService.deleteChatRoom(room.id);
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(success ? 'Chat eliminado' : 'Error al eliminar el chat'),
            action: success ? null : SnackBarAction(
              label: 'Reintentar',
              onPressed: () => chatService.deleteChatRoom(room.id),
            ),
          ),
        );
      },
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: chatColor.withOpacity(0.2),
          child: Icon(
            chatIcon,
            color: chatColor,
          ),
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(
                room.name.isNotEmpty ? room.name : 'Chat',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            // Indicador para chats grupales
            if (room.isGroup)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '${room.participants.length}',
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.blue,
                  ),
                ),
              ),
          ],
        ),
        subtitle: room.lastMessage != null
            ? Text(
                room.lastMessage!,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              )
            : const Text(
                'No hay mensajes aún',
                style: TextStyle(fontStyle: FontStyle.italic),
              ),
        trailing: room.lastMessageTime != null
            ? Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    _formatTime(room.lastMessageTime!),
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Icon(
                    Icons.arrow_forward_ios,
                    size: 14,
                    color: Colors.grey[400],
                  ),
                ],
              )
            : Icon(
                Icons.arrow_forward_ios,
                size: 14,
                color: Colors.grey[400],
              ),
        onTap: () async {
          final chatService = Provider.of<ChatService>(context, listen: false);
          setState(() {
            _isLoading = true;
          });
          
          await chatService.loadMessages(room.id);
          
          if (!mounted) return;
          
          setState(() {
            _isLoading = false;
          });
          
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ChatRoomScreen(roomId: room.id),
            ),
          ).then((_) async {
            // Recargar datos al volver
            await _loadChatRooms();
          });
        },
      ),
    );
  }

  // Formatear hora del último mensaje
  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final messageDate = DateTime(time.year, time.month, time.day);
    
    if (messageDate == today) {
      return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
    } else if (messageDate == yesterday) {
      return 'Ayer';
    } else {
      return '${time.day}/${time.month}';
    }
  }

  // Diálogo para crear nuevo chat
  void _showNewChatDialog(BuildContext context) {
    final TextEditingController nameController = TextEditingController();
    List<String> selectedUserIds = [];
    String? selectedUserId;  
    bool isGroupChat = false;
    
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: Text(isGroupChat ? 'Nuevo chat grupal' : 'Nuevo chat'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Selector de tipo de chat
                  SwitchListTile(
                    title: const Text('Chat grupal'),
                    value: isGroupChat,
                    onChanged: (value) {
                      setState(() {
                        isGroupChat = value;
                        if (!isGroupChat) {
                          nameController.clear();
                          selectedUserIds = selectedUserIds.isEmpty ? [] : [selectedUserIds.first];
                        }
                      });
                    },
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Nombre para chats grupales
                  if (isGroupChat)
                    TextField(
                      controller: nameController,
                      decoration: const InputDecoration(
                        labelText: 'Nombre del grupo',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  
                  const SizedBox(height: 16),
                  const Text('Selecciona usuarios:'),
                  const SizedBox(height: 8),
                  
                  // Usuarios seleccionados como chips
                  if (selectedUserIds.isNotEmpty)
                    Container(
                      constraints: const BoxConstraints(maxHeight: 100),
                      child: SingleChildScrollView(
                        child: Wrap(
                          spacing: 6.0,
                          runSpacing: 6.0,
                          children: selectedUserIds.map((userId) {
                            final user = _users.firstWhere(
                              (u) => u['id'] == userId,
                              orElse: () => {'id': userId, 'username': 'Usuario'},
                            );
                            return Chip(
                              label: Text(user['username']),
                              onDeleted: () {
                                setState(() {
                                  selectedUserIds.remove(userId);
                                });
                              },
                            );
                          }).toList(),
                        ),
                      ),
                    ),
                  
                  const SizedBox(height: 16),
                  _isLoadingUsers
                      ? const Center(child: CircularProgressIndicator())
                      : _users.isEmpty
                        ? const Text('No hay usuarios disponibles')
                        : DropdownButton<String>(
                            hint: const Text('Seleccionar usuario'),
                            value: selectedUserId,
                            isExpanded: true,
                            items: _users
                                .where((user) => !selectedUserIds.contains(user['id']))
                                .map<DropdownMenuItem<String>>((user) {
                              return DropdownMenuItem<String>(
                                value: user['id'],
                                child: Text(user['username']),
                              );
                            }).toList(),
                            onChanged: (value) {
                              if (value != null) {
                                setState(() {
                                  if (!isGroupChat) {
                                    // Solo un usuario para chat individual
                                    selectedUserIds = [value];
                                  } else {
                                    // Añadir a la lista para grupos
                                    selectedUserIds.add(value);
                                  }
                                  selectedUserId = null; // Resetear selección
                                });
                              }
                            },
                          ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancelar'),
              ),
              TextButton(
                onPressed: () async {
                  if (selectedUserIds.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Selecciona al menos un usuario')),
                    );
                    return;
                  }
                  
                  if (isGroupChat && nameController.text.trim().isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Ingresa un nombre para el grupo')),
                    );
                    return;
                  }
                  
                  Navigator.pop(context);
                  
                  setState(() => _isCreatingChat = true);
                  
                  try {
                    final authService = Provider.of<AuthService>(context, listen: false);
                    final chatService = Provider.of<ChatService>(context, listen: false);
                    final currentUserId = authService.currentUser?.id ?? '';
                    
                    if (currentUserId.isEmpty) {
                      throw Exception('No se pudo identificar al usuario actual');
                    }
                    
                    // Incluir al usuario actual en los participantes
                    final allParticipants = [currentUserId, ...selectedUserIds];
                    
                    // Nombre del chat
                    String chatName;
                    if (isGroupChat) {
                      chatName = nameController.text.trim();
                    } else {
                      // Para chat individual, usar nombre del otro usuario
                      final otherUser = _users.firstWhere(
                        (u) => u['id'] == selectedUserIds[0],
                        orElse: () => {'username': 'Chat'},
                      );
                      chatName = otherUser['username'];
                    }
                    
                    // Crear sala de chat
                    final room = await chatService.createChatRoom(
                      chatName,
                      allParticipants,
                      isGroupChat ? 'Chat grupal' : null,
                    );
                    
                    if (room != null) {
                      // Navegar a la nueva sala
                      if (mounted) {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => ChatRoomScreen(roomId: room.id),
                          ),
                        ).then((_) {
                          _loadChatRooms();
                        });
                      }
                    }
                  } catch (e) {
                    print('Error creando chat: $e');
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Error: $e')),
                    );
                  } finally {
                    if (mounted) {
                      setState(() => _isCreatingChat = false);
                    }
                  }
                },
                child: const Text('Crear'),
              ),
            ],
          );
        },
      ),
    );
  }
}