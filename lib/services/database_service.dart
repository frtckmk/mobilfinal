import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../models/attendance_model.dart';
import 'dart:math';

class DatabaseService with ChangeNotifier {
  // Mock Data Store
  final List<AttendanceModel> _attendanceRecords = [];
  final List<UserInfo> _students = [
    UserInfo(
      uid: 'student1',
      email: 'ahmet@ogrenci.com',
      fullName: 'Ahmet Yılmaz',
      studentId: '2023001',
      roomNumber: '101',
      parentName: 'Mehmet Yılmaz',
      parentPhone: '5551112233',
      penaltyPoints: 0,
    ),
    UserInfo(
      uid: 'student2',
      email: 'ayse@ogrenci.com',
      fullName: 'Ayşe Demir',
      studentId: '2023002',
      roomNumber: '102',
      parentName: 'Fatma Demir',
      parentPhone: '5554445566',
      penaltyPoints: 5,
    ),
     UserInfo(
      uid: 'student3',
      email: 'mehmet@ogrenci.com',
      fullName: 'Mehmet Kaya',
      studentId: '2023003',
      roomNumber: '103',
      parentName: 'Ali Kaya',
      parentPhone: '5557778899',
      penaltyPoints: 0,
    ),
  ];

  List<UserInfo> get students => _students;

  void addStudent(UserInfo student) {
    _students.add(student);
    notifyListeners();
  }

  // Veli kayıt olduğunda öğrenci bilgisini güncelle
  bool updateStudentParentInfo(String studentId, String parentName, String parentPhone, String affinity) {
    try {
      final index = _students.indexWhere((s) => s.studentId == studentId);
      if (index != -1) {
        final old = _students[index];
        _students[index] = UserInfo(
          uid: old.uid,
          email: old.email,
          fullName: old.fullName,
          role: old.role,
          studentId: old.studentId,
          roomNumber: old.roomNumber,
          parentName: parentName,
          parentPhone: parentPhone,
          penaltyPoints: old.penaltyPoints,
          affinity: affinity,
          phoneNumber: old.phoneNumber,
        );
        notifyListeners();
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  // Bugünün yoklamasını getir
  AttendanceStatus? getTodayStatus(String studentId) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    
    try {
      final record = _attendanceRecords.firstWhere(
        (a) => a.studentId == studentId && 
               a.date.year == today.year && 
               a.date.month == today.month && 
               a.date.day == today.day
      );
      return record.status;
    } catch (e) {
      return null;
    }
  }

  // Yoklama Ver
  Future<void> submitAttendance(String studentId, AttendanceStatus status) async {
    await Future.delayed(const Duration(milliseconds: 500));
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    // Varsa güncelle, yoksa ekle (Mock: basitçe listeye ekle, eskisini sil)
    _attendanceRecords.removeWhere((a) => a.studentId == studentId && 
               a.date.year == today.year && 
               a.date.month == today.month && 
               a.date.day == today.day);

    _attendanceRecords.add(AttendanceModel(
      id: Random().nextInt(10000).toString(),
      studentId: studentId,
      date: today,
      status: status,
      timestamp: now,
    ));
    notifyListeners();
  }

  // Acil Durum Bildirimi
  Future<void> sendEmergencyAlert(String studentId) async {
    // Admin'e bildirim gönderme simülasyonu
    print('EMERGENCY ALERT FROM STUDENT: $studentId');
    await Future.delayed(const Duration(seconds: 1));
  }

  // İstatistikler (Admin Dashboard)
  Map<String, int> getDailyStats() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    
    int present = 0;
    int onLeave = 0;
    int absent = 0;

    // Sadece bugünün kayıtları
    final todayRecords = _attendanceRecords.where((a) => 
      a.date.year == today.year && 
      a.date.month == today.month && 
      a.date.day == today.day
    );

    for (var record in todayRecords) {
      if (record.status == AttendanceStatus.present) present++;
      if (record.status == AttendanceStatus.onLeave) onLeave++;
      if (record.status == AttendanceStatus.absent) absent++;
    }
    
    // Henüz işlem yapmamış olanlar (Toplam öğrenci - kayıtlılar)
    // Basitlik için sadece kayıtlıları sayıyoruz veya varsayılan olarak göstermiyoruz.
    // Gerçek senaryoda eksik olanlar = Toplam Öğrenci - (Present + OnLeave) olarak hesaplanır ve Absent sayılır.
    
    return {
      'present': present,
      'onLeave': onLeave,
      'absent': absent, // Bu örnekte sadece açıkça "yurtta değil" diyenler.
      'total': _students.length,
    };
  }

  // Rapor için son 30 günlük veriler (Mock Data Generation included)
  List<AttendanceModel> getLast30DaysRecords() {
    // Mevcut kayıtlara ek olarak geçmiş veri simülasyonu yapalım eğer boşsa
    if (_attendanceRecords.length < 10) {
      final now = DateTime.now();
      final random = Random();
      
      for (var student in _students) {
        if (student.studentId == null) continue;
        for (int i = 1; i <= 30; i++) {
          final date = now.subtract(Duration(days: i));
          // %80 Yurtta, %10 İzinli, %10 Yok
          final r = random.nextDouble();
          AttendanceStatus s = AttendanceStatus.present;
          if (r > 0.9) s = AttendanceStatus.absent;
          else if (r > 0.8) s = AttendanceStatus.onLeave;
          
          _attendanceRecords.add(AttendanceModel(
            id: 'mock_${student.uid}_$i',
            studentId: student.studentId ?? 'unknown',
            date: date,
            status: s,
            timestamp: date.add(const Duration(hours: 22)),
          ));
        }
      }
    }

    final cutoff = DateTime.now().subtract(const Duration(days: 30));
    return _attendanceRecords.where((a) => a.date.isAfter(cutoff)).toList();
  }
}
