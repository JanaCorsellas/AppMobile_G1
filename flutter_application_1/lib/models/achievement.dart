class Achievement {
  final String id;
  final String title;
  final String description;
  final String condition;
  final String icon;
  final List<String> usersUnlocked;
  bool isUnlocked;

  Achievement({
    required this.id,
    required this.title,
    required this.description,
    required this.condition,
    required this.icon,
    required this.usersUnlocked,
    this.isUnlocked = false,
  });

  factory Achievement.fromJson(Map<String, dynamic> json) {
    List<String> parseUsersList(dynamic users) {
      if (users == null) return [];
      if (users is List) {
        return users.map((user) {
          if (user is Map) {
            return user['_id']?.toString() ?? '';
          } else {
            return user.toString();
          }
        }).toList();
      }
      return [];
    }

    return Achievement(
      id: json['_id'] ?? '',
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      condition: json['condition'] ?? '',
      icon: json['icon'] ?? 'emoji_events',
      usersUnlocked: parseUsersList(json['usersUnlocked']),
      isUnlocked: false, // Se actualizará después
    );
  }
}