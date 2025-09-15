import 'package:flutter/material.dart';

//import screens
import 'package:kine_app/screens/exercises_screen.dart';
import 'package:kine_app/screens/image_test_screen.dart';
import 'package:kine_app/screens/index.dart';
import 'package:kine_app/screens/profile_screen.dart';
import 'package:kine_app/screens/services_screen.dart';


class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 4, // Número de pestañas
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Kine app'),
          automaticallyImplyLeading: false, // Oculta el botón de "atrás"
        ),

        // Aquí se define el contenido de cada pestaña
        body: const TabBarView(
          children: [
            Index(),
            ExercisesScreen(),
            ServicesScreen(),
            ProfileScreen()
            // ImageTestScreen(), Para testear la imagen, se dejara en caso de necesitar hacer test de componentes 
          ],
        ),

        // Esta es la clave: el TabBar se mueve a la navegación inferior
        bottomNavigationBar: const TabBar(
          tabs: [
            Tab(icon: Icon(Icons.home), text: 'Inicio'),
            Tab(icon: Icon(Icons.search), text: 'Ejercicios'),
            Tab(icon: Icon(Icons.search), text: 'Servicios'),
            Tab(icon: Icon(Icons.person), text: 'Perfil'),
          ],
        ),
      ),
    );
  }
}
