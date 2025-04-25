enum ActivityType { running, cycling, hiking, walking }

class Activity {
  final String id;
  final String author;
  final String? authorName;
  final String name;
  final DateTime startTime;
  final DateTime endTime;
  final int duration; // in minutes
  final double distance; // in meters
  final double elevationGain;
  final double averageSpeed;
  final double? caloriesBurned;
  final List<String> route;
  final List<String>? musicPlaylist;
  final ActivityType type;

  Activity({
    required this.id,
    required this.author,
    this.authorName,
    required this.name,
    required this.startTime,
    required this.endTime,
    required this.duration,
    required this.distance,
    required this.elevationGain,
    required this.averageSpeed,
    this.caloriesBurned,
    required this.route,
    this.musicPlaylist,
    required this.type,
  });

  factory Activity.fromJson(Map<String, dynamic> json) {
    // Parse the type string to enum
    ActivityType parseType(String typeStr) {
      switch (typeStr.toLowerCase()) {
        case 'running': return ActivityType.running;
        case 'cycling': return ActivityType.cycling;
        case 'hiking': return ActivityType.hiking;
        case 'walking': return ActivityType.walking;
        default: return ActivityType.running;
      }
    }

    // Handle if author is either a string ID or a nested object with _id
    String getAuthorId(dynamic author) {
      if (author is String) return author;
      if (author is Map<String, dynamic> && author.containsKey('_id')) {
        return author['_id'] as String;
      }
      return '';
    }

    // Extract author name from object if available
    String? getAuthorName(dynamic author) {
      if (author is Map<String, dynamic> && author.containsKey('username')) {
        return author['username'] as String;
      }
      return null;
    }

    return Activity(
      id: json['_id'] ?? '',
      author: getAuthorId(json['author']),
      authorName: json['authorName'] ?? getAuthorName(json['author']),
      name: json['name'] ?? '',
      startTime: json['startTime'] != null 
          ? DateTime.parse(json['startTime']) 
          : DateTime.now(),
      endTime: json['endTime'] != null 
          ? DateTime.parse(json['endTime']) 
          : DateTime.now(),
      duration: json['duration'] ?? 0,
      distance: (json['distance'] ?? 0).toDouble(),
      elevationGain: (json['elevationGain'] ?? 0).toDouble(),
      averageSpeed: (json['averageSpeed'] ?? 0).toDouble(),
      caloriesBurned: json['caloriesBurned'] != null 
          ? (json['caloriesBurned']).toDouble() 
          : null,
      route: json['route'] != null 
          ? List<String>.from(json['route'])
          : [],
      musicPlaylist: json['musicPlaylist'] != null 
          ? List<String>.from(json['musicPlaylist'])
          : null,
      type: json['type'] != null 
          ? parseType(json['type'])
          : ActivityType.running,
    );
  }

  Map<String, dynamic> toJson() {
    // Convert enum to string
    String typeToString(ActivityType type) {
      switch (type) {
        case ActivityType.running: return 'running';
        case ActivityType.cycling: return 'cycling';
        case ActivityType.hiking: return 'hiking';
        case ActivityType.walking: return 'walking';
      }
    }

    return {
      '_id': id,
      'author': author,
      'name': name,
      'startTime': startTime.toIso8601String(),
      'endTime': endTime.toIso8601String(),
      'duration': duration,
      'distance': distance,
      'elevationGain': elevationGain,
      'averageSpeed': averageSpeed,
      'caloriesBurned': caloriesBurned,
      'route': route,
      'musicPlaylist': musicPlaylist,
      'type': typeToString(type),
    };
  }

  // Helper for formatting duration
  String formatDuration() {
    final hours = duration ~/ 60;
    final minutes = duration % 60;
    
    if (hours > 0) {
      return '${hours}h ${minutes}min';
    } else {
      return '${minutes}min';
    }
  }

  // Helper for distance in km
  String formatDistance() {
    return '${(distance / 1000).toStringAsFixed(2)} km';
  }

  Activity copyWith({
    String? id,
    String? author,
    String? authorName,
    String? name,
    DateTime? startTime,
    DateTime? endTime,
    int? duration,
    double? distance,
    double? elevationGain,
    double? averageSpeed,
    double? caloriesBurned,
    List<String>? route,
    List<String>? musicPlaylist,
    ActivityType? type,
  }) {
    return Activity(
      id: id ?? this.id,
      author: author ?? this.author,
      authorName: authorName ?? this.authorName,
      name: name ?? this.name,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      duration: duration ?? this.duration,
      distance: distance ?? this.distance,
      elevationGain: elevationGain ?? this.elevationGain,
      averageSpeed: averageSpeed ?? this.averageSpeed,
      caloriesBurned: caloriesBurned ?? this.caloriesBurned,
      route: route ?? this.route,
      musicPlaylist: musicPlaylist ?? this.musicPlaylist,
      type: type ?? this.type,
    );
  }
}