import 'package:afrilyft/views/pages/login_page.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../theme/app_colors.dart';
import '../../controllers/auth_controller.dart';
import 'onboarding_page.dart';
import '../home_view.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;
  final AuthController _authController = Get.find<AuthController>();

  @override
  void initState() {
    super.initState();

    // Configuration des animations
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.0, 0.5, curve: Curves.easeIn),
      ),
    );

    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.0, 0.5, curve: Curves.easeOut),
      ),
    );

    // Démarrer l'animation
    _animationController.forward();

    // Navigation vers la page appropriée après un délai
    Future.delayed(const Duration(seconds: 3), () {
      _navigateToNextScreen();
    });
  }

  void _navigateToNextScreen() async {
    // If user is authenticated, wait for profile to load then go to home
    if (_authController.isAuthenticated.value) {
      // Wait a bit for profile to load
      await Future.delayed(const Duration(milliseconds: 500));

      // Check if profile is loaded
      if (_authController.userProfile.value != null) {
        Get.offAll(() => const HomeView(), transition: Transition.fadeIn);
      } else {
        // If profile not loaded, try again after a short delay
        await Future.delayed(const Duration(milliseconds: 1000));
        Get.offAll(() => const HomeView(), transition: Transition.fadeIn);
      }
      return;
    }

    // If user has seen onboarding, go to login
    if (_authController.hasSeenOnboarding.value) {
      Get.off(() => const LoginPage(), transition: Transition.fadeIn);
    } else {
      // Otherwise, go to onboarding
      Get.off(() => const OnboardingPage(), transition: Transition.fadeIn);
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.secondary,
      body: Column(
        children: [
          Expanded(
            child: Center(
              child: AnimatedBuilder(
                animation: _animationController,
                builder: (context, child) {
                  return FadeTransition(
                    opacity: _fadeAnimation,
                    child: ScaleTransition(
                      scale: _scaleAnimation,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // Logo
                          Container(
                            width: 120,
                            height: 120,
                            decoration: BoxDecoration(
                              color: AppColors.primary,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: const Icon(
                              Icons.local_taxi_outlined,
                              color: AppColors.white,
                              size: 70,
                            ),
                          ),

                          const SizedBox(height: 24),

                          // Nom de l'application
                          const Text(
                            'AFRILYFT',
                            style: TextStyle(
                              color: AppColors.white,
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 2,
                            ),
                          ),

                          const SizedBox(height: 8),

                          // Slogan
                          const Text(
                            'Safe rides across Africa',
                            style: TextStyle(
                              color: AppColors.mediumGrey,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ),

          // Indicateur de chargement en bas de la page
          const Padding(
            padding: EdgeInsets.only(bottom: 50.0),
            child: SizedBox(
              width: 40,
              height: 40,
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                strokeWidth: 3,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
