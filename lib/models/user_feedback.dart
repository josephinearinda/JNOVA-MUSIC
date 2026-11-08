class UserFeedback {
  final String message;
  final String type;
  final String sender;
  final int rating;
  final DateTime submittedAt;

  const UserFeedback({
    required this.message,
    required this.type,
    required this.sender,
    required this.rating,
    required this.submittedAt,
  });

  factory UserFeedback.fromMap(Map<String, dynamic> map) {
    return UserFeedback(
      message: map['message'] as String,
      type: map['type'] as String,
      sender: map['sender_name'] as String,
      rating: (map['rating'] as num).toInt(),
      submittedAt: DateTime.parse(map['created_at'] as String).toLocal(),
    );
  }
}
