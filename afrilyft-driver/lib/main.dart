import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:firebase_core/firebase_core.dart';
import 'views/pages/splash_screen.dart';

import 'theme/app_theme.dart';
import 'controllers/auth_controller.dart';
import 'services/location_service.dart';
import 'services/realtime_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialiser Firebase
  // await Firebase.initializeApp();

  // Initialiser Supabase (même configuration que l'app client)
  await Supabase.initialize(
    url: 'https://fkqfebadrrgomfymziwd.supabase.co',
    anonKey:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImZrcWZlYmFkcnJnb21meW16aXdkIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTEyMzY5MTgsImV4cCI6MjA2NjgxMjkxOH0.BuZCFCM0O3Y2OAQaaDEwwIenV03wBAlOAusn6qbTJsA',
  );

  // Initialiser les services
  await LocationService.initialize();
  RealtimeService.initialize();

  // Initialiser les contrôleurs
  Get.put(AuthController());

  runApp(const DriverApp());
}

class DriverApp extends StatelessWidget {
  const DriverApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'AfriLyft Driver',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.driverTheme, // Thème spécifique chauffeur
      home: const SplashScreen(),
      onInit: () {
        // Initialisation des services en arrière-plan
        Future.delayed(const Duration(seconds: 1), () {
          RealtimeService.initialize();
        });
      },
    );
  }
}
