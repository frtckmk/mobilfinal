import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../constants/app_colors.dart';
import '../../constants/app_strings.dart';
import '../../services/auth_service.dart';
import '../../models/user_model.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  
  // Form Keys
  final _studentFormKey = GlobalKey<FormState>(); // Geri eklendi
  final _adminFormKey = GlobalKey<FormState>();
  final _parentFormKey = GlobalKey<FormState>(); // YENİ: Veli Form
  
  // Student Controllers
  final _sFullNameController = TextEditingController();
  final _sEmailController = TextEditingController();
  final _sPasswordController = TextEditingController();
  final _sStudentIdController = TextEditingController();
  final _sRoomNumberController = TextEditingController();
  final _sParentNameController = TextEditingController();
  final _sParentPhoneController = TextEditingController();
  final _sPhoneController = TextEditingController(); // YENİ: Öğrenci Telefon No
  
  // Admin Controllers
  final _aFullNameController = TextEditingController();
  final _aEmailController = TextEditingController();
  final _aPasswordController = TextEditingController();
  final _aPhoneController = TextEditingController();
  
  // Parent Controllers (YENİ)
  final _pFullNameController = TextEditingController();
  final _pPhoneController = TextEditingController();
  final _pAffinityController = TextEditingController();
  final _pPasswordController = TextEditingController(); // Veli şifresi (Opsiyonel / İlerleme için)
  
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this); // 3 Sekme: Öğrenci, Veli, Yönetici
  }

  @override
  void dispose() {
    _tabController.dispose();
    _sFullNameController.dispose();
    _sEmailController.dispose();
    _sPasswordController.dispose();
    _sStudentIdController.dispose();
    _sRoomNumberController.dispose();
    _sParentNameController.dispose();
    _sParentPhoneController.dispose();
    _sPhoneController.dispose();
    
    _aFullNameController.dispose();
    _aEmailController.dispose();
    _aPasswordController.dispose();
    _aPhoneController.dispose();

    _pFullNameController.dispose();
    _pPhoneController.dispose();
    _pAffinityController.dispose();
    _pPasswordController.dispose();
    super.dispose();
  }

  Future<void> _register(UserRole role) async {
    GlobalKey<FormState> formKey;
    if (role == UserRole.student) formKey = _studentFormKey;
    else if (role == UserRole.admin) formKey = _adminFormKey;
    else formKey = _parentFormKey;
    
    if (!formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    final authService = Provider.of<AuthService>(context, listen: false);

    bool success;
    if (role == UserRole.student) {
      success = await authService.register(
        email: _sEmailController.text.trim(),
        password: _sPasswordController.text.trim(),
        fullName: _sFullNameController.text.trim(),
        role: UserRole.student,
        studentId: _sStudentIdController.text.trim(),
        roomNumber: _sRoomNumberController.text.trim(),
        parentName: _sParentNameController.text.trim(),
        parentPhone: _sParentPhoneController.text.trim(),
        phoneNumber: _sPhoneController.text.trim(),
      );
    } else if (role == UserRole.admin) {
      success = await authService.register(
        email: _aEmailController.text.trim(),
        password: _aPasswordController.text.trim(),
        fullName: _aFullNameController.text.trim(),
        role: UserRole.admin,
        parentPhone: _aPhoneController.text.trim(),
      );
    } else {
      // Veli Kaydı
      success = await authService.register(
        email: _pPhoneController.text.trim(), // Veli email yerine telefon kullanabilir veya ayrı alan
        password: _pPasswordController.text.trim(),
        fullName: _pFullNameController.text.trim(),
        role: UserRole.parent,
        parentPhone: _pPhoneController.text.trim(),
        affinity: _pAffinityController.text.trim(),
        studentId: _sStudentIdController.text.trim(), // EKLENDİ
      );
    }

    setState(() => _isLoading = false);

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Kayıt başarılı! Lütfen giriş yapınız.'),
          backgroundColor: AppColors.success,
        ),
      );
      Navigator.pop(context);
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Bir hata oluştu.')),
      );
    }
  }

  // Validasyon: Türkçe karakter destekli
  String? _nameValidator(String? value) {
    if (value == null || value.isEmpty) return 'Bu alan gereklidir.';
    final nameRegex = RegExp(r'^[a-zA-ZçÇğĞıİöÖşŞüÜ ]+$');
    if (!nameRegex.hasMatch(value)) {
      return 'Geçersiz karakter (Sadece harf).';
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(AppStrings.registerTitle),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(icon: Icon(Icons.person), text: 'Öğrenci'),
            Tab(icon: Icon(Icons.family_restroom), text: 'Veli'),
            Tab(icon: Icon(Icons.admin_panel_settings), text: 'Yönetici'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildStudentForm(),
          _buildParentForm(),
          _buildAdminForm(),
        ],
      ),
    );
  }

  Widget _buildParentForm() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Form(
        key: _parentFormKey,
        child: Column(
          children: [
            const Padding(
              padding: EdgeInsets.only(bottom: 20),
              child: Text(
                'Veli kaydı için bilgilerinizi giriniz. Telefon numaranız öğrenci sistemiyle eşleşecektir.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey),
              ),
            ),
            TextFormField(
              controller: _pFullNameController,
              decoration: const InputDecoration(labelText: 'Ad Soyad', prefixIcon: Icon(Icons.person)),
              validator: _nameValidator,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _pPhoneController,
              decoration: const InputDecoration(labelText: 'Telefon Numarası', prefixIcon: Icon(Icons.phone)),
              keyboardType: TextInputType.phone,
              validator: (v) => v!.isEmpty ? 'Gerekli' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _pAffinityController,
              decoration: const InputDecoration(labelText: 'Yakınlık (Anne, Baba vb.)', prefixIcon: Icon(Icons.favorite)),
              validator: _nameValidator,
            ),
            const SizedBox(height: 12),
            // YENİ: Öğrenci Numarası Alanı
            TextFormField(
              controller: _sStudentIdController, // Öğrenci ID'sini buraya da bağlayabiliriz veya yeni controller
              decoration: const InputDecoration(labelText: 'Öğrenci Numarası (Çocuğunuzun Okul No)', prefixIcon: Icon(Icons.school)),
              validator: (v) => v!.isEmpty ? 'Öğrenciyle eşleşmek için gerekli' : null,
            ),
             const SizedBox(height: 12),
            TextFormField(
              controller: _pPasswordController,
              decoration: const InputDecoration(labelText: 'Şifre', prefixIcon: Icon(Icons.lock)),
              obscureText: true,
              validator: (v) => v!.isEmpty ? 'Gerekli' : null,
            ),
            const SizedBox(height: 24),
            _buildSubmitButton('VELİ KAYIT', () => _register(UserRole.parent)),
          ],
        ),
      ),
    );
  }

  Widget _buildStudentForm() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Form(
        key: _studentFormKey,
        child: Column(
          children: [
            TextFormField(
              controller: _sFullNameController,
              decoration: const InputDecoration(labelText: AppStrings.fullName),
              validator: _nameValidator, // Türkçe regex
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _sEmailController,
              decoration: const InputDecoration(labelText: AppStrings.email),
              validator: (v) => v!.isEmpty ? 'Gerekli' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _sPasswordController,
              decoration: const InputDecoration(labelText: AppStrings.password),
              obscureText: true,
              validator: (v) => v!.isEmpty ? 'Gerekli' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _sStudentIdController,
              decoration: const InputDecoration(labelText: AppStrings.studentId),
              validator: (v) => v!.isEmpty ? 'Gerekli' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _sPhoneController,
              decoration: const InputDecoration(labelText: 'Telefon Numarası'),
              keyboardType: TextInputType.phone,
              validator: (v) => v!.isEmpty ? 'Gerekli' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _sRoomNumberController,
              decoration: const InputDecoration(labelText: AppStrings.roomNumber),
              validator: (v) => v!.isEmpty ? 'Gerekli' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _sParentNameController,
              decoration: const InputDecoration(labelText: AppStrings.parentName),
              validator: _nameValidator,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _sParentPhoneController,
              decoration: const InputDecoration(labelText: AppStrings.parentPhone),
              keyboardType: TextInputType.phone,
              validator: (v) => v!.isEmpty ? 'Gerekli' : null,
            ),
            const SizedBox(height: 24),
            _buildSubmitButton('ÖĞRENCİ KAYIT', () => _register(UserRole.student)),
          ],
        ),
      ),
    );
  }

  Widget _buildAdminForm() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Form(
        key: _adminFormKey,
        child: Column(
          children: [
            const Padding(
              padding: EdgeInsets.only(bottom: 20),
              child: Text(
                'Yönetici hesabı oluşturmak için lütfen bilgilerinizi giriniz.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey),
              ),
            ),
            TextFormField(
              controller: _aFullNameController,
              decoration: const InputDecoration(labelText: AppStrings.fullName, prefixIcon: Icon(Icons.person)),
              validator: _nameValidator,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _aEmailController,
              decoration: const InputDecoration(labelText: AppStrings.email, prefixIcon: Icon(Icons.email)),
              validator: (v) => v!.isEmpty ? 'Gerekli' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _aPasswordController,
              decoration: const InputDecoration(labelText: AppStrings.password, prefixIcon: Icon(Icons.lock)),
              obscureText: true,
              validator: (v) => v!.isEmpty ? 'Gerekli' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _aPhoneController,
              decoration: const InputDecoration(labelText: 'Telefon Numarası', prefixIcon: Icon(Icons.phone)),
              keyboardType: TextInputType.phone,
              validator: (v) => v!.isEmpty ? 'Gerekli' : null,
            ),
            const SizedBox(height: 24),
            _buildSubmitButton('YÖNETİCİ KAYIT', () => _register(UserRole.admin)),
          ],
        ),
      ),
    );
  }

  Widget _buildSubmitButton(String text, VoidCallback onPressed) {
    return ElevatedButton(
      onPressed: _isLoading ? null : onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primary,
        minimumSize: const Size(double.infinity, 50),
      ),
      child: _isLoading 
        ? const CircularProgressIndicator(color: Colors.white)
        : Text(text, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
    );
  }
}
