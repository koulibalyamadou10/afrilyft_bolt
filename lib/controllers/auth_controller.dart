import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/supabase_service.dart';
import '../models/ride_model.dart';
import '../views/home_view.dart';
import '../views/pages/login_page.dart';
import '../views/pages/onboarding_page.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
        
        // Navigate to home after profile is loaded
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
      
      final response = await SupabaseService.signUp(
        email: email,
        password: password,
        fullName: fullName,
        phone: phone,
        role: role,
      );

      if (response.user != null) {
        Get.snackbar(
          'Inscription réussie',
          'Votre compte a été créé avec succès',
          duration: const Duration(seconds: 3),
        );
        return true;
      } else {
        Get.snackbar(
          'Erreur',
          response.session?.toString() ?? 'Erreur lors de l\'inscription',
        );
        return false;
      }
    } catch (e) {
      Get.snackbar('Erreur', 'Erreur lors de l\'inscription: $e');
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  Future<bool> signIn({
    required String email,
    required String password,
  }) async {
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
        Get.snackbar(
          'Erreur',
          'Email ou mot de passe incorrect',
        );
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
      
      Get.snackbar(
        'Succès',
        'Profil mis à jour avec succès',
      );
    } catch (e) {
      Get.snackbar('Erreur', 'Erreur lors de la mise à jour: $e');
    } finally {
      isLoading.value = false;
    }
  }

  bool get isCustomer => userProfile.value?.role == UserRole.customer;
  bool get isDriver => userProfile.value?.role == UserRole.driver;
}