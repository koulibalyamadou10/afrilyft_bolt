import 'package:get/get.dart';
import 'package:geolocator/geolocator.dart';
import '../models/ride_model.dart';
import '../services/supabase_service.dart';
import '../services/realtime_service.dart';
import '../services/location_service.dart';

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

  Future<void> _initializeDriver() async {
    await _getCurrentLocation();
    await _loadPendingRequests();
    _initializeRealtime();
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

  void _initializeRealtime() {
    RealtimeService.initialize();

    // Pour l'instant, on charge les demandes périodiquement
    // Le temps réel sera implémenté plus tard
    _loadPendingRequests();
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
        pendingRequests.removeWhere((req) => req.id == requestId);

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
      pendingRequests.removeWhere((req) => req.id == requestId);
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
      isOnline.value = !isOnline.value;

      if (isOnline.value) {
        // Démarrer le suivi de position
        await LocationService.startLocationTracking();
      } else {
        // Arrêter le suivi de position
        await LocationService.stopLocationTracking();
      }

      // Mettre à jour le statut dans la base de données
      await SupabaseService.updateDriverAvailability(isOnline.value);

      Get.snackbar(
        isOnline.value ? 'En ligne' : 'Hors ligne',
        isOnline.value
            ? 'Vous recevrez maintenant des demandes'
            : 'Vous ne recevrez plus de demandes',
      );
    } catch (e) {
      Get.snackbar('Erreur', 'Impossible de changer le statut: $e');
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
