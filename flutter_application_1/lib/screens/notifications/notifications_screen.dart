// lib/screens/notifications/notifications_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_application_1/screens/notifications/notification_detail_screen.dart';
import 'package:flutter_application_1/screens/chat/chat_room.dart';
import 'package:flutter_application_1/widgets/custom_drawer.dart';
import 'package:provider/provider.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:flutter_application_1/models/notification_models.dart';
import 'package:flutter_application_1/services/auth_service.dart';
import 'package:flutter_application_1/services/notification_services.dart';
import 'package:flutter_application_1/config/routes.dart';
import 'package:flutter_application_1/extensions/string_extensions.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({Key? key}) : super(key: key);

  @override
  _NotificationsScreenState createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  bool _isLoading = false;
  bool _isRefreshing = false;
  String? _errorMessage;
  final ScrollController _scrollController = ScrollController();
  int _currentPage = 1;
  bool _hasMoreData = true;

  @override
  void initState() {
    super.initState();
    _loadNotifications();
    
    // Add pagination listener
    _scrollController.addListener(_scrollListener);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_scrollListener);
    _scrollController.dispose();
    super.dispose();
  }

  // Listener for scroll pagination
  void _scrollListener() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent * 0.8 &&
        !_isLoading &&
        _hasMoreData) {
      _loadMoreNotifications();
    }
  }

  // Initial load of notifications
  Future<void> _loadNotifications() async {
    if (_isLoading) return;
    
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    
    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      final notificationService = Provider.of<NotificationService>(context, listen: false);
      
      if (authService.currentUser != null) {
        await notificationService.fetchNotifications(
          authService.currentUser!.id, 
          page: 1,
          limit: 20
        );
        
        _currentPage = 1;
        _hasMoreData = notificationService.notifications.length >= 20;
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'load_notifications_error'.tr(context);
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // Load more notifications for pagination
  Future<void> _loadMoreNotifications() async {
    if (_isLoading || !_hasMoreData) return;
    
    setState(() {
      _isLoading = true;
    });
    
    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      final notificationService = Provider.of<NotificationService>(context, listen: false);
      
      if (authService.currentUser != null) {
        final initialCount = notificationService.notifications.length;
        
        _currentPage++;
        await notificationService.fetchNotifications(
          authService.currentUser!.id, 
          page: _currentPage,
          limit: 20
        );
        
        // Check if we got new items
        final newCount = notificationService.notifications.length;
        _hasMoreData = newCount > initialCount;
      }
    } catch (e) {
      print('Error loading more notifications: $e');
      // Don't show error message for pagination failures
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // Pull to refresh
  Future<void> _refreshNotifications() async {
     setState(() {
    _isRefreshing = true;
  });
  
  try {
    await _loadNotifications();
  } finally {
    setState(() {
      _isRefreshing = false;
    });
  }
  }

  // Mark all as read
  Future<void> _markAllAsRead() async {
    final authService = Provider.of<AuthService>(context, listen: false);
    final notificationService = Provider.of<NotificationService>(context, listen: false);
    
    if (authService.currentUser == null) return;
    
    try {
      final success = await notificationService.markAllAsRead(authService.currentUser!.id);
      
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('all_notifications_read'.tr(context)))
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('error'.tr(context) + ': $e'))
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: const CustomDrawer(currentRoute: AppRoutes.notifications),
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 120,
            floating: false,
            pinned: true,
            elevation: 0,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Color(0xFF667eea),
                      Color(0xFF764ba2),
                    ],
                  ),
                ),
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 20),
                        Text(
                          'Notificaciones'.tr(context),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Tus notificaciones'.tr(context),
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.9),
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            actions: [
              Consumer<NotificationService>(
                builder: (context, notificationService, child) {
                  if (notificationService.unreadCount > 0) {
                    return IconButton(
                      icon: const Icon(Icons.done_all, color: Colors.white),
                      tooltip: 'mark_all_read'.tr(context),
                      onPressed: _markAllAsRead,
                    );
                  }
                  return const SizedBox.shrink();
                },
              ),
            ],
            bottom: _isRefreshing 
                ? const PreferredSize(
                    preferredSize: Size.fromHeight(2.0),
                    child: LinearProgressIndicator(),
                  )
                : null,
          ),

          SliverToBoxAdapter(
            child: RefreshIndicator(
              onRefresh: _refreshNotifications,
              child: Consumer<NotificationService>(
                builder: (context, notificationService, child) {
                  if (_isLoading && _currentPage == 1) {
                    return const SizedBox(
                      height: 300,
                      child: Center(child: CircularProgressIndicator()),
                    );
                  }

                  if (_errorMessage != null) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.error_outline, size: 48, color: Colors.red[300]),
                          const SizedBox(height: 16),
                          Text(
                            _errorMessage!,
                            textAlign: TextAlign.center,
                            style: TextStyle(color: Colors.red[300]),
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: _loadNotifications,
                            child: Text('retry'.tr(context)),
                          ),
                        ],
                      ),
                    );
                  }

                  final notifications = notificationService.notifications;

                  if (notifications.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.notifications_off, size: 64, color: Colors.grey[400]),
                          const SizedBox(height: 16),
                          Text(
                            'no_notifications'.tr(context),
                            style: TextStyle(
                              fontSize: 18,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  return Column(
                    children: [
                      ...notifications.map((notification) => _buildNotificationItem(notification)).toList(),
                      if (_hasMoreData)
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 16),
                          child: CircularProgressIndicator(),
                         ),
                      ],
                    );
                  },
                ),
              ),
            ),
          ],
        ),
    );
  }

  Widget _buildNotificationItem(NotificationModel notification) {
    return Dismissible(
      key: Key('notification_${notification.id}'),
      background: Container(
        color: Colors.red,
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 16.0),
        child: const Icon(
          Icons.delete,
          color: Colors.white,
        ),
      ),
      direction: DismissDirection.endToStart,
      onDismissed: (direction) {
        _deleteNotification(notification.id);
      },
      confirmDismiss: (direction) async {
        return await showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: Text('delete_notification'.tr(context)),
              content: Text('delete_notification_confirm'.tr(context)),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: Text('cancel'.tr(context)),
                ),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  child: Text('delete'.tr(context)),
                ),
              ],
            );
          },
        );
      },
      child: Card(
        margin: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 8.0),
        child: ListTile(
          leading: Container(
            padding: const EdgeInsets.all(8.0),
            decoration: BoxDecoration(
              color: notification.getColor().withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(
              notification.getIcon(),
              color: notification.getColor(),
            ),
          ),
          title: Text(
            notification.title,
            style: TextStyle(
              fontWeight: notification.read ? FontWeight.normal : FontWeight.bold,
            ),
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(notification.message),
              const SizedBox(height: 4),
              Text(
                timeago.format(notification.createdAt, locale: 'es'),
                style: const TextStyle(
                  fontSize: 12,
                  color: Colors.grey,
                ),
              ),
            ],
          ),
          trailing: notification.read
              ? null
              : Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: Colors.blue,
                    shape: BoxShape.circle,
                  ),
                ),
          onTap: () {
            _markAsRead(notification);
            _navigateToNotificationDetail(notification);
          },
        ),
      ),
    );
  }

  Future<void> _markAsRead(NotificationModel notification) async {
    if (!notification.read) {
      final notificationService = Provider.of<NotificationService>(context, listen: false);
      await notificationService.markAsRead(notification.id);
    }
  }

  void _navigateToNotificationDetail(NotificationModel notification) {
    _markAsRead(notification);
    // Navigate based on notification type and data
    if (notification.type == 'chat_message' && notification.data != null) {
      final roomId = notification.data?['roomId'];
      if (roomId != null) {
        // Navigate directly to chat room
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ChatRoomScreen(roomId: roomId),
          ),
        );
        return;
      }
    } else if (notification.type == 'achievement_unlocked' && notification.data != null) {
      final achievementId = notification.data?['achievementId'];
      if (achievementId != null) {
        // Navigate to achievement detail
        // Navigator.pushNamed(context, AppRoutes.achievementDetail, arguments: {'id': achievementId});
        return;
      }
    } else if (notification.type == 'challenge_completed' && notification.data != null) {
      final challengeId = notification.data?['challengeId'];
      if (challengeId != null) {
        // Navigate to challenge detail
        // Navigator.pushNamed(context, AppRoutes.challengeDetail, arguments: {'id': challengeId});
        return;
      }
    } else if (notification.type == 'friend_request' && notification.data != null) {
      final userId = notification.data?['userId'];
      if (userId != null) {
        // Navigate to user profile
        // Navigator.pushNamed(context, AppRoutes.userProfile, arguments: {'id': userId});
        return;
      }
    }
    
    // Default: Show notification detail
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => NotificationDetailScreen(notificationId: notification.id),
      ),
    );
  }

  Future<void> _deleteNotification(String notificationId) async {
    final notificationService = Provider.of<NotificationService>(context, listen: false);
    
    try {
      final success = await notificationService.deleteNotification(notificationId);
      
      if (!success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('delete_notification_error'.tr(context)))
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('error'.tr(context) + ': $e'))
        );
      }
    }
  }
}