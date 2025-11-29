import 'package:flutter/material.dart';
import 'package:kine_app/features/auth/services/get_user_data.dart';

/// Pantalla que muestra diferentes botones/acciones dependiendo del tipo de usuario autenticado.
/// Usa el servicio getUserData() para obtener la información
/// del usuario desde Firestore.
class ServicesScreen extends StatefulWidget {
  const ServicesScreen({super.key});

  @override
  State<ServicesScreen> createState() => _ServicesScreenState();
}

class _ServicesScreenState extends State<ServicesScreen> {
  /// Datos completos del usuario obtenidos desde Firestore.
  Map<String, dynamic>? _userData;

  /// Indica si la pantalla sigue cargando la información del usuario.
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  /// Carga los datos del usuario desde Firestore usando getUserData().
  /// Una vez completado, actualiza el estado local.
  Future<void> _loadUserData() async {
    final userData = await getUserData();

    setState(() {
      _userData = userData;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    /// Mientras se cargan los datos, se muestra un indicador de carga.
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    /// Extraemos el tipo de usuario (paciente o profesional).
    /// Si no existe en la BD, devolvemos un valor por defecto.
    final userStatus = _userData?['tipo_usuario_nombre'] ?? 'No especificado';

    return Scaffold(
      appBar: AppBar(title: const Text('Servicios')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            /// Botón visible para todos los usuarios (pacientes y profesionales).
            ElevatedButton(
              onPressed: () {
                // Acción general para todos los usuarios.
                // Aquí puedes navegar a otra pantalla o ejecutar lógica.
              },
              child: const Text('Tomar Servicio'),
            ),

            const SizedBox(height: 20),

            /// Botón EXCLUSIVO para usuarios tipo "profesional".
            /// Se renderiza solo si el usuario tiene ese rol.
            if (userStatus == 'profesional')
              ElevatedButton(
                onPressed: () {
                  // Acción exclusiva para profesionales.
                  // Aquí se colocan funciones especiales del kine.
                },
                child: const Text('Botón para profesionales'),
              ),
          ],
        ),
      ),
    );
  }
}
