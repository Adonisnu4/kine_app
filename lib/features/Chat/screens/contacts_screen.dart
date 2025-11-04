// lib/screens/contacts_screen.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/chat_service.dart';
import 'chat_screen.dart';

class ContactsScreen extends StatefulWidget {
  const ContactsScreen({super.key});

  @override
  State<ContactsScreen> createState() => _ContactsScreenState();
}

class _ContactsScreenState extends State<ContactsScreen> {
  final ChatService _chatService = ChatService();
  String? _currentUserTypeId;

  // 1. Definir un color primario para consistencia (el mismo que en ChatScreen)
  static const Color primaryBlue = Color(0xFF007AFF);

  @override
  void initState() {
    super.initState();
    _loadUserTypeId();
  }

  void _loadUserTypeId() async {
    final typeId = await _chatService.getCurrentUserTypeId();
    setState(() {
      _currentUserTypeId = typeId;
    });
  }

  @override
  Widget build(BuildContext context) {
    // 1. Mostrar carga mientras se obtiene el tipo de usuario
    if (_currentUserTypeId == null || _currentUserTypeId == '0') {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Contactos', style: TextStyle(color: primaryBlue)),
          backgroundColor: Colors.white,
          elevation: 0.5,
        ),
        body: const Center(
          child: CircularProgressIndicator(color: primaryBlue),
        ),
      );
    }

    // 2. Definir el título basado en el tipo de usuario
    String title = _currentUserTypeId == '3'
        ? 'Pacientes' // Si soy Kine (ID 3), busco Pacientes
        : 'Kinesiólogos'; // Si soy Paciente (ID 3), busco Kines

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Chat con $title',
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        centerTitle: false,
        backgroundColor: Colors.white,
        elevation: 0.5, // Sombra sutil para la AppBar
        iconTheme: const IconThemeData(color: primaryBlue),
      ),
      // Añadimos un fondo claro para suavizar la lista
      backgroundColor: const Color(0xFFF0F0F0),
      body: _buildContactsList(),
    );
  }

  // 3. Widget de Contacto (como un componente separado para reusabilidad y limpieza)
  Widget _buildContactItem(
    BuildContext context,
    String receiverId,
    Map<String, dynamic> data,
  ) {
    final receiverName = data['nombre_completo'] ?? 'Usuario Desconocido';
    final receiverEmail = data['nombre_usuario'] ?? 'Sin correo';

    // Obtener la primera letra del nombre para el Avatar
    final initial = receiverName.isNotEmpty
        ? receiverName[0].toUpperCase()
        : '?';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
      child: Card(
        // Utilizamos Card para darle elevación y bordes redondeados (sombra sutil)
        elevation: 1.5,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: InkWell(
          // InkWell para un efecto de toque elegante
          borderRadius: BorderRadius.circular(12),
          onTap: () {
            // Navegar a la pantalla de chat
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ChatScreen(
                  receiverId: receiverId,
                  receiverName: receiverName,
                ),
              ),
            );
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 12.0),
            child: ListTile(
              // Avatar Circular con la inicial
              leading: CircleAvatar(
                backgroundColor: primaryBlue.withOpacity(0.8),
                radius: 28, // Tamaño del avatar
                child: Text(
                  initial,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
                  ),
                ),
              ),
              title: Text(
                receiverName,
                style: const TextStyle(
                  fontWeight:
                      FontWeight.w600, // Seminegrita para destacar el nombre
                  fontSize: 17,
                  color: Colors.black87,
                ),
              ),
              subtitle: Text(
                receiverEmail,
                style: TextStyle(color: Colors.grey[600], fontSize: 14),
              ),
              trailing: const Icon(
                Icons.arrow_forward_ios,
                color: Colors.grey,
                size: 18,
              ),
            ),
          ),
        ),
      ),
    );
  }

  // 4. Lista de Contactos
  Widget _buildContactsList() {
    return StreamBuilder<QuerySnapshot>(
      stream: _chatService.getContactsByType(_currentUserTypeId!),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(
            child: Text(
              'Error al cargar: ${snapshot.error}',
              style: const TextStyle(color: Colors.red),
            ),
          );
        }
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(color: primaryBlue),
          );
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Center(
            child: Text(
              'No hay contactos disponibles.',
              style: TextStyle(color: Colors.grey[600], fontSize: 16),
            ),
          );
        }

        return ListView.builder(
          itemCount: snapshot.data!.docs.length,
          // Un poco de padding en el listado
          padding: const EdgeInsets.only(top: 8.0, bottom: 8.0),
          itemBuilder: (context, index) {
            final document = snapshot.data!.docs[index];
            Map<String, dynamic> data =
                document.data()! as Map<String, dynamic>;
            final receiverId = document.id;

            return _buildContactItem(context, receiverId, data);
          },
        );
      },
    );
  }
}
