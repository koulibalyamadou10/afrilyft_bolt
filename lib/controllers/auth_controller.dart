import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/supabase_service.dart';
import '../models/ride_model.dart';
import '../views/home_view.dart';
import '../views/pages/login_page.dart';
import '../views/pages/onboarding_page.dart';
import 'package:flutter/material.dart';

class AuthController extends GetxController {
  final Rx<User?> user = Rx<User?>(null);
  final Rx<UserProfile?> userProfile = Rx<UserProfile?>(null);
  final RxBool isLoading = false.obs;
  final RxBool isAuthenticated = false.obs;
  final RxBool hasSeenOnboarding = false.obs;

  @override
  void onInit() {
    super.onInit();
    _initAuth();
    _checkOnboardingStatus();
  }

  Future<void> _checkOnboardingStatus() async {
    final prefs = await SharedPreferences.getInstance();
    hasSeenOnboarding.value = prefs.getBool('hasSeenOnboarding') ?? false;
  }

  Future<void> setOnboardingComplete() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('hasSeenOnboarding', true);
    hasSeenOnboarding.value = true;
  }

  void _initAuth() {
    // Écouter les changements d'authentification
    SupabaseService.client.auth.onAuthStateChange.listen((data) {
      final AuthChangeEvent event = data.event;
      final Session? session = data.session;

      switch (event) {
        case AuthChangeEvent.signedIn:
          user.value = session?.user;
          isAuthenticated.value = true;
          _loadUserProfile();
          break;
        case AuthChangeEvent.signedOut:
          user.value = null;
          userProfile.value = null;
          isAuthenticated.value = false;
          Get.offAll(() => const LoginPage());
          break;
        default:
          break;
      }
    });

    // Vérifier si l'utilisateur est déjà connecté
    final currentUser = SupabaseService.client.auth.currentUser;
    if (currentUser != null) {
      user.value = currentUser;
      isAuthenticated.value = true;
      _loadUserProfile();
    }
  }

  Future<void> _loadUserProfile() async {
    try {
      final profile = await SupabaseService.getCurrentUserProfile();
      if (profile != null) {
        userProfile.value = UserProfile.fromJson(profile);

        // Navigate to home view after profile is loaded
        Get.offAll(() => const HomeView());
      }
    } catch (e) {
      print('Erreur lors du chargement du profil: $e');
    }
  }

  Future<bool> signUp({
    required String email,
    required String password,
    required String fullName,
    required String phone,
    String role = 'customer',
  }) async {
    try {
      isLoading.value = true;
      print('🚀 Début de l\'inscription dans AuthController');

      final response = await SupabaseService.signUp(
        email: email,
        password: password,
        fullName: fullName,
        phone: phone,
        role: role,
      );

      if (response.user != null) {
        print('✅ Inscription réussie, utilisateur créé');

        // Attendre un peu pour que le profil soit créé
        await Future.delayed(const Duration(seconds: 2));

        // Vérifier si le profil a été créé
        try {
          final profile = await SupabaseService.getCurrentUserProfile();
          if (profile != null) {
            print('✅ Profil trouvé, navigation vers la page d\'accueil');
            userProfile.value = UserProfile.fromJson(profile);
            Get.snackbar(
              'Inscription réussie',
              'Votre compte a été créé avec succès',
              duration: const Duration(seconds: 3),
              backgroundColor: Colors.green,
              colorText: Colors.white,
            );
            return true;
          } else {
            print('⚠️ Profil non trouvé après inscription');
            Get.snackbar(
              'Inscription partielle',
              'Compte créé mais profil non trouvé. Veuillez vous reconnecter.',
              duration: const Duration(seconds: 5),
              backgroundColor: Colors.orange,
              colorText: Colors.white,
            );
            return false;
          }
        } catch (e) {
          print('❌ Erreur lors de la vérification du profil: $e');
          Get.snackbar(
            'Inscription partielle',
            'Compte créé mais erreur lors de la vérification du profil.',
            duration: const Duration(seconds: 5),
            backgroundColor: Colors.orange,
            colorText: Colors.white,
          );
          return false;
        }
      } else {
        print('❌ Aucun utilisateur créé');
        Get.snackbar(
          'Erreur',
          'Aucun utilisateur créé lors de l\'inscription',
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
        return false;
      }
    } catch (e) {
      print('❌ Erreur dans AuthController.signUp: $e');

      String errorMessage = 'Erreur lors de l\'inscription';

      if (e.toString().contains('Un compte avec cet email existe déjà')) {
        errorMessage = 'Un compte avec cet email existe déjà';
      } else if (e.toString().contains('Format d\'email invalide')) {
        errorMessage = 'Format d\'email invalide';
      } else if (e.toString().contains('Le mot de passe doit contenir')) {
        errorMessage = 'Le mot de passe doit contenir au moins 6 caractères';
      } else if (e.toString().contains('Numéro de téléphone')) {
        errorMessage = 'Numéro de téléphone invalide ou déjà utilisé';
      } else if (e.toString().contains('network')) {
        errorMessage =
            'Erreur de connexion réseau. Vérifiez votre connexion internet.';
      }

      Get.snackbar(
        'Erreur',
        errorMessage,
        backgroundColor: Colors.red,
        colorText: Colors.white,
        duration: const Duration(seconds: 5),
      );
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  Future<bool> signIn({required String email, required String password}) async {
    try {
      isLoading.value = true;

      final response = await SupabaseService.signIn(
        email: email,
        password: password,
      );

      if (response.user != null) {
        // Profile will be loaded automatically via _loadUserProfile
        return true;
      } else {
        Get.snackbar('Erreur', 'Email ou mot de passe incorrect');
        return false;
      }
    } catch (e) {
      Get.snackbar('Erreur', 'Erreur lors de la connexion: $e');
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> signOut() async {
    try {
      isLoading.value = true;
      await SupabaseService.signOut();
      isLoading.value = false;
    } catch (e) {
      Get.snackbar('Erreur', 'Erreur lors de la déconnexion: $e');
      isLoading.value = false;
    }
  }

  Future<void> updateProfile(Map<String, dynamic> updates) async {
    try {
      isLoading.value = true;

      await SupabaseService.updateProfile(updates);
      await _loadUserProfile();

      Get.snackbar('Succès', 'Profil mis à jour avec succès');
    } catch (e) {
      Get.snackbar('Erreur', 'Erreur lors de la mise à jour: $e');
    } finally {
      isLoading.value = false;
    }
  }

  bool get isCustomer => userProfile.value?.role == UserRole.customer;
  bool get isDriver => userProfile.value?.role == UserRole.driver;
}
