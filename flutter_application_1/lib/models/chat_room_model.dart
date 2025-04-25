class ChatRoom {
  final String id;
  final String name;
  final String? description;
  final List<String> participants;
  final DateTime createdAt;
  final String? lastMessage;
  final DateTime? lastMessageTime;
  final bool isGroup;

  ChatRoom({
    required this.id,
    required this.name,
    this.description,
    required this.participants,
    required this.createdAt,
    this.lastMessage,
    this.lastMessageTime,
    this.isGroup = false,
  });

  factory ChatRoom.fromJson(Map<String, dynamic> json) {
    // Asegurar que obtenemos el ID correcto del servidor
    final String roomId = json['_id'] ?? json['id'] ?? '';
    
    String roomName = json['name'] ?? 'Chat';
    
    List<String> participantsList = [];
    if (json['participants'] is List) {
      participantsList = List<String>.from(
        (json['participants'] as List).map((item) {
          if (item is Map) {
            return item['_id'] ?? item['id'] ?? '';
          }
          return item.toString();
        })
      );
    }
    
    DateTime createdAtDate;
    try {
      createdAtDate = json['createdAt'] != null 
          ? DateTime.parse(json['createdAt']) 
          : DateTime.now();
    } catch (e) {
      print('Error parsing createdAt: $e');
      createdAtDate = DateTime.now();
    }
    
    DateTime? lastMessageTimeDate;
    if (json['lastMessageTime'] != null) {
      try {
        lastMessageTimeDate = DateTime.parse(json['lastMessageTime']);
      } catch (e) {
        print('Error parsing lastMessageTime: $e');
        lastMessageTimeDate = null;
      }
    }

    // Determinar si es un grupo
    bool isGroupChat = json['isGroup'] ?? participantsList.length > 2;

    return ChatRoom(
      id: roomId,
      name: roomName,
      description: json['description'],
      participants: participantsList,
      createdAt: createdAtDate,
      lastMessage: json['lastMessage'],
      lastMessageTime: lastMessageTimeDate,
      isGroup: isGroupChat,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id, // Usar _id para consistencia con el servidor
      'name': name,
      'description': description,
      'participants': participants,
      'createdAt': createdAt.toIso8601String(),
      'lastMessage': lastMessage,
      'lastMessageTime': lastMessageTime?.toIso8601String(),
      'isGroup': isGroup,
    };
  }

  ChatRoom copyWith({
    String? id,
    String? name,
    String? description,
    List<String>? participants,
    DateTime? createdAt,
    String? lastMessage,
    DateTime? lastMessageTime,
    bool? isGroup,
  }) {
    return ChatRoom(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      participants: participants ?? this.participants,
      createdAt: createdAt ?? this.createdAt,
      lastMessage: lastMessage ?? this.lastMessage,
      lastMessageTime: lastMessageTime ?? this.lastMessageTime,
      isGroup: isGroup ?? this.isGroup,
    );
  }
}