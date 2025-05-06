import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_application_1/models/activity_tracking.dart';
import 'package:flutter_application_1/services/activity_tracking_service.dart';
import 'package:flutter_application_1/services/location_service.dart';
import 'package:flutter_application_1/services/auth_service.dart';
import 'package:geolocator/geolocator.dart';

class ActivityTrackingProvider extends ChangeNotifier {
  final ActivityTrackingService _trackingService;
  final LocationService _locationService;
  final AuthService _authService;
  
  ActivityTracking? _currentTracking;
  bool _isLoading = false;
  String _error = '';
  Timer? _updateTimer;
  Timer? _durationTimer; // Timer para actualizar la duración
  
  ActivityTracking? get currentTracking => _currentTracking;
  bool get isTracking => _locationService.isTracking;
  bool get isPaused => _locationService.isPaused;
  bool get isLoading => _isLoading;
  String get error => _error;
  
  ActivityTrackingProvider(
    this._trackingService, 
    this._locationService,
    this._authService,
  ) {
    _locationService.addListener(_handleLocationUpdate);
  }

  void _handleLocationUpdate() {
    if (_currentTracking != null && 
        _locationService.isTracking && 
        !_locationService.isPaused && 
        _locationService.currentPosition != null) {
      
      _currentTracking!.currentDistance = _locationService.getTotalDistance();
      _currentTracking!.elevationGain = _locationService.getElevationGain();
      
      // La duración ahora se actualiza con el _durationTimer
      
      _currentTracking!.currentSpeed = _locationService.getCurrentSpeed();
      
      if (_currentTracking!.currentSpeed > _currentTracking!.maxSpeed) {
        _currentTracking!.maxSpeed = _currentTracking!.currentSpeed;
      }
      
      if (_currentTracking!.currentDuration > 0) {
        _currentTracking!.averageSpeed = 
            _currentTracking!.currentDistance / _currentTracking!.currentDuration;
      }
      
      notifyListeners();
    }
  }

 Future<bool> startTracking(String activityType) async {
  // Verificar primero si hay actividades activas
  await checkActiveTrackings();
  
  if (_currentTracking != null) {
    _error = 'Ya hay una actividad activa';
    notifyListeners();
    return false;
  }

  if (_locationService.isTracking) {
    return false;
  }
  
  _isLoading = true;
  _error = '';
  notifyListeners();
  
  try {
    final userId = _authService.currentUser?.id;
    if (userId == null || userId.isEmpty) {
      _error = 'No hay usuario autenticado';
      _isLoading = false;
      notifyListeners();
      return false;
    }
    
    final tracking = await _trackingService.startTracking(userId, activityType);
    _currentTracking = tracking;
    
    final success = await _locationService.startTracking(trackingId: tracking.id);
    
    if (!success) {
      await _trackingService.discardTracking(tracking.id);
      _currentTracking = null;
      _error = 'No se pudo iniciar el seguimiento de ubicación';
      _isLoading = false;
      notifyListeners();
      return false;
    }
    
    _setupUpdateTimer();
    _setupDurationTimer(); // Configura el timer para la duración
    
    _isLoading = false;
    notifyListeners();
    return true;
  } catch (e) {
    _error = 'Error iniciando tracking: $e';
    _isLoading = false;
    notifyListeners();
    return false;
  }
}

  // Nuevo método para configurar el timer de duración
  void _setupDurationTimer() {
    _durationTimer?.cancel();
    _durationTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_currentTracking != null && !_currentTracking!.isPaused) {
        final now = DateTime.now();
        int durationMs = now.difference(_currentTracking!.startTime).inMilliseconds;
        durationMs -= _currentTracking!.totalPausedTime;
        _currentTracking!.currentDuration = (durationMs / 1000).round();
        notifyListeners();
      }
    });
  }

  Future<bool> pauseTracking() async {
    if (_currentTracking == null || !_locationService.isTracking || _locationService.isPaused) {
      return false;
    }
    
    _isLoading = true;
    notifyListeners();
    
    try {
      _locationService.pauseTracking();
      
      final updatedTracking = await _trackingService.pauseTracking(_currentTracking!.id);
      _currentTracking = updatedTracking;
      
      _updateTimer?.cancel();
      _updateTimer = null;
      // No cancela _durationTimer, solo se detendrá la actualización por la condición de isPaused
      
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = 'Error pausando tracking: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> resumeTracking() async {
    if (_currentTracking == null || !_locationService.isTracking || !_locationService.isPaused) {
      return false;
    }
    
    _isLoading = true;
    notifyListeners();
    
    try {
      _locationService.resumeTracking();
      
      final updatedTracking = await _trackingService.resumeTracking(_currentTracking!.id);
      _currentTracking = updatedTracking;
      
      _setupUpdateTimer();
      // No es necesario configurar _durationTimer porque ya debe estar ejecutándose
      
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = 'Error reanudando tracking: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<Map<String, dynamic>> finishTracking({String? name}) async {
    if (_currentTracking == null) {
      throw Exception('No hay tracking activo');
    }
    
    _isLoading = true;
    notifyListeners();
    
    try {
      final result = await _trackingService.finishTracking(_currentTracking!.id, name: name);
      
      _locationService.stopTracking();
      
      _updateTimer?.cancel();
      _updateTimer = null;
      
      _durationTimer?.cancel(); // Detener el timer de duración
      _durationTimer = null;
      
      _currentTracking = null;
      _isLoading = false;
      notifyListeners();
      
      return result;
    } catch (e) {
      _error = 'Error finalizando tracking: $e';
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }

  Future<bool> discardTracking() async {
    if (_currentTracking == null) {
      return false;
    }
    
    _isLoading = true;
    notifyListeners();
    
    try {
      final success = await _trackingService.discardTracking(_currentTracking!.id);
      
      _locationService.stopTracking();
      
      _updateTimer?.cancel();
      _updateTimer = null;
      
      _durationTimer?.cancel(); // Detener el timer de duración
      _durationTimer = null;
      
      _currentTracking = null;
      _isLoading = false;
      notifyListeners();
      
      return success;
    } catch (e) {
      _error = 'Error descartando tracking: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> checkActiveTrackings() async {
  final userId = _authService.currentUser?.id;
  if (userId == null || userId.isEmpty) return;
  
  try {
    _isLoading = true;
    notifyListeners();
    
    final activeTrackings = await _trackingService.getActiveTrackings(userId);
    
    if (activeTrackings.isNotEmpty) {
      _currentTracking = activeTrackings[0];
      
      if (!_currentTracking!.isPaused) {
        await _locationService.startTracking(trackingId: _currentTracking!.id);
        _setupUpdateTimer();
        _setupDurationTimer(); // Configurar el timer de duración al reanudar
      }
    } else {
      _currentTracking = null;
    }
  } catch (e) {
    print('Error verificando trackings activos: $e');
    _currentTracking = null;
  } finally {
    _isLoading = false;
    notifyListeners();
  }
}

  Future<void> _sendLocationUpdate() async {
    if (_currentTracking == null || 
        !_locationService.isTracking || 
        _locationService.isPaused || 
        _locationService.currentPosition == null) {
      return;
    }
    
    try {
      final position = _locationService.currentPosition!;
      
      await _trackingService.updateLocation(
        _currentTracking!.id,
        position.latitude,
        position.longitude,
        altitude: position.altitude,
        speed: position.speed,
      );
    } catch (e) {
      print('Error enviando actualización de ubicación: $e');
    }
  }

  void _setupUpdateTimer() {
    _updateTimer?.cancel();
    _updateTimer = Timer.periodic(const Duration(seconds: 10), (timer) {
      _sendLocationUpdate();
    });
  }

  @override
  void dispose() {
    _locationService.removeListener(_handleLocationUpdate);
    _updateTimer?.cancel();
    _durationTimer?.cancel(); // Limpiar el timer de duración
    super.dispose();
  }
}