import 'package:flutter/material.dart';

import 'package:kine_app/screens/contacts_screen.dart';
import 'package:kine_app/screens/planes_ejercicio_screen.dart';
import 'package:kine_app/screens/index.dart';
import 'package:kine_app/screens/profile_screen.dart';
import 'package:kine_app/screens/services_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 5, // Número de pestañas: 4 originales + Mensajes
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Kine app'),
          automaticallyImplyLeading: false,
        ),

        // Contenido de cada pestaña
        body: const TabBarView(
          children: [
            Index(),
            PlanesDeEjercicio(),
            ServicesScreen(),
            ContactsScreen(), // Pestaña de Mensajes
            ProfileScreen(),
          ],
        ),

        // Navegación inferior
        bottomNavigationBar: const TabBar(
          isScrollable: true,
          tabs: [
            Tab(icon: Icon(Icons.home), text: 'Inicio'),
            Tab(icon: Icon(Icons.search), text: 'Ejercicios'),
            Tab(icon: Icon(Icons.search), text: 'Servicios'),
            Tab(icon: Icon(Icons.chat_bubble), text: 'Mensajes'),
            Tab(icon: Icon(Icons.person), text: 'Perfil'),
          ],
        ),
      ),
    );
  }
}
