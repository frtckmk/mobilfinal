import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../constants/app_colors.dart';
import '../../constants/app_strings.dart';
import '../../services/auth_service.dart';
import '../../services/database_service.dart';
import '../../models/attendance_model.dart';
import 'package:intl/intl.dart';
import '../../models/user_model.dart'; // UserRole için eklendi

class ParentHomeScreen extends StatelessWidget {
  const ParentHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthService>(context);
    final db = Provider.of<DatabaseService>(context);
    
    final childId = auth.currentUser?.studentId;
    final childStatus = childId != null ? db.getTodayStatus(childId) : null;
    
    UserInfo? student;
    try {
      student = db.students.firstWhere((s) => s.studentId == childId);
    } catch (e) {
      student = UserInfo(
        uid: 'unknown',
        email: '',
        fullName: 'Öğrenci Bulunamadı',
        role: UserRole.student,
        roomNumber: '-',
      );
    }

    // Bildirim Mesajı Belirleme
    String notificationMessage = '';
    Color notificationColor = Colors.transparent;
    IconData notificationIcon = Icons.notifications_none;
    bool showNotification = false;

    if (childStatus == AttendanceStatus.absent) {
      showNotification = true;
      notificationMessage = 'UYARI: Öğrenciniz yurtta bulunmamaktadır! Sistem tarafından size ve öğrenciye SMS/Bildirim gönderilmiştir.';
      notificationColor = Colors.red.shade100;
      notificationIcon = Icons.warning_amber_rounded;
    } else if (childStatus == AttendanceStatus.present) {
       showNotification = true;
       notificationMessage = 'BİLGİ: Öğrenciniz şu an yurtta.';
       notificationColor = Colors.green.shade100;
       notificationIcon = Icons.check_circle_outline;
    } else if (childStatus == AttendanceStatus.onLeave) {
       showNotification = true;
       notificationMessage = 'BİLGİ: Öğrenciniz izinli.';
       notificationColor = Colors.orange.shade100;
       notificationIcon = Icons.info_outline;
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Veli Paneli'),
        backgroundColor: AppColors.secondary,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => auth.logout(),
          )
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
             // Bildirim Alanı (Simülasyon)
            if (showNotification)
              Container(
                margin: const EdgeInsets.only(bottom: 16),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: notificationColor,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: notificationColor.withOpacity(1).withBlue(50)),
                ),
                child: Row(
                  children: [
                    Icon(notificationIcon, color: Colors.black87),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        notificationMessage,
                        style: const TextStyle(color: Colors.black87, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              ),

            // Öğrenci Bilgi Kartı
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    const CircleAvatar(
                      radius: 40,
                      backgroundColor: Colors.grey,
                      child: Icon(Icons.person, size: 40, color: Colors.white),
                    ),
                    const SizedBox(height: 12),
                    Text(student.fullName, style: Theme.of(context).textTheme.headlineSmall),
                    const SizedBox(height: 4),
                    Text('Öğrenci No: ${student.studentId ?? "-"}', style: Theme.of(context).textTheme.titleMedium),
                    Text('Oda: ${student.roomNumber ?? "-"}', style: Theme.of(context).textTheme.bodyLarge),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            
            // Durum Kartı
            const Text('Bugünkü Durum', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: _getStatusColor(childStatus).withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: _getStatusColor(childStatus), width: 2),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                   Icon(_getStatusIcon(childStatus), size: 48, color: _getStatusColor(childStatus)),
                   const SizedBox(width: 16),
                   Text(
                    _getStatusText(childStatus), 
                    style: TextStyle(
                      fontSize: 24, 
                      fontWeight: FontWeight.bold,
                      color: _getStatusColor(childStatus)
                    )
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 24),
            const Text('Haftalık Özet', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            const SizedBox(height: 8),
            // Mock Geçmiş Listesi (Statik görüntü)
            ListView.builder(
              physics: const NeverScrollableScrollPhysics(),
              shrinkWrap: true,
              itemCount: 3,
              itemBuilder: (context, index) {
                final date = DateTime.now().subtract(Duration(days: index + 1));
                return ListTile(
                  leading: const Icon(Icons.check_circle, color: AppColors.success),
                  title: Text(DateFormat('dd.MM.yyyy').format(date)),
                  subtitle: const Text('Yurtta'),
                  trailing: const Text('23:00'),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Color _getStatusColor(AttendanceStatus? status) {
    if (status == null) return Colors.grey;
    switch (status) {
      case AttendanceStatus.present: return AppColors.present;
      case AttendanceStatus.onLeave: return AppColors.onLeave;
      case AttendanceStatus.absent: return AppColors.absent;
    }
  }

  String _getStatusText(AttendanceStatus? status) {
    if (status == null) return 'Veri Yok';
    switch (status) {
      case AttendanceStatus.present: return 'YURTTA';
      case AttendanceStatus.onLeave: return 'İZİNLİ';
      case AttendanceStatus.absent: return 'YOK';
    }
  }

  IconData _getStatusIcon(AttendanceStatus? status) {
     if (status == null) return Icons.question_mark;
    switch (status) {
      case AttendanceStatus.present: return Icons.home;
      case AttendanceStatus.onLeave: return Icons.directions_walk;
      case AttendanceStatus.absent: return Icons.close;
    }
  }
}
