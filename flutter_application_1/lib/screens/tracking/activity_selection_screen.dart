import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_application_1/screens/tracking/tracking_screen.dart';
import 'package:flutter_application_1/utils/permission_handler.dart';
import 'package:flutter_application_1/providers/activity_provider_tracking.dart';

class ActivitySelectionScreen extends StatefulWidget {
  const ActivitySelectionScreen({Key? key}) : super(key: key);

  @override
  State<ActivitySelectionScreen> createState() => _ActivitySelectionScreenState();
}

class _ActivitySelectionScreenState extends State<ActivitySelectionScreen> {
  bool _isChecking = false;

  @override
  void initState() {
    super.initState();
    _checkActiveTrackings();
  }

  Future<void> _checkActiveTrackings() async {
    if (_isChecking) return;

    setState(() {
      _isChecking = true;
    });

    try {
      final trackingProvider = Provider.of<ActivityTrackingProvider>(context, listen: false);
      await trackingProvider.checkActiveTrackings();

      if (trackingProvider.currentTracking != null && mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => TrackingScreen(
              activityType: trackingProvider.currentTracking!.activityType,
              resuming: true,
            ),
          ),
        );
      }
    } catch (e) {
      print('Error checking active trackings: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isChecking = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Iniciar Actividad'),
      ),
      body: _isChecking
          ? const Center(child: CircularProgressIndicator())
          : Consumer<ActivityTrackingProvider>(
              builder: (context, trackingProvider, child) {
                if (trackingProvider.isLoading) {
                  return const Center(child: CircularProgressIndicator());
                }

                return Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Selecciona el tipo de actividad',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Expanded(
                        child: GridView.count(
                          crossAxisCount: 2,
                          crossAxisSpacing: 16.0,
                          mainAxisSpacing: 16.0,
                          children: [
                            _buildActivityCard(
                              context,
                              'running',
                              'Correr',
                              Icons.directions_run,
                              Colors.orange,
                            ),
                            _buildActivityCard(
                              context,
                              'cycling',
                              'Ciclismo',
                              Icons.directions_bike,
                              Colors.blue,
                            ),
                            _buildActivityCard(
                              context,
                              'hiking',
                              'Senderismo',
                              Icons.terrain,
                              Colors.green,
                            ),
                            _buildActivityCard(
                              context,
                              'walking',
                              'Caminar',
                              Icons.directions_walk,
                              Colors.purple,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
    );
  }

  Widget _buildActivityCard(
    BuildContext context,
    String activityType,
    String title,
    IconData icon,
    Color color,
  ) {
    return GestureDetector(
      onTap: () => _checkPermissionsAndNavigate(context, activityType),
      child: Card(
        elevation: 4.0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16.0),
        ),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16.0),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                color.withOpacity(0.7),
                color,
              ],
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 48.0,
                color: Colors.white,
              ),
              const SizedBox(height: 8.0),
              Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18.0,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _checkPermissionsAndNavigate(BuildContext context, String activityType) async {
    final trackingProvider = Provider.of<ActivityTrackingProvider>(context, listen: false);
    
    // Verificar si hay una actividad activa
    await trackingProvider.checkActiveTrackings();

    if (!mounted) return;

    if (trackingProvider.currentTracking != null) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => TrackingScreen(
            activityType: trackingProvider.currentTracking!.activityType,
            resuming: true,
          ),
        ),
      );
      return;
    }

    // Si no hay actividad activa, verificar permisos y continuar
    final hasPermission = await PermissionHandler.checkLocationPermission(context);
    
    if (!mounted) return;
    
    if (hasPermission) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => TrackingScreen(
            activityType: activityType,
            resuming: false,
          ),
        ),
      );
    }
  }
}