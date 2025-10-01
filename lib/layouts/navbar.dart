import 'package:flutter/material.dart';

class Navbar extends StatelessWidget {
  const Navbar({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return const TabBar(
      tabs: [
        Tab(icon: Icon(Icons.home), text: 'Inicio'),
        Tab(icon: Icon(Icons.search), text: 'Ejercicios'),
        Tab(icon: Icon(Icons.search), text: 'Servicios'),
        Tab(icon: Icon(Icons.person), text: 'Perfil'),
      ],
    );
  }
}