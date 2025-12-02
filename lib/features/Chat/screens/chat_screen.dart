import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import '../services/chat_service.dart';
import '../models/message.dart';

/// Paleta de colores de la app.
/// ⚠️ Si ya la tienes definida, elimina esta clase e importa la original.
class AppColors {
  static const blue = Color(0xFF47A5D6);
  static const orange = Color(0xFFE28825);
  static const grey = Color(0xFF7A8285);
  static const bg = Color(0xFFF3F3F3);
  static const white = Colors.white;
  static const text = Color(0xFF111111);
}

// Pantalla de conversación entre dos usuarios.
class ChatScreen extends StatefulWidget {
  // ID del usuario receptor del chat.
  final String receiverId;

  // Nombre del usuario receptor, utilizado en el encabezado.
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
  // Controlador para manejar la entrada de texto del mensaje.
  final TextEditingController _messageController = TextEditingController();

  // Servicio encargado de gestionar envío y obtención de mensajes.
  final ChatService _chatService = ChatService();

  // Instancia de FirebaseAuth para obtener el usuario actual.
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Controlador para permitir desplazamiento automático del ListView.
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _ensureChatRoomInitialized();
  }

  // Asegura que el documento de la sala de chat exista en la base de datos.
  void _ensureChatRoomInitialized() async {
    final currentUserId = _auth.currentUser?.uid;
    if (currentUserId != null) {
      await _chatService.ensureChatRoomExists(currentUserId, widget.receiverId);
    }
  }

  // Acción al pulsar el encabezado de la app (nombre del receptor).
  void _navigateToUserProfile() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Navegando al perfil del usuario...')),
    );
  }

  // Envía un mensaje utilizando el chatService.
  void sendMessage() async {
    if (_messageController.text.isNotEmpty) {
      await _chatService.sendMessage(
        widget.receiverId,
        _messageController.text,
      );
      _messageController.clear();
    }
  }

  // Formatea la hora del mensaje.
  String _formatTimestamp(DateTime timestamp) {
    return DateFormat('h:mm a').format(timestamp);
  }

  // Widget para un mensaje individual.
  Widget _buildMessageItem(Message message) {
    final bool isCurrentUser = message.senderId == _auth.currentUser!.uid;

    // Colores de las burbujas según la paleta de la app:
    // - Usuario actual: azul principal.
    // - Otro usuario: gris muy clarito.
    final Color senderColor = AppColors.blue;
    const Color receiverColor = Color(0xFFF5F6F8);

    final Alignment alignment =
        isCurrentUser ? Alignment.centerRight : Alignment.centerLeft;

    final Color messageColor = isCurrentUser ? senderColor : receiverColor;
    final Color textColor = isCurrentUser ? Colors.white : AppColors.text;
    final Color timeColor = isCurrentUser ? Colors.white70 : Colors.black54;

    final BorderRadius borderRadius = BorderRadius.only(
      topLeft: const Radius.circular(20),
      topRight: const Radius.circular(20),
      bottomLeft:
          isCurrentUser ? const Radius.circular(20) : const Radius.circular(8),
      bottomRight:
          isCurrentUser ? const Radius.circular(8) : const Radius.circular(20),
    );

    final String formattedTime = _formatTimestamp(message.timestamp.toDate());

    return Container(
      alignment: alignment,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.78,
        ),
        child: Container(
          padding: const EdgeInsets.fromLTRB(14, 10, 14, 6),
          decoration: BoxDecoration(
            color: messageColor,
            borderRadius: borderRadius,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.03),
                spreadRadius: 0,
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
            border: isCurrentUser
                ? null
                : Border.all(
                    color: const Color(0xFFE5E7EB),
                    width: 1,
                  ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                message.content,
                style: TextStyle(
                  color: textColor,
                  fontSize: 15,
                  height: 1.3,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                formattedTime,
                style: TextStyle(
                  color: timeColor,
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Lista de mensajes.
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

        List<Message> messages = snapshot.data ?? [];

        if (messages.isEmpty) {
          return const Center(
            child: Text(
              'Empieza la conversación ✨',
              style: TextStyle(color: AppColors.grey, fontSize: 15),
            ),
          );
        }

        return ListView.builder(
          controller: _scrollController,
          reverse: true, //hace que el chat comience desde abajo
          itemCount: messages.length,
          padding: const EdgeInsets.only(top: 8, bottom: 8),
          itemBuilder: (context, index) {
            Message message = messages[messages.length - 1 - index];
            return _buildMessageItem(message);
          },
        );
      },
    );
  }

  // Campo de texto para escribir mensajes (no se usa en build, pero dejo lógica igual).
  Widget _buildMessageInput() {
    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 6.0),
        decoration: BoxDecoration(
          color: AppColors.bg,
          border: const Border(
            top: BorderSide(color: Color(0xFFE5E7EB), width: 1.0),
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: AppColors.white,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: const Color(0xFFE0E3E7),
                    width: 1,
                  ),
                ),
                child: TextField(
                  controller: _messageController,
                  decoration: const InputDecoration(
                    hintText: 'Escribe un mensaje...',
                    hintStyle: TextStyle(
                      color: Color(0xFF9AA0A5),
                      fontSize: 14,
                    ),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 10,
                    ),
                  ),
                  onSubmitted: (_) => sendMessage(),
                ),
              ),
            ),
            const SizedBox(width: 10),
            CircleAvatar(
              backgroundColor: AppColors.blue,
              radius: 24,
              child: IconButton(
                onPressed: sendMessage,
                icon: const Icon(Icons.send_rounded, color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Fondo gris clarito de la app.
      backgroundColor: AppColors.bg,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(60),
        child: AppBar(
          titleSpacing: 0,
          backgroundColor: AppColors.white,
          elevation: 0,
          centerTitle: false,
          foregroundColor: AppColors.blue,
          leading: IconButton(
            icon: const Icon(
              Icons.arrow_back_ios_new_rounded,
              size: 20,
            ),
            onPressed: () => Navigator.pop(context),
          ),
          title: GestureDetector(
            onTap: _navigateToUserProfile,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.receiverName,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                    color: Colors.black87,
                  ),
                ),
                const Text(
                  'Chat de kinesiología',
                  style: TextStyle(
                    fontSize: 11.5,
                    color: Color(0xFF9AA0A5),
                  ),
                ),
              ],
            ),
          ),
          // Línea finita abajo para separar el header.
          bottom: const PreferredSize(
            preferredSize: Size.fromHeight(0.5),
            child: Divider(
              height: 0.5,
              thickness: 0.5,
              color: Color(0xFFE5E7EB),
            ),
          ),
        ),
      ),
      body: Column(
        children: [
          Expanded(child: _buildMessageList()),
          // Input con el mismo estilo que definimos arriba
          SafeArea(
            top: false,
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 12.0, vertical: 6.0),
              decoration: const BoxDecoration(
                color: AppColors.bg,
                border: Border(
                  top: BorderSide(color: Color(0xFFE5E7EB), width: 1.0),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: AppColors.white,
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(
                          color: const Color(0xFFE0E3E7),
                          width: 1,
                        ),
                      ),
                      child: TextField(
                        controller: _messageController,
                        decoration: const InputDecoration(
                          hintText: 'Escribe un mensaje...',
                          hintStyle: TextStyle(
                            color: Color(0xFF9AA0A5),
                            fontSize: 14,
                          ),
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 10,
                          ),
                        ),
                        onSubmitted: (_) => sendMessage(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  CircleAvatar(
                    backgroundColor: AppColors.blue,
                    radius: 24,
                    child: IconButton(
                      onPressed: sendMessage,
                      icon:
                          const Icon(Icons.send_rounded, color: Colors.white),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
