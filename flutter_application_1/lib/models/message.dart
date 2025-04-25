class Message {
  final String id;
  final String roomId;
  final String senderId;
  final String senderName;
  final String content;
  final DateTime timestamp;
  final bool isRead;

  Message({
    required this.id,
    required this.roomId,
    required this.senderId,
    required this.senderName,
    required this.content,
    required this.timestamp,
    this.isRead = false,
  });

  factory Message.fromJson(Map<String, dynamic> json) {
    // Manejar el ID correctamente
    String messageId = '';
    if (json['_id'] != null) {
      messageId = json['_id'] is Map ? 
          (json['_id']['oid'] ?? json['_id'].toString()) : 
          json['_id'].toString();
    } else if (json['id'] != null) {
      messageId = json['id'].toString();
    }
    
    // Manejar roomId correctamente
    String roomIdValue = '';
    if (json['roomId'] != null) {
      roomIdValue = json['roomId'] is Map ? 
          (json['roomId']['oid'] ?? json['roomId'].toString()) : 
          json['roomId'].toString();
    }
    
    // Manejar senderId correctamente
    String senderIdValue = '';
    if (json['senderId'] != null) {
      if (json['senderId'] is Map) {
        // Si senderId es un objeto, intentar extraer el valor _id primero
        senderIdValue = json['senderId']['_id']?.toString() ?? 
                       json['senderId']['oid']?.toString() ?? 
                       json['senderId'].toString();
      } else {
        senderIdValue = json['senderId'].toString();
      }
    }
    
    // Extraer el nombre del remitente
    String senderNameValue = 'Usuario';
    if (json['senderName'] != null) {
      senderNameValue = json['senderName'].toString();
    } else if (json['senderId'] is Map && json['senderId']['username'] != null) {
      // Si senderId es un objeto con un campo de username, usar ese
      senderNameValue = json['senderId']['username'].toString();
    }
    
    // Parsear timestamp
    DateTime timestampValue;
    try {
      if (json['timestamp'] != null) {
        if (json['timestamp'] is String) {
          timestampValue = DateTime.parse(json['timestamp']);
        } else if (json['timestamp'] is Map && json['timestamp']['\$date'] != null) {
          timestampValue = DateTime.fromMillisecondsSinceEpoch(
            json['timestamp']['\$date'] is int 
                ? json['timestamp']['\$date'] 
                : int.parse(json['timestamp']['\$date'].toString())
          );
        } else {
          timestampValue = DateTime.now();
        }
      } else {
        timestampValue = DateTime.now();
      }
    } catch (e) {
      print('Error al parsear timestamp: $e');
      timestampValue = DateTime.now();
    }

    return Message(
      id: messageId,
      roomId: roomIdValue,
      senderId: senderIdValue,
      senderName: senderNameValue,
      content: json['content']?.toString() ?? '',
      timestamp: timestampValue,
      isRead: json['isRead'] == true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'roomId': roomId,
      'senderId': senderId,
      'senderName': senderName,
      'content': content,
      'timestamp': timestamp.toIso8601String(),
      'isRead': isRead,
    };
  }
}