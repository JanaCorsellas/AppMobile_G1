// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';

class BackgroundImage extends StatelessWidget {
  final Widget child;
  final double opacity;

  const BackgroundImage({
    Key? key,
    required this.child,
    this.opacity = 0.2, // Valor de opacidad por defecto
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Capa 1: Imagen de fondo
        Positioned.fill(
          child: Image.asset(
            'assets/images/background2.ppg', // Ruta a tu imagen
            fit: BoxFit.cover,
          ),
        ),
        // Capa 2: Capa de opacidad
        Positioned.fill(
          child: Container(
            color: Colors.white.withOpacity(opacity),
          ),
        ),
        // Capa 3: Contenido de la pantalla
        child,
      ],
    );
  }
}