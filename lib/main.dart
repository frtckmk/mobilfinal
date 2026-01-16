import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'constants/app_colors.dart';
import 'services/auth_service.dart';
import 'services/database_service.dart';
import 'screens/auth/login_screen.dart';
import 'screens/student/student_home_screen.dart';
import 'screens/admin/admin_dashboard_screen.dart';
import 'screens/role_selection_screen.dart';
import 'screens/parent/parent_home_screen.dart';
import 'screens/onboarding_screen.dart';

void main() {
  runApp(const YurtNetApp());
}

class YurtNetApp extends StatelessWidget {
  const YurtNetApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => DatabaseService()), 
        ChangeNotifierProxyProvider<DatabaseService, AuthService>(
          create: (context) => AuthService(Provider.of<DatabaseService>(context, listen: false)),
          update: (context, db, auth) => auth!..update(db),
        ),
      ],
      child: MaterialApp(
        title: 'YurtNet',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          primaryColor: AppColors.primary,
          colorScheme: ColorScheme.fromSeed(seedColor: AppColors.primary, error: AppColors.error),
          scaffoldBackgroundColor: AppColors.background,
          useMaterial3: true,
          textTheme: GoogleFonts.interTextTheme(),
          appBarTheme: const AppBarTheme(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            centerTitle: true,
          ),
          elevatedButtonTheme: ElevatedButtonThemeData(
            style: ElevatedButton.styleFrom(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
          ),
          inputDecorationTheme: InputDecorationTheme(
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Colors.grey),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Colors.grey),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: AppColors.primary, width: 2),
            ),
          ),
        ),
        home: const AuthWrapper(),
      ),
    );
  }
}

class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  bool _isInit = true;

  @override
  void didChangeDependencies() {
    if (_isInit) {
      Provider.of<AuthService>(context, listen: false).checkOnboardingStatus();
      _isInit = false;
    }
    super.didChangeDependencies();
  }

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);

    // Onboarding kontrolü
    if (!authService.seenOnboarding) {
      return const OnboardingScreen();
    }

    if (!authService.isAuthenticated) {
      return RoleSelectionScreen();
    }

    if (authService.isAdmin) {
      return AdminDashboardScreen();
    } else if (authService.isParent) {
      return ParentHomeScreen();
    } else {
      return StudentHomeScreen();
    }
  }
}
