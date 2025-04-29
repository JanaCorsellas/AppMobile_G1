import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_application_1/services/notification_service.dart';
import 'package:flutter_application_1/widgets/notification_tile.dart';
import 'package:flutter_application_1/models/notification.dart' as app;
import 'package:flutter_application_1/config/routes.dart';

class NotificationScreen extends StatefulWidget {
  const NotificationScreen({Key? key}) : super(key: key);

  @override
  _NotificationScreenState createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  final ScrollController _scrollController = ScrollController();
  bool _isLoadingMore = false;
  int _currentPage = 1;
  
  @override
  void initState() {
    super.initState();
    _loadNotifications();
    
    // Configurar scroll infinito
    _scrollController.addListener(_scrollListener);
  }
  
  @override
  void dispose() {
    _scrollController.removeListener(_scrollListener);
    _scrollController.dispose();
    super.dispose();
  }
  
  void _scrollListener() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent * 0.8) {
      _loadMoreNotifications();
    }
  }
  
  Future<void> _loadNotifications() async {
    final notificationService = Provider.of<NotificationService>(context, listen: false);
    
    // Restablecer a la primera página
    _currentPage = 1;
    await notificationService.getNotifications(page: _currentPage);
    
    // Marcar todas como leídas automáticamente al ver la pantalla
    await notificationService.markAllAsRead();
  }
  
  Future<void> _loadMoreNotifications() async {
    if (_isLoadingMore) return;
    
    setState(() {
      _isLoadingMore = true;
    });
    
    final notificationService = Provider.of<NotificationService>(context, listen: false);
    
    // Cargar siguiente página
    _currentPage++;
    await notificationService.getNotifications(page: _currentPage);
    
    setState(() {
      _isLoadingMore = false;
    });
  }
  
  Future<void> _refreshNotifications() async {
    final notificationService = Provider.of<NotificationService>(context, listen: false);
    _currentPage = 1;
    await notificationService.getNotifications(page: _currentPage);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notificaciones'),
        actions: [
          // Botón para marcar todas como leídas
          IconButton(
            icon: const Icon(Icons.done_all),
            onPressed: () async {
              final notificationService = Provider.of<NotificationService>(context, listen: false);
              await notificationService.markAllAsRead();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Todas las notificaciones marcadas como leídas')),
              );
            },
            tooltip: 'Marcar todas como leídas',
          ),
        ],
      ),
      body: Consumer<NotificationService>(
        builder: (context, notificationService, child) {
          if (notificationService.isLoading && notificationService.notifications.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }
          
          if (notificationService.notifications.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.notifications_none,
                    size: 80,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No tienes notificaciones',
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            );
          }
          
          return RefreshIndicator(
            onRefresh: _refreshNotifications,
            child: ListView.builder(
              controller: _scrollController,
              itemCount: notificationService.notifications.length + (_isLoadingMore ? 1 : 0),
              itemBuilder: (context, index) {
                if (index >= notificationService.notifications.length) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(8.0),
                      child: CircularProgressIndicator(),
                    ),
                  );
                }
                
                final notification = notificationService.notifications[index];
                return Dismissible(
                  key: Key('notification_${notification.id}'),
                  direction: DismissDirection.endToStart,
                  background: Container(
                    color: Colors.red,
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: const Icon(
                      Icons.delete,
                      color: Colors.white,
                    ),
                  ),
                  confirmDismiss: (direction) async {
                    return await showDialog(
                      context: context,
                      builder: (BuildContext context) {
                        return AlertDialog(
                          title: const Text("Confirmar eliminación"),
                          content: const Text("¿Estás seguro de que quieres eliminar esta notificación?"),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.of(context).pop(false),
                              child: const Text("Cancelar"),
                            ),
                            TextButton(
                              onPressed: () => Navigator.of(context).pop(true),
                              child: const Text(
                                "Eliminar",
                                style: TextStyle(color: Colors.red),
                              ),
                            ),
                          ],
                        );
                      },
                    );
                  },
                  onDismissed: (direction) async {
                    await notificationService.deleteNotification(notification.id);
                    
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Notificación eliminada')),
                    );
                  },
                  child: NotificationTile(
                    notification: notification,
                    onTap: () => _handleNotificationTap(notification),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
  
  void _handleNotificationTap(app.Notification notification) async {
    // Marcar como leída
    final notificationService = Provider.of<NotificationService>(context, listen: false);
    await notificationService.markAsRead(notification.id);
    
    // Navegar según el tipo de notificación
    switch (notification.type) {
      case 'chat':
        if (notification.entityId != null) {
          Navigator.pushNamed(
            context, 
            AppRoutes.chatRoom,
            arguments: {'roomId': notification.entityId!}
          );
        } else {
          Navigator.pushNamed(context, AppRoutes.chatList);
        }
        break;
        
      case 'activity':
        // Navegar a la vista de actividad
        if (notification.entityId != null) {
          // Aquí deberías navegar a la vista de detalles de actividad
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Navegando a la actividad ${notification.entityId}')),
          );
        }
        break;
        
      case 'challenge':
        // Navegar a la vista de reto
        if (notification.entityId != null) {
          // Aquí deberías navegar a la vista de detalles de reto
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Navegando al reto ${notification.entityId}')),
          );
        }
        break;
        
      case 'achievement':
        // Navegar a la vista de logro
        if (notification.entityId != null) {
          // Aquí deberías navegar a la vista de detalles de logro
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Navegando al logro ${notification.entityId}')),
          );
        }
        break;
        
      case 'follow':
        // Navegar al perfil del usuario
        if (notification.sender.id.isNotEmpty) {
          // Aquí deberías navegar al perfil del usuario
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Navegando al perfil de usuario ${notification.sender.username ?? notification.sender.id}')),
          );
        }
        break;
        
      default:
        // No hacer nada para notificaciones del sistema
        break;
    }
  }
}