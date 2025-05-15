import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_application_1/services/auth_service.dart';
import 'package:flutter_application_1/widgets/custom_drawer.dart';
import 'package:flutter_application_1/config/routes.dart';

class AchievementsScreen extends StatefulWidget {
  const AchievementsScreen({Key? key}) : super(key: key);

  @override
  State<AchievementsScreen> createState() => _AchievementsScreenState();
}

class _AchievementsScreenState extends State<AchievementsScreen> {
  bool _isLoading = true;
  
  // Lista de ejemplo para mostrar algunos logros
  final List<Map<String, dynamic>> _achievements = [
    {
      'id': '1',
      'title': 'Primeros Pasos',
      'description': 'Completa tu primera actividad',
      'icon': Icons.hiking,
      'unlocked': true,
      'progress': 100,
      'reward': '10 puntos de experiencia',
      'dateUnlocked': DateTime(2024, 5, 10),
    },
    {
      'id': '2',
      'title': 'Explorador de Montañas',
      'description': 'Completa 5 rutas diferentes',
      'icon': Icons.landscape,
      'unlocked': true,
      'progress': 100,
      'reward': '50 puntos de experiencia',
      'dateUnlocked': DateTime(2024, 5, 12),
    },
    {
      'id': '3',
      'title': 'Madrugador',
      'description': 'Inicia 3 actividades antes de las 8 AM',
      'icon': Icons.wb_sunny,
      'unlocked': false,
      'progress': 66,
      'reward': '30 puntos de experiencia',
      'dateUnlocked': null,
    },
    {
      'id': '4',
      'title': 'Maratonista',
      'description': 'Acumula un total de 42 km corriendo',
      'icon': Icons.directions_run,
      'unlocked': false,
      'progress': 40,
      'reward': '100 puntos de experiencia',
      'dateUnlocked': null,
    },
    {
      'id': '5',
      'title': 'Rey de la Montaña',
      'description': 'Alcanza una elevación acumulada de 1000m',
      'icon': Icons.terrain,
      'unlocked': false,
      'progress': 75,
      'reward': '80 puntos de experiencia',
      'dateUnlocked': null,
    },
    {
      'id': '6',
      'title': 'Social Tracker',
      'description': 'Chatea con 5 usuarios diferentes',
      'icon': Icons.chat,
      'unlocked': true,
      'progress': 100,
      'reward': '20 puntos de experiencia',
      'dateUnlocked': DateTime(2024, 5, 5),
    },
  ];

  @override
  void initState() {
    super.initState();
    // Simular carga de datos
    Future.delayed(const Duration(milliseconds: 800), () {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      //drawer: const CustomDrawer(currentRoute: AppRoutes.achievements),
      appBar: AppBar(
        title: const Text('Mis Logros'),
        backgroundColor: const Color.fromARGB(255, 21, 95, 51),
        foregroundColor: Colors.white,
        elevation: 0,
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
                            '3',
                            'Logros\nDesbloqueados',
                            Icons.emoji_events,
                          ),
                          _buildStatCard(
                            '6',
                            'Total de\nLogros',
                            Icons.stars,
                          ),
                          _buildStatCard(
                            '50%',
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
                  child: ListView.builder(
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

  Widget _buildAchievementCard(Map<String, dynamic> achievement) {
    final bool isUnlocked = achievement['unlocked'] == true;
    
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: () {
          _showAchievementDetails(achievement);
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  // Icono del logro
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
                      achievement['icon'],
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
                          achievement['title'],
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: isUnlocked ? Colors.black87 : Colors.grey[700],
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          achievement['description'],
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
              
              // Barra de progreso
              const SizedBox(height: 12),
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: LinearProgressIndicator(
                  value: achievement['progress'] / 100,
                  backgroundColor: Colors.grey[200],
                  valueColor: AlwaysStoppedAnimation<Color>(
                    isUnlocked
                        ? const Color.fromARGB(255, 21, 95, 51)
                        : Colors.amber,
                  ),
                  minHeight: 8,
                ),
              ),
              const SizedBox(height: 8),
              
              // Texto de progreso
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    isUnlocked
                        ? 'Completado'
                        : '${achievement['progress']}% completado',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                  if (isUnlocked && achievement['dateUnlocked'] != null)
                    Text(
                      'Desbloqueado: ${_formatDate(achievement['dateUnlocked'])}',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showAchievementDetails(Map<String, dynamic> achievement) {
    final bool isUnlocked = achievement['unlocked'] == true;
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(achievement['title']),
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
                achievement['icon'],
                color: isUnlocked
                    ? const Color.fromARGB(255, 21, 95, 51)
                    : Colors.grey,
                size: 48,
              ),
            ),
            const SizedBox(height: 16),
            
            // Descripción
            Text(
              achievement['description'],
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 16),
            
            // Recompensa
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
                    Icons.card_giftcard,
                    color: isUnlocked
                        ? const Color.fromARGB(255, 21, 95, 51)
                        : Colors.grey,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Recompensa: ${achievement['reward']}',
                    style: TextStyle(
                      color: isUnlocked
                          ? const Color.fromARGB(255, 21, 95, 51)
                          : Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
            
            // Fecha de desbloqueo
            if (isUnlocked && achievement['dateUnlocked'] != null)
              Padding(
                padding: const EdgeInsets.only(top: 16),
                child: Text(
                  'Desbloqueado el ${_formatDate(achievement['dateUnlocked'])}',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                    fontStyle: FontStyle.italic,
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
  
  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}