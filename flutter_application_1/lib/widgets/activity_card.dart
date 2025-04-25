import 'package:flutter/material.dart';
import 'package:flutter_application_1/models/activity.dart';

class ActivityCard extends StatelessWidget {
  final Activity activity;
  final VoidCallback onView;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onViewHistory;

  const ActivityCard({
    Key? key,
    required this.activity,
    required this.onView,
    required this.onEdit,
    required this.onDelete,
    required this.onViewHistory,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12.0),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12.0),
      ),
      child: Column(
        children: [
          Container(
            decoration: BoxDecoration(
              color: _getTypeColor(activity.type).withOpacity(0.2),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12.0),
                topRight: Radius.circular(12.0),
              ),
            ),
            padding: const EdgeInsets.symmetric(
              horizontal: 16.0,
              vertical: 12.0,
            ),
            child: Row(
              children: [
                _getTypeIcon(activity.type),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        activity.name,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Author: ${activity.authorName ?? activity.author}',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.black54,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: _getTypeColor(activity.type),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    _getTypeLabel(activity.type),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildInfoItem(
                      Icons.calendar_today,
                      'Date',
                      _formatDate(activity.startTime),
                    ),
                    _buildInfoItem(
                      Icons.timer,
                      'Duration',
                      _formatDuration(activity.duration),
                    ),
                    _buildInfoItem(
                      Icons.straighten,
                      'Distance',
                      _formatDistance(activity.distance),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildInfoItem(
                      Icons.speed,
                      'Speed',
                      '${activity.averageSpeed.toStringAsFixed(1)} km/h',
                    ),
                    _buildInfoItem(
                      Icons.terrain,
                      'Elevation',
                      '${activity.elevationGain.toStringAsFixed(0)} m',
                    ),
                    if (activity.caloriesBurned != null)
                      _buildInfoItem(
                        Icons.local_fire_department,
                        'Calories',
                        '${activity.caloriesBurned!.toStringAsFixed(0)} kcal',
                      )
                    else
                      _buildInfoItem(
                        Icons.route,
                        'Route Points',
                        activity.route.length.toString(),
                      ),
                  ],
                ),
              ],
            ),
          ),
          ButtonBar(
            alignment: MainAxisAlignment.spaceEvenly,
            children: [
              TextButton.icon(
                onPressed: onView,
                icon: const Icon(Icons.visibility),
                label: const Text('View'),
                style: TextButton.styleFrom(
                  foregroundColor: Colors.blue,
                ),
              ),
              TextButton.icon(
                onPressed: onEdit,
                icon: const Icon(Icons.edit),
                label: const Text('Edit'),
                style: TextButton.styleFrom(
                  foregroundColor: Colors.green,
                ),
              ),
              TextButton.icon(
                onPressed: onDelete,
                icon: const Icon(Icons.delete),
                label: const Text('Delete'),
                style: TextButton.styleFrom(
                  foregroundColor: Colors.red,
                ),
              ),
              TextButton.icon(
                onPressed: onViewHistory,
                icon: const Icon(Icons.history),
                label: const Text('History'),
                style: TextButton.styleFrom(
                  foregroundColor: Colors.purple,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInfoItem(IconData icon, String label, String value) {
    return Expanded(
      child: Column(
        children: [
          Icon(
            icon,
            color: Colors.grey.shade700,
            size: 20,
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              color: Colors.grey.shade700,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  String _formatDuration(int minutes) {
    final hours = minutes ~/ 60;
    final mins = minutes % 60;
    
    if (hours > 0) {
      return '${hours}h ${mins}min';
    } else {
      return '${mins}min';
    }
  }

  String _formatDistance(double meters) {
    return '${(meters / 1000).toStringAsFixed(1)} km';
  }

  Color _getTypeColor(ActivityType type) {
    switch (type) {
      case ActivityType.running:
        return Colors.green;
      case ActivityType.cycling:
        return Colors.blue;
      case ActivityType.hiking:
        return Colors.orange;
      case ActivityType.walking:
        return Colors.purple;
    }
  }

  Widget _getTypeIcon(ActivityType type) {
    IconData iconData;
    Color color = _getTypeColor(type);
    
    switch (type) {
      case ActivityType.running:
        iconData = Icons.directions_run;
        break;
      case ActivityType.cycling:
        iconData = Icons.directions_bike;
        break;
      case ActivityType.hiking:
        iconData = Icons.terrain;
        break;
      case ActivityType.walking:
        iconData = Icons.directions_walk;
        break;
    }
    
    return Icon(iconData, color: color);
  }

  String _getTypeLabel(ActivityType type) {
    switch (type) {
      case ActivityType.running:
        return 'Running';
      case ActivityType.cycling:
        return 'Cycling';
      case ActivityType.hiking:
        return 'Hiking';
      case ActivityType.walking:
        return 'Walking';
    }
  }
}