import 'dart:convert';
import 'package:flutter_application_1/config/api_constants.dart';
import 'package:flutter_application_1/models/activity_tracking.dart';
import 'package:flutter_application_1/services/http_service.dart';

class ActivityTrackingService {
  final HttpService _httpService;
  
  ActivityTrackingService(this._httpService);

  // Iniciar una nueva actividad de tracking
  Future<ActivityTracking> startTracking(String userId, String activityType) async {
    try {
      final response = await _httpService.post(
        '${ApiConstants.baseUrl}/api/activity-tracking/start',
        body: {
          'userId': userId,
          'activityType': activityType,
        },
      );

      final data = await _httpService.parseJsonResponse(response);
      
      if (data != null && data['tracking'] != null) {
        // El backend devuelve solo información básica, así que hacemos una petición adicional para obtener todos los datos
        return await getTrackingById(data['tracking']['id']);
      }
      
      throw Exception('Error iniciando actividad de tracking: Datos incompletos');
    } catch (e) {
      print('Error iniciando actividad de tracking: $e');
      rethrow;
    }
  }

  // Actualizar la ubicación en un tracking
  Future<ActivityTracking> updateLocation(
    String trackingId, 
    double latitude, 
    double longitude, 
    {double? altitude, double? speed}
  ) async {
    try {
      final response = await _httpService.post(
        '${ApiConstants.baseUrl}/api/activity-tracking/$trackingId/location',
        body: {
          'latitude': latitude,
          'longitude': longitude,
          if (altitude != null) 'altitude': altitude,
          if (speed != null) 'speed': speed,
        },
      );

      await _httpService.parseJsonResponse(response);
      
      // Obtenemos los datos actualizados
      return await getTrackingById(trackingId);
    } catch (e) {
      print('Error actualizando ubicación: $e');
      rethrow;
    }
  }

  // Pausar un tracking
  Future<ActivityTracking> pauseTracking(String trackingId) async {
    try {
      final response = await _httpService.post(
        '${ApiConstants.baseUrl}/api/activity-tracking/$trackingId/pause',
        body: {},
      );

      await _httpService.parseJsonResponse(response);
      
      // Actualizar tracking completo
      return await getTrackingById(trackingId);
    } catch (e) {
      print('Error pausando tracking: $e');
      rethrow;
    }
  }

  // Reanudar un tracking
  Future<ActivityTracking> resumeTracking(String trackingId) async {
    try {
      final response = await _httpService.post(
        '${ApiConstants.baseUrl}/api/activity-tracking/$trackingId/resume',
        body: {},
      );

      await _httpService.parseJsonResponse(response);
      
      // Actualizar tracking completo
      return await getTrackingById(trackingId);
    } catch (e) {
      print('Error reanudando tracking: $e');
      rethrow;
    }
  }

  // Finalizar un tracking
  Future<Map<String, dynamic>> finishTracking(String trackingId, {String? name}) async {
    try {
      // Agregar un pequeño retraso para asegurar que todas las peticiones anteriores están completas
      await Future.delayed(const Duration(milliseconds: 500));
      
      final response = await _httpService.post(
        '${ApiConstants.baseUrl}/api/activity-tracking/$trackingId/finish',
        body: name != null ? {'name': name} : {},
      );

      final data = await _httpService.parseJsonResponse(response);
      
      return {
        'trackingId': data['tracking']['id'] ?? trackingId,
        'activityId': data['activity']?['id'] ?? '',
        'name': data['activity']?['name'] ?? '',
      };
    } catch (e) {
      print('Error finalizando tracking: $e');
      rethrow;
    }
  }

  // Descartar un tracking
  Future<bool> discardTracking(String trackingId) async {
    try {
      final response = await _httpService.delete(
        '${ApiConstants.baseUrl}/api/activity-tracking/$trackingId/discard',
      );

      return response.statusCode >= 200 && response.statusCode < 300;
    } catch (e) {
      print('Error descartando tracking: $e');
      return false;
    }
  }

  // Obtener tracking por ID
  Future<ActivityTracking> getTrackingById(String trackingId) async {
    try {
      final response = await _httpService.get(
        '${ApiConstants.baseUrl}/api/activity-tracking/$trackingId',
      );

      final data = await _httpService.parseJsonResponse(response);
      
      // Verificar si los datos son válidos
      if (data == null) {
        throw Exception('No se recibieron datos del servidor');
      }
      
      // Intentar manejar diferentes formatos de datos
      if (data is! Map<String, dynamic>) {
        if (data is String) {
          // Intentar parsear como JSON si es string
          try {
            return ActivityTracking.fromJson(json.decode(data));
          } catch (_) {
            throw Exception('Formato de datos no válido: $data');
          }
        }
        
        throw Exception('Formato de datos no válido: ${data.runtimeType}');
      }
      
      return ActivityTracking.fromJson(data);
    } catch (e) {
      print('Error obteniendo tracking: $e');
      rethrow;
    }
  }

  // Obtener trackings activos de un usuario
  Future<List<ActivityTracking>> getActiveTrackings(String userId) async {
    try {
      final response = await _httpService.get(
        '${ApiConstants.baseUrl}/api/activity-tracking/user/$userId/active',
      );

      final data = await _httpService.parseJsonResponse(response);
      
      List<ActivityTracking> trackings = [];
      
      if (data != null) {
        if (data['trackings'] != null && data['trackings'] is List) {
          for (var tracking in data['trackings']) {
            try {
              trackings.add(ActivityTracking.fromJson(tracking));
            } catch (e) {
              print('Error al parsear tracking: $e');
            }
          }
        } else if (data is List) {
          // Si la respuesta ya es una lista
          for (var tracking in data) {
            try {
              trackings.add(ActivityTracking.fromJson(tracking));
            } catch (e) {
              print('Error al parsear tracking: $e');
            }
          }
        }
      }
      
      return trackings;
    } catch (e) {
      print('Error obteniendo trackings activos: $e');
      return [];
    }
  }
}