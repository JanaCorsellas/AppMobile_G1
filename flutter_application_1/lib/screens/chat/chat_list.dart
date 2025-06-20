// lib/screens/chat/chat_list.dart
import 'package:flutter/material.dart';
import 'package:flutter_application_1/config/routes.dart';
import 'package:flutter_application_1/widgets/custom_drawer.dart';
import 'package:provider/provider.dart';
import 'package:flutter_application_1/models/chat_room_model.dart';
import 'package:flutter_application_1/services/auth_service.dart';
import 'package:flutter_application_1/services/chat_service.dart';
import 'package:flutter_application_1/services/user_service.dart';
import 'package:flutter_application_1/screens/chat/chat_room.dart';
import 'package:flutter_application_1/services/socket_service.dart';
import 'package:flutter_application_1/services/http_service.dart';
import 'package:flutter_application_1/extensions/string_extensions.dart';
import 'package:cached_network_image/cached_network_image.dart';


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
  
  // Map para almacenar nombres de usuarios para chats personales
  Map<String, Map<String, String>> _userCache = {};

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
      
      // Pre-cargar nombres de usuarios para chats personales
      await _loadUserNamesForChats(chatService.chatRooms, authService.currentUser!.id);
    }
    
    setState(() {
      _isLoading = false;
    });
  }
  
  // Cargar nombres de usuarios para chats personales
  Future<void> _loadUserNamesForChats(List<ChatRoom> rooms, String currentUserId) async {
    for (var room in rooms) {
      if (!room.isGroup && room.participants.length == 2) {
        try {
          // Encontrar el ID del otro usuario
          final otherUserId = room.participants.firstWhere(
            (id) => id != currentUserId,
            orElse: () => '',
          );
          
          if (otherUserId.isNotEmpty && !_userCache.containsKey(otherUserId)) {
            final user = await _userService.getUserById(otherUserId);
            if (user != null) {
              setState(() {
                _userCache[otherUserId] = {
                  'username': user.username,
                  'profilePictureUrl': user.profilePictureUrl ?? '',
                };
              });
            }
          }
        } catch (e) {
          print('Error cargando nombre de usuario: $e');
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final chatService = Provider.of<ChatService>(context);
    
    return Scaffold(
      drawer: const CustomDrawer(currentRoute: AppRoutes.chatList),
      appBar: AppBar(
        title: Text('chat'.tr(context)),
        actions: [
          // Botón de actualizar
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _isLoading ? null : _loadChatRooms,
            tooltip: 'refresh'.tr(context),
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
        tooltip: 'new_chat'.tr(context),
      ),
    );
  }

  // Widget de estado cuando no hay chats
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
            'no_conversations'.tr(context),
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'start_new_chat'.tr(context),
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
    final currentUserId = Provider.of<AuthService>(context, listen: false).currentUser?.id ?? '';
    
    return RefreshIndicator(
      onRefresh: _loadChatRooms,
      child: ListView.builder(
        itemCount: chatRooms.length,
        itemBuilder: (context, index) {
          final room = chatRooms[index];
          
          // Para chats 1:1, mostrar el nombre del otro usuario
          String displayName = room.name;
          if (!room.isGroup && room.participants.length == 2) {
            final otherUserId = room.participants.firstWhere(
              (id) => id != currentUserId,
              orElse: () => '',
            );
            
            if (otherUserId.isNotEmpty && _userCache.containsKey(otherUserId)) {
              displayName = _userCache[otherUserId]!['username'] ?? room.name;
            }
          }
          
          return _buildChatRoomItem(room, displayName);
        },
      ),
    );
  }

  // Item de sala de chat
  Widget _buildChatRoomItem(ChatRoom room, String displayName) {
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
              title: Text('confirm_delete'.tr(context)),
              content: Text('confirm_delete_chat'.tr(context)),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: Text('cancel'.tr(context)),
                ),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  child: Text('delete'.tr(context), style: const TextStyle(color: Colors.red)),
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
            content: Text(success ? 'chat_deleted'.tr(context) : 'chat_delete_error'.tr(context)),
            action: success ? null : SnackBarAction(
              label: 'retry'.tr(context),
              onPressed: () => chatService.deleteChatRoom(room.id),
            ),
          ),
        );
      },
      child: ListTile(
        leading: room.isGroup 
          ? _buildGroupAvatar(room) 
          : _buildUserAvatar(room),

        title: Row(
          children: [
            Expanded(
              child: Text(
                displayName.isNotEmpty ? displayName : 'chat'.tr(context),
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
            : Text(
                'no_messages_yet'.tr(context),
                style: const TextStyle(fontStyle: FontStyle.italic),
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

  Widget _buildUserAvatar(ChatRoom room) {
    final currentUserId = Provider.of<AuthService>(context, listen: false).currentUser?.id ?? '';
    final otherUserId = room.participants.firstWhere(
      (id) => id != currentUserId,
      orElse: () => '',
    );
    final userData = _userCache[otherUserId];
    final profileUrl = userData?['profilePictureUrl'] ?? '';

    if (profileUrl.isNotEmpty) {
      return CircleAvatar(
        backgroundColor: Colors.grey[200],
        backgroundImage: CachedNetworkImageProvider(profileUrl),
      );
    } else {
      return const CircleAvatar(
        backgroundColor: Colors.grey,
        child: Icon(Icons.person, color: Colors.white),
      );
    }
  }

  Widget _buildGroupAvatar(ChatRoom room) {
    // Si tiene foto de grupo, mostrarla
    if (room.groupPictureUrl != null && room.groupPictureUrl!.isNotEmpty) {
      return CircleAvatar(
        backgroundColor: Colors.grey[200],
        backgroundImage: CachedNetworkImageProvider(room.groupPictureUrl!),
      );
    } else {
      // Sin foto: icono por defecto
      return CircleAvatar(
        backgroundColor: Colors.blue.withOpacity(0.2),
        child: const Icon(Icons.group, color: Colors.blue),
      );
    }
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
      return 'yesterday'.tr(context);
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
            title: Text(isGroupChat ? 'new_group_chat'.tr(context) : 'new_chat'.tr(context)),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Selector de tipo de chat
                  SwitchListTile(
                    title: Text('group_chat'.tr(context)),
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
                      decoration: InputDecoration(
                        labelText: 'group_name'.tr(context),
                        border: const OutlineInputBorder(),
                      ),
                    ),
                  
                  const SizedBox(height: 16),
                  Text('select_users'.tr(context) + ':'),
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
                              orElse: () => {'id': userId, 'username': 'user'.tr(context)},
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
                        ? Text('no_users_available'.tr(context))
                        : DropdownButton<String>(
                            hint: Text('select_user'.tr(context)),
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
                child: Text('cancel'.tr(context)),
              ),
              TextButton(
                onPressed: () async {
                  if (selectedUserIds.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('select_at_least_one_user'.tr(context))),
                    );
                    return;
                  }
                  
                  if (isGroupChat && nameController.text.trim().isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('enter_group_name'.tr(context))),
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
                      throw Exception('current_user_not_identified'.tr(context));
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
                        orElse: () => {'username': 'chat'.tr(context)},
                      );
                      chatName = otherUser['username'];
                      
                      // Guardar en caché
                      _userCache[selectedUserIds[0]] = {
                        'username': otherUser['username'],
                        'profilePictureUrl': otherUser['profilePictureUrl'] ?? '',
                      };
                    }
                    
                    // Crear sala de chat
                    final room = await chatService.createChatRoom(
                      chatName,
                      allParticipants,
                      isGroupChat ? 'group_chat'.tr(context) : null,
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
                      SnackBar(content: Text('error'.tr(context) + ': $e')),
                    );
                  } finally {
                    if (mounted) {
                      setState(() => _isCreatingChat = false);
                    }
                  }
                },
                child: Text('create'.tr(context)),
              ),
            ],
          );
        },
      ),
    );
  }
  
  // Placeholder para el formulario de creación
  Widget _buildCreateChatForm() {
    return Center(
      child: Text('create_chat_form'.tr(context)),
    );
  }
}