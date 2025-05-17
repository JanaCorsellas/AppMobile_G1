import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_application_1/services/auth_service.dart';
import 'package:flutter_application_1/services/achievementService.dart';
import 'package:flutter_application_1/services/http_service.dart';
import 'package:flutter_application_1/models/achievement.dart';
import 'package:flutter_application_1/widgets/custom_drawer.dart';
import 'package:flutter_application_1/config/routes.dart';

class AchievementsScreen extends StatefulWidget {
  const AchievementsScreen({Key? key}) : super(key: key);

  @override
  State<AchievementsScreen> createState() => _AchievementsScreenState();
}

class _AchievementsScreenState extends State<AchievementsScreen> {
  bool _isLoading = true;
  List<Achievement> _achievements = [];
  int _unlockedCount = 0;

  @override
  void initState() {
    super.initState();
    _loadAchievements();
  }

  Future<void> _loadAchievements() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      final httpService = HttpService(authService);
      final achievementService = AchievementService(httpService);

      if (authService.currentUser == null) {
        throw Exception('No authenticated user');
      }

      final achievements = await achievementService.getUserAchievements(
        authService.currentUser!.id,
      );

      if (mounted) {
        setState(() {
          _achievements = achievements;
          _unlockedCount = achievements.where((a) => a.isUnlocked).length;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
      print('Error loading achievements: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: const CustomDrawer(currentRoute: AppRoutes.achievements),
      appBar: AppBar(
        title: const Text('Mis Logros'),
        backgroundColor: const Color.fromARGB(255, 21, 95, 51),
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadAchievements,
            tooltip: 'Refrescar',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Encabezado con estadísticas
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
                  color: const Color.fromARGB(255, 21, 95, 51),
                  child: Column(
                    children: [
                      const Text(
                        'Estadísticas de Logros',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          _buildStatCard(
                            '$_unlockedCount',
                            'Logros\nDesbloqueados',
                            Icons.emoji_events,
                          ),
                          _buildStatCard(
                            '${_achievements.length}',
                            'Total de\nLogros',
                            Icons.stars,
                          ),
                          _buildStatCard(
                            '${_achievements.isEmpty ? 0 : (_unlockedCount / _achievements.length * 100).toStringAsFixed(0)}%',
                            'Progreso\nTotal',
                            Icons.analytics,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                
                // Lista de logros
                Expanded(
                  child: _achievements.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.emoji_events_outlined,
                                size: 48,
                                color: Colors.grey[400],
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'No hay logros disponibles',
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: 16,
                                ),
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: _achievements.length,
                          itemBuilder: (context, index) {
                            final achievement = _achievements[index];
                            return _buildAchievementCard(achievement);
                          },
                        ),
                ),
              ],
            ),
    );
  }

  Widget _buildStatCard(String value, String label, IconData icon) {
    return Container(
      width: 100,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Icon(icon, color: Colors.white, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white.withOpacity(0.9),
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAchievementCard(Achievement achievement) {
    final bool isUnlocked = achievement.isUnlocked;
    
    // Convertir string de icono a IconData
    IconData getIconData(String iconString) {
      switch (iconString) {
        case 'directions_run':
          return Icons.directions_run;
        case 'landscape':
          return Icons.landscape;
        case 'wb_sunny':
          return Icons.wb_sunny;
        case 'terrain':
          return Icons.terrain;
        case 'chat':
          return Icons.chat;
        default:
          return Icons.emoji_events;
      }
    }
    
    final IconData iconData = getIconData(achievement.icon);
    
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: isUnlocked ? 2 : 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      color: isUnlocked ? Colors.white : Colors.grey[100],
      child: InkWell(
        onTap: () {
          _showAchievementDetails(achievement);
        },
        borderRadius: BorderRadius.circular(12),
        child: Opacity(
          opacity: isUnlocked ? 1.0 : 0.7,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    // Icono
                    Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        color: isUnlocked
                            ? const Color.fromARGB(255, 21, 95, 51).withOpacity(0.1)
                            : Colors.grey.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        iconData,
                        color: isUnlocked
                            ? const Color.fromARGB(255, 21, 95, 51)
                            : Colors.grey,
                        size: 28,
                      ),
                    ),
                    const SizedBox(width: 16),
                    
                    // Título y descripción
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            achievement.title,
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: isUnlocked ? Colors.black87 : Colors.grey[700],
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            achievement.description,
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    // Insignia o candado
                    isUnlocked
                        ? const Icon(
                            Icons.verified,
                            color: Color.fromARGB(255, 21, 95, 51),
                            size: 24,
                          )
                        : const Icon(
                            Icons.lock_outline,
                            color: Colors.grey,
                            size: 24,
                          ),
                  ],
                ),
                
                // Condición
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: isUnlocked
                        ? const Color.fromARGB(255, 21, 95, 51).withOpacity(0.1)
                        : Colors.grey.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    achievement.condition,
                    style: TextStyle(
                      fontSize: 12,
                      color: isUnlocked
                          ? const Color.fromARGB(255, 21, 95, 51)
                          : Colors.grey[600],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showAchievementDetails(Achievement achievement) {
    final bool isUnlocked = achievement.isUnlocked;
    
    // Convertir string de icono a IconData
    IconData getIconData(String iconString) {
      switch (iconString) {
        case 'directions_run':
          return Icons.directions_run;
        case 'landscape':
          return Icons.landscape;
        case 'wb_sunny':
          return Icons.wb_sunny;
        case 'terrain':
          return Icons.terrain;
        case 'chat':
          return Icons.chat;
        default:
          return Icons.emoji_events;
      }
    }
    
    final IconData iconData = getIconData(achievement.icon);
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(achievement.title),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Icono grande
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: isUnlocked
                    ? const Color.fromARGB(255, 21, 95, 51).withOpacity(0.1)
                    : Colors.grey.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                iconData,
                color: isUnlocked
                    ? const Color.fromARGB(255, 21, 95, 51)
                    : Colors.grey,
                size: 48,
              ),
            ),
            const SizedBox(height: 16),
            
            // Descripción
            Text(
              achievement.description,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 16),
            
            // Condición
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: isUnlocked
                    ? const Color.fromARGB(255, 21, 95, 51).withOpacity(0.1)
                    : Colors.grey.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.info_outline,
                    color: isUnlocked
                        ? const Color.fromARGB(255, 21, 95, 51)
                        : Colors.grey,
                  ),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      achievement.condition,
                      style: TextStyle(
                        color: isUnlocked
                            ? const Color.fromARGB(255, 21, 95, 51)
                            : Colors.grey[600],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            
            // Estado
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: isUnlocked ? Colors.green[50] : Colors.grey[100],
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isUnlocked ? Colors.green : Colors.grey,
                  width: 1,
                ),
              ),
              child: Text(
                isUnlocked ? '¡Desbloqueado!' : 'Aún no desbloqueado',
                style: TextStyle(
                  color: isUnlocked ? Colors.green : Colors.grey,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cerrar'),
          ),
        ],
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
    );
  }
}