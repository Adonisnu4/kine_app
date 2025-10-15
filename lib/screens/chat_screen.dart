// lib/screens/chat_screen.dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/chat_service.dart'; // RUTA AJUSTADA
import '../models/message.dart'; // RUTA AJUSTADA

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

  void sendMessage() async {
    if (_messageController.text.isNotEmpty) {
      await _chatService.sendMessage(
        widget.receiverId,
        _messageController.text,
      );
      _messageController.clear();
    }
  }

  Widget _buildMessageItem(Message message) {
    bool isCurrentUser = message.senderId == _auth.currentUser!.uid;
    var alignment = isCurrentUser
        ? Alignment.centerRight
        : Alignment.centerLeft;
    var color = isCurrentUser ? Colors.blue[600] : Colors.grey[700];

    return Container(
      alignment: alignment,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(15),
        ),
        child: Text(
          message.content,
          style: const TextStyle(color: Colors.white, fontSize: 16),
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
          return Center(child: Text('Error: ${snapshot.error}'));
        }
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        List<Message> messages = snapshot.data!;
        return ListView.builder(
          reverse: true, // Mostrar los mensajes más recientes abajo
          itemCount: messages.length,
          itemBuilder: (context, index) {
            Message message = messages[messages.length - 1 - index];
            return _buildMessageItem(message);
          },
        );
      },
    );
  }

  Widget _buildMessageInput() {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _messageController,
              decoration: InputDecoration(
                hintText: 'Escribe un mensaje...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 10,
                ),
              ),
              onSubmitted: (value) => sendMessage(),
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            onPressed: sendMessage,
            icon: const Icon(Icons.send, color: Colors.blue),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.receiverName)),
      body: Column(
        children: [
          Expanded(child: _buildMessageList()),
          _buildMessageInput(),
        ],
      ),
    );
  }
}
