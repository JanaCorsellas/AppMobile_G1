import 'package:flutter/material.dart';
import 'package:flutter_application_1/models/user.dart';

class UserCard extends StatelessWidget {
  final User user;
  final VoidCallback onView;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onToggleVisibility;

  const UserCard({
    Key? key,
    required this.user,
    required this.onView,
    required this.onEdit,
    required this.onDelete,
    required this.onToggleVisibility,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12.0),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12.0),
      ),
      child: Opacity(
        opacity: user.visibility ? 1.0 : 0.6,
        child: Column(
          children: [
            ListTile(
              leading: CircleAvatar(
                backgroundColor: Colors.grey.shade200,
                backgroundImage: user.profilePicture != null && user.profilePicture!.isNotEmpty
                    ? NetworkImage(user.profilePicture!)
                    : null,
                child: user.profilePicture == null || user.profilePicture!.isEmpty
                    ? const Icon(
                        Icons.person,
                        color: Colors.grey,
                      )
                    : null,
              ),
              title: Row(
                children: [
                  Text(
                    user.username,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (!user.visibility)
                    Container(
                      margin: const EdgeInsets.only(left: 8),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Text(
                        'Hidden',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.black54,
                        ),
                      ),
                    ),
                ],
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(user.email),
                  const SizedBox(height: 4),
                  Text('Level: ${user.level}'),
                ],
              ),
              trailing: IconButton(
                icon: const Icon(Icons.more_vert),
                onPressed: () {
                  _showOptionsMenu(context);
                },
              ),
              onTap: onView,
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.directions_run,
                        size: 16,
                        color: Colors.grey.shade700,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${user.activities?.length ?? 0} activities',
                        style: TextStyle(
                          color: Colors.grey.shade700,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      Icon(
                        Icons.emoji_events,
                        size: 16,
                        color: Colors.grey.shade700,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${user.achievements?.length ?? 0} achievements',
                        style: TextStyle(
                          color: Colors.grey.shade700,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      Icon(
                        Icons.flag,
                        size: 16,
                        color: Colors.grey.shade700,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${user.challengesCompleted?.length ?? 0} challenges',
                        style: TextStyle(
                          color: Colors.grey.shade700,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showOptionsMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.visibility),
                title: Text(user.visibility ? 'Hide User' : 'Show User'),
                onTap: () {
                  Navigator.pop(context);
                  onToggleVisibility();
                },
              ),
              ListTile(
                leading: const Icon(Icons.info),
                title: const Text('View Details'),
                onTap: () {
                  Navigator.pop(context);
                  onView();
                },
              ),
              ListTile(
                leading: const Icon(Icons.edit),
                title: const Text('Edit User'),
                onTap: () {
                  Navigator.pop(context);
                  onEdit();
                },
              ),
              ListTile(
                leading: const Icon(
                  Icons.delete,
                  color: Colors.red,
                ),
                title: const Text(
                  'Delete User',
                  style: TextStyle(color: Colors.red),
                ),
                onTap: () {
                  Navigator.pop(context);
                  onDelete();
                },
              ),
            ],
          ),
        );
      },
    );
  }
}