class Message {
  final int senderId;
  final int receiverId;
  final String content;
  final String nonce;
  final String mac;
  final String senderPublicEphemeral;

  Message({
    required this.senderId,
    required this.receiverId,
    required this.content,
    required this.nonce,
    required this.mac,
    required this.senderPublicEphemeral,
  });

  factory Message.fromJson(Map<String, dynamic> json) => Message(
        senderId: json['sender_id'],
        receiverId: json['receiver_id'],
        content: json['content'],
        nonce: json['nonce'],
        mac: json['mac'],
        senderPublicEphemeral: json['sender_public_ephemeral'],
      );
}
