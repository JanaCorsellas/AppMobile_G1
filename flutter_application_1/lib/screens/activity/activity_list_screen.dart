import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_application_1/models/activity.dart';
import 'package:flutter_application_1/services/auth_service.dart';
import 'package:flutter_application_1/services/http_service.dart';
import 'package:flutter_application_1/services/activity_service.dart';
import 'package:flutter_application_1/widgets/custom_drawer.dart';
import 'package:flutter_application_1/config/routes.dart';
import 'package:flutter_application_1/screens/activity/activity_detail_screen.dart';

class ActivitiesListScreen extends StatefulWidget {
  const ActivitiesListScreen({Key? key}) : super(key: key);

  @override
  _ActivitiesListScreenState createState() => _ActivitiesListScreenState();
}

class _ActivitiesListScreenState extends State<ActivitiesListScreen> {
  bool _isLoading = true;
  List<Activity> _activities = [];
  String _errorMessage = '';
  
  @override
  void initState() {
    super.initState();
    _loadActivities();
  }
  
  Future<void> _loadActivities() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });
    
    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      final httpService = HttpService(authService);
      final activityService = ActivityService(httpService);
      
      // Si tienes un usuario logueado, carga sus actividades
      if (authService.currentUser != null) {
        final activities = await activityService.getActivitiesByUserId(
          authService.currentUser!.id
        );
        
        setState(() {
          _activities = activities;
          _isLoading = false;
        });
      } else {
        setState(() {
          _errorMessage = 'No hay usuario autenticado';
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error cargando actividades: $e');
      setState(() {
        _errorMessage = 'Error al cargar actividades';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: const CustomDrawer(currentRoute: AppRoutes.activities), // Usaremos una nueva ruta
      appBar: AppBar(
        title: const Text('Mis Actividades'),
        backgroundColor: const Color.fromARGB(255, 21, 95, 51),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadActivities,
            tooltip: 'Actualizar',
          ),
        ],
      ),
      body: _isLoading 
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage.isNotEmpty
              ? _buildErrorView()
              : _activities.isEmpty
                  ? _buildEmptyView()
                  : _buildActivitiesList(),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.pushNamed(context, AppRoutes.activitySelection);
        },
        backgroundColor: const Color.fromARGB(255, 21, 95, 51),
        child: const Icon(Icons.add),
        tooltip: 'Iniciar nueva actividad',
      ),
    );
  }
  
  Widget _buildEmptyView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.directions_run_outlined,
            size: 80,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 20),
          Text(
            'No hay actividades',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'Inicia tu primera actividad con el botón +',
            style: TextStyle(
              color: Colors.grey[500],
            ),
          ),
          const SizedBox(height: 30),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.pushNamed(context, AppRoutes.activitySelection);
            },
            icon: const Icon(Icons.add),
            label: const Text('Nueva actividad'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color.fromARGB(255, 21, 95, 51),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildErrorView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 80,
            color: Colors.red[300],
          ),
          const SizedBox(height: 20),
          Text(
            'Error al cargar actividades',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.red[700],
            ),
          ),
          const SizedBox(height: 10),
          Text(
            _errorMessage,
            style: TextStyle(
              color: Colors.red[500],
            ),
          ),
          const SizedBox(height: 30),
          ElevatedButton.icon(
            onPressed: _loadActivities,
            icon: const Icon(Icons.refresh),
            label: const Text('Reintentar'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildActivitiesList() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _activities.length,
      itemBuilder: (context, index) {
        final activity = _activities[index];
        return _buildActivityCard(activity);
      },
    );
  }
  
  Widget _buildActivityCard(Activity activity) {
    // Define iconos y colores según el tipo de actividad
    IconData activityIcon;
    Color activityColor;
    
    switch (activity.type) {
      case ActivityType.running:
        activityIcon = Icons.directions_run;
        activityColor = Colors.green;
        break;
      case ActivityType.cycling:
        activityIcon = Icons.directions_bike;
        activityColor = Colors.blue;
        break;
      case ActivityType.hiking:
        activityIcon = Icons.terrain;
        activityColor = Colors.orange;
        break;
      case ActivityType.walking:
        activityIcon = Icons.directions_walk;
        activityColor = Colors.purple;
        break;
    }
    
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: () {
          // Navegar a los detalles de la actividad
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ActivityDetailScreen(activity: activity),
            ),
          );
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    backgroundColor: activityColor.withOpacity(0.2),
                    radius: 24,
                    child: Icon(
                      activityIcon,
                      color: activityColor,
                      size: 30,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          activity.name,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${_formatDate(activity.startTime)} • ${activity.formatDuration()}',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        activity.formatDistance(),
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${(activity.averageSpeed * 3.6).toStringAsFixed(1)} km/h',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}