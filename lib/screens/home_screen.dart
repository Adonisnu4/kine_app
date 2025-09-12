import 'package:flutter/material.dart';

<<<<<<< Updated upstream
=======
//import screens
import 'package:kine_app/screens/exercises_screen.dart';
import 'package:kine_app/screens/profile_screen.dart';


>>>>>>> Stashed changes
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      home: Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: Text(
            "Hola", style: TextStyle(color: Colors.white, fontSize: 24)
          ),
        ),
<<<<<<< Updated upstream
      )
=======
        
        // Aquí se define el contenido de cada pestaña
        body: const TabBarView(
          children: [
            Center(child: Text('Contenido de Inicio')),
            ExercisesScreen(),
            ProfileScreen(),
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
>>>>>>> Stashed changes
    );
  }
}