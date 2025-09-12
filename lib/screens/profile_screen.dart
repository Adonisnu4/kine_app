import 'package:flutter/material.dart';

// Asumo que tu archivo 'column.dart' no es necesario para este widget de perfil.
// Si lo fuera, puedes descomentar la siguiente línea:
// import 'package:kine_app/layouts/column.dart';

// Convertimos a StatefulWidget para poder guardar y actualizar el estado
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  // Variables para almacenar los datos del perfil que pueden cambiar
  String _userName = 'Nombre Apellido';
  String _userEmail = 'usuario@email.com';
  String _userStatus = 'Disponible'; // Nueva variable para el estado

  // Función para navegar a la pantalla de edición y esperar un resultado
  void _navigateToEditProfile() async {
    // Navega y espera a que la pantalla de edición devuelva datos
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EditProfileScreen(
          currentName: _userName,
          currentEmail: _userEmail,
          currentStatus: _userStatus, // Pasamos el estado actual
        ),
      ),
    );

    // Si recibimos datos de vuelta, actualizamos el estado
    if (result != null && result is Map) {
      setState(() {
        _userName = result['name'];
        _userEmail = result['email'];
        _userStatus = result['status']; // Actualizamos el estado
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Mi Perfil',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.teal,
        elevation: 2,
        centerTitle: true,
      ),
      body: Container(
        // Un degradado sutil para el fondo
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.teal.shade50, Colors.white],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: ListView(
          physics: const BouncingScrollPhysics(),
          children: [
            const SizedBox(height: 30),
            // --- SECCIÓN DE LA IMAGEN DE PERFIL Y NOMBRE ---
            Center(
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  const CircleAvatar(
                    radius: 60,
                    backgroundColor: Colors.white,
                    backgroundImage: NetworkImage(
                        'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?ixlib=rb-4.0.3&ixid=M3wxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHx8fA%3D%3D&auto=format&fit=crop&w=120&h=120&q=80'),
                  ),
                  // "Nube" con el estado
                  Positioned(
                    bottom: -10,
                    left: 0,
                    right: 0,
                    child: Center(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.teal.shade400,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.15),
                              spreadRadius: 1,
                              blurRadius: 3,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Text(
                          _userStatus,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 25), // Aumentamos el espacio para la nube
            Center(
              child: Text(
                _userName, // Usamos la variable de estado
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
            ),
            Center(
              child: Text(
                _userEmail, // Usamos la variable de estado
                style: const TextStyle(
                  fontSize: 16,
                  color: Colors.grey,
                ),
              ),
            ),
            const SizedBox(height: 20),

            // --- SECCIÓN DE ESTADÍSTICAS ---
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildStatItem('Citas', '23'),
                  _buildStatItem('Seguidores', '1.2k'),
                  _buildStatItem('Siguiendo', '345'),
                ],
              ),
            ),
            const SizedBox(height: 30),

            // --- SECCIÓN DE OPCIONES DEL MENÚ ---
            _buildProfileMenuItem(
              icon: Icons.person_outline,
              text: 'Editar Perfil',
              onTap: _navigateToEditProfile, // Llamamos a nuestra función de navegación
            ),
            _buildProfileMenuItem(
              icon: Icons.settings_outlined,
              text: 'Configuración',
              onTap: () {
                // Lógica para ir a configuración
              },
            ),
            _buildProfileMenuItem(
              icon: Icons.notifications_outlined,
              text: 'Notificaciones',
              onTap: () {
                // Lógica para notificaciones
              },
            ),
            _buildProfileMenuItem(
              icon: Icons.help_outline,
              text: 'Ayuda y Soporte',
              onTap: () {
                // Lógica para la sección de ayuda
              },
            ),
            const Divider(height: 40, indent: 20, endIndent: 20),
            _buildProfileMenuItem(
              icon: Icons.logout,
              text: 'Cerrar Sesión',
              textColor: Colors.red,
              onTap: () {
                // Lógica para cerrar sesión
              },
            ),
          ],
        ),
      ),
    );
  }

  // Widget auxiliar para crear los items de estadísticas
  Widget _buildStatItem(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.teal,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            color: Colors.grey,
          ),
        ),
      ],
    );
  }

  // Widget auxiliar para crear las opciones del menú de perfil
  Widget _buildProfileMenuItem({
    required IconData icon,
    required String text,
    required VoidCallback onTap,
    Color textColor = Colors.black87,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: InkWell(
        onTap: onTap,
        child: Row(
          children: [
            Icon(icon, color: Colors.teal, size: 28),
            const SizedBox(width: 20),
            Text(
              text,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w500,
                color: textColor,
              ),
            ),
            const Spacer(),
            Icon(
              Icons.arrow_forward_ios,
              color: Colors.grey.shade400,
              size: 16,
            ),
          ],
        ),
      ),
    );
  }
}

// --- PANTALLA PARA EDITAR EL PERFIL ---

class EditProfileScreen extends StatefulWidget {
  final String currentName;
  final String currentEmail;
  final String currentStatus; // Recibimos el estado

  const EditProfileScreen({
    super.key,
    required this.currentName,
    required this.currentEmail,
    required this.currentStatus, // Requerimos el estado
  });

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  late TextEditingController _nameController;
  late TextEditingController _emailController;
  late TextEditingController _statusController; // Controller para el estado
  final _bioController = TextEditingController(text: 'Escribe algo sobre ti...');

  @override
  void initState() {
    super.initState();
    // Inicializamos los controllers con los datos actuales
    _nameController = TextEditingController(text: widget.currentName);
    _emailController = TextEditingController(text: widget.currentEmail);
    _statusController = TextEditingController(text: widget.currentStatus); // Inicializamos el estado
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _statusController.dispose(); // Limpiamos el controller
    _bioController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Editar Perfil', style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.teal,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: ListView(
        padding: const EdgeInsets.all(24.0),
        children: <Widget>[
          const SizedBox(height: 20),
          TextField(
            controller: _nameController,
            decoration: const InputDecoration(
              labelText: 'Nombre Completo',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.person),
            ),
          ),
          const SizedBox(height: 20),
          TextField(
            controller: _emailController,
            decoration: const InputDecoration(
              labelText: 'Correo Electrónico',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.email),
            ),
            keyboardType: TextInputType.emailAddress,
          ),
          const SizedBox(height: 20),
          // Nuevo campo de texto para el estado
          TextField(
            controller: _statusController,
            decoration: const InputDecoration(
              labelText: 'Estado',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.bubble_chart_outlined),
            ),
          ),
          const SizedBox(height: 20),
          TextField(
            controller: _bioController,
            decoration: const InputDecoration(
              labelText: 'Biografía',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.article),
            ),
            maxLines: 3,
          ),
          const SizedBox(height: 40),
          ElevatedButton(
            onPressed: () {
              // Creamos un mapa con los nuevos datos
              final updatedData = {
                'name': _nameController.text,
                'email': _emailController.text,
                'status': _statusController.text, // Añadimos el estado
              };
              // Devolvemos los datos a la pantalla anterior
              Navigator.pop(context, updatedData);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.teal,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text(
              'Guardar Cambios',
              style: TextStyle(fontSize: 18, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}

