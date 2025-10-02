// lib/services/chat_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/message.dart';

class ChatService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Genera un ID de chat consistente entre dos usuarios.
  String getChatRoomId(String userId1, String userId2) {
    List<String> ids = [userId1, userId2];
    ids.sort();
    return ids.join("_");
  }

  // Envía un nuevo mensaje y actualiza el chat.
  Future<void> sendMessage(String receiverId, String content) async {
    final String currentUserId = _auth.currentUser!.uid;
    final String currentUserEmail = _auth.currentUser!.email!;
    final Timestamp timestamp = Timestamp.now();

    Message newMessage = Message(
      senderId: currentUserId,
      senderEmail: currentUserEmail,
      receiverId: receiverId,
      content: content,
      timestamp: timestamp,
    );

    String chatRoomId = getChatRoomId(currentUserId, receiverId);

    // Actualiza el documento principal del chat (Colección 'chats')
    await _firestore.collection('chats').doc(chatRoomId).set({
      'participants': [currentUserId, receiverId],
      'lastMessage': content,
      'lastMessageTimestamp': timestamp,
    }, SetOptions(merge: true));

    // Agrega el mensaje a la subcolección
    await _firestore
        .collection('chats')
        .doc(chatRoomId)
        .collection('messages')
        .add(newMessage.toMap());
  }

  // Stream para obtener mensajes en tiempo real.
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

  // Obtiene el ID del tipo de usuario (ej: '1' o '3') usando la referencia.
  Future<String?> getCurrentUserTypeId() async {
    final uid = _auth.currentUser?.uid;

    // 🚨 DEBUG CRÍTICO: Indica el estado de autenticación 🚨
    if (uid == null) {
      print(
        "DEBUG CRÍTICO: Usuario NO logueado. UID es NULL. Esto causa el error de permisos.",
      );
      return null;
    }
    print("DEBUG CRÍTICO: Usuario logueado. UID: $uid");

    try {
      // Colección 'usuarios'
      final doc = await _firestore.collection('usuarios').doc(uid).get();

      // Obtener la referencia de Firestore (campo 'tipo_usuario')
      final DocumentReference? tipoUsuarioRef = doc.data()?['tipo_usuario'];

      // Retorna el ID del documento referenciado ('1' o '3')
      return tipoUsuarioRef?.id;
    } catch (e) {
      print("Error al obtener tipo de usuario: $e");
      return null;
    }
  }

  // Filtra y obtiene los usuarios del tipo opuesto.
  Stream<QuerySnapshot> getContactsByType(String currentUserTypeId) {
    String targetTypeId;

    // Si soy '1' (Normal), busco '3' (Kine). Si soy '3', busco '1'.
    if (currentUserTypeId == '1') {
      targetTypeId = '3';
    } else if (currentUserTypeId == '3') {
      targetTypeId = '1';
    } else {
      return Stream.empty();
    }

    // Crea la referencia completa para el filtro: /tipo_usuario/{targetTypeId}
    final DocumentReference targetRef = _firestore
        .collection('tipo_usuario')
        .doc(targetTypeId);

    return _firestore
        .collection('usuarios') // Colección 'usuarios'
        .where(
          'tipo_usuario',
          isEqualTo: targetRef,
        ) // Filtra usando la REFERENCIA
        // No mostrarse a sí mismo
        .where(FieldPath.documentId, isNotEqualTo: _auth.currentUser!.uid)
        .snapshots();
  }
}
