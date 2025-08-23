import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart' as provider;
// Import for VoidCallback
import '../widgets/aura_background.dart';
import '../utils/app_colors.dart';
import '../providers/auth_provider.dart';
import 'auth_screen.dart';
import 'home_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  late AuthProvider _authProvider;
  late VoidCallback _authListener;

  @override
  void initState() {
    super.initState();
    _authProvider = provider.Provider.of<AuthProvider>(context, listen: false);
    _authListener = () {
      if (_authProvider.state != AuthState.initial && _authProvider.state != AuthState.loading) {
        _performNavigation();
      }
    };
    _authProvider.addListener(_authListener);

    // If auth state is already determined (e.g., hot restart), navigate immediately
    if (_authProvider.state != AuthState.initial && _authProvider.state != AuthState.loading) {
      _performNavigation();
    }
  }

  @override
  void dispose() {
    _authProvider.removeListener(_authListener);
    super.dispose();
  }

  void _performNavigation() {
    if (!mounted) return; // Ensure widget is still in tree

    Widget destination;
    if (_authProvider.isAuthenticated) {
      destination = const HomeScreen();
    } else {
      destination = const AuthScreen();
    }

    Navigator.pushReplacement(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => destination,
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
        transitionDuration: const Duration(milliseconds: 800),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Animated background
          const AuraBackground(),
          
          // Main content
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Logo placeholder - you can replace with actual logo
                Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: AppColors.auraGradient1,
                  ),
                  child: const Icon(
                    Icons.self_improvement_rounded,
                    size: 60,
                    color: AppColors.textPrimary,
                  ),
                )
                    .animate()
                    .scale(
                      duration: const Duration(milliseconds: 800),
                      curve: Curves.elasticOut,
                    )
                    .then()
                    .shimmer(
                      duration: const Duration(milliseconds: 1200),
                      color: AppColors.accentTeal,
                    ),

                const SizedBox(height: 32),

                // App name
                const Text(
                  'AuraCare',
                  style: TextStyle(
                    fontSize: 36,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                    letterSpacing: 1.2,
                  ),
                )
                    .animate(delay: const Duration(milliseconds: 400))
                    .fadeIn(duration: const Duration(milliseconds: 600))
                    .slideY(begin: 0.3, end: 0),

                const SizedBox(height: 16),

                // Tagline
                const Text(
                  'Your Mood, Your Mate, Your Mind',
                  style: TextStyle(
                    fontSize: 16,
                    color: AppColors.textSecondary,
                    letterSpacing: 0.5,
                  ),
                  textAlign: TextAlign.center,
                )
                    .animate(delay: const Duration(milliseconds: 800))
                    .fadeIn(duration: const Duration(milliseconds: 600))
                    .slideY(begin: 0.3, end: 0),

                const SizedBox(height: 48),

                // Loading indicator
                const BreathingDots()
                    .animate(delay: const Duration(milliseconds: 1200))
                    .fadeIn(duration: const Duration(milliseconds: 600)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
