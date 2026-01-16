enum UserRole {
  student,
  admin,
  parent
}

class UserInfo {
  final String uid;
  final String email; // Veli için telefon no tutabilir veya boş olabilir
  final String fullName;
  final UserRole role;
  final String? studentId; // Öğrenci için kendi nosu, Veli için çocuğunun ID'si
  final String? roomNumber;
  final String? parentName;
  final String? parentPhone;
  final int penaltyPoints;
  final String? affinity; // YENİ: Veli için yakınlık derecesi
  final String? phoneNumber; // YENİ: Öğrenci için telefon numarası

  UserInfo({
    required this.uid,
    required this.email,
    required this.fullName,
    this.role = UserRole.student,
    this.studentId,
    this.roomNumber,
    this.parentName,
    this.parentPhone,
    this.penaltyPoints = 0,
    this.affinity,
    this.phoneNumber,
  });

  factory UserInfo.fromJson(Map<String, dynamic> json) {
    UserRole getRole(String? r) {
      if (r == 'admin') return UserRole.admin;
      if (r == 'parent') return UserRole.parent;
      return UserRole.student;
    }

    return UserInfo(
      uid: json['uid'],
      email: json['email'],
      fullName: json['fullName'],
      role: getRole(json['role']),
      studentId: json['studentId'],
      roomNumber: json['roomNumber'],
      parentName: json['parentName'],
      parentPhone: json['parentPhone'],
      penaltyPoints: json['penaltyPoints'] ?? 0,
      affinity: json['affinity'],
      phoneNumber: json['phoneNumber'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'uid': uid,
      'email': email,
      'fullName': fullName,
      'role': role.toString().split('.').last,
      'studentId': studentId,
      'roomNumber': roomNumber,
      'parentName': parentName,
      'parentPhone': parentPhone,
      'penaltyPoints': penaltyPoints,
      'affinity': affinity,
      'phoneNumber': phoneNumber,
    };
  }
}
