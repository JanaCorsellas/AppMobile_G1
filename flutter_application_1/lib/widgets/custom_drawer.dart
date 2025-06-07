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
      child: Column(
        children: [
          // Header con fondo e información del usuario
          Container(
            height: 200,
            decoration: const BoxDecoration(
              color: Color.fromARGB(255, 21, 95, 51),
              image: DecorationImage(
                image: AssetImage('assets/images/background2.png'),
                fit: BoxFit.cover,
                colorFilter: ColorFilter.mode(
                  Color.fromARGB(180, 21, 95, 51),
                  BlendMode.srcOver,
                ),
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  // Avatar del usuario con borde
                  Row(
                    children: [
                      Container(
                        width: 60,
                        height: 60,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                          color: Colors.white.withOpacity(0.2),
                        ),
                        child: ClipOval(
                          child: user?.profilePicture != null && user!.profilePicture!.isNotEmpty
                              ? Image.network(
                                  user.profilePicture!,
                                  fit: BoxFit.cover,
                                  errorBuilder: (ctx, obj, stack) => const Icon(
                                    Icons.person,
                                    color: Colors.white,
                                    size: 40,
                                  ),
                                )
                              : const Icon(
                                  Icons.person,
                                  color: Colors.white,
                                  size: 40,
                                ),
                        ),
                      ),
                      const SizedBox(width: 15),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            user?.username ?? 'user'.tr(context),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            user?.email ?? '',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.9),
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 5),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              '${('level').tr(context)} ${user?.level ?? 1}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 15),
                  
                  // Logo y nombre de la app
                  const Row(
                    children: [
                      Icon(Icons.terrain, color: Colors.white, size: 18),
                      SizedBox(width: 8),
                      Text(
                        'Trazer',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            child: Container(
              color: Colors.white,
              child: ListView(
                padding: EdgeInsets.zero,
                children: [
                  _buildMenuItem(
                    context,
                    icon: Icons.home_outlined,
                    title: 'home'.tr(context),
                    route: AppRoutes.userHome,
                    currentRoute: currentRoute,
                  ),
              
                  _buildMenuItem(
                    context,
                    icon: Icons.person_outline,
                    title: 'profile'.tr(context),
                    route: AppRoutes.userProfile,
                    currentRoute: currentRoute,
                  ),
                  _buildMenuItem(
                    context,
                    icon: Icons.history,
                    title: 'my_activities'.tr(context),
                    route: AppRoutes.activities,
                    currentRoute: currentRoute,
                  ),
                  _buildMenuItem(
                    context,
                    icon: Icons.directions_run,
                    title: 'start_activity'.tr(context),
                    route: AppRoutes.activitySelection,
                    currentRoute: currentRoute,
                  ),
                 /* _buildMenuItem(
                    context,
                    icon: Icons.music_note_outlined,
                    title: 'my_songs'.tr(context),
                    route: 'songs',
                    currentRoute: currentRoute,
                    onTap: () {
                      Navigator.pop(context); // Cerrar drawer
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Pantalla de playlist en desarrollo'))
                      );
                    },
                  ),*/
                  _buildMenuItem(
                    context,
                    icon: Icons.emoji_events_outlined,
                    title: 'achievements'.tr(context),
                    route: AppRoutes.achievements,
                    currentRoute: currentRoute,
                  ),
                  _buildMenuItem(
                    context,
                    icon: Icons.chat_bubble_outline,
                    title: 'chat'.tr(context),
                    route: AppRoutes.chatList,
                    currentRoute: currentRoute,
                  ),
                  _buildMenuItem(
                    context,
                    icon: Icons.notifications_none_outlined,
                    title: 'notifications'.tr(context),
                    route: AppRoutes.notifications,
                    currentRoute: currentRoute,
                  ),
                  _buildMenuItem(
                    context,
                    icon: Icons.settings,
                    title: 'settings'.tr(context),
                    route: AppRoutes.settingsRoute,
                    currentRoute: currentRoute,
                  ),
                  const Divider(),
                  _buildMenuItem(
                    context,
                    icon: Icons.logout,
                    title: 'logout'.tr(context),
                    onTap: () async {
                      final confirm = await showDialog<bool>(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: Text('logout'.tr(context)),
                          content: Text('logout_confirm'.tr(context)),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context, false),
                              child: Text('cancel'.tr(context)),
                            ),
                            TextButton(
                              onPressed: () => Navigator.pop(context, true),
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
          
          // Footer con versión
          Container(
            padding: const EdgeInsets.symmetric(vertical: 8),
            color: Colors.grey[100],
            child: Center(
              child: Text(
                'v1.0.0',
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 12,
                ),
              ),
            ),
          ),
        ],
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
  }) {
    final isSelected = route == currentRoute;
    final primaryColor = const Color.fromARGB(255, 21, 95, 51);

    return ListTile(
      leading: Icon(
        icon,
        color: isSelected ? primaryColor : Colors.grey[700],
        size: 24,
      ),
      title: Text(
        title,
        style: TextStyle(
          color: isSelected ? primaryColor : Colors.grey[800],
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          fontSize: 16,
        ),
      ),
      onTap: onTap ?? () {
        if (route != null && route != currentRoute) {
          Navigator.pushReplacementNamed(context, route);
        } else {
          Navigator.pop(context);
        }
      },
      tileColor: isSelected ? Colors.green.withOpacity(0.1) : null,
      shape: isSelected
          ? const RoundedRectangleBorder(
              borderRadius: BorderRadius.only(
                topRight: Radius.circular(30),
                bottomRight: Radius.circular(30),
              ),
            )
          : null,
      contentPadding: const EdgeInsets.symmetric(vertical: 2, horizontal: 16),
      dense: true,
    );
  }
}