// lib/config/api_constants.dart
class ApiConstants {
  // Base URL - adjust this to your actual backend URL
  //static const String baseUrl = 'http://ea1-api.upc.edu';
  static const String baseUrl = 'http://localhost:3000';
  static const String apiPath = '/api';
  //static const String apiPath = '/api-docs';
  
  // Auth endpoints
  static const String login = '$baseUrl$apiPath/auth/login';
  static const String register = '$baseUrl$apiPath/auth/register';
  static const String refreshToken = '$baseUrl$apiPath/auth/refresh';
  static const String logout = '$baseUrl$apiPath/auth/logout';
  
  // User endpoints
  static const String users = '$baseUrl$apiPath/users';
  static String user(String id) => '$baseUrl$apiPath/users/$id';
  static String userByUsername(String username) => '$baseUrl$apiPath/users/username/$username';
  static String searchUsers(String query) => '$baseUrl$apiPath/users/search?query=$query';
  static String toggleUserVisibility(String id) => '$baseUrl$apiPath/users/$id/toggle-visibility';
  
  // Activity endpoints
  static const String activities = '$baseUrl$apiPath/activities';
  static String activity(String id) => '$baseUrl$apiPath/activities/$id';
  static String userActivities(String userId) => '$baseUrl$apiPath/activities/user/$userId';
  
  // Activity history endpoints
  static const String activityHistory = '$baseUrl$apiPath/activity-history';
  static String activityHistoryByActivityId(String activityId) => '$baseUrl$apiPath/activity-history/activity/$activityId';
  
  // Chat endpoints
  static const String chatRooms = '$baseUrl$apiPath/chat/rooms';
  static String userChatRooms(String userId) => '$baseUrl$apiPath/chat/rooms/user/$userId';
  static String chatRoom(String id) => '$baseUrl$apiPath/chat/rooms/$id';
  static String chatMessages(String roomId) => '$baseUrl$apiPath/chat/messages/$roomId';
  static const String sendMessage = '$baseUrl$apiPath/chat/messages';
  static const String markMessagesRead = '$baseUrl$apiPath/chat/messages/read';
  static String deleteChatRoom(String roomId) => '$baseUrl$apiPath/chat/rooms/$roomId';

  static String uploadGroupPicture(String roomId) => '$chatRooms/$roomId/group-picture';
  
  // Notification endpoints
  static String notifications(String userId) => '$baseUrl$apiPath/notifications/user/$userId';
  static String markNotificationRead(String id) => '$baseUrl$apiPath/notifications/$id/read';
  static String markAllNotificationsRead(String userId) => '$baseUrl$apiPath/notifications/user/$userId/read-all';
  static String deleteNotification(String id) => '$baseUrl$apiPath/notifications/$id';
  static const String createNotification = '$baseUrl$apiPath/notifications';
  static const String bulkNotifications = '$baseUrl$apiPath/notifications/bulk';
  
  // Achievement endpoints - ACTUALIZADOS
  static const String achievements = '$baseUrl$apiPath/achievements';
  static const String allAchievements = '$baseUrl$apiPath/achievements/all/list';
  static String achievement(String id) => '$baseUrl$apiPath/achievements/$id';
  static String userAchievements(String userId) => '$baseUrl$apiPath/achievements/user/$userId';
  static String checkUserAchievements(String userId) => '$baseUrl$apiPath/achievements/user/$userId/check';
  static const String initializeAchievements = '$baseUrl$apiPath/achievements/initialize/defaults';
}