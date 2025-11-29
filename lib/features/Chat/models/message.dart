// lib/models/message.dart

import 'package:cloud_firestore/cloud_firestore.dart';

// Se utiliza para mapear datos desde y hacia Firestore.
class Message {
  // ID del usuario que envía el mensaje.
  final String senderId;

  // Correo electrónico del remitente (útil para mostrar datos o logs).
  final String senderEmail;

  // ID del usuario que recibe el mensaje.
  final String receiverId;

  // Contenido del mensaje enviado.
  final String content;

  // Timestamp de Firestore que indica la fecha/hora exacta del envío.
  final Timestamp timestamp;

  // Constructor principal del modelo.
  Message({
    required this.senderId,
    required this.senderEmail,
    required this.receiverId,
    required this.content,
    required this.timestamp,
  });

  // Constructor que crea una instancia de Message usando datos obtenidos
  // desde Firestore. Proporciona valores por defecto en caso de campos nulos.
  factory Message.fromFirestore(Map<String, dynamic> data) {
    return Message(
      senderId: data['senderId'] as String? ?? '',
      senderEmail: data['senderEmail'] as String? ?? '',
      receiverId: data['receiverId'] as String? ?? '',
      content: data['content'] as String? ?? '',
      timestamp: data['timestamp'] as Timestamp? ?? Timestamp.now(),
    );
  }

  // Convierte una instancia de Message en un mapa compatible con Firestore.
  // Este método se usa para guardar o actualizar mensajes en la base de datos.
  Map<String, dynamic> toMap() {
    return {
      'senderId': senderId,
      'senderEmail': senderEmail,
      'receiverId': receiverId,
      'content': content,
      'timestamp': timestamp,
    };
  }
}
