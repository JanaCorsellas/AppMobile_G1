// lib/widgets/user_list_tile.dart - Widget para mostrar usuarios en listas
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_application_1/models/user.dart';
import 'package:flutter_application_1/services/follow_service.dart';
import 'package:flutter_application_1/services/auth_service.dart';
import 'package:flutter_application_1/extensions/string_extensions.dart';

class UserListTile extends StatefulWidget {
  final User user;
  final bool showFollowButton;
  final VoidCallback? onUserTap;
  final VoidCallback? onFollowChanged;

  const UserListTile({
    Key? key,
    required this.user,
    this.showFollowButton = false,
    this.onUserTap,
    this.onFollowChanged,
  }) : super(key: key);

  @override
  State<UserListTile> createState() => _UserListTileState();
}

class _UserListTileState extends State<UserListTile> {
  bool _isFollowing = false;
  bool _isLoading = false;
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    if (widget.showFollowButton) {
      _checkFollowStatus();
    }
  }

  Future<void> _checkFollowStatus() async {
    final authService = Provider.of<AuthService>(context, listen: false);
    final followService = Provider.of<FollowService>(context, listen: false);
    
    final currentUser = authService.currentUser;
    if (currentUser == null || currentUser.id == widget.user.id) {
      return;
    }

    try {
      final status = await followService.checkFollowStatus(
        currentUser.id,
        widget.user.id,
        authService.accessToken,
      );

      if (mounted) {
        setState(() {
          _isFollowing = status['isFollowing'] ?? false;
          _isInitialized = true;
        });
      }
    } catch (e) {
      print('Error verificando estado de seguimiento: $e');
      if (mounted) {
        setState(() {
          _isInitialized = true;
        });
      }
    }
  }

  Future<void> _toggleFollow() async {
    final authService = Provider.of<AuthService>(context, listen: false);
    final followService = Provider.of<FollowService>(context, listen: false);
    
    final currentUser = authService.currentUser;
    if (currentUser == null) return;

    setState(() {
      _isLoading = true;
    });

    try {
      bool success;
      if (_isFollowing) {
        success = await followService.unfollowUser(
          currentUser.id,
          widget.user.id,
          authService.accessToken,
        );
      } else {
        success = await followService.followUser(
          currentUser.id,
          widget.user.id,
          authService.accessToken,
        );
      }

      if (success && mounted) {
        setState(() {
          _isFollowing = !_isFollowing;
        });
        
        // Notificar cambio al widget padre
        widget.onFollowChanged?.call();
        
        // Mostrar mensaje de confirmación
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _isFollowing
                  ? 'following_user'.tr(context).replaceAll('{user}', widget.user.username)
                  : 'unfollowed_user'.tr(context).replaceAll('{user}', widget.user.username),
            ),
            duration: const Duration(seconds: 2),
            backgroundColor: _isFollowing ? Colors.green : Colors.orange,
          ),
        );
      } else if (followService.error.isNotEmpty) {
        // Mostrar error
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(followService.error),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      // Mostrar error genérico
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al procesar la acción: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);
    final isCurrentUser = authService.currentUser?.id == widget.user.id;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      elevation: 2,
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: _buildAvatar(),
        title: Text(
          widget.user.username,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 16,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (widget.user.bio != null && widget.user.bio!.isNotEmpty)
              Text(
                widget.user.bio!,
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 14,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(
                  Icons.star,
                  size: 16,
                  color: Colors.amber[600],
                ),
                const SizedBox(width: 4),
                Text(
                  '${'level'.tr(context)} ${widget.user.level}',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(width: 16),
                Icon(
                  Icons.people,
                  size: 16,
                  color: Colors.blue[600],
                ),
                const SizedBox(width: 4),
                Text(
                  '${widget.user.followersCount} ${'followers'.tr(context)}',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ],
        ),
        trailing: _buildTrailing(isCurrentUser),
        onTap: widget.onUserTap,
      ),
    );
  }

  Widget _buildAvatar() {
    return CircleAvatar(
      radius: 24,
      backgroundColor: Colors.grey[300],
      backgroundImage: widget.user.profilePicture != null && widget.user.profilePicture!.isNotEmpty
          ? NetworkImage(widget.user.profilePicture!)
          : null,
      child: widget.user.profilePicture == null || widget.user.profilePicture!.isEmpty
          ? Text(
              widget.user.username.isNotEmpty 
                  ? widget.user.username[0].toUpperCase() 
                  : '?',
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            )
          : null,
    );
  }

  Widget? _buildTrailing(bool isCurrentUser) {
    if (!widget.showFollowButton || isCurrentUser) {
      return const Icon(Icons.chevron_right);
    }

    if (!_isInitialized) {
      return const SizedBox(
        width: 20,
        height: 20,
        child: CircularProgressIndicator(strokeWidth: 2),
      );
    }

    return SizedBox(
      width: 100,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _toggleFollow,
        style: ElevatedButton.styleFrom(
          backgroundColor: _isFollowing ? Colors.grey[300] : Colors.blue,
          foregroundColor: _isFollowing ? Colors.black87 : Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          minimumSize: const Size(80, 32),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        child: _isLoading
            ? const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            : Text(
                _isFollowing ? 'unfollow'.tr(context) : 'follow'.tr(context),
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
      ),
    );
  }
}