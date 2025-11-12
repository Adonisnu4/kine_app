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

  // paleta
  static const Color _blue = Color(0xFF47A5D6);
  static const Color _orange = Color(0xFFE28825);
  static const Color _bg = Color(0xFFF3F3F3);
  static const Color _text = Color(0xFF111111);

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
    if (_currentUserTypeId == null || _currentUserTypeId == '0') {
      return const Scaffold(
        backgroundColor: _bg,
        body: SafeArea(
          child: Center(
            child: CircularProgressIndicator(color: _blue),
          ),
        ),
      );
    }

    final String title =
        _currentUserTypeId == '3' ? 'Pacientes' : 'Kinesiólogos';

    return Scaffold(
      backgroundColor: _bg,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 14),
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
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4),
              child: Text(
                'Selecciona un contacto para continuar.',
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey.shade600,
                ),
              ),
            ),
            // barra más pegadita
            Container(
              margin: const EdgeInsets.fromLTRB(16, 0, 0, 10),
              width: 48,
              height: 3.5,
              decoration: BoxDecoration(
                color: _orange,
                borderRadius: BorderRadius.circular(99),
              ),
            ),
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
            child: CircularProgressIndicator(color: _blue),
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
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
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
        title: Text(
          receiverName,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 15.5,
            color: _text,
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
          color: Colors.black45,
          size: 20,
        ),
      ),
    );
  }
}
