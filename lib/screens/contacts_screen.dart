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
  // 🚨 CAMBIO: Ahora es String?
  String? _currentUserTypeId;

  @override
  void initState() {
    super.initState();
    _loadUserTypeId();
  }

  void _loadUserTypeId() async {
    // La función devuelve String?
    final typeId = await _chatService.getCurrentUserTypeId();
    setState(() {
      _currentUserTypeId = typeId;
    });
  }

  @override
  Widget build(BuildContext context) {
    // 1. Mostrar carga mientras se obtiene el tipo de usuario
    // 🚨 Solución al error 'const': Eliminar la palabra clave 'const' del Scaffold.
    if (_currentUserTypeId == null || _currentUserTypeId == '0') {
      return Scaffold(
        // <--- ¡Sin 'const'!
        appBar: AppBar(title: const Text('Contactos')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    // 2. Definir el título basado en el tipo de usuario (usando String)
    String title = _currentUserTypeId == '1'
        ? 'Contactar Kines (tipo 3)'
        : 'Contactar Pacientes (tipo 1)';

    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: _buildContactsList(),
    );
  }

  Widget _buildContactsList() {
    return StreamBuilder<QuerySnapshot>(
      // Pasar el String ID ('1' o '3')
      stream: _chatService.getContactsByType(_currentUserTypeId!),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(child: Text('No hay contactos disponibles.'));
        }

        return ListView(
          children: snapshot.data!.docs.map((document) {
            Map<String, dynamic> data =
                document.data()! as Map<String, dynamic>;
            final receiverId = document.id;
            final receiverName =
                data['nombre'] ??
                'Usuario Desconocido'; // Usando 'nombre' de tu imagen

            return ListTile(
              title: Text(receiverName),
              subtitle: Text("ID: $receiverId"),
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
            );
          }).toList(),
        );
      },
    );
  }
}
