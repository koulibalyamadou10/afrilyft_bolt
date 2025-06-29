import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'views/pages/splash_screen.dart';
import 'theme/app_theme.dart';
import 'controllers/auth_controller.dart';
import 'services/realtime_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialiser Supabase
  await Supabase.initialize(
    url: 'https://your-project.supabase.co', // Remplacez par votre URL
    anonKey: 'your-anon-key', // Remplacez par votre clé anonyme
  );
  
  // Initialiser les contrôleurs globaux
  Get.put(AuthController());
  
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'AfriLyft',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: const SplashScreen(),
      onInit: () {
        // Initialiser les services temps réel après que l'app soit prête
        Future.delayed(const Duration(seconds: 1), () {
          RealtimeService.initialize();
        });
      },
    );
  }
}