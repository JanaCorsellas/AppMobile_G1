import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_application_1/services/auth_service.dart';
import 'package:flutter_application_1/services/achievementService.dart';
import 'package:flutter_application_1/services/http_service.dart';
import 'package:flutter_application_1/models/achievement.dart';
import 'package:flutter_application_1/config/routes.dart';

class AchievementProgressWidget extends StatefulWidget {
  final bool showTitle;
  final int maxAchievements;

  const AchievementProgressWidget({
    Key? key,
    this.showTitle = true,
    this.maxAchievements = 3,
  }) : super(key: key);

  @override
  State<AchievementProgressWidget> createState() => _AchievementProgressWidgetState();
}

class _AchievementProgressWidgetState extends State<AchievementProgressWidget> {
  List<Achievement> _recentAchievements = [];
  int _totalCount = 0;
  int _unlockedCount = 0;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadAchievementProgress();
  }

  Future<void> _loadAchievementProgress() async {
    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      if (authService.currentUser == null) return;

      final httpService = HttpService(authService);
      final achievementService = AchievementService(httpService);

      final achievementData = await achievementService.getUserAchievements(
        authService.currentUser!.id,
      );

      if (mounted) {
        setState(() {
          final unlocked = achievementData['unlocked'] as List<Achievement>;
          _recentAchievements = unlocked.take(widget.maxAchievements).toList();
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
      }
      print('Error loading achievement progress: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Center(child: CircularProgressIndicator()),
        ),
      );
    }

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: () {
          Navigator.pushNamed(context, AppRoutes.achievements);
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (widget.showTitle) ...[
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Logros',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      '$_unlockedCount/$_totalCount',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
              ],

              // Barra de progreso
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: LinearProgressIndicator(
                  value: _totalCount > 0 ? _unlockedCount / _totalCount : 0,
                  backgroundColor: Colors.grey[300],
                  valueColor: const AlwaysStoppedAnimation<Color>(
                    Color.fromARGB(255, 21, 95, 51),
                  ),
                  minHeight: 8,
                ),
              ),
              const SizedBox(height: 12),

              // Logros recientes
              if (_recentAchievements.isNotEmpty) ...[
                const Text(
                  'Logros recientes:',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 8),
                ..._recentAchievements.map((achievement) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    children: [
                      Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: achievement.getDifficultyColor().withOpacity(0.2),
                        ),
                        child: Icon(
                          achievement.getTypeIcon(),
                          color: achievement.getDifficultyColor(),
                          size: 18,
                        ),
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
                              '+${achievement.points} puntos',
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
              ] else ...[
                Center(
                  child: Column(
                    children: [
                      Icon(
                        Icons.emoji_events_outlined,
                        color: Colors.grey[400],
                        size: 48,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Aún no tienes logros',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '¡Empieza una actividad!',
                        style: TextStyle(
                          color: Colors.grey[500],
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: 8),
              Center(
                child: Text(
                  'Toca para ver todos',
                  style: TextStyle(
                    color: const Color.fromARGB(255, 21, 95, 51),
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}