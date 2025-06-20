import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_application_1/services/auth_service.dart';
import 'package:flutter_application_1/services/achievementService.dart';
import 'package:flutter_application_1/services/http_service.dart';
import 'package:flutter_application_1/models/achievement.dart';
import 'package:flutter_application_1/widgets/custom_drawer.dart';
import 'package:flutter_application_1/config/routes.dart';
import 'package:flutter_application_1/extensions/string_extensions.dart';

class AchievementsScreen extends StatefulWidget {
  const AchievementsScreen({Key? key}) : super(key: key);

  @override
  State<AchievementsScreen> createState() => _AchievementsScreenState();
}

class _AchievementsScreenState extends State<AchievementsScreen> 
    with TickerProviderStateMixin {
  bool _isLoading = true;
  List<Achievement> _unlockedAchievements = [];
  List<Achievement> _lockedAchievements = [];
  int _totalCount = 0;
  int _unlockedCount = 0;
  late TabController _tabController;
  String _selectedDifficulty = 'all';
  String _selectedType = 'all';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadAchievements();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
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

      // Verificar si hay nuevos logros
      final newlyUnlocked = await achievementService.checkUserAchievements(
        authService.currentUser!.id,
      );

      // Si hay nuevos logros, mostrar notificación
      if (newlyUnlocked.isNotEmpty && mounted) {
        _showNewAchievementsDialog(newlyUnlocked);
      }

      // Obtener todos los logros del usuario
      final achievementData = await achievementService.getUserAchievements(
        authService.currentUser!.id,
      );

      if (mounted) {
        setState(() {
          _unlockedAchievements = achievementData['unlocked'] ?? [];
          _lockedAchievements = achievementData['locked'] ?? [];
          _totalCount = achievementData['totalCount'] ?? 0;
          _unlockedCount = achievementData['unlockedCount'] ?? 0;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${'error_loading_activities'.tr(context)}: $e')),
        );
      }
      print('Error loading achievements: $e');
    }
  }

  void _showNewAchievementsDialog(List<Achievement> newAchievements) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.celebration, color: Colors.amber, size: 28),
            const SizedBox(width: 8),
            Text('new_achievements_dialog'.tr(context)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              newAchievements.length == 1
                  ? 'unlocked_one_achievement'.tr(context)
                  : 'unlocked_multiple_achievements'.trParams(context, {'count': newAchievements.length.toString()}),
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 16),
            ...newAchievements.map((achievement) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: [
                  Icon(
                    achievement.getTypeIcon(),
                    color: achievement.getDifficultyColor(),
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          achievement.title,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                        Text(
                          '+${achievement.points} ${'points_label'.tr(context)}',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            )).toList(),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('great_button'.tr(context)),
          ),
        ],
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
    );
  }

  List<Achievement> _getFilteredAchievements(List<Achievement> achievements) {
    return achievements.where((achievement) {
      bool difficultyMatch = _selectedDifficulty == 'all' || 
                           achievement.difficulty == _selectedDifficulty;
      bool typeMatch = _selectedType == 'all' || 
                      achievement.type.startsWith(_selectedType);
      return difficultyMatch && typeMatch;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: const CustomDrawer(currentRoute: AppRoutes.achievements),
      appBar: AppBar(
        title: Text('achievements'.tr(context)),
        backgroundColor: const Color(0xFF667eea),
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadAchievements,
            tooltip: 'refresh'.tr(context),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: [
            Tab(
              text: '${'unlocked_achievements'.tr(context)} ($_unlockedCount)',
              icon: const Icon(Icons.verified),
            ),
            Tab(
              text: '${'locked_achievements'.tr(context)} (${_totalCount - _unlockedCount})',
              icon: const Icon(Icons.lock),
            ),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Encabezado con estadísticas
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Color(0xFF667eea),
                        Color(0xFF764ba2),
                      ],
                    ),
                  ),
                  child: Column(
                    children: [
                      Text(
                        'achievements_statistics'.tr(context),
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
                            'unlocked_achievements_stats'.tr(context),
                            Icons.verified,
                          ),
                          _buildStatCard(
                            '$_totalCount',
                            'total_achievements_stats'.tr(context),
                            Icons.stars,
                          ),
                          _buildStatCard(
                            '${_totalCount == 0 ? 0 : ((_unlockedCount / _totalCount) * 100).toStringAsFixed(0)}%',
                            'total_progress_stats'.tr(context),
                            Icons.analytics,
                          ),
                          _buildStatCard(
                            '${_unlockedAchievements.fold(0, (sum, a) => sum + a.points)}',
                            'total_points_stats'.tr(context),
                            Icons.grade,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Filtros
                Container(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          value: _selectedDifficulty,
                          decoration: InputDecoration(
                            labelText: 'difficulty'.tr(context),
                            border: OutlineInputBorder(),
                            contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          ),
                          items: [
                            DropdownMenuItem(value: 'all', child: Text('all_difficulties'.tr(context))),
                            DropdownMenuItem(value: 'bronze', child: Text('bronze'.tr(context))),
                            DropdownMenuItem(value: 'silver', child: Text('silver'.tr(context))),
                            DropdownMenuItem(value: 'gold', child: Text('gold'.tr(context))),
                            DropdownMenuItem(value: 'diamond', child: Text('diamond'.tr(context))),
                          ],
                          onChanged: (value) {
                            setState(() {
                              _selectedDifficulty = value ?? 'all';
                            });
                          },
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          value: _selectedType,
                          decoration: InputDecoration(
                            labelText: 'type'.tr(context),
                            border: OutlineInputBorder(),
                            contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          ),
                          items: [
                            DropdownMenuItem(value: 'all', child: Text('all_types_achievements'.tr(context))),
                            DropdownMenuItem(value: 'distance', child: Text('distance_achievements'.tr(context))),
                            DropdownMenuItem(value: 'time', child: Text('time_achievements'.tr(context))),
                            DropdownMenuItem(value: 'activity', child: Text('activities_achievements'.tr(context))),
                            DropdownMenuItem(value: 'speed', child: Text('speed_achievements'.tr(context))),
                            DropdownMenuItem(value: 'elevation', child: Text('elevation_achievements'.tr(context))),
                            DropdownMenuItem(value: 'consecutive', child: Text('consecutive_achievements'.tr(context))),
                          ],
                          onChanged: (value) {
                            setState(() {
                              _selectedType = value ?? 'all';
                            });
                          },
                        ),
                      ),
                    ],
                  ),
                ),

                // Lista de logros con pestañas
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      // Logros desbloqueados
                      _buildAchievementsList(
                        _getFilteredAchievements(_unlockedAchievements),
                        true,
                      ),
                      // Logros bloqueados
                      _buildAchievementsList(
                        _getFilteredAchievements(_lockedAchievements),
                        false,
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildStatCard(String value, String label, IconData icon) {
    return Container(
      width: 80,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Icon(icon, color: Colors.white, size: 20),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white.withOpacity(0.9),
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAchievementsList(List<Achievement> achievements, bool isUnlocked) {
    if (achievements.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isUnlocked ? Icons.verified_outlined : Icons.lock_outline,
              size: 48,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              isUnlocked
                  ? 'no_unlocked_filtered'.tr(context)
                  : 'no_locked_filtered'.tr(context),
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 16,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: achievements.length,
      itemBuilder: (context, index) {
        final achievement = achievements[index];
        return _buildAchievementCard(achievement);
      },
    );
  }

  Widget _buildAchievementCard(Achievement achievement) {
    final bool isUnlocked = achievement.isUnlocked;
    final Color difficultyColor = achievement.getDifficultyColor();
    final IconData typeIcon = achievement.getTypeIcon();
    
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: isUnlocked ? 3 : 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: InkWell(
        onTap: () => _showAchievementDetails(achievement),
        borderRadius: BorderRadius.circular(16),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: isUnlocked
                ? LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      difficultyColor.withOpacity(0.1),
                      Colors.white,
                    ],
                  )
                : null,
            color: isUnlocked ? null : Colors.grey[50],
          ),
          child: Opacity(
            opacity: isUnlocked ? 1.0 : 0.6,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      // Icono con borde de dificultad
                      Container(
                        width: 60,
                        height: 60,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: isUnlocked
                              ? difficultyColor.withOpacity(0.2)
                              : Colors.grey.withOpacity(0.1),
                          border: Border.all(
                            color: isUnlocked ? difficultyColor : Colors.grey,
                            width: 2,
                          ),
                        ),
                        child: Icon(
                          typeIcon,
                          color: isUnlocked ? difficultyColor : Colors.grey,
                          size: 28,
                        ),
                      ),
                      const SizedBox(width: 16),
                      
                      // Título, descripción y puntos
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Text(
                                    achievement.title,
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: isUnlocked ? Colors.black87 : Colors.grey[700],
                                    ),
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: difficultyColor.withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    '${achievement.points} ${'points'.tr(context)}',
                                    style: TextStyle(
                                      color: difficultyColor,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                              ],
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
                      
                      // Estado (desbloqueado/bloqueado)
                      const SizedBox(width: 8),
                      Icon(
                        isUnlocked ? Icons.verified : Icons.lock_outline,
                        color: isUnlocked ? difficultyColor : Colors.grey,
                        size: 24,
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 12),
                  
                  // Información adicional
                  Row(
                    children: [
                      // Dificultad
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: difficultyColor.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          achievement.difficulty.toUpperCase(),
                          style: TextStyle(
                            color: difficultyColor,
                            fontWeight: FontWeight.bold,
                            fontSize: 11,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      
                      // Objetivo
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.grey.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          achievement.getFormattedTargetValue(),
                          style: TextStyle(
                            color: Colors.grey[700],
                            fontSize: 11,
                          ),
                        ),
                      ),
                      
                      const Spacer(),
                      
                      // Tipo de actividad (si es específica)
                      if (achievement.activityType != null && achievement.activityType != 'all')
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.blue.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            achievement.activityType!.toUpperCase(),
                            style: TextStyle(
                              color: Colors.blue[700],
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _showAchievementDetails(Achievement achievement) {
    final bool isUnlocked = achievement.isUnlocked;
    final Color difficultyColor = achievement.getDifficultyColor();
    final IconData typeIcon = achievement.getTypeIcon();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(achievement.title),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Icono grande con animación
              AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isUnlocked
                      ? difficultyColor.withOpacity(0.2)
                      : Colors.grey.withOpacity(0.1),
                  border: Border.all(
                    color: isUnlocked ? difficultyColor : Colors.grey,
                    width: 3,
                  ),
                  boxShadow: isUnlocked
                      ? [
                          BoxShadow(
                            color: difficultyColor.withOpacity(0.3),
                            blurRadius: 10,
                            spreadRadius: 2,
                          ),
                        ]
                      : null,
                ),
                child: Icon(
                  typeIcon,
                  color: isUnlocked ? difficultyColor : Colors.grey,
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
              
              // Detalles en tarjetas
              Row(
                children: [
                  Expanded(
                    child: _buildDetailCard(
                      'difficulty'.tr(context),
                      achievement.difficulty.toUpperCase(),
                      difficultyColor,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildDetailCard(
                      'points_label'.tr(context),
                      '${achievement.points}',
                      Colors.amber,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              _buildDetailCard(
                'achievement_target'.tr(context),
                achievement.getFormattedTargetValue(),
                Colors.blue,
              ),
              if (achievement.activityType != null && achievement.activityType != 'all')
                Column(
                  children: [
                    const SizedBox(height: 8),
                    _buildDetailCard(
                      'activity_type_achievement'.tr(context),
                      achievement.activityType!.toUpperCase(),
                      const Color(0xFF667eea),
                    ),
                  ],
                ),
              
              const SizedBox(height: 16),
              
              // Estado
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: isUnlocked ? const Color(0xFF667eea).withOpacity(0.1) : Colors.grey[100],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isUnlocked ? const Color(0xFF667eea) : Colors.grey,
                    width: 1,
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      isUnlocked ? Icons.verified : Icons.lock_outline,
                      color: isUnlocked ? const Color(0xFF667eea) : Colors.grey,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      isUnlocked ? 'unlocked_status'.tr(context) : 'not_unlocked_status'.tr(context),
                      style: TextStyle(
                        color: isUnlocked ? const Color(0xFF667eea) : Colors.grey,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('close'.tr(context)),
          ),
        ],
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
    );
  }

  Widget _buildDetailCard(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}