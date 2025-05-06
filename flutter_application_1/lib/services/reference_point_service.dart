import 'dart:convert';
import 'package:flutter_application_1/config/api_constants.dart';
import 'package:flutter_application_1/services/http_service.dart';
import 'package:latlong2/latlong.dart';

class ReferencePointService {
  final HttpService _httpService;
  
  // Cache para puntos de referencia
  final Map<String, dynamic> _pointsCache = {};

  ReferencePointService(this._httpService);

  // Extraer el ID del punto de referencia (podría ser un objeto o un string)
  String _extractReferencePointId(dynamic referencePoint) {
    if (referencePoint is String) {
      return referencePoint;
    } else if (referencePoint is Map<String, dynamic>) {
      // Si es un objeto, extraer el ID
      return referencePoint['_id']?.toString() ?? 
             referencePoint['id']?.toString() ?? '';
    } else {
      // Si no podemos extraer un ID, devolvemos cadena vacía
      return '';
    }
  }

  // Obtener un punto de referencia por ID
  Future<Map<String, dynamic>> getReferencePointById(String id) async {
    // Primero extraemos el ID limpio
    final pointId = _extractReferencePointId(id);
    
    if (pointId.isEmpty) {
      print('ID de punto de referencia inválido: $id');
      throw Exception('ID de punto de referencia inválido');
    }
    
    // Comprobar si ya tenemos el punto en caché
    if (_pointsCache.containsKey(pointId)) {
      return _pointsCache[pointId];
    }

    try {
      final response = await _httpService.get('${ApiConstants.baseUrl}/api/referencePoints/$pointId');
      final data = await _httpService.parseJsonResponse(response);
      
      // Guardar en caché
      _pointsCache[pointId] = data;
      
      return data;
    } catch (e) {
      print('Error obteniendo punto de referencia $pointId: $e');
      throw Exception('No se pudo cargar el punto de referencia');
    }
  }

  // Obtener múltiples puntos de referencia por sus IDs
  Future<List<Map<String, dynamic>>> getReferencePointsByIds(List<dynamic> ids) async {
    final results = <Map<String, dynamic>>[];
    
    for (var id in ids) {
      try {
        final pointId = _extractReferencePointId(id);
        if (pointId.isEmpty) continue;
        
        final point = await getReferencePointById(pointId);
        results.add(point);
      } catch (e) {
        print('Error obteniendo punto $id: $e');
        // Continuamos con el siguiente punto
      }
    }
    
    return results;
  }

  // Convertir puntos de referencia a coordenadas LatLng para el mapa
  List<LatLng> convertToLatLng(List<Map<String, dynamic>> referencePoints) {
    return referencePoints.map((point) {
      return LatLng(
        point['latitude'] ?? 0,
        point['longitude'] ?? 0,
      );
    }).toList();
  }

  // Obtener LatLng directamente para una lista de IDs de puntos de referencia
  Future<List<LatLng>> getRoutePoints(List<dynamic> routeIds) async {
    try {
      final points = await getReferencePointsByIds(routeIds);
      return convertToLatLng(points);
    } catch (e) {
      print('Error obteniendo puntos de ruta: $e');
      return [];
    }
  }
}