import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../constants/app_colors.dart';
import '../../constants/app_strings.dart';
import '../../models/attendance_model.dart';
import '../../services/auth_service.dart';
import '../../services/database_service.dart';

class AttendanceWizardScreen extends StatefulWidget {
  const AttendanceWizardScreen({super.key});

  @override
  State<AttendanceWizardScreen> createState() => _AttendanceWizardScreenState();
}

class _AttendanceWizardScreenState extends State<AttendanceWizardScreen> {
  int _currentStep = 0;
  AttendanceStatus? _selectedStatus;
  bool _isLoading = false;

  final List<Map<String, dynamic>> _statusOptions = [
    {
      'status': AttendanceStatus.present,
      'title': AppStrings.statusInDorm,
      'icon': Icons.home,
      'color': AppColors.present,
    },
    {
      'status': AttendanceStatus.onLeave,
      'title': AppStrings.statusOnLeave,
      'icon': Icons.directions_walk,
      'color': AppColors.onLeave,
    },
    {
      'status': AttendanceStatus.absent,
      'title': AppStrings.statusNotInDorm,
      'icon': Icons.not_interested,
      'color': AppColors.absent,
    },
  ];

  void _nextStep() {
    if (_currentStep == 0 && _selectedStatus == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Lütfen bir durum seçiniz.')),
      );
      return;
    }
    setState(() => _currentStep++);
  }

  void _prevStep() {
    if (_currentStep > 0) {
      setState(() => _currentStep--);
    } else {
      Navigator.pop(context);
    }
  }

  void _submit() async {
    setState(() => _isLoading = true);
    final auth = Provider.of<AuthService>(context, listen: false);
    final db = Provider.of<DatabaseService>(context, listen: false);

    if (auth.currentUser?.studentId != null && _selectedStatus != null) {
      await db.submitAttendance(auth.currentUser!.studentId!, _selectedStatus!);
      if (mounted) {
        // İşlem başarılı, ana ekrana dön
        ScaffoldMessenger.of(context).showSnackBar(
           const SnackBar(content: Text(AppStrings.attendanceSuccess), backgroundColor: AppColors.success),
        );
        Navigator.pop(context);
      }
    }
    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Yoklama Bildirimi'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        children: [
          // İlerleme Çubuğu
          LinearProgressIndicator(
            value: (_currentStep + 1) / 2,
            backgroundColor: Colors.grey[200],
            valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: _currentStep == 0 ? _buildSelectionStep() : _buildConfirmationStep(),
          ),
          _buildBottomBar(),
        ],
      ),
    );
  }

  Widget _buildSelectionStep() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Lütfen bugünkü durumunuzu seçin:',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          Expanded(
            child: ListView.separated(
              itemCount: _statusOptions.length,
              separatorBuilder: (c, i) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final option = _statusOptions[index];
                final isSelected = _selectedStatus == option['status'];
                return InkWell(
                  onTap: () => setState(() => _selectedStatus = option['status']),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: isSelected ? option['color'].withOpacity(0.1) : Colors.white,
                      border: Border.all(
                        color: isSelected ? option['color'] : Colors.grey[300]!,
                        width: 2,
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Icon(option['icon'], color: option['color'], size: 32),
                        const SizedBox(width: 16),
                        Text(
                          option['title'],
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                            color: isSelected ? option['color'] : Colors.black87,
                          ),
                        ),
                        const Spacer(),
                        if (isSelected)
                          Icon(Icons.check_circle, color: option['color']),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConfirmationStep() {
    final option = _statusOptions.firstWhere((o) => o['status'] == _selectedStatus);
    
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.help_outline_rounded, size: 80, color: AppColors.primary),
          const SizedBox(height: 24),
          const Text(
            'İşlemi Onaylıyor Musunuz?',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          const Text(
            'Seçtiğiniz durum:',
            style: TextStyle(color: Colors.grey),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            decoration: BoxDecoration(
              color: option['color'],
              borderRadius: BorderRadius.circular(30),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(option['icon'], color: Colors.white),
                const SizedBox(width: 8),
                Text(
                  option['title'],
                  style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),
          const Text(
            'Bu işlem geri alınamaz ve velinize bildirim olarak düşebilir.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 12, color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomBar() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 4, offset: const Offset(0, -2))],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          TextButton(
            onPressed: _isLoading ? null : _prevStep,
            child: const Text('GERİ', style: TextStyle(fontSize: 16)),
          ),
          ElevatedButton(
            onPressed: _isLoading ? null : (_currentStep == 0 ? _nextStep : _submit),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
            ),
            child: _isLoading
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                : Text(_currentStep == 0 ? 'İLERİ' : 'ONAYLA', style: const TextStyle(fontSize: 16)),
          ),
        ],
      ),
    );
  }
}
