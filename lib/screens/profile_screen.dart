import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:kine_app/services/get_user_data.dart';
import 'package:kine_app/screens/login_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  late Future<Map<String, dynamic>?> _userDataFuture;

  @override
  void initState() {
    super.initState();
    _userDataFuture = getUserData();
  }

  // Función para recargar los datos del perfil (llamada después de enviar una solicitud)
  void _refreshProfile() {
    setState(() {
      _userDataFuture = getUserData();
    });
  }

  // --- Modal para la Solicitud de Certificado (Lógica de subida va aquí) ---
  void _showActivationModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (BuildContext context) {
        return SingleChildScrollView(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
            top: 20,
            left: 20,
            right: 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Solicitar Cuenta Kinesiólogo',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const Divider(),
              const SizedBox(height: 10),
              const Text(
                'Para verificar tu cuenta como Kinesiólogo, sube tu **Certificado Profesional** o título. Revisaremos la documentación y actualizaremos tu estado.',
                style: TextStyle(fontSize: 15, color: Colors.black87),
              ),
              const SizedBox(height: 25),
              ElevatedButton.icon(
                onPressed: () async {
                  // TODO: Implementar la subida real del archivo y actualización de Firestore aquí.

                  // SIMULACIÓN DE ÉXITO:
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'Solicitud enviada. Estado: Pendiente de revisión.',
                      ),
                    ),
                  );
                  Navigator.pop(context);
                  _refreshProfile(); // Refresca la UI para mostrar el estado "Pendiente"
                },
                icon: const Icon(Icons.upload_file),
                label: const Text('Subir Certificado'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.teal,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 15),
                ),
              ),
              const SizedBox(height: 30),
            ],
          ),
        );
      },
    );
  }

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
        Text(label, style: const TextStyle(fontSize: 14, color: Colors.grey)),
      ],
    );
  }

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
      body: FutureBuilder<Map<String, dynamic>?>(
        future: _userDataFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError || !snapshot.hasData || snapshot.data == null) {
            return const Center(
              child: Text(
                'Error al cargar el perfil. Por favor, reinicia la aplicación.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.red),
              ),
            );
          }

          final userData = snapshot.data!;
          final userName = userData['nombre'] ?? 'Usuario';
          final userEmail =
              FirebaseAuth.instance.currentUser?.email ?? 'No disponible';
          final userStatusName =
              userData['tipo_usuario_nombre'] ?? 'No especificado';
          // --- VALOR CLAVE: Esta ID debe ser 3 para ocultar el menú ---
          final userStatusId = userData['tipo_usuario_id'] ?? 1;

          final isVerified = userStatusId == 3; // Kinesiólogo Verificado
          final isPending = userStatusId == 2; // Kine Pendiente
          final isNormal = userStatusId == 1; // Usuario Normal

          final userImageUrl =
              userData['imagen_perfil'] ??
              'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?ixlib=rb-4.0.3&ixid=M3wxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHx8fA%3D%3D&auto=format&fit=crop&w=120&h=120&q=80';

          return ListView(
            physics: const BouncingScrollPhysics(),
            children: [
              const SizedBox(height: 30),
              Center(
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    CircleAvatar(
                      radius: 60,
                      backgroundColor: Colors.white,
                      backgroundImage: NetworkImage(userImageUrl),
                    ),
                    Positioned(
                      bottom: -10,
                      left: 0,
                      right: 0,
                      child: Center(
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            // Usamos el color azul si está verificado, si no el teal
                            color: isVerified
                                ? Colors.blue.shade600
                                : Colors.teal.shade400,
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
                            userStatusName,
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
              const SizedBox(height: 25),
              Center(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      userName,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    if (isVerified) // Muestra el ticket si ID == 3
                      Padding(
                        padding: const EdgeInsets.only(left: 8.0),
                        child: Icon(
                          Icons.verified,
                          color: Colors.blue.shade400,
                          size: 24,
                        ),
                      ),
                  ],
                ),
              ),

              Center(
                child: Text(
                  userEmail,
                  style: const TextStyle(fontSize: 16, color: Colors.grey),
                ),
              ),
              const SizedBox(height: 20),
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
              _buildProfileMenuItem(
                icon: Icons.person_outline,
                text: 'Editar Perfil',
                onTap: () {},
              ),
              _buildProfileMenuItem(
                icon: Icons.settings_outlined,
                text: 'Configuración',
                onTap: () {},
              ),
              _buildProfileMenuItem(
                icon: Icons.notifications_outlined,
                text: 'Notificaciones',
                onTap: () {},
              ),

              // --- LÓGICA DE OCULTAMIENTO ---
              // SOLO renderiza si isVerified es false (es decir, ID es 1 o 2).
              if (!isVerified)
                if (isNormal) // Estado "Normal" (ID 1)
                  _buildProfileMenuItem(
                    icon: Icons.school_outlined,
                    text: 'Activar cuenta de profesional',
                    onTap: _showActivationModal,
                  )
                else if (isPending) // Estado "Kine Pendiente" (ID 2)
                  _buildProfileMenuItem(
                    icon: Icons.access_time_filled,
                    text: 'Revisión en curso (Pendiente)',
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'Tu solicitud ya fue enviada y está siendo revisada.',
                          ),
                        ),
                      );
                    },
                    textColor: Colors.orange.shade800,
                  ),

              // --- FIN LÓGICA DE OCULTAMIENTO ---
              _buildProfileMenuItem(
                icon: Icons.help_outline,
                text: 'Ayuda y Soporte',
                onTap: () {},
              ),
              const Divider(height: 40, indent: 20, endIndent: 20),
              _buildProfileMenuItem(
                icon: Icons.logout,
                text: 'Cerrar Sesión',
                textColor: Colors.red,
                onTap: () async {
                  await FirebaseAuth.instance.signOut();
                  if (mounted) {
                    Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const LoginScreen(),
                      ),
                      (Route<dynamic> route) => false,
                    );
                  }
                },
              ),
            ],
          );
        },
      ),
    );
  }
}
