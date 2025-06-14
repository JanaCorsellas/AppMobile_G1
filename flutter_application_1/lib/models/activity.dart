enum ActivityType { running, cycling, hiking, walking }

class Activity {
  final String id;
  final String author;
  final String? authorName;
  final String name;
  final DateTime startTime;
  final DateTime endTime;
  final int duration; 
  final double distance; 
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
    ActivityType parseType(dynamic typeData) {
      if (typeData is String) {
        switch (typeData.toLowerCase()) {
          case 'running': return ActivityType.running;
          case 'cycling': return ActivityType.cycling;
          case 'hiking': return ActivityType.hiking;
          case 'walking': return ActivityType.walking;
          default: return ActivityType.running;
        }
      }
      return ActivityType.running; // Default case
    }

    // Handle if author is either a string ID or a nested object with _id
    String getAuthorId(dynamic author) {
      if (author == null) return '';
      if (author is String) return author;
      if (author is Map<String, dynamic>) {
        if (author.containsKey('_id')) {
          final id = author['_id'];
          if (id is String) return id;
          // If id is not a string, convert it to string
          return id.toString();
        }
        return '';
      }
      return '';
    }

    List<String> safeRouteList(dynamic routeData) {
      if (routeData == null) return [];
      if (routeData is List) {
        return routeData.map((item) {
          if (item is String) return item;
          if (item is Map) {
          // If it's an object ID or location object, convert to string
          if (item['_id'] != null) return item['_id'].toString();
          if (item['latitude'] != null && item['longitude'] != null) {
            return "${item['latitude']},${item['longitude']}";
          }
        }
          // If route item is a map or other type, convert to string
          return item.toString();
        }).toList();
      }
      return [];
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
      duration: json['duration'] is int 
          ? json['duration'] 
          : (json['duration'] is double ? json['duration'].round() : 0),
      distance: (json['distance'] ?? 0).toDouble(),
      elevationGain: (json['elevationGain'] ?? 0).toDouble(),
      averageSpeed: (json['averageSpeed'] ?? 0).toDouble(),
      caloriesBurned: json['caloriesBurned'] != null 
          ? (json['caloriesBurned']).toDouble() 
          : null,
      route: safeRouteList(json['route']),
      musicPlaylist: json['musicPlaylist'] != null 
          ? List<String>.from(json['musicPlaylist'])
          : null,
      type: json['type'] != null 
          ? parseType(json['type'])
          : ActivityType.running,
    );
  }

  get username => null;

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

String formatDuration() {
 
  int totalSeconds = duration;
  
  int hours = totalSeconds ~/ 3600;
  int minutes = (totalSeconds % 3600) ~/ 60;
  int seconds = totalSeconds % 60;
  
  if (hours > 0) {
    return '$hours:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  } else {
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }
}

  
  // Formatea la distancia para mostrarla en kilómetros o metros
  String formatDistance() {
  if (distance < 1000) {
    // Si es menor a 1000 metros, mostrar en metros
    return '${distance.toStringAsFixed(0)} m';
  } else {
    // Si es 1000 metros o más, mostrar en kilómetros
    final kilometers = distance / 1000;
    
    // Si es un número entero (como 1.0, 2.0, etc.), mostrar sin decimales
    if (kilometers == kilometers.roundToDouble()) {
      return '${kilometers.toInt()} km';
    }
    
    // Para distancias con decimales, mostrar con 2 decimales
    return '${kilometers.toStringAsFixed(2)} km';
  }
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