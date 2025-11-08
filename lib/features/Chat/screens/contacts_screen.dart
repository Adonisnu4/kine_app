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

  static const Color _primary = Color(0xFF111111); // negro suave

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
    // mientras no sé quién soy, muestro loader pero con el mismo fondo
    if (_currentUserTypeId == null || _currentUserTypeId == '0') {
      return const Scaffold(
        backgroundColor: Color(0xFFF3F3F3),
        body: SafeArea(
          child: Center(
            child: CircularProgressIndicator(color: Colors.black87),
          ),
        ),
      );
    }

    // si soy kine (3) veo pacientes, si soy paciente veo kines
    final String title =
        _currentUserTypeId == '3' ? 'Pacientes' : 'Kinesiólogos';

    return Scaffold(
      backgroundColor: const Color(0xFFF3F3F3),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 18),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Text(
                'Chat con $title',
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: _primary,
                ),
              ),
            ),
            const SizedBox(height: 6),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Text(
                'Selecciona un contacto para continuar.',
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey.shade600,
                ),
              ),
            ),
            const SizedBox(height: 12),

            // LISTA
            Expanded(child: _buildContactsList()),
          ],
        ),
      ),
    );
  }

  Widget _buildContactsList() {
    return StreamBuilder<QuerySnapshot>(
      stream: _chatService.getContactsByType(_currentUserTypeId!),
      builder: (context, snapshot) {
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

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(color: Colors.black87),
          );
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Center(
            child: Text(
              'No hay contactos disponibles.',
              style: TextStyle(color: Colors.grey.shade600, fontSize: 15),
            ),
          );
        }

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

  Widget _contactCard(
    BuildContext context,
    String receiverId,
    Map<String, dynamic> data,
  ) {
    final receiverName = data['nombre_completo'] ?? 'Usuario';
    final receiverUser = data['nombre_usuario'] ?? '';
    final initial =
        receiverName.isNotEmpty ? receiverName[0].toUpperCase() : '?';

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0x0F000000)),
      ),
      child: ListTile(
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
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        leading: CircleAvatar(
          radius: 26,
          backgroundColor: Colors.black.withOpacity(0.08),
          child: Text(
            initial,
            style: const TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 18,
              color: _primary,
            ),
          ),
        ),
        title: Text(
          receiverName,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 15.5,
            color: _primary,
          ),
        ),
        subtitle: receiverUser.isNotEmpty
            ? Text(
                receiverUser,
                style: TextStyle(
                  color: Colors.grey.shade600,
                  fontSize: 12.5,
                ),
              )
            : null,
        trailing: const Icon(
          Icons.chevron_right_rounded,
          color: Colors.black54,
          size: 20,
        ),
      ),
    );
  }
}
