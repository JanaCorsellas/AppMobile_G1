import 'package:flutter/material.dart';
import 'package:flutter_application_1/config/routes.dart';
import 'package:flutter_application_1/widgets/custom_drawer.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_application_1/providers/theme_provider.dart';
import 'package:flutter_application_1/providers/language_provider.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({Key? key}) : super(key: key);

  @override
  _SettingsScreenState createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _darkMode = false;
  String _selectedLanguage = 'es'; // Default language
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _darkMode = prefs.getBool('darkMode') ?? false;
      _selectedLanguage = prefs.getString('language') ?? 'es';
      _isLoading = false;
    });
  }

  Future<void> _saveSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('darkMode', _darkMode);
    await prefs.setString('language', _selectedLanguage);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: const CustomDrawer(currentRoute: AppRoutes.settingsRoute),
      appBar: AppBar(
        title: const Text('Configuración'),
        backgroundColor: const Color.fromARGB(255, 21, 95, 51),
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Apariencia',
                    style: TextStyle(
                      fontSize: 20.0,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16.0),
                  Card(
                    child: SwitchListTile(
                      title: const Text('Modo oscuro'),
                      subtitle: const Text('Cambiar entre tema claro y oscuro'),
                      value: _darkMode,
                      onChanged: (value) {
                        setState(() {
                          _darkMode = value;
                        });
                        _saveSettings();
                        // If you have a ThemeProvider
                        // Provider.of<ThemeProvider>(context, listen: false).toggleTheme();
                      },
                      secondary: Icon(
                        _darkMode ? Icons.dark_mode : Icons.light_mode,
                        color: _darkMode ? Colors.deepPurple : Colors.amber,
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 24.0),
                  
                  const Text(
                    'Idioma',
                    style: TextStyle(
                      fontSize: 20.0,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16.0),
                  Card(
                    child: Column(
                      children: [
                        RadioListTile<String>(
                          title: const Text('Español'),
                          value: 'es',
                          groupValue: _selectedLanguage,
                          onChanged: (value) {
                            setState(() {
                              _selectedLanguage = value!;
                            });
                            _saveSettings();
                            // If you have a LanguageProvider
                            // Provider.of<LanguageProvider>(context, listen: false).setLanguage(value!);
                          },
                        ),
                        RadioListTile<String>(
                          title: const Text('Català'),
                          value: 'ca',
                          groupValue: _selectedLanguage,
                          onChanged: (value) {
                            setState(() {
                              _selectedLanguage = value!;
                            });
                            _saveSettings();
                            // If you have a LanguageProvider
                            // Provider.of<LanguageProvider>(context, listen: false).setLanguage(value!);
                          },
                        ),
                        RadioListTile<String>(
                          title: const Text('English'),
                          value: 'en',
                          groupValue: _selectedLanguage,
                          onChanged: (value) {
                            setState(() {
                              _selectedLanguage = value!;
                            });
                            _saveSettings();
                            // If you have a LanguageProvider
                            // Provider.of<LanguageProvider>(context, listen: false).setLanguage(value!);
                          },
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 24.0),
                  
                  const Text(
                    'Notificaciones',
                    style: TextStyle(
                      fontSize: 20.0,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16.0),
                  Card(
                    child: Column(
                      children: [
                        SwitchListTile(
                          title: const Text('Notificaciones push'),
                          subtitle: const Text('Recibir notificaciones en tiempo real'),
                          value: true, // Replace with your state variable
                          onChanged: (value) {
                            // Implement notification toggle
                          },
                          secondary: const Icon(Icons.notifications),
                        ),
                        SwitchListTile(
                          title: const Text('Notificaciones de actividad'),
                          subtitle: const Text('Recordatorios para hacer ejercicio'),
                          value: false, // Replace with your state variable
                          onChanged: (value) {
                            // Implement activity notifications toggle
                          },
                          secondary: const Icon(Icons.fitness_center),
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 24.0),
                  
                  const Text(
                    'Privacidad',
                    style: TextStyle(
                      fontSize: 20.0,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16.0),
                  Card(
                    child: Column(
                      children: [
                        SwitchListTile(
                          title: const Text('Perfil público'),
                          subtitle: const Text('Mostrar mi perfil a otros usuarios'),
                          value: true, // Replace with your state variable
                          onChanged: (value) {
                            // Implement privacy toggle
                          },
                          secondary: const Icon(Icons.visibility),
                        ),
                        SwitchListTile(
                          title: const Text('Compartir actividades'),
                          subtitle: const Text('Permitir que otros vean mis actividades'),
                          value: true, // Replace with your state variable
                          onChanged: (value) {
                            // Implement activity sharing toggle
                          },
                          secondary: const Icon(Icons.share),
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 24.0),
                  
                  Center(
                    child: Text(
                      'Versión 1.0.0',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 14.0,
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}