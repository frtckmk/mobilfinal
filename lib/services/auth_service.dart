import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_model.dart';
import 'database_service.dart'; // Öğrenci aramak için gerekli

class AuthService with ChangeNotifier {
  UserInfo? _currentUser;
  DatabaseService _databaseService;
  bool _seenOnboarding = false;

  AuthService(this._databaseService);

  void update(DatabaseService db) {
    _databaseService = db;
    notifyListeners();
  }

  UserInfo? get currentUser => _currentUser;
  bool get isAuthenticated => _currentUser != null;
  bool get isAdmin => _currentUser?.role == UserRole.admin;
  bool get isParent => _currentUser?.role == UserRole.parent;
  bool get seenOnboarding => _seenOnboarding;

  Future<void> checkOnboardingStatus() async {
    final prefs = await SharedPreferences.getInstance();
    _seenOnboarding = prefs.getBool('seenOnboarding') ?? false;
    notifyListeners();
  }

  // Mock Login (Öğrenci & Admin)
  Future<bool> login(String email, String password) async {
    await Future.delayed(const Duration(seconds: 1)); 

    if (email.isNotEmpty && password.isNotEmpty) {
      if (email.contains('admin')) {
        _currentUser = UserInfo(
          uid: 'admin1',
          email: email,
          fullName: 'Yurt Yöneticisi',
          role: UserRole.admin,
        );
      } else {
        // Mock veritabanından öğrenci bulmaya çalışalım (gerçekte backend yapar)
        UserInfo? student = _databaseService.students.firstWhere(
          (s) => s.email == email, 
          orElse: () => UserInfo(uid: '', email: '', fullName: '')
        );

        if (student.uid.isNotEmpty) {
           _currentUser = student;
        } else {
           // Fallback demo user if not found in list but correct credentials format
           _currentUser = UserInfo(
            uid: 'student1',
            email: email,
            fullName: 'Ahmet Yılmaz',
            role: UserRole.student,
            studentId: '2023001',
            roomNumber: '101',
            parentName: 'Mehmet Yılmaz',
            parentPhone: '5551234567',
            penaltyPoints: 0,
          );
        }
      }
      notifyListeners();
      return true;
    }
    return false;
  }

  // Veli Girişi (Telefon + OTP)
  Future<bool> loginAsParent(String phone, String otp) async {
    await Future.delayed(const Duration(seconds: 1));
    
    // OTP kontrolü (simülasyon: her kod kabul 1234 hariç)
    if (otp.length < 4) return false;

    // Telefon numarasına sahip öğrenciyi bul
    try {
      final student = _databaseService.students.firstWhere((s) => s.parentPhone == phone);
      
      _currentUser = UserInfo(
        uid: 'parent_${student.uid}',
        email: phone, // Email yerine telefon
        fullName: student.parentName ?? 'Veli',
        role: UserRole.parent,
        studentId: student.studentId, // Çocuğunun ID'si
      );
      notifyListeners();
      return true;
    } catch (e) {
      // Öğrenci bulunamadı
      return false;
    }
  }

  // Mock Register
  Future<bool> register({
    required String email,
    required String password,
    required String fullName,
    required UserRole role, // Rol eklendi
    String? studentId, // Opsiyonel
    String? roomNumber, // Opsiyonel
    String? parentName, // Opsiyonel
    String? parentPhone, // Opsiyonel
    String? affinity, // YENİ: Veli için yakınlık
    String? phoneNumber, // YENİ: Öğrenci telefonu
  }) async {
    await Future.delayed(const Duration(seconds: 1));
    
    final newUser = UserInfo(
      uid: DateTime.now().millisecondsSinceEpoch.toString(),
      email: email,
      fullName: fullName,
      role: role,
      studentId: studentId,
      roomNumber: roomNumber,
      parentName: parentName,
      parentPhone: parentPhone,
      penaltyPoints: 0,
      affinity: affinity,
      phoneNumber: phoneNumber,
    );
    
    // _currentUser = newUser; // Artık otomatik giriş yapmıyoruz
    
    // Eğer Veli ise ve Öğrenci No girilmişse, o öğrencinin veli bilgisini güncelle
    if (role == UserRole.parent && studentId != null && studentId.isNotEmpty) {
      bool linked = _databaseService.updateStudentParentInfo(
        studentId, 
        fullName, 
        email, // Veli giriş telefonu (email parametresinde geliyor)
        affinity ?? 'Veli'
      );
      if (!linked) {
        // Öğrenci bulunamadıysa ne yapılmalı?
        // Şimdilik veliyi yine de kaydediyoruz ama öğrenci bulunamadı diyebiliriz.
      }
    }

    // Database servisine de ekleyelim ki listelerde çıksın
     _databaseService.addStudent(newUser);

    notifyListeners();
    return true;
  }

  void logout() {
    _currentUser = null;
    notifyListeners();
  }
}
