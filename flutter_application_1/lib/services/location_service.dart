import 'dart:async';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_application_1/models/activity_tracking.dart';

class LocationService extends ChangeNotifier {
  StreamSubscription<Position>? _positionStreamSubscription;
  Position? _currentPosition;
  List<LocationPoint> _locationHistory = [];
  bool _isTracking = false;
  bool _isPaused = false;
  
  // Identificadores del tracking actual (opcional)
  String? _trackingId;
  DateTime? _trackingStartTime;
  
  // Para calcular la velocidad
  Position? _lastPosition;
  DateTime? _lastPositionTime;
  
  // Getters
  Position? get currentPosition => _currentPosition;
  List<LocationPoint> get locationHistory => _locationHistory;
  bool get isTracking => _isTracking;
  bool get isPaused => _isPaused;
  String? get trackingId => _trackingId;
  DateTime? get trackingStartTime => _trackingStartTime;

  // Control de precisión
  final LocationSettings _locationSettings = const LocationSettings(
    accuracy: LocationAccuracy.high,
    distanceFilter: 5, // Actualizar cuando el usuario se mueva 5 metros
  );

  Future<bool> _checkPermissions() async {
    bool serviceEnabled;
    LocationPermission permission;

    // Verificar si el servicio de ubicación está habilitado
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      // Los servicios de ubicación no están habilitados
      return false;
    }

    // Verificar permisos de ubicación
    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        // Permisos denegados
        return false;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      // Permisos denegados permanentemente
      return false;
    }

    // Permisos concedidos
    return true;
  }

  // Iniciar el seguimiento de ubicación
  Future<bool> startTracking({String? trackingId, LocationAccuracy accuracy = LocationAccuracy.high}) async {
    if (_isTracking) {
      return true; // Ya está rastreando
    }

    final permissionsGranted = await _checkPermissions();
    if (!permissionsGranted) {
      return false;
    }

    try {
      // Primero intentamos obtener la posición actual antes de iniciar el stream
      try {
        _currentPosition = await Geolocator.getCurrentPosition(
          desiredAccuracy: accuracy,
          timeLimit: const Duration(seconds: 10), // Añadimos un tiempo límite para evitar bloqueos
        );
      } catch (e) {
        print('Error obteniendo posición inicial: $e');
        // Si falla, podemos continuar de todos modos, el stream eventualmente nos dará una posición
      }
      
      // Iniciar el stream de posiciones
      _positionStreamSubscription = Geolocator.getPositionStream(
        locationSettings: _locationSettings,
      ).listen(
        (Position position) {
          _updatePosition(position);
        },
        onError: (e) {
          print('Error en stream de posición: $e');
          // No detenemos el tracking por errores ocasionales
        },
      );

      // Marcar como rastreando
      _isTracking = true;
      _isPaused = false;
      _trackingId = trackingId;
      _trackingStartTime = DateTime.now();
      _locationHistory = [];

      if (_currentPosition != null) {
        _addToHistory(_currentPosition!);
      }

      notifyListeners();
      return true;
    } catch (e) {
      print('Error iniciando seguimiento de ubicación: $e');
      return false;
    }
  }

  // Pausar el seguimiento
  void pauseTracking() {
    if (!_isTracking || _isPaused) return;
    
    _positionStreamSubscription?.pause();
    _isPaused = true;
    notifyListeners();
  }

  // Reanudar el seguimiento
  void resumeTracking() {
    if (!_isTracking || !_isPaused) return;
    
    _positionStreamSubscription?.resume();
    _isPaused = false;
    notifyListeners();
  }

  // Detener el seguimiento
  void stopTracking() {
    _positionStreamSubscription?.cancel();
    _positionStreamSubscription = null;
    _isTracking = false;
    _isPaused = false;
    _trackingId = null;
    _trackingStartTime = null;
    notifyListeners();
  }

  // Limpiar los datos de seguimiento
  void clearTracking() {
    stopTracking();
    _locationHistory = [];
    _currentPosition = null;
    _lastPosition = null;
    _lastPositionTime = null;
    notifyListeners();
  }

  // Actualizar la posición actual y mantener historial
  void _updatePosition(Position position) {
    _currentPosition = position;
    
    // Calcular velocidad si tenemos una posición anterior
    double? speed;
    if (_lastPosition != null && _lastPositionTime != null) {
      final distance = Geolocator.distanceBetween(
        _lastPosition!.latitude,
        _lastPosition!.longitude,
        position.latitude,
        position.longitude,
      );
      
      final timeDiff = DateTime.now().difference(_lastPositionTime!).inMilliseconds / 1000;
      
      if (timeDiff > 0) {
        speed = distance / timeDiff; // metros por segundo
      }
    }
    
    // Usar velocidad calculada o la del GPS si está disponible
    final finalSpeed = speed ?? position.speed;
    
    _addToHistory(position, speed: finalSpeed);
    
    // Almacenar para el próximo cálculo
    _lastPosition = position;
    _lastPositionTime = DateTime.now();
    
    notifyListeners();
  }

  // Añadir posición al historial
  void _addToHistory(Position position, {double? speed}) {
    if (!_isTracking || _isPaused) return;
    
    _locationHistory.add(
      LocationPoint(
        latitude: position.latitude,
        longitude: position.longitude,
        altitude: position.altitude,
        timestamp: DateTime.now(),
        speed: speed ?? position.speed,
      ),
    );
  }

  // Obtener la distancia total del tracking en metros
  double getTotalDistance() {
    if (_locationHistory.length < 2) return 0;
    
    double totalDistance = 0;
    for (int i = 0; i < _locationHistory.length - 1; i++) {
      totalDistance += Geolocator.distanceBetween(
        _locationHistory[i].latitude,
        _locationHistory[i].longitude,
        _locationHistory[i + 1].latitude,
        _locationHistory[i + 1].longitude,
      );
    }
    
    return totalDistance;
  }

  // Obtener la velocidad actual en metros/segundo
  double getCurrentSpeed() {
    return _currentPosition?.speed ?? 0;
  }

  // Obtener la elevación actual
  double getCurrentAltitude() {
    return _currentPosition?.altitude ?? 0;
  }

  // Calcular la ganancia de elevación (solo subidas)
  double getElevationGain() {
    if (_locationHistory.length < 2) return 0;
    
    double gain = 0;
    for (int i = 0; i < _locationHistory.length - 1; i++) {
      final diff = (_locationHistory[i + 1].altitude ?? 0) - (_locationHistory[i].altitude ?? 0);
      if (diff > 0) gain += diff;
    }
    
    return gain;
  }

  @override
  void dispose() {
    _positionStreamSubscription?.cancel();
    super.dispose();
  }
}