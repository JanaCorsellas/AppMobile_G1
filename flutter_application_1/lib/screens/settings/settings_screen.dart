import 'package:flutter/material.dart';
import 'package:flutter_application_1/config/routes.dart';
import 'package:flutter_application_1/widgets/custom_drawer.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_application_1/providers/theme_provider.dart';
import 'package:flutter_application_1/providers/language_provider.dart';
import 'package:flutter_application_1/extensions/string_extensions.dart';

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
        title: Text('settings'.tr(context)),
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
                  Text(
                    'appearance'.tr(context),
                    style: const TextStyle(
                      fontSize: 20.0,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16.0),
                  Card(
                    child: SwitchListTile(
                      title: Text('dark_mode'.tr(context)),
                      subtitle: Text('switch_theme'.tr(context)),
                      value: _darkMode,
                      onChanged: (value) {
                        setState(() {
                          _darkMode = value;
                        });
                        _saveSettings();
                        // If you have a ThemeProvider
                        Provider.of<ThemeProvider>(context, listen: false).toggleTheme();
                      },
                      secondary: Icon(
                        _darkMode ? Icons.dark_mode : Icons.light_mode,
                        color: _darkMode ? Colors.deepPurple : Colors.amber,
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 24.0),
                  
                  Text(
                    'language'.tr(context),
                    style: const TextStyle(
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
                            // Actualizar el idioma en el provider
                            Provider.of<LanguageProvider>(context, listen: false).setLanguage(value!);
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
                            // Actualizar el idioma en el provider
                            Provider.of<LanguageProvider>(context, listen: false).setLanguage(value!);
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
                            // Actualizar el idioma en el provider
                            Provider.of<LanguageProvider>(context, listen: false).setLanguage(value!);
                          },
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 24.0),
                  
                  Text(
                    'notifications'.tr(context),
                    style: const TextStyle(
                      fontSize: 20.0,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16.0),
                  Card(
                    child: Column(
                      children: [
                        SwitchListTile(
                          title: Text('push_notifications'.tr(context)),
                          subtitle: Text('receive_notifications'.tr(context)),
                          value: true, // Replace with your state variable
                          onChanged: (value) {
                            // Implement notification toggle
                          },
                          secondary: const Icon(Icons.notifications),
                        ),
                        SwitchListTile(
                          title: Text('activity_notifications'.tr(context)),
                          subtitle: Text('exercise_reminders'.tr(context)),
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
                  
                  Text(
                    'privacy'.tr(context),
                    style: const TextStyle(
                      fontSize: 20.0,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16.0),
                  Card(
                    child: Column(
                      children: [
                        SwitchListTile(
                          title: Text('public_profile'.tr(context)),
                          subtitle: Text('show_profile'.tr(context)),
                          value: true, // Replace with your state variable
                          onChanged: (value) {
                            // Implement privacy toggle
                          },
                          secondary: const Icon(Icons.visibility),
                        ),
                        SwitchListTile(
                          title: Text('share_activities'.tr(context)),
                          subtitle: Text('allow_viewing'.tr(context)),
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
                      '${('version').tr(context)} 1.0.0',
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