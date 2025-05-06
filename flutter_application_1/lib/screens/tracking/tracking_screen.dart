import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:flutter_application_1/providers/activity_provider_tracking.dart';
import 'package:flutter_application_1/services/location_service.dart';
import 'package:flutter_application_1/config/routes.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_application_1/models/activity_tracking.dart';
import 'package:flutter_application_1/utils/permission_handler.dart';

class TrackingScreen extends StatefulWidget {
  final String activityType;
  final bool resuming;

  const TrackingScreen({
    Key? key,
    required this.activityType,
    this.resuming = false,
  }) : super(key: key);

  @override
  State<TrackingScreen> createState() => TrackingScreenState();
}

class TrackingScreenState extends State<TrackingScreen> with WidgetsBindingObserver {
  final MapController _mapController = MapController();
  final TextEditingController _activityNameController = TextEditingController();
  bool _mapFollowing = true;
  bool _showFinishDialog = false;
  bool _isInitialized = false;
  bool _isMapReady = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    
    if (!widget.resuming) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _checkPermissionsAndStartTracking();
      });
    } else {
      _isInitialized = true;
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _activityNameController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (!_isInitialized) return;
    
    final trackingProvider = Provider.of<ActivityTrackingProvider>(context, listen: false);
    
    if (state == AppLifecycleState.paused) {
      if (trackingProvider.isTracking && !trackingProvider.isPaused) {
        trackingProvider.pauseTracking();
      }
    }
  }

  Future<void> _checkPermissionsAndStartTracking() async {
    final hasPermission = await PermissionHandler.checkLocationPermission(context);
    
    if (!hasPermission) {
      if (mounted) {
        Navigator.pop(context);
      }
      return;
    }
    
    if (mounted) {
      await _startTracking();
    }
  }

  Future<void> _startTracking() async {
    final trackingProvider = Provider.of<ActivityTrackingProvider>(context, listen: false);
    
    if (!trackingProvider.isTracking) {
      final success = await trackingProvider.startTracking(widget.activityType);
      
      if (!success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(trackingProvider.error)),
        );
        Navigator.pop(context);
        return;
      }
    }
    
    if (mounted) {
      setState(() {
        _isInitialized = true;
      });
    }
  }

  void _showFinishConfirmDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Finalizar actividad'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('¿Estás seguro de que quieres finalizar esta actividad?'),
            const SizedBox(height: 16),
            TextField(
              controller: _activityNameController,
              decoration: const InputDecoration(
                labelText: 'Nombre de la actividad (opcional)',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _finishTracking();
            },
            child: const Text('Finalizar'),
          ),
        ],
      ),
    );
  }

  Future<void> _finishTracking() async {
    final trackingProvider = Provider.of<ActivityTrackingProvider>(context, listen: false);
    
    try {
      final name = _activityNameController.text.trim().isNotEmpty 
          ? _activityNameController.text.trim() 
          : null;
          
      setState(() {
        _showFinishDialog = true;
      });
      
      final result = await trackingProvider.finishTracking(name: name);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Actividad finalizada con éxito')),
        );
        
        Navigator.pushReplacementNamed(
          context, 
          AppRoutes.userHome, 
          arguments: {'activityId': result['activityId']},
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _showFinishDialog = false;
        });
      }
    }
  }

  Future<void> _discardTracking() async {
    final trackingProvider = Provider.of<ActivityTrackingProvider>(context, listen: false);
    
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Descartar actividad'),
        content: const Text('¿Estás seguro de que quieres descartar esta actividad? Los datos no se guardarán.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Descartar'),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
          ),
        ],
      ),
    );
    
    if (confirm == true) {
      await trackingProvider.discardTracking();
      
      if (mounted) {
        Navigator.pop(context);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer2<ActivityTrackingProvider, LocationService>(
      builder: (context, trackingProvider, locationService, child) {
        final tracking = trackingProvider.currentTracking;
        final currentPosition = locationService.currentPosition;
        final locationHistory = locationService.locationHistory;
        
        // Solo intentamos mover el mapa si está listo y tenemos una posición
        if (_isMapReady && _mapFollowing && currentPosition != null) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            try {
              _mapController.move(
                LatLng(currentPosition.latitude, currentPosition.longitude),
                17,
              );
            } catch (e) {
              // Ignoramos errores durante el movimiento del mapa
            }
          });
        }
        
        return Scaffold(
          appBar: AppBar(
            title: Text(
              tracking?.activityType.toUpperCase() ?? widget.activityType.toUpperCase(),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.delete),
                onPressed: _isInitialized && locationService.isTracking ? _discardTracking : null,
                tooltip: 'Descartar actividad',
              ),
            ],
          ),
          body: Stack(
            children: [
              _buildMap(currentPosition, locationHistory),
              
              Positioned(
                bottom: 100,
                left: 0,
                right: 0,
                child: _buildStatsPanel(tracking),
              ),
              
              Positioned(
                bottom: 16,
                left: 0,
                right: 0,
                child: _buildTrackingControls(trackingProvider),
              ),
              
              if (!_isInitialized || trackingProvider.isLoading)
                Container(
                  color: Colors.black.withOpacity(0.3),
                  child: const Center(
                    child: CircularProgressIndicator(),
                  ),
                ),
              
              if (_showFinishDialog)
                Container(
                  color: Colors.black.withOpacity(0.3),
                  child: const Center(
                    child: Card(
                      child: Padding(
                        padding: EdgeInsets.all(16.0),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            CircularProgressIndicator(),
                            SizedBox(height: 16),
                            Text('Finalizando actividad...'),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildMap(Position? currentPosition, List<LocationPoint> locationHistory) {
    return FlutterMap(
      mapController: _mapController,
      options: MapOptions(
        center: currentPosition != null 
            ? LatLng(currentPosition.latitude, currentPosition.longitude)
            : LatLng(41.3851, 2.1734),
        zoom: 17,
        onTap: (_, __) {
          setState(() {
            _mapFollowing = false;
          });
        },
        onMapReady: () {
          setState(() {
            _isMapReady = true;
          });
        },
      ),
      children: [
        TileLayer(
          urlTemplate: 'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
          subdomains: const ['a', 'b', 'c'],
        ),
        if (locationHistory.length > 1)
          PolylineLayer(
            polylines: [
              Polyline(
                points: locationHistory
                    .map((p) => LatLng(p.latitude, p.longitude))
                    .toList(),
                color: Colors.blue,
                strokeWidth: 4.0,
              ),
            ],
          ),
        if (currentPosition != null)
          MarkerLayer(
            markers: [
              Marker(
                point: LatLng(currentPosition.latitude, currentPosition.longitude),
                width: 20,
                height: 20,
                builder: (context) => Container(
                  decoration: BoxDecoration(
                    color: Colors.blue,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                ),
              ),
            ],
          ),
      ],
    );
  }

  Widget _buildStatsPanel(ActivityTracking? activityTracking) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildStatItem(
                'Distancia',
                activityTracking?.formattedDistance ?? '0.00 km',
                Icons.straighten,
              ),
              _buildStatItem(
                'Tiempo',
                activityTracking?.formattedDuration ?? '00:00',
                Icons.timer,
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildStatItem(
                'Ritmo',
                activityTracking?.formattedPace ?? '--:-- min/km',
                Icons.speed,
              ),
              _buildStatItem(
                'Elevación',
                activityTracking?.formattedElevationGain ?? '0 m',
                Icons.trending_up,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon) {
    return Expanded(
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 16, color: Colors.grey),
              const SizedBox(width: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTrackingControls(ActivityTrackingProvider trackingProvider) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          FloatingActionButton(
            heroTag: 'center_map',
            backgroundColor: _mapFollowing ? Colors.blue : Colors.grey,
            mini: true,
            onPressed: () {
              setState(() {
                _mapFollowing = true;
              });
            },
            child: const Icon(Icons.my_location),
          ),
          
          FloatingActionButton(
            heroTag: 'pause_resume',
            backgroundColor: Colors.amber,
            onPressed: _isInitialized && !trackingProvider.isLoading
                ? trackingProvider.isPaused
                    ? () => trackingProvider.resumeTracking()
                    : () => trackingProvider.pauseTracking()
                : null,
            child: Icon(
              trackingProvider.isPaused ? Icons.play_arrow : Icons.pause,
            ),
          ),
          
          FloatingActionButton(
            heroTag: 'finish',
            backgroundColor: Colors.green,
            onPressed: _isInitialized && !trackingProvider.isLoading
                ? _showFinishConfirmDialog
                : null,
            child: const Icon(Icons.stop),
          ),
        ],
      ),
    );
 
  }
}