// lib/models/message.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class Message {
  final String senderId;
  final String senderEmail;
  final String receiverId;
  final String content;
  final Timestamp timestamp;

  Message({
    required this.senderId,
    required this.senderEmail,
    required this.receiverId,
    required this.content,
    required this.timestamp,
  });

  factory Message.fromFirestore(Map<String, dynamic> data) {
    return Message(
      senderId: data['senderId'] as String? ?? '',
      senderEmail: data['senderEmail'] as String? ?? '',
      receiverId: data['receiverId'] as String? ?? '',
      content: data['content'] as String? ?? '',
      timestamp: data['timestamp'] as Timestamp? ?? Timestamp.now(),
    );
  }

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
