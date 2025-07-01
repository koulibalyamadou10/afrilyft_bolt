import 'package:get/get.dart';
import 'package:geolocator/geolocator.dart';
import '../models/ride_model.dart';
import '../services/supabase_service.dart';
import '../services/realtime_service.dart';
import '../services/location_service.dart';
import '../theme/app_colors.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/material.dart';

class DriverController extends GetxController {
  final RxList<RideRequest> pendingRequests = <RideRequest>[].obs;
  final Rx<RideModel?> currentRide = Rx<RideModel?>(null);
  final RxBool isOnline = false.obs;
  final RxBool isAvailable = true.obs;
  final Rx<Position?> currentLocation = Rx<Position?>(null);

  @override
  void onInit() {
    super.onInit();
    _initializeDriver();
  }

  @override
  void onClose() {
    RealtimeService.cleanup();
    super.dispose();
  }

  Future<void> _initializeDriver() async {
    await _getCurrentLocation();
    await _loadPendingRequests();
    await _initializeRealtime();
  }

  Future<void> _getCurrentLocation() async {
    try {
      final position = await LocationService.getCurrentLocation();
      currentLocation.value = position;
    } catch (e) {
      Get.snackbar('Erreur', 'Impossible d\'obtenir votre position: $e');
    }
  }

  Future<void> _loadPendingRequests() async {
    try {
      final requests = await SupabaseService.getDriverRideRequests();
      pendingRequests.value =
          requests.map((json) => RideRequest.fromJson(json)).toList();
    } catch (e) {
      print('Erreur lors du chargement des demandes: $e');
    }
  }

  // Méthode publique pour rafraîchir les demandes
  Future<void> refreshPendingRequests() async {
    print('🔄 Rafraîchissement des demandes en attente...');
    await _loadPendingRequests();
    print(
      '✅ Demandes rafraîchies: ${pendingRequests.length} demandes trouvées',
    );
  }

  Future<void> _initializeRealtime() async {
    try {
      await RealtimeService.initialize();
      print('✅ Service temps réel initialisé pour le chauffeur');
    } catch (e) {
      print('❌ Erreur lors de l\'initialisation du temps réel: $e');
    }
  }

  // NOUVELLE: Ajouter une demande en attente
  void addPendingRequest(RideRequest request) {
    // Vérifier si la demande n'existe pas déjà
    final existingIndex = pendingRequests.indexWhere(
      (req) => req.id == request.id,
    );
    if (existingIndex == -1) {
      pendingRequests.insert(0, request);
      print('✅ Nouvelle demande ajoutée: ${request.id}');
    } else {
      // Mettre à jour la demande existante
      pendingRequests[existingIndex] = request;
      print('🔄 Demande mise à jour: ${request.id}');
    }
  }

  // NOUVELLE: Supprimer une demande
  void removePendingRequest(String requestId) {
    pendingRequests.removeWhere((req) => req.id == requestId);
    print('🗑️ Demande supprimée: $requestId');
  }

  void _viewRideRequest(String requestId) {
    // Navigation vers la page de détail de la demande
    Get.toNamed('/ride-request-detail', arguments: requestId);
  }

  // Accepter une demande de trajet
  Future<void> acceptRideRequest(String requestId) async {
    try {
      final success = await RealtimeService.acceptRide(requestId);
      if (success) {
        // Supprimer la demande de la liste
        removePendingRequest(requestId);

        // Charger les détails du trajet accepté
        await _loadCurrentRide(requestId);

        Get.snackbar('Succès', 'Trajet accepté !');
        Get.toNamed('/ride-tracking');
      } else {
        Get.snackbar('Erreur', 'Impossible d\'accepter ce trajet');
      }
    } catch (e) {
      Get.snackbar('Erreur', 'Erreur lors de l\'acceptation: $e');
    }
  }

  // Refuser une demande de trajet
  Future<void> declineRideRequest(String requestId) async {
    try {
      await SupabaseService.declineRideRequest(requestId);
      removePendingRequest(requestId);
      Get.snackbar('Info', 'Demande refusée');
    } catch (e) {
      Get.snackbar('Erreur', 'Erreur lors du refus: $e');
    }
  }

  Future<void> _loadCurrentRide(String requestId) async {
    try {
      final rideData = await SupabaseService.getRideByRequestId(requestId);
      if (rideData != null) {
        currentRide.value = RideModel.fromJson(rideData);
      }
    } catch (e) {
      print('Erreur lors du chargement du trajet: $e');
    }
  }

  // Basculer le statut en ligne/hors ligne
  Future<void> toggleOnlineStatus() async {
    try {
      final newStatus = !isOnline.value;
      print(
        '🔄 Tentative de changement de statut: ${newStatus ? "En ligne" : "Hors ligne"}',
      );

      // Vérifier l'authentification
      final supabase = Supabase.instance.client;
      final user = supabase.auth.currentUser;
      if (user == null) {
        print('❌ Utilisateur non authentifié');
        Get.snackbar(
          'Erreur',
          'Vous devez être connecté pour changer votre statut',
          backgroundColor: AppColors.error,
          colorText: Colors.white,
        );
        return;
      }

      // Si on veut se mettre en ligne, vérifier la position d'abord
      if (newStatus) {
        print('📍 Vérification de la position avant mise en ligne...');
        try {
          final position = await LocationService.getCurrentLocation();
          currentLocation.value = position;
          print(
            '✅ Position actuelle récupérée: ${position.latitude}, ${position.longitude}',
          );
        } catch (e) {
          print('❌ Erreur lors de la récupération de la position: $e');
          Get.snackbar(
            'Erreur de localisation',
            'Impossible d\'obtenir votre position. Vérifiez vos permissions de localisation.',
            backgroundColor: AppColors.warning,
            colorText: Colors.white,
            duration: const Duration(seconds: 4),
          );
          return;
        }
      }

      // Mettre à jour le statut local immédiatement pour l'UI
      isOnline.value = newStatus;
      print(
        '🔄 Statut local mis à jour: ${newStatus ? "En ligne" : "Hors ligne"}',
      );

      // Gérer le suivi de position
      if (newStatus) {
        // Se mettre en ligne
        print('📍 Démarrage du suivi de position...');
        try {
          await LocationService.startLocationTracking();
          print('✅ Suivi de position démarré');
        } catch (e) {
          print('❌ Erreur lors du démarrage du suivi: $e');
          // Remettre hors ligne en cas d'erreur
          isOnline.value = false;
          Get.snackbar(
            'Erreur de suivi',
            'Impossible de démarrer le suivi de position: $e',
            backgroundColor: AppColors.error,
            colorText: Colors.white,
          );
          return;
        }
      } else {
        // Se mettre hors ligne
        print('📍 Arrêt du suivi de position...');
        try {
          await LocationService.stopLocationTracking();
          print('✅ Suivi de position arrêté');

          // Vider la liste des demandes en attente quand on se met hors ligne
          pendingRequests.clear();
          print('🗑️ Demandes en attente supprimées (hors ligne)');
        } catch (e) {
          print('❌ Erreur lors de l\'arrêt du suivi: $e');
          // Ne pas remettre en ligne car l'arrêt peut échouer sans problème majeur
        }
      }

      // Mettre à jour le statut dans la base de données
      print('📍 Mise à jour du statut en base de données...');
      try {
        await SupabaseService.updateDriverAvailability(newStatus);
        print('✅ Statut mis à jour en base de données');
      } catch (e) {
        print('❌ Erreur lors de la mise à jour en base: $e');

        // En cas d'erreur de base de données, remettre le statut local
        isOnline.value = !newStatus;

        // Arrêter le suivi si on était en train de se mettre en ligne
        if (newStatus) {
          try {
            await LocationService.stopLocationTracking();
          } catch (stopError) {
            print(
              '❌ Erreur lors de l\'arrêt du suivi après erreur: $stopError',
            );
          }
        }

        Get.snackbar(
          'Erreur de connexion',
          'Impossible de mettre à jour votre statut. Vérifiez votre connexion internet.',
          backgroundColor: AppColors.error,
          colorText: Colors.white,
          duration: const Duration(seconds: 4),
        );
        return;
      }

      // Afficher le message de succès avec plus de détails
      if (newStatus) {
        Get.snackbar(
          '🟢 En ligne',
          'Vous recevrez maintenant des demandes de trajet',
          duration: const Duration(seconds: 3),
          backgroundColor: AppColors.success,
          colorText: Colors.white,
          icon: const Icon(Icons.check_circle, color: Colors.white),
        );
      } else {
        Get.snackbar(
          '🔴 Hors ligne',
          'Vous ne recevrez plus de demandes de trajet',
          duration: const Duration(seconds: 3),
          backgroundColor: AppColors.grey,
          colorText: Colors.white,
          icon: const Icon(Icons.cancel, color: Colors.white),
        );
      }

      print(
        '✅ Changement de statut réussi: ${newStatus ? "En ligne" : "Hors ligne"}',
      );
    } catch (e) {
      print('❌ Erreur générale lors du changement de statut: $e');

      // Remettre le statut local en cas d'erreur générale
      isOnline.value = false;

      Get.snackbar(
        'Erreur',
        'Impossible de changer le statut: $e',
        backgroundColor: AppColors.error,
        colorText: Colors.white,
        duration: const Duration(seconds: 4),
      );
    }
  }

  // Méthode pour forcer la mise hors ligne (utile en cas de problème)
  Future<void> forceOffline() async {
    try {
      print('🔄 Forçage de la mise hors ligne...');

      // Arrêter le suivi de position
      try {
        await LocationService.stopLocationTracking();
        print('✅ Suivi de position arrêté');
      } catch (e) {
        print('⚠️ Erreur lors de l\'arrêt du suivi: $e');
      }

      // Vider les demandes
      pendingRequests.clear();

      // Mettre à jour le statut local
      isOnline.value = false;

      // Mettre à jour en base de données
      try {
        await SupabaseService.updateDriverAvailability(false);
        print('✅ Statut mis à jour en base de données');
      } catch (e) {
        print('⚠️ Erreur lors de la mise à jour en base: $e');
      }

      Get.snackbar(
        '🔴 Hors ligne forcé',
        'Vous êtes maintenant hors ligne',
        backgroundColor: AppColors.grey,
        colorText: Colors.white,
      );
    } catch (e) {
      print('❌ Erreur lors du forçage hors ligne: $e');
    }
  }

  // Démarrer un trajet
  Future<void> startRide() async {
    if (currentRide.value != null) {
      try {
        await RealtimeService.updateRideStatus(
          currentRide.value!.id,
          'in_progress',
        );
        Get.snackbar('Trajet démarré', 'Le client a été notifié');
      } catch (e) {
        Get.snackbar('Erreur', 'Impossible de démarrer le trajet: $e');
      }
    }
  }

  // Terminer un trajet
  Future<void> completeRide() async {
    if (currentRide.value != null) {
      try {
        await RealtimeService.updateRideStatus(
          currentRide.value!.id,
          'completed',
        );
        currentRide.value = null;
        Get.snackbar('Trajet terminé', 'Merci pour votre service !');
        Get.offAllNamed('/driver-home');
      } catch (e) {
        Get.snackbar('Erreur', 'Impossible de terminer le trajet: $e');
      }
    }
  }
}
