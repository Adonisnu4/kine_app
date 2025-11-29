import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import '../services/chat_service.dart';
import '../models/message.dart';

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

  // LÓGICA DE NAVEGACIÓN

  // Acción al pulsar el encabezado de la app (nombre del receptor).
  void _navigateToUserProfile() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Navegando al perfil del usuario...')),
    );
  }

  // Envía un mensaje utilizando el chatService si el campo no está vacío.
  void sendMessage() async {
    if (_messageController.text.isNotEmpty) {
      await _chatService.sendMessage(
        widget.receiverId,
        _messageController.text,
      );
      _messageController.clear();
    }
  }

  // Formatea la hora del mensaje a un formato legible (ej: 5:31 PM).
  String _formatTimestamp(DateTime timestamp) {
    return DateFormat('h:mm a').format(timestamp);
  }

  // ITEM INDIVIDUAL DEL MENSAJE

  // Construye el widget visual para un mensaje individual del chat.
  Widget _buildMessageItem(Message message) {
    // Determina si el mensaje fue enviado por el usuario actual.
    bool isCurrentUser = message.senderId == _auth.currentUser!.uid;

    // Define colores dependiendo del remitente.
    final Color primaryColor = Theme.of(context).colorScheme.primary;
    final Color senderColor = primaryColor.withOpacity(0.9);
    const Color receiverColor = Color(0xFFE0E0E0);

    // Define la alineación del mensaje.
    final Alignment alignment = isCurrentUser
        ? Alignment.centerRight
        : Alignment.centerLeft;

    // Define el color del globo de mensaje.
    final Color messageColor = isCurrentUser ? senderColor : receiverColor;

    // Color del texto según si es enviado o recibido.
    final Color textColor = isCurrentUser ? Colors.white : Colors.black87;

    // Color de la hora de envío.
    final Color timeColor = isCurrentUser ? Colors.white70 : Colors.black54;

    // Bordes personalizados para diferenciar mensajes del remitente.
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

    // Convierte el timestamp Firestore a un DateTime legible.
    final String formattedTime = _formatTimestamp(message.timestamp.toDate());

    return Container(
      alignment: alignment,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          // Limita el ancho máximo del mensaje.
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

  //
  // LISTA DE MENSAJES
  Widget _buildMessageList() {
    // Obtiene el ID del usuario actual para identificar mensajes propios.
    String currentUserId = _auth.currentUser!.uid;

    return StreamBuilder<List<Message>>(
      // Escucha los mensajes en tiempo real entre usuario y receptor.
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

        // Estado inicial mientras carga los primeros mensajes.
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        // Lista final de mensajes obtenidos.
        List<Message> messages = snapshot.data!;

        return ListView.builder(
          controller: _scrollController,
          reverse: true, // Hace que el chat empiece desde abajo.
          itemCount: messages.length,
          padding: const EdgeInsets.only(top: 8),
          itemBuilder: (context, index) {
            // Se invierte el orden manualmente para que coincida con reverse:true.
            Message message = messages[messages.length - 1 - index];
            return _buildMessageItem(message);
          },
        );
      },
    );
  }

  //CAMPO DE TEXTO PARA ESCRIBIR MENSAJES
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

  // BUILD PRINCIPAL DE LA PANTALLA
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        // Hace que el título (nombre del usuario) sea clickeable.
        title: GestureDetector(
          onTap: _navigateToUserProfile,
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
