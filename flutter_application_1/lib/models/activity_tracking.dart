class LocationPoint {
  final double latitude;
  final double longitude;
  final double? altitude;
  final DateTime timestamp;
  final double? speed;

  LocationPoint({
    required this.latitude,
    required this.longitude,
    this.altitude,
    required this.timestamp,
    this.speed,
  });

  factory LocationPoint.fromJson(Map<String, dynamic> json) {
    return LocationPoint(
      latitude: json['latitude']?.toDouble() ?? 0.0,
      longitude: json['longitude']?.toDouble() ?? 0.0,
      altitude: json['altitude']?.toDouble(),
      timestamp: json['timestamp'] != null 
          ? DateTime.parse(json['timestamp']) 
          : DateTime.now(),
      speed: json['speed']?.toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'latitude': latitude,
      'longitude': longitude,
      'altitude': altitude,
      'timestamp': timestamp.toIso8601String(),
      'speed': speed,
    };
  }
}

enum ActivityTrackingStatus {
  active,
  paused,
  finished,
  discarded
}

class ActivityTracking {
  final String id;
  final String userId;
  final String activityType;
  final DateTime startTime;
  DateTime? endTime;
  bool isActive;
  bool isPaused;
  DateTime? pauseTime;
  int totalPausedTime; // en milisegundos
  double currentDistance; // en metros
  int currentDuration; // en segundos
  double currentSpeed; // metros por segundo
  double averageSpeed; // metros por segundo
  double maxSpeed; // metros por segundo
  double elevationGain; // en metros
  List<LocationPoint> locationPoints;
  ActivityTrackingStatus status;

  ActivityTracking({
    required this.id,
    required this.userId,
    required this.activityType,
    required this.startTime,
    this.endTime,
    this.isActive = true,
    this.isPaused = false,
    this.pauseTime,
    this.totalPausedTime = 0,
    this.currentDistance = 0,
    this.currentDuration = 0,
    this.currentSpeed = 0,
    this.averageSpeed = 0,
    this.maxSpeed = 0,
    this.elevationGain = 0,
    this.locationPoints = const [],
    this.status = ActivityTrackingStatus.active,
  });

  factory ActivityTracking.fromJson(Map<String, dynamic> json) {
    ActivityTrackingStatus status;
    if (json['isActive'] == false) {
      status = ActivityTrackingStatus.finished;
    } else if (json['isPaused'] == true) {
      status = ActivityTrackingStatus.paused;
    } else {
      status = ActivityTrackingStatus.active;
    }

    // Extrae ID de diferentes formatos posibles
    String trackingId = '';
    if (json.containsKey('_id')) {
      if (json['_id'] is Map) {
        trackingId = json['_id'].toString();
      } else {
        trackingId = json['_id'] ?? '';
      }
    } else if (json.containsKey('id')) {
      trackingId = json['id'] ?? '';
    }

    return ActivityTracking(
      id: trackingId,
      userId: json['userId']?.toString() ?? '',
      activityType: json['activityType'] ?? 'running',
      startTime: json['startTime'] != null 
          ? DateTime.parse(json['startTime'].toString()) 
          : DateTime.now(),
      endTime: json['endTime'] != null 
          ? DateTime.parse(json['endTime'].toString()) 
          : null,
      isActive: json['isActive'] ?? true,
      isPaused: json['isPaused'] ?? false,
      pauseTime: json['pauseTime'] != null 
          ? DateTime.parse(json['pauseTime'].toString()) 
          : null,
      totalPausedTime: (json['totalPausedTime'] ?? 0).toInt(),
      currentDistance: json['currentDistance']?.toDouble() ?? 0.0,
      currentDuration: (json['currentDuration'] ?? 0).toInt(),
      currentSpeed: json['currentSpeed']?.toDouble() ?? 0.0,
      averageSpeed: json['averageSpeed']?.toDouble() ?? 0.0,
      maxSpeed: json['maxSpeed']?.toDouble() ?? 0.0,
      elevationGain: json['elevationGain']?.toDouble() ?? 0.0,
      locationPoints: json['locationPoints'] != null 
          ? (json['locationPoints'] as List)
              .map((point) => LocationPoint.fromJson(point))
              .toList() 
          : [],
      status: status,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'activityType': activityType,
      'startTime': startTime.toIso8601String(),
      'endTime': endTime?.toIso8601String(),
      'isActive': isActive,
      'isPaused': isPaused,
      'pauseTime': pauseTime?.toIso8601String(),
      'totalPausedTime': totalPausedTime,
      'currentDistance': currentDistance,
      'currentDuration': currentDuration,
      'currentSpeed': currentSpeed,
      'averageSpeed': averageSpeed,
      'maxSpeed': maxSpeed,
      'elevationGain': elevationGain,
      'locationPoints': locationPoints.map((point) => point.toJson()).toList(),
    };
  }

  // Formatea la distancia para mostrarla en kilómetros
  String get formattedDistance {
    if (currentDistance < 1000) {
      return '${currentDistance.toStringAsFixed(0)} m';
    }
    return '${(currentDistance / 1000).toStringAsFixed(2)} km';
  }

  // Formatea la duración en formato HH:MM:SS
  String get formattedDuration {
    final hours = currentDuration ~/ 3600;
    final minutes = (currentDuration % 3600) ~/ 60;
    final seconds = currentDuration % 60;
    
    if (hours > 0) {
      return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
    }
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  // Formatea la velocidad para mostrarla en km/h
  String get formattedSpeed {
    return '${(currentSpeed * 3.6).toStringAsFixed(1)} km/h';
  }

  // Formatea la velocidad promedio para mostrarla en km/h
  String get formattedAverageSpeed {
    return '${(averageSpeed * 3.6).toStringAsFixed(1)} km/h';
  }

  // Formatea el ritmo (pace) en minutos por kilómetro
  String get formattedPace {
    if (currentSpeed <= 0) return '--:--';
    
    // Convertir m/s a minutos por kilómetro
    final paceInSeconds = 1000 / currentSpeed;
    final paceMinutes = (paceInSeconds / 60).floor();
    final paceSeconds = (paceInSeconds % 60).floor();
    
    return '${paceMinutes.toString().padLeft(2, '0')}:${paceSeconds.toString().padLeft(2, '0')} min/km';
  }

  // Formatea la ganancia de elevación
  String get formattedElevationGain {
    return '${elevationGain.toStringAsFixed(0)} m';
  }
}