class Message {
  final int senderId;
  final int receiverId;
  final String content;
  final String nonce;
  final String mac;
  final String senderPublicEphemeral;
  final String type; // 'text', 'choice', 'file', etc.
  final List<String>? options;

  Message({
    required this.senderId,
    required this.receiverId,
    required this.content,
    required this.nonce,
    required this.mac,
    required this.senderPublicEphemeral,
    this.type = 'text',
    this.options,
  });

  factory Message.fromJson(Map<String, dynamic> json) => Message(
        senderId: json['sender_id'],
        receiverId: json['receiver_id'],
        content: json['content'],
        nonce: json['nonce'],
        mac: json['mac'],
        senderPublicEphemeral: json['sender_public_ephemeral'],
        type: json['type'] ?? 'text',
        options:
            json['options'] != null ? List<String>.from(json['options']) : null,
      );
}
