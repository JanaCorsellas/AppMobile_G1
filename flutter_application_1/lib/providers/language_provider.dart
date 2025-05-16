import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LanguageProvider with ChangeNotifier {
  String _currentLanguage = 'es'; // Default to Spanish
  
  String get currentLanguage => _currentLanguage;
  
  Locale get locale => _getLocale(_currentLanguage);
  
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
  
  // You could also add translation functions or maps here
  String translate(String key) {
    final translations = {
      'settings': {
        'en': 'Settings',
        'es': 'Configuración',
        'ca': 'Configuració',
      },
      'dark_mode': {
        'en': 'Dark Mode',
        'es': 'Modo Oscuro',
        'ca': 'Mode Fosc',
      },
      // Add more translations as needed
    };
    
    return translations[key]?[_currentLanguage] ?? key;
  }
}