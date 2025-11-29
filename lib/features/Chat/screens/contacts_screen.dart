// lib/screens/contacts_screen.dart

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/chat_service.dart';
import 'chat_screen.dart';

// Pantalla que muestra la lista de contactos disponibles para iniciar un chat.
// El contenido mostrado depende del tipo de usuario: paciente o kinesiólogo.
class ContactsScreen extends StatefulWidget {
  const ContactsScreen({super.key});

  @override
  State<ContactsScreen> createState() => _ContactsScreenState();
}

class _ContactsScreenState extends State<ContactsScreen> {
  // Servicio que gestiona la obtención de contactos y mensajes.
  final ChatService _chatService = ChatService();

  // Almacena el ID del tipo de usuario actual (1 = paciente, 3 = kinesiólogo).
  String? _currentUserTypeId;

  // Paleta de colores utilizada por la pantalla.
  static const Color _blue = Color(0xFF47A5D6);
  static const Color _orange = Color(0xFFE28825);
  static const Color _bg = Color(0xFFF3F3F3);
  static const Color _text = Color(0xFF111111);

  @override
  void initState() {
    super.initState();
    _loadUserTypeId();
  }

  // Obtiene desde el servicio el tipo de usuario actualmente autenticado
  // y lo guarda para renderizar correctamente la pantalla.
  void _loadUserTypeId() async {
    final typeId = await _chatService.getCurrentUserTypeId();
    setState(() {
      _currentUserTypeId = typeId;
    });
  }

  @override
  Widget build(BuildContext context) {
    // Si aún no se ha cargado el tipo de usuario, muestra un loader.
    if (_currentUserTypeId == null || _currentUserTypeId == '0') {
      return const Scaffold(
        backgroundColor: _bg,
        body: SafeArea(
          child: Center(child: CircularProgressIndicator(color: _blue)),
        ),
      );
    }

    // Define si se deben mostrar pacientes o kinesiólogos según el tipo de usuario.
    final String title = _currentUserTypeId == '3'
        ? 'Pacientes'
        : 'Kinesiólogos';

    return Scaffold(
      backgroundColor: _bg,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 14),

            // Encabezado de la pantalla.
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Text(
                'Chat con $title',
                style: const TextStyle(
                  fontSize: 19,
                  fontWeight: FontWeight.w700,
                  color: _text,
                  letterSpacing: -.1,
                ),
              ),
            ),

            // Subtítulo.
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 16.0,
                vertical: 4,
              ),
              child: Text(
                'Selecciona un contacto para continuar.',
                style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
              ),
            ),

            // Barra decorativa.
            Container(
              margin: const EdgeInsets.fromLTRB(16, 0, 0, 10),
              width: 48,
              height: 3.5,
              decoration: BoxDecoration(
                color: _orange,
                borderRadius: BorderRadius.circular(99),
              ),
            ),

            // Lista de contactos.
            Expanded(child: _buildContactsList()),
          ],
        ),
      ),
    );
  }

  // Construye la lista de contactos según el rol del usuario.
  Widget _buildContactsList() {
    return StreamBuilder<QuerySnapshot>(
      // Stream que obtiene la lista de contactos ordenados por tipo.
      stream: _chatService.getContactsByType(_currentUserTypeId!),
      builder: (context, snapshot) {
        // Manejo de errores del stream.
        if (snapshot.hasError) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                'Error al cargar: ${snapshot.error}',
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.red),
              ),
            ),
          );
        }

        // Muestra un loader mientras se obtienen los datos.
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: _blue));
        }

        // Si la consulta no retorna datos, indica que no hay contactos disponibles.
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Center(
            child: Text(
              'No hay contactos disponibles.',
              style: TextStyle(color: Colors.grey.shade600, fontSize: 15),
            ),
          );
        }

        // Lista de documentos obtenidos.
        final docs = snapshot.data!.docs;

        return ListView.builder(
          padding: const EdgeInsets.fromLTRB(12, 0, 12, 16),
          itemCount: docs.length,
          itemBuilder: (context, index) {
            final document = docs[index];
            final data = document.data()! as Map<String, dynamic>;
            final receiverId = document.id;

            return _contactCard(context, receiverId, data);
          },
        );
      },
    );
  }

  // Construye cada tarjeta individual de contacto (usuario).
  Widget _contactCard(
    BuildContext context,
    String receiverId,
    Map<String, dynamic> data,
  ) {
    // Extrae nombre completo y nombre de usuario.
    final receiverName = data['nombre_completo'] ?? 'Usuario';
    final receiverUser = data['nombre_usuario'] ?? '';

    // Obtiene la inicial del nombre para mostrar en el avatar.
    final initial = receiverName.isNotEmpty
        ? receiverName[0].toUpperCase()
        : '?';

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0x0F000000)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(.015),
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: ListTile(
        // Abre la pantalla de chat al pulsar el contacto.
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => ChatScreen(
                receiverId: receiverId,
                receiverName: receiverName,
              ),
            ),
          );
        },

        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 10,
        ),

        // Avatar con la inicial del usuario.
        leading: CircleAvatar(
          radius: 25,
          backgroundColor: _blue.withOpacity(.12),
          child: Text(
            initial,
            style: const TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 17,
              color: _text,
            ),
          ),
        ),

        // Nombre visible en la tarjeta.
        title: Text(
          receiverName,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 15.5,
            color: _text,
          ),
        ),

        // Muestra el nombre de usuario si existe.
        subtitle: receiverUser.isNotEmpty
            ? Text(
                receiverUser,
                style: TextStyle(color: Colors.grey.shade600, fontSize: 12.5),
              )
            : null,

        // Icono de navegación.
        trailing: const Icon(
          Icons.chevron_right_rounded,
          color: Colors.black45,
          size: 20,
        ),
      ),
    );
  }
}
