class Attendance {
  int? id;
  String type;
  String date;
  String time;
  String? reason;
  String userEmail; // ⬅️ Tambahan

  Attendance({
    this.id,
    required this.type,
    required this.date,
    required this.time,
    this.reason,
    required this.userEmail,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'type': type,
      'date': date,
      'time': time,
      'reason': reason,
      'user_email': userEmail,
    };
  }

  factory Attendance.fromMap(Map<String, dynamic> map) {
    return Attendance(
      id: map['id'],
      type: map['type'],
      date: map['date'],
      time: map['time'],
      reason: map['reason'],
      userEmail: map['user_email'],
    );
  }
}
