import 'package:flutter/material.dart';

//Widget Navbar
//Este widget define un TabBar estándar que se usará como barra de
//navegación inferior o superior dependiendo del Scaffold donde se inserte.
//Solo construye UI (no contiene lógica).
//Se recomienda que el TabBar sea controlado por un TabController desde
//un widget padre (como HomeScreen).
class Navbar extends StatelessWidget {
  const Navbar({super.key});

  @override
  Widget build(BuildContext context) {
    return const TabBar(
      // Cada Tab representa una sección de navegación
      tabs: [
        /// Sección de Inicio
        Tab(icon: Icon(Icons.home), text: 'Inicio'),

        /// Sección de Ejercicios
        Tab(icon: Icon(Icons.search), text: 'Ejercicios'),

        /// Sección de Servicios
        /// (Esta etiqueta podría cambiar a "Kinesiólogos" si usas directorio)
        Tab(icon: Icon(Icons.search), text: 'Servicios'),

        /// Sección de Perfil
        Tab(icon: Icon(Icons.person), text: 'Perfil'),
      ],
    );
  }
}
