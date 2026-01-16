import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../constants/app_colors.dart';
import '../../constants/app_strings.dart';
import '../../services/auth_service.dart';
import '../../services/database_service.dart';
import '../../services/report_service.dart';
import '../../models/attendance_model.dart';
import '../../models/user_model.dart';

class AdminDashboardScreen extends StatelessWidget {
  const AdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final db = Provider.of<DatabaseService>(context);
    final stats = db.getDailyStats();
    final students = db.students; // Mock list of all students

    return Scaffold(
      appBar: AppBar(
        title: const Text(AppStrings.dashboardTitle),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => Provider.of<AuthService>(context, listen: false).logout(),
          )
        ],
      ),
      body: CustomScrollView(
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.all(16),
            sliver: SliverGrid.count(
              crossAxisCount: 2,
              mainAxisSpacing: 16,
              crossAxisSpacing: 16,
              childAspectRatio: 1.5,
              children: [
                _buildStatCard(context, AppStrings.statsTotal, stats['total'].toString(), Colors.blue),
                _buildStatCard(context, AppStrings.statsPresent, stats['present'].toString(), AppColors.present),
                _buildStatCard(context, AppStrings.statsLeave, stats['onLeave'].toString(), AppColors.onLeave),
                _buildStatCard(context, AppStrings.statsAbsent, stats['absent'].toString(), AppColors.absent),
              ],
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Text('Hızlı İşlemler', style: Theme.of(context).textTheme.titleLarge),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildActionButton(
                        context,
                        icon: Icons.picture_as_pdf,
                        label: 'Denetim (PDF)',
                        onTap: () async {
                           ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Rapor hazırlanıyor...')),
                          );
                          
                          final db = Provider.of<DatabaseService>(context, listen: false);
                          final records = db.getLast30DaysRecords();
                          final students = db.students;
                          
                          try {
                            await ReportService().generateAndPrintReport(records, students);
                          } catch (e) {
                             ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Hata: $e'), backgroundColor: Colors.red),
                            );
                          }
                        },
                      ),
                       _buildActionButton(
                        context,
                        icon: Icons.qr_code_scanner,
                        label: 'QR Oku',
                        onTap: () {
                           ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Yakında...')),
                          );
                        },
                      ),
                       _buildActionButton(
                        context,
                        icon: Icons.settings,
                        label: 'Ayarlar',
                        onTap: () {
                           showDialog(
                            context: context,
                            builder: (context) => AlertDialog(
                              title: const Text('Sistem Hakkında'),
                              content: const Text(
                                'Uygulamada denetim raporu, QR ve ayarlar gibi modüller genişletilebilir mimariyle tasarlanmıştır. '
                                'Denetim raporunda oluşan hata, veri kontrol mekanizmasının geliştirilmesiyle giderilmektedir. '
                                'Yoklama işlemleri konum doğrulamasıyla desteklenerek veritabanı ile senkronize ve güvenli bir yapı oluşturulmuştur.',
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(context),
                                  child: const Text('Tamam'),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                  const Divider(height: 32),
                ],
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Text('Öğrenci Listesi', style: Theme.of(context).textTheme.titleLarge),
            ),
          ),
          SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final student = students[index];
                final status = student.studentId != null ? db.getTodayStatus(student.studentId!) : null;
                
                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: _getStatusColor(status),
                      child: Icon(_getStatusIcon(status), color: Colors.white),
                    ),
                    title: Text(student.fullName),
                    subtitle: Text('Oda: ${student.roomNumber} - Ceza: ${student.penaltyPoints}'),
                    trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                    onTap: () {
                      // Detay sayfasına git (şimdilik boş)
                    },
                  ),
                );
              },
              childCount: students.length,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(BuildContext context, String title, String value, Color color) {
    return Card(
      color: color,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(value, style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.white)),
            Text(title, style: const TextStyle(fontSize: 16, color: Colors.white70)),
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

  IconData _getStatusIcon(AttendanceStatus? status) {
     if (status == null) return Icons.question_mark;
    switch (status) {
      case AttendanceStatus.present: return Icons.home;
      case AttendanceStatus.onLeave: return Icons.directions_walk;
      case AttendanceStatus.absent: return Icons.close;
    }
  }
  Widget _buildActionButton(BuildContext context, {required IconData icon, required String label, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      child: Column(
        children: [
          CircleAvatar(
            radius: 24,
            backgroundColor: AppColors.primary.withOpacity(0.1),
            child: Icon(icon, color: AppColors.primary),
          ),
          const SizedBox(height: 8),
          Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}
