

class NotificationType {
  static const String chat = 'chat';
  static const String activity = 'activity';
  static const String challenge = 'challenge';
  static const String achievement = 'achievement';
  static const String follow = 'follow';
  static const String system = 'system';
}

class Notification {
  final String id;
  final String recipientId;
  final SenderInfo sender;
  final String type;
  final String content;
  final String? entityId;
  final String? entityType;
  final bool isRead;
  final DateTime createdAt;

  Notification({
    required this.id,
    required this.recipientId,
    required this.sender,
    required this.type,
    required this.content,
    this.entityId,
    this.entityType,
    required this.isRead,
    required this.createdAt,
  });

  factory Notification.fromJson(Map<String, dynamic> json) {
    return Notification(
      id: json['_id'] ?? json['id'] ?? '',
      recipientId: json['recipient']?.toString() ?? '',
      sender: SenderInfo.fromJson(json['sender'] ?? json['senderInfo'] ?? {}),
      type: json['type'] ?? '',
      content: json['content'] ?? '',
      entityId: json['entityId']?.toString(),
      entityType: json['entityType'],
      isRead: json['isRead'] ?? false,
      createdAt: json['createdAt'] != null 
        ? DateTime.parse(json['createdAt']) 
        : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'recipient': recipientId,
      'sender': sender.toJson(),
      'type': type,
      'content': content,
      'entityId': entityId,
      'entityType': entityType,
      'isRead': isRead,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  // Crear copia con cambios
  Notification copyWith({
    String? id,
    String? recipientId,
    SenderInfo? sender,
    String? type,
    String? content,
    String? entityId,
    String? entityType,
    bool? isRead,
    DateTime? createdAt,
  }) {
    return Notification(
      id: id ?? this.id,
      recipientId: recipientId ?? this.recipientId,
      sender: sender ?? this.sender,
      type: type ?? this.type,
      content: content ?? this.content,
      entityId: entityId ?? this.entityId,
      entityType: entityType ?? this.entityType,
      isRead: isRead ?? this.isRead,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

class SenderInfo {
  final String id;
  final String? username;
  final String? profilePicture;

  SenderInfo({
    required this.id,
    this.username,
    this.profilePicture,
  });

  factory SenderInfo.fromJson(Map<String, dynamic> json) {
    // Handle different possible formats
    String userId = '';
    if (json['_id'] != null) {
      userId = json['_id'].toString();
    } else if (json['id'] != null) {
      userId = json['id'].toString();
    }

    return SenderInfo(
      id: userId,
      username: json['username'],
      profilePicture: json['profilePicture'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'username': username,
      'profilePicture': profilePicture,
    };
  }
}