import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import '../services/chat_service.dart';
import '../models/message.dart';

class ChatScreen extends StatefulWidget {
  final String receiverId;
  final String receiverName;

  const ChatScreen({
    super.key,
    required this.receiverId,
    required this.receiverName,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ChatService _chatService = ChatService();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final ScrollController _scrollController = ScrollController();

  // ----------------------
  // LÓGICA DE NAVEGACIÓN
  // ----------------------
  void _navigateToUserProfile() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Navegando al perfil del usuario...')),
    );
  }

  void sendMessage() async {
    if (_messageController.text.isNotEmpty) {
      await _chatService.sendMessage(
        widget.receiverId,
        _messageController.text,
      );
      _messageController.clear();
      // Opcional: Asegúrate de que el ListView se desplace al final si es necesario.
    }
  }

  String _formatTimestamp(DateTime timestamp) {
    return DateFormat('h:mm a').format(timestamp);
  }

  // ----------------------
  // WIDGETS
  // ----------------------

  Widget _buildMessageItem(Message message) {
    bool isCurrentUser = message.senderId == _auth.currentUser!.uid;

    final Color primaryColor = Theme.of(context).colorScheme.primary;
    final Color senderColor = primaryColor.withOpacity(0.9);
    const Color receiverColor = Color(0xFFE0E0E0);

    final Alignment alignment = isCurrentUser
        ? Alignment.centerRight
        : Alignment.centerLeft;
    final Color messageColor = isCurrentUser ? senderColor : receiverColor;
    final Color textColor = isCurrentUser ? Colors.white : Colors.black87;
    final Color timeColor = isCurrentUser ? Colors.white70 : Colors.black54;

    final BorderRadius borderRadius = BorderRadius.only(
      topLeft: const Radius.circular(20),
      topRight: const Radius.circular(20),
      bottomLeft: isCurrentUser
          ? const Radius.circular(20)
          : const Radius.circular(5),
      bottomRight: isCurrentUser
          ? const Radius.circular(5)
          : const Radius.circular(20),
    );

    final String formattedTime = _formatTimestamp(message.timestamp.toDate());

    return Container(
      alignment: alignment,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
        ),
        child: Container(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
          decoration: BoxDecoration(
            color: messageColor,
            borderRadius: borderRadius,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.08),
                spreadRadius: 1,
                blurRadius: 3,
                offset: const Offset(0, 1),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                message.content,
                style: TextStyle(color: textColor, fontSize: 16),
              ),
              const SizedBox(height: 4),
              Text(
                formattedTime,
                style: TextStyle(color: timeColor, fontSize: 10),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMessageList() {
    String currentUserId = _auth.currentUser!.uid;

    return StreamBuilder<List<Message>>(
      stream: _chatService.getMessages(currentUserId, widget.receiverId),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(
            child: Text(
              'Error al cargar mensajes: ${snapshot.error}',
              style: const TextStyle(color: Colors.red),
            ),
          );
        }
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        List<Message> messages = snapshot.data!;
        return ListView.builder(
          controller: _scrollController,
          reverse: true,
          itemCount: messages.length,
          padding: const EdgeInsets.only(top: 8),
          itemBuilder: (context, index) {
            Message message = messages[messages.length - 1 - index];
            return _buildMessageItem(message);
          },
        );
      },
    );
  }

  Widget _buildMessageInput() {
    final Color primaryColor = Theme.of(context).colorScheme.primary;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        border: Border(
          top: BorderSide(color: Colors.grey.shade200, width: 1.0),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _messageController,
              decoration: InputDecoration(
                hintText: 'Escribe un mensaje...',
                fillColor: Colors.grey.shade100,
                filled: true,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(25),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 10,
                ),
              ),
              onSubmitted: (value) => sendMessage(),
            ),
          ),
          const SizedBox(width: 8),
          CircleAvatar(
            backgroundColor: primaryColor,
            radius: 24,
            child: IconButton(
              onPressed: sendMessage,
              icon: const Icon(Icons.send, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        // Utiliza GestureDetector para hacer que el título sea clickeable
        title: GestureDetector(
          onTap:
              _navigateToUserProfile, // Llama a la nueva función de navegación
          child: Text(
            widget.receiverName,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
          ),
        ),
        centerTitle: false,
        elevation: 1,
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          Expanded(child: _buildMessageList()),
          _buildMessageInput(),
          const SizedBox(height: 5),
        ],
      ),
    );
  }
}
