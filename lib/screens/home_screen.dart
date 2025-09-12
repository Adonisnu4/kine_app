import 'package:flutter/material.dart';

//import screens
import 'package:kine_app/screens/exercises_screen.dart';


class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3, // Número de pestañas
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Mi App con Pestañas'),
          automaticallyImplyLeading: false, // Oculta el botón de "atrás"
        ),
        
        // Aquí se define el contenido de cada pestaña
        body: const TabBarView(
          children: [
            Center(child: Text('Contenido de Inicio')),
            ExercisesScreen(),

            Center(child: Text('Contenido de Perfil')),

          ],
        ),
        
        // Esta es la clave: el TabBar se mueve a la navegación inferior
        bottomNavigationBar: const TabBar(
          tabs: [
            Tab(icon: Icon(Icons.home), text: 'Inicio'),
            Tab(icon: Icon(Icons.search), text: 'Ejercicios'),
            Tab(icon: Icon(Icons.person), text: 'Perfil'),
          ],
        ),
      ),
    );
  }
}