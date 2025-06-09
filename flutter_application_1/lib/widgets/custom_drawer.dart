import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_application_1/config/routes.dart';
import 'package:flutter_application_1/services/auth_service.dart';
import 'package:flutter_application_1/services/socket_service.dart';
import 'package:flutter_application_1/providers/language_provider.dart';
import 'package:flutter_application_1/extensions/string_extensions.dart';

class CustomDrawer extends StatelessWidget {
  final String currentRoute;

  const CustomDrawer({
    Key? key,
    required this.currentRoute,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);
    final socketService = Provider.of<SocketService>(context);
    final user = authService.currentUser;

    return Drawer(
      child: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF6B55D1),
              Color(0xFFF5F5F5),
            ],
            stops: [0.0, 0.3],
          ),
        ),
        child: Column(
          children: [
            // Header mejorado con diseño Trazer
            Container(
              height: 220,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xFF6B55D1),
                    Color(0xFF8B6FE7),
                  ],
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 10,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Stack(
                children: [
                  // Patrón de fondo decorativo
                  Positioned(
                    right: -30,
                    top: -30,
                    child: Container(
                      width: 150,
                      height: 150,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withOpacity(0.1),
                      ),
                    ),
                  ),
                  Positioned(
                    left: -50,
                    bottom: -50,
                    child: Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withOpacity(0.08),
                      ),
                    ),
                  ),
                  // Contenido del header
                  Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        // Avatar del usuario mejorado
                        Row(
                          children: [
                            Container(
                              width: 70,
                              height: 70,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: const LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: [
                                    Color(0xFFFF6B6B),
                                    Color(0xFFFF8787),
                                  ],
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.2),
                                    blurRadius: 8,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(3.0),
                                child: ClipOval(
                                  child: Container(
                                    color: Colors.white,
                                    child: user?.profilePicture != null && user!.profilePicture!.isNotEmpty
                                        ? Image.network(
                                            user.profilePicture!,
                                            fit: BoxFit.cover,
                                            errorBuilder: (ctx, obj, stack) => const Icon(
                                              Icons.person,
                                              color: Color(0xFF6B55D1),
                                              size: 35,
                                            ),
                                          )
                                        : const Icon(
                                            Icons.person,
                                            color: Color(0xFF6B55D1),
                                            size: 35,
                                          ),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 15),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    user?.username ?? 'user'.tr(context),
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    user?.email ?? '',
                                    style: TextStyle(
                                      color: Colors.white.withOpacity(0.9),
                                      fontSize: 14,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                                    decoration: BoxDecoration(
                                      gradient: const LinearGradient(
                                        colors: [
                                          Color(0xFFFF6B6B),
                                          Color(0xFFFF8787),
                                        ],
                                      ),
                                      borderRadius: BorderRadius.circular(20),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withOpacity(0.2),
                                          blurRadius: 4,
                                          offset: const Offset(0, 2),
                                        ),
                                      ],
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const Icon(
                                          Icons.star,
                                          color: Colors.white,
                                          size: 16,
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          '${('level').tr(context)} ${user?.level ?? 1}',
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 13,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        
                        const SizedBox(height: 20),
                        
                        // Logo y nombre de la app mejorado
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.terrain, color: Colors.white, size: 20),
                              SizedBox(width: 8),
                              Text(
                                'Trazer',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 1,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            
            // Lista de menú mejorada
            Expanded(
              child: Container(
                decoration: const BoxDecoration(
                  color: Color(0xFFF5F5F5),
                ),
                child: ListView(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  children: [
                    _buildMenuItem(
                      context,
                      icon: Icons.home_rounded,
                      title: 'home'.tr(context),
                      route: AppRoutes.userHome,
                      currentRoute: currentRoute,
                    ),
                
                    _buildMenuItem(
                      context,
                      icon: Icons.person_rounded,
                      title: 'profile'.tr(context),
                      route: AppRoutes.userProfile,
                      currentRoute: currentRoute,
                    ),
                    
                    _buildMenuItem(
                      context,
                      icon: Icons.history_rounded,
                      title: 'my_activities'.tr(context),
                      route: AppRoutes.activities,
                      currentRoute: currentRoute,
                    ),
                    
                    _buildMenuItem(
                      context,
                      icon: Icons.people_alt_rounded,
                      title: 'following_activities'.tr(context),
                      route: AppRoutes.followingActivities,
                      currentRoute: currentRoute,
                    ),
                    
                    _buildMenuItem(
                      context,
                      icon: Icons.directions_run_rounded,
                      title: 'start_activity'.tr(context),
                      route: AppRoutes.activitySelection,
                      currentRoute: currentRoute,
                      isHighlighted: true,
                    ),
                    
                    _buildMenuItem(
                      context,
                      icon: Icons.emoji_events_rounded,
                      title: 'achievements'.tr(context),
                      route: AppRoutes.achievements,
                      currentRoute: currentRoute,
                    ),
                    
                    _buildMenuItem(
                      context,
                      icon: Icons.chat_bubble_rounded,
                      title: 'chat'.tr(context),
                      route: AppRoutes.chatList,
                      currentRoute: currentRoute,
                    ),
                    
                    _buildMenuItem(
                      context,
                      icon: Icons.notifications_rounded,
                      title: 'notifications'.tr(context),
                      route: AppRoutes.notifications,
                      currentRoute: currentRoute,
                    ),
                    
                    _buildMenuItem(
                      context,
                      icon: Icons.settings_rounded,
                      title: 'settings'.tr(context),
                      route: AppRoutes.settingsRoute,
                      currentRoute: currentRoute,
                    ),
                    
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                      child: Divider(color: Color(0xFFE0E0E0)),
                    ),
                    
                    _buildMenuItem(
                      context,
                      icon: Icons.logout_rounded,
                      title: 'logout'.tr(context),
                      isDanger: true,
                      onTap: () async {
                        final confirm = await showDialog<bool>(
                          context: context,
                          builder: (context) => AlertDialog(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                            title: Row(
                              children: [
                                const Icon(
                                  Icons.logout_rounded,
                                  color: Color(0xFFFF6B6B),
                                ),
                                const SizedBox(width: 10),
                                Text('logout'.tr(context)),
                              ],
                            ),
                            content: Text('logout_confirm'.tr(context)),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context, false),
                                child: Text(
                                  'cancel'.tr(context),
                                  style: const TextStyle(color: Colors.grey),
                                ),
                              ),
                              ElevatedButton(
                                onPressed: () => Navigator.pop(context, true),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFFFF6B6B),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
                                child: Text('logout'.tr(context)),
                              ),
                            ],
                          ),
                        );
                        
                        if (confirm == true) {
                          await authService.logout(socketService);
                          Navigator.pushReplacementNamed(context, AppRoutes.login);
                        }
                      },
                    ),
                  ],
                ),
              ),
            ),
            
            // Footer mejorado
            Container(
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, -5),
                  ),
                ],
              ),
              child: Center(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.terrain,
                      color: Colors.grey[600],
                      size: 16,
                    ),
                    const SizedBox(width: 5),
                    Text(
                      'Trazer v1.0.0',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    String? route,
    String? currentRoute,
    VoidCallback? onTap,
    bool isHighlighted = false,
    bool isDanger = false,
  }) {
    final isSelected = route == currentRoute;
    final primaryColor = const Color(0xFF6B55D1);
    final highlightColor = const Color(0xFFFF6B6B);
    final dangerColor = const Color(0xFFFF4757);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(15),
        gradient: isSelected
            ? LinearGradient(
                colors: [
                  primaryColor.withOpacity(0.1),
                  primaryColor.withOpacity(0.05),
                ],
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
              )
            : null,
        boxShadow: isSelected
            ? [
                BoxShadow(
                  color: primaryColor.withOpacity(0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ]
            : null,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(15),
          onTap: onTap ?? () {
            if (route != null && route != currentRoute) {
              Navigator.pushReplacementNamed(context, route);
            } else {
              Navigator.pop(context);
            }
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: isSelected
                        ? primaryColor
                        : isHighlighted
                            ? highlightColor.withOpacity(0.1)
                            : isDanger
                                ? dangerColor.withOpacity(0.1)
                                : Colors.grey.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    icon,
                    color: isSelected
                        ? Colors.white
                        : isHighlighted
                            ? highlightColor
                            : isDanger
                                ? dangerColor
                                : Colors.grey[700],
                    size: 22,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      color: isSelected
                          ? primaryColor
                          : isDanger
                              ? dangerColor
                              : Colors.grey[800],
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                      fontSize: 16,
                    ),
                  ),
                ),
                if (isSelected)
                  Container(
                    width: 4,
                    height: 24,
                    decoration: BoxDecoration(
                      color: primaryColor,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                if (isHighlighted && !isSelected)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: highlightColor,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.arrow_forward,
                      color: Colors.white,
                      size: 16,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}