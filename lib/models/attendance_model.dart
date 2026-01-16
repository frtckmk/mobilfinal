enum AttendanceStatus {
  present, // Yurtta
  onLeave, // İzinli/Evci
  absent,  // Yoklama yapmadı/Yurtta değil
}

class AttendanceModel {
  final String id;
  final String studentId;
  final DateTime date;
  final AttendanceStatus status;
  final DateTime timestamp;

  AttendanceModel({
    required this.id,
    required this.studentId,
    required this.date,
    required this.status,
    required this.timestamp,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'studentId': studentId,
      'date': date.toIso8601String(),
      'status': status.toString(),
      'timestamp': timestamp.toIso8601String(),
    };
  }
}
