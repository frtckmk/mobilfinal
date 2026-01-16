import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../constants/app_colors.dart';
import '../../constants/app_strings.dart';
import '../../models/attendance_model.dart';
import '../../models/user_model.dart';
import '../../services/auth_service.dart';
import '../../services/database_service.dart';
import 'attendance_wizard_screen.dart';

class StudentHomeScreen extends StatefulWidget {
  const StudentHomeScreen({super.key});

  @override
  State<StudentHomeScreen> createState() => _StudentHomeScreenState();
}

class _StudentHomeScreenState extends State<StudentHomeScreen> {
  bool _isLoading = false;

  void _submitAttendance(AttendanceStatus status) async {
    setState(() => _isLoading = true);
    final auth = Provider.of<AuthService>(context, listen: false);
    final db = Provider.of<DatabaseService>(context, listen: false);

    if (auth.currentUser?.studentId != null) {
      await db.submitAttendance(auth.currentUser!.studentId!, status);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text(AppStrings.attendanceSuccess), backgroundColor: AppColors.success),
        );
      }
    }
    setState(() => _isLoading = false);
  }

  void _sendEmergency() async {
    // Onay penceresi
    bool? confirm = await showDialog(
      context: context, 
      builder: (c) => AlertDialog(
        title: const Text('ACİL DURUM'),
        content: const Text('Yöneticiye acil durum bildirimi gönderilsin mi?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('İptal')),
          TextButton(onPressed: () => Navigator.pop(c, true), child: const Text('GÖNDER', style: TextStyle(color: AppColors.error))),
        ],
      )
    );

    if (confirm == true) {
      final auth = Provider.of<AuthService>(context, listen: false);
      final db = Provider.of<DatabaseService>(context, listen: false);
      if (auth.currentUser?.studentId != null) {
        await db.sendEmergencyAlert(auth.currentUser!.studentId!);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text(AppStrings.emergencyAlertSent), backgroundColor: AppColors.error),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = Provider.of<AuthService>(context).currentUser;
    final db = Provider.of<DatabaseService>(context); // Listen for updates
    
    // Anlık durum (veritabanından çek)
    final todayStatus = user?.studentId != null ? db.getTodayStatus(user!.studentId!) : null;

    return Scaffold(
      appBar: AppBar(
        title: const Text(AppStrings.appName),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => Provider.of<AuthService>(context, listen: false).logout(),
          )
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // User Greeting Card
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('${AppStrings.welcome} ${user?.fullName ?? ""}', style: Theme.of(context).textTheme.titleLarge),
                    const SizedBox(height: 8),
                    Text('${AppStrings.roomNumber}: ${user?.roomNumber ?? "-"}'),
                    Text('${AppStrings.penaltyPoints}: ${user?.penaltyPoints ?? 0}', style: const TextStyle(color: AppColors.error, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            
            // Status Indicator
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: _getStatusColor(todayStatus).withAlpha(50),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: _getStatusColor(todayStatus), width: 2),
              ),
              child: Column(
                children: [
                  Text(AppStrings.statusTitle, style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 8),
                  Text(
                    _getStatusText(todayStatus), 
                    style: TextStyle(
                      fontSize: 24, 
                      fontWeight: FontWeight.bold,
                      color: _getStatusColor(todayStatus)
                    )
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // Attendance Wizard Button
            if (todayStatus == null)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.touch_app),
                  label: const Text('YOKLAMA BAŞLAT'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.all(20),
                    textStyle: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const AttendanceWizardScreen()),
                    );
                  },
                ),
              )
            else
               // Zaten yoklama yapıldıysa mesaj göster
               const Center(
                 child: Padding(
                   padding: EdgeInsets.all(16.0),
                   child: Text(
                     'Bugünkü yoklamanız alındı. Değişiklik için yönetimle iletişime geçiniz.',
                     textAlign: TextAlign.center,
                     style: TextStyle(color: Colors.grey),
                   ),
                 ),
               ),

            const SizedBox(height: 48),
            
            // Emergency Button
            Padding(
              padding: const EdgeInsets.only(bottom: 24.0),
              child: ElevatedButton(
                onPressed: _sendEmergency,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.error,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 24),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(50)),
                  elevation: 8,
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.warning_amber_rounded, size: 32),
                    SizedBox(width: 8),
                    Text(AppStrings.emergencyButton, style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getStatusColor(AttendanceStatus? status) {
    switch (status) {
      case AttendanceStatus.present: return AppColors.present;
      case AttendanceStatus.onLeave: return AppColors.onLeave;
      case AttendanceStatus.absent: return AppColors.absent;
      default: return Colors.grey;
    }
  }

  String _getStatusText(AttendanceStatus? status) {
    switch (status) {
      case AttendanceStatus.present: return AppStrings.statusInDorm;
      case AttendanceStatus.onLeave: return AppStrings.statusOnLeave;
      case AttendanceStatus.absent: return AppStrings.statusNotInDorm;
      default: return 'Henüz Bildirilmedi';
    }
  }
}
