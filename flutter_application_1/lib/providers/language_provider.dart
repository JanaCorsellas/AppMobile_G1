import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LanguageProvider with ChangeNotifier {
  String _currentLanguage = 'es'; // Default to Spanish
  
  String get currentLanguage => _currentLanguage;
  
  Locale get locale => _getLocale(_currentLanguage);
  
  // Mapa de traducciones
  final Map<String, Map<String, String>> _translations = {
    'app_title': {
      'en': 'Sport Activity App',
      'es': 'Aplicación de Actividades Deportivas',
      'ca': 'Aplicació d\'Activitats Esportives',
    },
    'settings': {
      'en': 'Settings',
      'es': 'Configuración',
      'ca': 'Configuració',
    },
    'appearance': {
      'en': 'Appearance',
      'es': 'Apariencia',
      'ca': 'Aparença',
    },
    'dark_mode': {
      'en': 'Dark mode',
      'es': 'Modo oscuro',
      'ca': 'Mode fosc',
    },
    'switch_theme': {
      'en': 'Switch between light and dark theme',
      'es': 'Cambiar entre tema claro y oscuro',
      'ca': 'Canviar entre tema clar i fosc',
    },
    'language': {
      'en': 'Language',
      'es': 'Idioma',
      'ca': 'Idioma',
    },
    'notifications': {
      'en': 'Notifications',
      'es': 'Notificaciones',
      'ca': 'Notificacions',
    },
    'push_notifications': {
      'en': 'Push notifications',
      'es': 'Notificaciones push',
      'ca': 'Notificacions push',
    },
    'receive_notifications': {
      'en': 'Receive notifications in real time',
      'es': 'Recibir notificaciones en tiempo real',
      'ca': 'Rebre notificacions en temps real',
    },
    'activity_notifications': {
      'en': 'Activity notifications',
      'es': 'Notificaciones de actividad',
      'ca': 'Notificacions d\'activitat',
    },
    'exercise_reminders': {
      'en': 'Exercise reminders',
      'es': 'Recordatorios para hacer ejercicio',
      'ca': 'Recordatoris per fer exercici',
    },
    'privacy': {
      'en': 'Privacy',
      'es': 'Privacidad',
      'ca': 'Privacitat',
    },
    'public_profile': {
      'en': 'Public profile',
      'es': 'Perfil público',
      'ca': 'Perfil públic',
    },
    'show_profile': {
      'en': 'Show my profile to other users',
      'es': 'Mostrar mi perfil a otros usuarios',
      'ca': 'Mostrar el meu perfil a altres usuaris',
    },
    'share_activities': {
      'en': 'Share activities',
      'es': 'Compartir actividades',
      'ca': 'Compartir activitats',
    },
    'allow_viewing': {
      'en': 'Allow others to see my activities',
      'es': 'Permitir que otros vean mis actividades',
      'ca': 'Permetre que altres vegin les meves activitats',
    },
    'version': {
      'en': 'Version',
      'es': 'Versión',
      'ca': 'Versió',
    },
    'home': {
      'en': 'Home',
      'es': 'Inicio',
      'ca': 'Inici',
    },
    'profile': {
      'en': 'Profile',
      'es': 'Perfil',
      'ca': 'Perfil',
    },
    'my_activities': {
      'en': 'My activities',
      'es': 'Mis actividades',
      'ca': 'Les meves activitats',
    },
    'start_activity': {
      'en': 'Start activity',
      'es': 'Iniciar actividad',
      'ca': 'Iniciar activitat',
    },
    'my_songs': {
      'en': 'My songs',
      'es': 'Mis canciones',
      'ca': 'Les meves cançons',
    },
    'achievements': {
      'en': 'Achievements',
      'es': 'Logros',
      'ca': 'Assoliments',
    },
    'chat': {
      'en': 'Chat',
      'es': 'Chat',
      'ca': 'Xat',
    },
    'notifications_title': {
      'en': 'Notifications',
      'es': 'Notificaciones',
      'ca': 'Notificacions',
    },
    'logout': {
      'en': 'Logout',
      'es': 'Cerrar sesión',
      'ca': 'Tancar sessió',
    },
    'logout_confirm': {
      'en': 'Are you sure you want to log out?',
      'es': '¿Estás seguro de que quieres cerrar sesión?',
      'ca': 'Estàs segur que vols tancar la sessió?',
    },
    'cancel': {
      'en': 'Cancel',
      'es': 'Cancelar',
      'ca': 'Cancel·lar',
    },
    'retry': {
      'en': 'Retry',
      'es': 'Reintentar',
      'ca': 'Tornar a intentar',
    },
    'welcome': {
      'en': 'Welcome',
      'es': 'Bienvenido',
      'ca': 'Benvingut',
    },
    'welcome_user': {
      'en': 'Welcome, {username}',
      'es': 'Bienvenido, {username}',
      'ca': 'Benvingut, {username}',
    },
    'activity_management': {
      'en': 'Here you can manage your sport activities and track your progress.',
      'es': 'Aquí puedes gestionar tus actividades deportivas y seguir tu progreso.',
      'ca': 'Aquí pots gestionar les teves activitats esportives i seguir el teu progrés.',
    },
    'view_profile': {
      'en': 'View Profile',
      'es': 'Ver Perfil',
      'ca': 'Veure Perfil',
    },
    'quick_stats': {
      'en': 'Quick stats',
      'es': 'Estadísticas rápidas',
      'ca': 'Estadístiques ràpides',
    },
    'level': {
      'en': 'Level',
      'es': 'Nivel',
      'ca': 'Nivell',
    },
    'distance': {
      'en': 'Distance',
      'es': 'Distancia',
      'ca': 'Distància',
    },
    'time': {
      'en': 'Time',
      'es': 'Tiempo',
      'ca': 'Temps',
    },
    'recent_activities': {
      'en': 'Recent activities',
      'es': 'Actividades recientes',
      'ca': 'Activitats recents',
    },
    'view_less': {
      'en': 'View less',
      'es': 'Ver menos',
      'ca': 'Veure menys',
    },
    'view_all': {
      'en': 'View all',
      'es': 'Ver todas',
      'ca': 'Veure totes',
    },
    'no_activities': {
      'en': 'No activities registered',
      'es': 'No tienes actividades registradas',
      'ca': 'No tens activitats registrades',
    },
    'start_new_activity': {
      'en': 'Start a new activity with the "Start Activity" button',
      'es': 'Comienza una nueva actividad con el botón "Iniciar Actividad"',
      'ca': 'Comença una nova activitat amb el botó "Iniciar Activitat"',
    },
    'users_online': {
      'en': 'Users online',
      'es': 'Usuarios conectados',
      'ca': 'Usuaris connectats',
    },
    'total_online': {
      'en': 'Total:',
      'es': 'Total:',
      'ca': 'Total:',
    },
    'users': {
      'en': 'users online',
      'es': 'usuarios en línea',
      'ca': 'usuaris en línia',
    },
    'no_users_online': {
      'en': 'No users online',
      'es': 'No hay usuarios conectados',
      'ca': 'No hi ha usuaris connectats',
    },
    'user': {
      'en': 'User',
      'es': 'Usuario',
      'ca': 'Usuari',
    },
    'save_changes': {
      'en': 'Save Changes',
      'es': 'Guardar Cambios',
      'ca': 'Desar Canvis',
    },
    'connected': {
      'en': 'Connected',
      'es': 'Conectado',
      'ca': 'Connectat',
    },
    'connecting': {
      'en': 'Connecting...',
      'es': 'Conectando...',
      'ca': 'Connectant...',
    },
    'disconnected': {
      'en': 'Disconnected',
      'es': 'Desconectado',
      'ca': 'Desconnectat',
    },
  };
  
  LanguageProvider() {
    _loadLanguageFromPrefs();
  }
  
  Future<void> _loadLanguageFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    _currentLanguage = prefs.getString('language') ?? 'es';
    notifyListeners();
  }
  
  Future<void> setLanguage(String languageCode) async {
    _currentLanguage = languageCode;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('language', languageCode);
    notifyListeners();
  }
  
  Locale _getLocale(String languageCode) {
    switch (languageCode) {
      case 'en':
        return const Locale('en', 'US');
      case 'ca':
        return const Locale('ca', 'ES');
      case 'es':
      default:
        return const Locale('es', 'ES');
    }
  }
  
  // Método para obtener traducciones
  String translate(String key) {
    if (!_translations.containsKey(key)) {
      return key; // Si la clave no existe, devolver la misma clave
    }
    
    final translations = _translations[key]!;
    return translations[_currentLanguage] ?? translations['es'] ?? key;
  }
  
  // Método para obtener traducciones con parámetros
  String translateWithParams(String key, Map<String, String> params) {
    String translated = translate(key);
    params.forEach((paramKey, paramValue) {
      translated = translated.replaceAll('{$paramKey}', paramValue);
    });
    return translated;
  }
}