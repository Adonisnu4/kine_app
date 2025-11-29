// lib/services/chat_service.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/message.dart';

// Servicio encargado de manejar toda la lógica del chat.
// Incluye envío de mensajes, generación de rooms,
// obtención de mensajes y filtrado de contactos.
class ChatService {
  // Instancia de autenticación actual.
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Conexión a la base de datos Firestore.
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Genera un ID único y consistente para un chat entre dos usuarios.
  // Ordena ambos IDs y los une para evitar duplicados.
  String getChatRoomId(String userId1, String userId2) {
    List<String> ids = [userId1, userId2];
    ids.sort(); // Asegura que siempre estén en el mismo orden.
    return ids.join("_"); // Devuelve un identificador único.
  }

  // Envía un nuevo mensaje y actualiza los datos del chat correspondiente.
  Future<void> sendMessage(String receiverId, String content) async {
    // Obtiene datos del usuario emisor.
    final String currentUserId = _auth.currentUser!.uid;
    final String currentUserEmail = _auth.currentUser!.email ?? "SinEmail";
    final Timestamp timestamp = Timestamp.now();

    // Crea un objeto Message del modelo.
    Message newMessage = Message(
      senderId: currentUserId,
      senderEmail: currentUserEmail,
      receiverId: receiverId,
      content: content,
      timestamp: timestamp,
    );

    // Obtiene el ID único del chat.
    String chatRoomId = getChatRoomId(currentUserId, receiverId);

    try {
      // Actualiza o crea el documento principal del chat.
      await _firestore.collection('chats').doc(chatRoomId).set({
        'participants': [currentUserId, receiverId],
        'lastMessage': content,
        'lastMessageTimestamp': timestamp,
        'updatedAt': timestamp,
      }, SetOptions(merge: true));
      // merge: true evita sobrescribir datos existentes.

      // Guarda el mensaje dentro de la subcolección "messages".
      await _firestore
          .collection('chats')
          .doc(chatRoomId)
          .collection('messages')
          .add({
            ...newMessage.toMap(), // Convierte el objeto en mapa.
            'chatId': chatRoomId, // Identificador del chat.
            'messageType':
                'texto', // Permite futuras extensiones (imágenes, audios, etc.).
            'read': false, // Campo útil para futuro sistema de lectura.
          });

      print("Mensaje enviado correctamente a $receiverId");
    } catch (e) {
      print("Error al enviar mensaje: $e");
      rethrow;
    }
  }

  // Obtiene el stream de mensajes en tiempo real entre dos usuarios.
  Stream<List<Message>> getMessages(String userId, String otherUserId) {
    // Obtiene el ID único del chat.
    String chatRoomId = getChatRoomId(userId, otherUserId);

    return _firestore
        .collection('chats')
        .doc(chatRoomId)
        .collection('messages')
        .orderBy('timestamp', descending: false) // Orden cronológico.
        .snapshots()
        .map((snapshot) {
          // Convierte cada documento de Firestore a un objeto Message.
          return snapshot.docs.map((doc) {
            return Message.fromFirestore(doc.data());
          }).toList();
        });
  }

  // Obtiene el ID del tipo de usuario actualmente logueado.
  // Retorna valores como "1" (paciente) o "3" (kinesiólogo).
  Future<String?> getCurrentUserTypeId() async {
    final uid = _auth.currentUser?.uid;

    if (uid == null) {
      print("Usuario no logueado, UID es null");
      return null;
    }

    try {
      final doc = await _firestore.collection('usuarios').doc(uid).get();
      final DocumentReference? tipoUsuarioRef = doc.data()?['tipo_usuario'];

      // Retorna el ID del documento referenciado.
      return tipoUsuarioRef?.id;
    } catch (e) {
      print("Error al obtener tipo_usuario: $e");
      return null;
    }
  }

  // Obtiene los contactos cuyo tipo de usuario es opuesto al del usuario actual.
  // Si el usuario es paciente (1), obtiene kinesiólogos (3).
  // Si es kinesiólogo (3), obtiene pacientes (1).
  Stream<QuerySnapshot> getContactsByType(String currentUserTypeId) {
    String targetTypeId;

    // Determina el tipo de contacto necesario.
    if (currentUserTypeId == '1') {
      targetTypeId = '3'; // Paciente busca kine.
    } else if (currentUserTypeId == '3') {
      targetTypeId = '1'; // Kine busca pacientes.
    } else {
      return Stream.empty();
      // Para cualquier otro valor, no devuelve contactos.
    }

    // Referencia al documento del tipo buscado.
    final DocumentReference targetRef = _firestore
        .collection('tipo_usuario')
        .doc(targetTypeId);

    // Consulta Firestore filtrando por tipo de usuario.
    return _firestore
        .collection('usuarios')
        .where('tipo_usuario', isEqualTo: targetRef)
        .where(FieldPath.documentId, isNotEqualTo: _auth.currentUser!.uid)
        .snapshots();
  }
}
