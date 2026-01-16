import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../constants/app_colors.dart';
import '../../constants/app_strings.dart';
import '../../services/auth_service.dart';

class ParentLoginScreen extends StatefulWidget {
  const ParentLoginScreen({super.key});

  @override
  State<ParentLoginScreen> createState() => _ParentLoginScreenState();
}

class _ParentLoginScreenState extends State<ParentLoginScreen> {
  final _phoneController = TextEditingController();
  final _otpController = TextEditingController(); // Basitlik için tek alan
  bool _codeSent = false;
  bool _isLoading = false;

  void _sendCode() async {
    if (_phoneController.text.isEmpty) return;
    setState(() => _isLoading = true);
    await Future.delayed(const Duration(seconds: 1)); // Simülasyon
    setState(() {
      _isLoading = false;
      _codeSent = true;
    });
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Doğrulama kodu gönderildi: 1234')),
      );
    }
  }

  void _verifyAndLogin() async {
    setState(() => _isLoading = true);
    final authService = Provider.of<AuthService>(context, listen: false);
    
    // Test için OTP 1234
    bool success = await authService.loginAsParent(
      _phoneController.text.trim(),
      _otpController.text.trim(),
    );

    setState(() => _isLoading = false);

    if (!success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Giriş başarısız. Numara kayıtlı olmayabilir veya kod yanlış.')),
      );
    } else if (success && mounted) {
      // Başarılı giriş
       // Navigator stack'ini temizle ve AuthWrapper'ın yeniden tetiklenmesini sağla
       Navigator.of(context).popUntil((route) => route.isFirst);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Veli Girişi'), backgroundColor: AppColors.secondary),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            const Icon(Icons.sms_failed_outlined, size: 64, color: AppColors.secondary),
            const SizedBox(height: 24),
            Text(
              _codeSent ? 'Doğrulama Kodu' : 'Telefon Numarası',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              _codeSent 
                ? 'Lütfen telefonunuza gelen 4 haneli kodu giriniz.' 
                : 'Sistemde kayıtlı telefon numaranızla giriş yapınız.',
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 32),
            
            if (!_codeSent)
              TextField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(
                  labelText: 'Telefon Numarası',
                  prefixIcon: Icon(Icons.phone),
                  hintText: '0555...',
                ),
              )
            else
              TextField(
                controller: _otpController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Doğrulama Kodu (OTP)',
                  prefixIcon: Icon(Icons.lock_clock),
                  counterText: '',
                ),
                maxLength: 4,
              ),
              
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _isLoading ? null : (_codeSent ? _verifyAndLogin : _sendCode),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.secondary,
                  foregroundColor: Colors.white,
                ),
                child: _isLoading 
                  ? const CircularProgressIndicator(color: Colors.white)
                  : Text(_codeSent ? 'GİRİŞ YAP' : 'KOD GÖNDER'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
