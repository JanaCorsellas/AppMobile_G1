// lib/models/user.dart - Versión corregida
class User {
  final String id;
  final String username;
  final String email;
  final String? profilePicture; // Ahora almacena la ruta del archivo
  final String? bio;
  final int level;
  final double totalDistance;
  final int totalTime;
  final List<String>? activities;
  final List<String>? achievements;
  final List<String>? challengesCompleted;
  final bool visibility;
  final String role;
  final DateTime createdAt;
  final DateTime updatedAt;

  User({
    required this.id,
    required this.username,
    required this.email,
    this.profilePicture,
    this.bio,
    required this.level,
    required this.totalDistance,
    required this.totalTime,
    this.activities,
    this.achievements,
    this.challengesCompleted,
    required this.visibility,
    required this.role,
    required this.createdAt,
    required this.updatedAt,
  });

  // ✅ MEJORADO: Get full profile picture URL con validación más estricta
  String? get profilePictureUrl {
    if (profilePicture == null || profilePicture!.isEmpty) {
      return null;
    }
    
    // If it's already a full URL, return as is
    if (profilePicture!.startsWith('http')) {
      return profilePicture;
    }
    
    // ✅ NUEVO: Agregar timestamp para evitar caché del navegador
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    
    // Otherwise, construct the full URL
    // Cambiar localhost por tu IP o dominio en producción
    return 'http://localhost:3000/$profilePicture?t=$timestamp';
  }

  // ✅ MEJORADO: Check if user has profile picture con validación más estricta
  bool get hasProfilePicture {
    return profilePicture != null && 
           profilePicture!.isNotEmpty && 
           profilePicture != 'null' && 
           profilePicture != 'undefined';
  }

  // ✅ MEJORADO: fromJson con mejor manejo de profilePicture
  factory User.fromJson(Map<String, dynamic> json) {
    // Mejorado: Manejo más robusto del ID
    String userId = '';
    if (json.containsKey('_id')) {
      userId = json['_id'].toString();
    } else if (json.containsKey('id')) {
      userId = json['id'].toString();
    }
    
    // Mejorado: Manejo más robusto del nombre de usuario
    String username = '';
    if (json.containsKey('username')) {
      username = json['username'];
    } else if (json.containsKey('name')) {
      username = json['name'];
    }
    
    // ✅ NUEVO: Manejo mejorado y más estricto del profilePicture
    String? profilePicture;
    
    // Verificar múltiples campos posibles
    if (json.containsKey('profilePicture')) {
      final value = json['profilePicture'];
      // Solo asignar si no es null, undefined, o string vacío
      if (value != null && 
          value.toString().isNotEmpty && 
          value.toString() != 'null' && 
          value.toString() != 'undefined') {
        profilePicture = value.toString();
      }
    }
    
    // También verificar si viene con el campo virtual profilePictureUrl
    if (profilePicture == null && json.containsKey('profilePictureUrl')) {
      final value = json['profilePictureUrl'];
      if (value != null && 
          value.toString().isNotEmpty && 
          value.toString() != 'null' && 
          value.toString() != 'undefined') {
        profilePicture = value.toString();
      }
    }
    
    // Debug logging
    print('User.fromJson - profilePicture processing:');
    print('  Raw profilePicture: ${json['profilePicture']}');
    print('  Raw profilePictureUrl: ${json['profilePictureUrl']}');
    print('  Final profilePicture: $profilePicture');
    
    // Arreglo: Convertir todos los campos a los tipos correctos
    return User(
      id: userId,
      username: username,
      email: json['email'] ?? '',
      profilePicture: profilePicture, // ✅ Valor ya filtrado
      bio: json['bio'],
      level: json['level'] != null ? int.tryParse(json['level'].toString()) ?? 1 : 1,
      totalDistance: json['totalDistance'] != null 
          ? double.tryParse(json['totalDistance'].toString()) ?? 0.0 
          : 0.0,
      totalTime: json['totalTime'] != null 
          ? (double.tryParse(json['totalTime'].toString()) ?? 0).round() 
          : 0,
      activities: json['activities'] != null 
          ? List<String>.from(json['activities'].map((e) => e.toString())) 
          : [],
      achievements: json['achievements'] != null 
          ? List<String>.from(json['achievements'].map((e) => e.toString())) 
          : [],
      challengesCompleted: json['challengesCompleted'] != null 
          ? List<String>.from(json['challengesCompleted'].map((e) => e.toString())) 
          : [],
      visibility: json['visibility'] ?? true,
      role: json['role'] ?? 'user',
      createdAt: json['createdAt'] != null 
          ? DateTime.parse(json['createdAt'].toString())
          : DateTime.now(),
      updatedAt: json['updatedAt'] != null 
          ? DateTime.parse(json['updatedAt'].toString())
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'username': username,
      'email': email,
      'profilePicture': profilePicture,
      'bio': bio,
      'level': level,
      'totalDistance': totalDistance,
      'totalTime': totalTime,
      'activities': activities,
      'achievements': achievements,
      'challengesCompleted': challengesCompleted,
      'visibility': visibility,
      'role': role,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  // ✅ MEJORADO: copyWith con mejor manejo de profilePicture null
  User copyWith({
    String? id,
    String? username,
    String? email,
    String? profilePicture,
    bool clearProfilePicture = false, // ✅ NUEVO: flag explícito para limpiar
    String? bio,
    int? level,
    double? totalDistance,
    int? totalTime,
    List<String>? activities,
    List<String>? achievements,
    List<String>? challengesCompleted,
    bool? visibility,
    String? role,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    // ✅ NUEVO: Manejar explícitamente la limpieza de profilePicture
    String? newProfilePicture;
    if (clearProfilePicture) {
      newProfilePicture = null;
    } else if (profilePicture != null) {
      newProfilePicture = profilePicture;
    } else {
      newProfilePicture = this.profilePicture;
    }
    
    return User(
      id: id ?? this.id,
      username: username ?? this.username,
      email: email ?? this.email,
      profilePicture: newProfilePicture,
      bio: bio ?? this.bio,
      level: level ?? this.level,
      totalDistance: totalDistance ?? this.totalDistance,
      totalTime: totalTime ?? this.totalTime,
      activities: activities ?? this.activities,
      achievements: achievements ?? this.achievements,
      challengesCompleted: challengesCompleted ?? this.challengesCompleted,
      visibility: visibility ?? this.visibility,
      role: role ?? this.role,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}