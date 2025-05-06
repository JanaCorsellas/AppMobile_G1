import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';

class PermissionHandler {
  // Verificar y solicitar permisos de ubicación
  static Future<bool> checkLocationPermission(BuildContext context) async {
    bool serviceEnabled;
    LocationPermission permission;

    // Verificar si el servicio de ubicación está habilitado
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      // Mostrar un diálogo solicitando activar el servicio de ubicación
      final bool shouldOpenSettings = await _showLocationServiceDialog(context);
      if (shouldOpenSettings) {
        await Geolocator.openLocationSettings();
        // Después de abrir la configuración, volvemos a verificar
        await Future.delayed(const Duration(seconds: 2));
        serviceEnabled = await Geolocator.isLocationServiceEnabled();
        if (!serviceEnabled) {
          return false;
        }
      } else {
        return false;
      }
    }

    // Verificar permisos de ubicación
    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Los permisos de ubicación son necesarios para usar esta función'),
          ),
        );
        return false;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      // Mostrar un diálogo informando que los permisos están denegados permanentemente
      final bool shouldOpenSettings = await _showPermissionDeniedForeverDialog(context);
      if (shouldOpenSettings) {
        await Geolocator.openAppSettings();
        // Después de abrir la configuración, volvemos a verificar
        await Future.delayed(const Duration(seconds: 2));
        permission = await Geolocator.checkPermission();
        if (permission == LocationPermission.deniedForever) {
          return false;
        }
      } else {
        return false;
      }
    }

    // El usuario ha concedido permisos
    return true;
  }

  // Diálogo para solicitar activar el servicio de ubicación
  static Future<bool> _showLocationServiceDialog(BuildContext context) async {
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Ubicación desactivada'),
          content: const Text(
              'El servicio de ubicación está desactivado. Por favor actívalo para usar esta función.'),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancelar'),
              onPressed: () {
                Navigator.of(context).pop(false);
              },
            ),
            TextButton(
              child: const Text('Abrir Ajustes'),
              onPressed: () {
                Navigator.of(context).pop(true);
              },
            ),
          ],
        );
      },
    );
    
    return result ?? false;
  }

  // Diálogo para informar que los permisos están denegados permanentemente
  static Future<bool> _showPermissionDeniedForeverDialog(BuildContext context) async {
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Permisos de ubicación'),
          content: const Text(
              'Los permisos de ubicación están denegados permanentemente. Por favor, actívalos en los ajustes de la aplicación.'),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancelar'),
              onPressed: () {
                Navigator.of(context).pop(false);
              },
            ),
            TextButton(
              child: const Text('Abrir Ajustes'),
              onPressed: () {
                Navigator.of(context).pop(true);
              },
            ),
          ],
        );
      },
    );
    
    return result ?? false;
  }
}