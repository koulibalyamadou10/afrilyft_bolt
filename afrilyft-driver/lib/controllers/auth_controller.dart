import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/supabase_service.dart';
import '../models/ride_model.dart';
import '../views/pages/driver_home_page.dart';
import '../views/pages/login_page.dart';

class AuthController extends GetxController {
  final Rx<User?> user = Rx<User?>(null);
  final Rx<UserProfile?> userProfile = Rx<UserProfile?>(null);
  final RxBool isLoading = false.obs;
  final RxBool isAuthenticated = false.obs;

  @override
  void onInit() {
    super.onInit();
    _initAuth();
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
        
        // Vérifier que c'est bien un chauffeur
        if (userProfile.value?.role != UserRole.driver) {
          Get.snackbar(
            'Erreur',
            'Cette application est réservée aux chauffeurs',
            backgroundColor: Get.theme.colorScheme.error,
            colorText: Get.theme.colorScheme.onError,
          );
          await signOut();
          return;
        }
        
        // Naviguer vers la page d'accueil chauffeur
        Get.offAll(() => const DriverHomePage());
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
  }) async {
    try {
      isLoading.value = true;
      
      final response = await SupabaseService.signUp(
        email: email,
        password: password,
        fullName: fullName,
        phone: phone,
        role: 'driver', // Toujours driver pour cette app
      );

      if (response.user != null) {
        Get.snackbar(
          'Inscription réussie',
          'Votre compte chauffeur a été créé avec succès',
          duration: const Duration(seconds: 3),
          backgroundColor: Get.theme.primaryColor,
          colorText: Get.theme.colorScheme.onPrimary,
        );
        return true;
      } else {
        Get.snackbar(
          'Erreur',
          'Erreur lors de l\'inscription',
          backgroundColor: Get.theme.colorScheme.error,
          colorText: Get.theme.colorScheme.onError,
        );
        return false;
      }
    } catch (e) {
      Get.snackbar(
        'Erreur', 
        'Erreur lors de l\'inscription: ${e.toString()}',
        backgroundColor: Get.theme.colorScheme.error,
        colorText: Get.theme.colorScheme.onError,
      );
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
        // Le profil sera chargé automatiquement via _loadUserProfile
        return true;
      } else {
        Get.snackbar(
          'Erreur',
          'Email ou mot de passe incorrect',
          backgroundColor: Get.theme.colorScheme.error,
          colorText: Get.theme.colorScheme.onError,
        );
        return false;
      }
    } catch (e) {
      Get.snackbar(
        'Erreur', 
        'Erreur lors de la connexion: ${e.toString()}',
        backgroundColor: Get.theme.colorScheme.error,
        colorText: Get.theme.colorScheme.onError,
      );
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> signOut() async {
    try {
      await SupabaseService.signOut();
    } catch (e) {
      Get.snackbar(
        'Erreur', 
        'Erreur lors de la déconnexion: ${e.toString()}',
        backgroundColor: Get.theme.colorScheme.error,
        colorText: Get.theme.colorScheme.onError,
      );
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
        backgroundColor: Get.theme.primaryColor,
        colorText: Get.theme.colorScheme.onPrimary,
      );
    } catch (e) {
      Get.snackbar(
        'Erreur', 
        'Erreur lors de la mise à jour: ${e.toString()}',
        backgroundColor: Get.theme.colorScheme.error,
        colorText: Get.theme.colorScheme.onError,
      );
    } finally {
      isLoading.value = false;
    }
  }

  bool get isDriver => userProfile.value?.role == UserRole.driver;
}