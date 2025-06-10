class Message {
  final String id;
  final int consultationId;
  final int senderId;
  final int receiverId;
  final String type; // 'text', 'image', 'audio', 'pdf'
  final String content; // peut être texte ou URL de fichier
  final String status; // 'sent', 'read'
  final DateTime createdAt;

  Message({
    required this.id,
    required this.consultationId,
    required this.senderId,
    required this.receiverId,
    required this.type,
    required this.content,
    required this.status,
    required this.createdAt,
  });

  factory Message.fromJson(Map<String, dynamic> json) => Message(
        id: json['id'].toString(),
        consultationId: json['consultation_id'],
        senderId: json['sender_id'],
        receiverId: json['receiver_id'],
        type: json['type'],
        content: json['ciphertext'] ?? '',
        status: json['status'],
        createdAt: DateTime.parse(json['created_at']),
      );
}
