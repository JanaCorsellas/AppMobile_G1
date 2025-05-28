/*import 'package:flutter/material.dart';

// 1. Activity model
class Activity {
  final String username;
  final String title;
  final String type;
  final String description;
  final DateTime date;

  Activity({
    required this.username, 
    required this.title, 
    required this.type,
    required this.description,
    required this.date
    }
  );
}

// 2. Mock service to fetch activities (replace with your API call)
Future<List<Activity>> fetchActivities() async {
  await Future.delayed(const Duration(seconds: 1)); // Simulate network delay
  return [
    Activity(username: 'Alice', title: "pica d'estats", type: "Hiking",description: 'Completed a 5km run', date: DateTime.now().subtract(const Duration(hours: 1))),
    Activity(username: 'Bob', title: "pica d'estats", type: "Hiking", description: 'Cycled 20km', date: DateTime.now().subtract(const Duration(hours: 2))),
    Activity(username: 'Charlie', title: "pica d'estats", type: "Hiking", description: 'Hiked a mountain', date: DateTime.now().subtract(const Duration(days: 1))),
  ];
}

// 3. Feed UI
class UserFeedScreen extends StatefulWidget {
  const UserFeedScreen({Key? key}) : super(key: key);

  @override
  State<UserFeedScreen> createState() => _UserFeedScreenState();
}

class _UserFeedScreenState extends State<UserFeedScreen> {
  late Future<List<Activity>> _activitiesFuture;

  @override
  void initState() {
    super.initState();
    _activitiesFuture = fetchActivities();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Feed')),
      body: FutureBuilder<List<Activity>>(
        future: _activitiesFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          final activities = snapshot.data ?? [];
          if (activities.isEmpty) {
            return const Center(child: Text('No activities yet.'));
          }
          return ListView.builder(
            itemCount: activities.length,
            itemBuilder: (context, index) {
              final activity = activities[index];
              return ListTile(
                leading: const Icon(Icons.directions_run),
                title: Text("${activity.username}:${activity.title}"),
                subtitle: Text("${activity.type}:${activity.description}"),
                trailing: Text(
                  '${activity.date.hour}:${activity.date.minute.toString().padLeft(2, '0')}',
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
              );
            },
          );
        },
      ),
    );
  }
}*/


import 'package:flutter/material.dart';
import 'package:flutter_application_1/config/routes.dart';
import 'package:flutter_application_1/widgets/custom_drawer.dart';
import 'package:provider/provider.dart';
import 'package:flutter_application_1/models/activity.dart';
import 'package:flutter_application_1/services/auth_service.dart';
import 'package:flutter_application_1/services/http_service.dart';
import 'package:flutter_application_1/services/activity_service.dart';
import 'package:flutter_application_1/screens/activity/activity_detail_screen.dart';

class UserFeedScreen extends StatefulWidget {
  const UserFeedScreen({Key? key}) : super(key: key);

  @override
  State<UserFeedScreen> createState() => _UserFeedScreenState();
}

class _UserFeedScreenState extends State<UserFeedScreen> {
  bool _isLoading = true;
  List<Activity> _activities = [];
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _loadAllActivities();
  }

  Future<void> _loadAllActivities() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      final httpService = HttpService(authService);
      final activityService = ActivityService(httpService);

      // Fetch all activities from all users
      final activities = await activityService.getAllActivities();

      setState(() {
        _activities = activities.reversed.toList();
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Error loading feed: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: const CustomDrawer(currentRoute: AppRoutes.userFeed),
      appBar: AppBar(title: const Text('Feed')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage.isNotEmpty
              ? Center(child: Text(_errorMessage))
              : _activities.isEmpty
                  ? const Center(child: Text('No activities yet.'))
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _activities.length,
                      itemBuilder: (context, index) {
                        final activity = _activities[index];
                        return _buildActivityCard(activity);
                      },
                    /*
                      itemCount: _activities.length,
                      itemBuilder: (context, index) {
                        final activity = _activities[index];
                        return ListTile(
                          leading: Icon(_getActivityIcon(activity.type)),
                          title: Text(activity.name),
                          subtitle: Text('${activity.authorName} • ${activity.formatDistance()} • ${activity.formatDuration()}'),
                          trailing: Text(
                            '${activity.startTime.day}/${activity.startTime.month}/${activity.startTime.year}',
                            style: const TextStyle(fontSize: 12, color: Colors.grey),
                          ),
                        );
                      },
                    */),
    );
  }

  Widget _buildActivityCard(Activity activity) {
    IconData activityIcon;
    Color activityColor;

    switch (activity.type) {
      case ActivityType.running:
        activityIcon = Icons.directions_run;
        activityColor = Colors.green;
        break;
      case ActivityType.cycling:
        activityIcon = Icons.directions_bike;
        activityColor = Colors.blue;
        break;
      case ActivityType.hiking:
        activityIcon = Icons.terrain;
        activityColor = Colors.orange;
        break;
      case ActivityType.walking:
        activityIcon = Icons.directions_walk;
        activityColor = Colors.purple;
        break;
      default:
        activityIcon = Icons.directions_run;
        activityColor = Colors.grey;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ActivityDetailScreen(activity: activity),
            ),
          );
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    backgroundColor: activityColor.withOpacity(0.2),
                    radius: 24,
                    child: Icon(
                      activityIcon,
                      color: activityColor,
                      size: 30,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          activity.name,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${activity.authorName} • ${activity.formatDistance()} • ${activity.formatDuration()}',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    '${activity.startTime.day}/${activity.startTime.month}/${activity.startTime.year}',
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  IconData _getActivityIcon(ActivityType type) {
    switch (type) {
      case ActivityType.running:
        return Icons.directions_run;
      case ActivityType.cycling:
        return Icons.directions_bike;
      case ActivityType.hiking:
        return Icons.terrain;
      case ActivityType.walking:
        return Icons.directions_walk;
      default:
        return Icons.directions_run;
    }
  }
}