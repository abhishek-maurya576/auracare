import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart' as provider;
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'screens/splash_screen.dart';
import 'screens/auth_screen.dart';
import 'screens/home_screen.dart';
import 'screens/onboarding_screen.dart';
import 'providers/auth_provider.dart';
import 'providers/mood_provider.dart';
import 'providers/user_profile_provider.dart';
import 'providers/journal_provider.dart';
import 'providers/crisis_alert_provider.dart';
import 'utils/app_colors.dart';
import 'providers/api_status_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  try {
    // Initialize Firebase
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    debugPrint('Firebase initialized successfully');
  } catch (e) {
    debugPrint('Error initializing Firebase: $e');
  }
  
  // Create API status provider first to validate API configuration
  final apiStatusProvider = ApiStatusProvider();
  
  // Validate API configuration (don't await to avoid blocking app startup)
  apiStatusProvider.validateApiConfiguration().then((isValid) {
    if (!isValid) {
      debugPrint('⚠️ API validation failed - some features may not work correctly');
    } else {
      debugPrint('✅ API validation successful');
    }
  });
  
  runApp(
    provider.MultiProvider(
      providers: [
        provider.ChangeNotifierProvider.value(value: apiStatusProvider),
        provider.ChangeNotifierProvider(create: (_) => AuthProvider()),
        provider.ChangeNotifierProvider(create: (_) => MoodProvider()),
        provider.ChangeNotifierProvider(create: (_) => UserProfileProvider()),
        provider.ChangeNotifierProvider(create: (_) => JournalProvider()),
        provider.ChangeNotifierProvider(create: (_) => CrisisAlertProvider()),
      ],
      child: const AuraCareApp(),
    ),
  );
}

class AuraCareApp extends StatelessWidget {
  const AuraCareApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'AuraCare',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        // Use Google Fonts for better typography
        textTheme: GoogleFonts.interTextTheme(
          Theme.of(context).textTheme.apply(
            bodyColor: AppColors.textPrimary,
            displayColor: AppColors.textPrimary,
          ),
        ),
        primarySwatch: Colors.blue,
        scaffoldBackgroundColor: Colors.transparent,
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.transparent,
          elevation: 0,
          titleTextStyle: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 20,
            fontWeight: FontWeight.w700,
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.accentTeal.withValues(alpha: 0.85),
            foregroundColor: AppColors.textPrimary,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          ),
        ),
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(
            foregroundColor: AppColors.textPrimary,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
        iconTheme: const IconThemeData(
          color: AppColors.textPrimary,
        ),
        useMaterial3: true,
      ),
      // Define named routes
      initialRoute: '/',
      routes: {
        '/': (context) => const SplashScreen(),
        '/auth': (context) => const AuthScreen(),
        '/home': (context) => const HomeScreen(),
        '/onboarding': (context) => const OnboardingScreen(),
      },
      // Add onGenerateRoute for handling undefined routes
      onGenerateRoute: (settings) {
        // If route is not found, redirect to splash screen
        return MaterialPageRoute(builder: (context) => const SplashScreen());
      },
    );
  }
}
