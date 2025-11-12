// lib/services/chat_service.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/message.dart';

class ChatService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // 🔹 Genera un ID de chat consistente entre dos usuarios.
  String getChatRoomId(String userId1, String userId2) {
    List<String> ids = [userId1, userId2];
    ids.sort();
    return ids.join("_");
  }

  // 🔹 Envía un nuevo mensaje y actualiza el chat.
  Future<void> sendMessage(String receiverId, String content) async {
    final String currentUserId = _auth.currentUser!.uid;
    final String currentUserEmail = _auth.currentUser!.email ?? "SinEmail";
    final Timestamp timestamp = Timestamp.now();

    // Crear objeto mensaje
    Message newMessage = Message(
      senderId: currentUserId,
      senderEmail: currentUserEmail,
      receiverId: receiverId,
      content: content,
      timestamp: timestamp,
    );

    // ID único del chat
    String chatRoomId = getChatRoomId(currentUserId, receiverId);

    try {
      // 🔸 Actualiza o crea el documento principal del chat
      await _firestore.collection('chats').doc(chatRoomId).set({
        'participants': [currentUserId, receiverId],
        'lastMessage': content,
        'lastMessageTimestamp': timestamp,
        'updatedAt': timestamp,
      }, SetOptions(merge: true));

      // 🔸 Agrega el mensaje en la subcolección "messages"
      await _firestore
          .collection('chats')
          .doc(chatRoomId)
          .collection('messages')
          .add({
            ...newMessage.toMap(),
            'chatId': chatRoomId, // 🟢 IMPORTANTE para notificaciones
            'messageType': 'texto', // puede ser texto, imagen, etc.
            'read': false, // para futuras funciones
          });

      print("✅ Mensaje enviado correctamente a $receiverId");
    } catch (e) {
      print("❌ Error al enviar mensaje: $e");
      rethrow;
    }
  }

  // 🔹 Stream de mensajes en tiempo real.
  Stream<List<Message>> getMessages(String userId, String otherUserId) {
    String chatRoomId = getChatRoomId(userId, otherUserId);

    return _firestore
        .collection('chats')
        .doc(chatRoomId)
        .collection('messages')
        .orderBy('timestamp', descending: false)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map((doc) {
            return Message.fromFirestore(doc.data());
          }).toList();
        });
  }

  // 🔹 Obtiene el ID del tipo de usuario (1 = paciente, 3 = kine)
  Future<String?> getCurrentUserTypeId() async {
    final uid = _auth.currentUser?.uid;

    if (uid == null) {
      print("⚠️ Usuario no logueado, UID es null");
      return null;
    }

    try {
      final doc = await _firestore.collection('usuarios').doc(uid).get();
      final DocumentReference? tipoUsuarioRef = doc.data()?['tipo_usuario'];
      return tipoUsuarioRef?.id;
    } catch (e) {
      print("Error al obtener tipo_usuario: $e");
      return null;
    }
  }

  // 🔹 Obtiene los contactos del tipo opuesto
  Stream<QuerySnapshot> getContactsByType(String currentUserTypeId) {
    String targetTypeId;

    if (currentUserTypeId == '1') {
      targetTypeId = '3';
    } else if (currentUserTypeId == '3') {
      targetTypeId = '1';
    } else {
      return Stream.empty();
    }

    final DocumentReference targetRef = _firestore
        .collection('tipo_usuario')
        .doc(targetTypeId);

    return _firestore
        .collection('usuarios')
        .where('tipo_usuario', isEqualTo: targetRef)
        .where(FieldPath.documentId, isNotEqualTo: _auth.currentUser!.uid)
        .snapshots();
  }
}
