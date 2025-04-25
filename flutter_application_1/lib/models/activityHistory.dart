enum ChangeType { create, update, delete }

class ActivityHistory {
  final String id;
  final ActivityHistoryReference activityId;
  final ActivityHistoryReference userId;
  final ChangeType changeType;
  final List<String>? changedFields;
  final Map<String, dynamic>? previousValues;
  final Map<String, dynamic>? newValues;
  final DateTime timestamp;

  ActivityHistory({
    required this.id,
    required this.activityId,
    required this.userId,
    required this.changeType,
    this.changedFields,
    this.previousValues,
    this.newValues,
    required this.timestamp,
  });

  factory ActivityHistory.fromJson(Map<String, dynamic> json) {
    // Parse change type string to enum
    ChangeType parseChangeType(String typeStr) {
      switch (typeStr.toLowerCase()) {
        case 'create': return ChangeType.create;
        case 'update': return ChangeType.update;
        case 'delete': return ChangeType.delete;
        default: return ChangeType.create;
      }
    }

    return ActivityHistory(
      id: json['_id'] ?? '',
      activityId: ActivityHistoryReference.fromJson(json['activityId']),
      userId: ActivityHistoryReference.fromJson(json['userId']),
      changeType: json['changeType'] != null 
          ? parseChangeType(json['changeType'])
          : ChangeType.create,
      changedFields: json['changedFields'] != null 
          ? List<String>.from(json['changedFields'])
          : null,
      previousValues: json['previousValues'],
      newValues: json['newValues'],
      timestamp: json['timestamp'] != null 
          ? DateTime.parse(json['timestamp'])
          : DateTime.now(),
    );
  }
}

class ActivityHistoryReference {
  final String id;
  final String? name;
  final String? username;

  ActivityHistoryReference({
    required this.id,
    this.name,
    this.username,
  });

  factory ActivityHistoryReference.fromJson(dynamic json) {
    // Handle different formats that might come from the API
    if (json is String) {
      return ActivityHistoryReference(id: json);
    } else if (json is Map<String, dynamic>) {
      return ActivityHistoryReference(
        id: json['_id'] ?? '',
        name: json['name'],
        username: json['username'],
      );
    }
    return ActivityHistoryReference(id: '');
  }
}