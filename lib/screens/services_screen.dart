import 'package:flutter/material.dart';
import 'package:kine_app/services/get_user_data.dart'; // Asegúrate de tener este servicio

class ServicesScreen extends StatefulWidget {
  const ServicesScreen({super.key});

  @override
  State<ServicesScreen> createState() => _ServicesScreenState();
}

class _ServicesScreenState extends State<ServicesScreen> {
  // Aquí almacenamos los datos del usuario
  Map<String, dynamic>? _userData;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final userData = await getUserData();
    setState(() {
      _userData = userData;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    final userStatus = _userData?['tipo_usuario_nombre'] ?? 'No especificado';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Servicios'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Botón para todos los usuarios
            ElevatedButton(
              onPressed: () {
                // Lógica para 'Tomar Servicio'
              },
              child: const Text('Tomar Servicio'),
            ),

            const SizedBox(height: 20),

            // Botón condicional solo para usuarios "Profesionales"
            if (userStatus == 'profesional')
              ElevatedButton(
                onPressed: () {
                  // Lógica para el botón de profesional
                },
                child: const Text('Botón para profesionales'),
              ),
          ],
        ),
      ),
    );
  }
}