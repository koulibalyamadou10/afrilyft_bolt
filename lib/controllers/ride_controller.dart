import 'package:get/get.dart';
import 'package:geolocator/geolocator.dart';
import '../models/ride_model.dart';
import '../services/supabase_service.dart';
import '../services/realtime_service.dart';
import '../services/notification_service.dart';
import 'auth_controller.dart';
import 'dart:math';

class RideController extends GetxController {
  final Rx<RideModel?> currentRide = Rx<RideModel?>(null);
  final RxList<RideModel> rideHistory = <RideModel>[].obs;
  final RxList<DriverLocation> nearbyDrivers = <DriverLocation>[].obs;
  final RxBool isLoading = false.obs;
  final RxBool isSearchingDriver = false.obs;
  final Rx<Position?> currentLocation = Rx<Position?>(null);

  @override
  void onInit() {
    super.onInit();
    _getCurrentLocation();
    _loadRideHistory();
    _initializeRealtime();
  }

  @override
  void onClose() {
    RealtimeService.cleanup();
    super.dispose();
  }

  Future<void> _initializeRealtime() async {
    await RealtimeService.initialize();
    
    // Écouter les changements de statut des trajets
    RealtimeService.subscribeToRideUpdates((rideData) {
      final ride = RideModel.fromJson(rideData);
      
      // Si c'est notre trajet actuel
      if (currentRide.value?.id == ride.id) {
        currentRide.value = ride;
        
        // Si le trajet a été accepté, arrêter la recherche
        if (ride.status == RideStatus.accepted) {
          isSearchingDriver.value = false;
          Get.snackbar(
            '🚗 Chauffeur trouvé !',
            'Un chauffeur a accepté votre demande',
            duration: const Duration(seconds: 3),
          );
        }
      }
      
      // Mettre à jour l'historique
      updateRideInHistory(ride);
    });
  }

  Future<void> _getCurrentLocation() async {
    try {
      final position = await SupabaseService.getCurrentLocation();
      currentLocation.value = position;
    } catch (e) {
      Get.snackbar('Erreur', 'Impossible d\'obtenir votre position: $e');
    }
  }

  Future<void> _loadRideHistory() async {
    try {
      isLoading.value = true;
      final rides = await SupabaseService.getUserRides();
      rideHistory.value = rides.map((json) => RideModel.fromJson(json)).toList();
      
      // Vérifier s'il y a un trajet en cours
      final activeRide = rideHistory.firstWhereOrNull((ride) => 
        ride.status == RideStatus.searching ||
        ride.status == RideStatus.accepted ||
        ride.status == RideStatus.inProgress
      );
      
      if (activeRide != null) {
        currentRide.value = activeRide;
        if (activeRide.status == RideStatus.searching) {
          isSearchingDriver.value = true;
          await findNearbyDriversPreview(activeRide.pickupLat, activeRide.pickupLon);
        }
      }
    } catch (e) {
      Get.snackbar('Erreur', 'Impossible de charger l\'historique: $e');
    } finally {
      isLoading.value = false;
    }
  }

  // NOUVEAU: Prévisualisation des chauffeurs sans créer de trajet
  Future<void> findNearbyDriversPreview(double pickupLat, double pickupLon) async {
    try {
      final drivers = await SupabaseService.findNearbyDrivers(
        pickupLat: pickupLat,
        pickupLon: pickupLon,
        radiusKm: 5.0,
        maxDrivers: 10,
      );

      nearbyDrivers.value = drivers.map((driver) => DriverLocation(
        id: driver['driver_id'],
        driverId: driver['driver_id'],
        lat: driver['location_lat'],
        lon: driver['location_lon'],
        heading: driver['heading']?.toDouble(),
        speed: driver['speed']?.toDouble(),
        isAvailable: true,
        lastUpdated: DateTime.parse(driver['last_updated']),
      )).toList();

      print('${nearbyDrivers.length} chauffeurs trouvés pour prévisualisation');
    } catch (e) {
      print('Erreur lors de la recherche de chauffeurs: $e');
    }
  }

  Future<void> createRide({
    required double pickupLat,
    required double pickupLon,
    required String pickupAddress,
    required double destinationLat,
    required double destinationLon,
    required String destinationAddress,
    String paymentMethod = 'cash',
    String? notes,
    DateTime? scheduledFor,
  }) async {
    try {
      isLoading.value = true;
      isSearchingDriver.value = true;

      // 1. Créer le trajet dans la base de données
      final rideId = await SupabaseService.createRide(
        pickupLat: pickupLat,
        pickupLon: pickupLon,
        pickupAddress: pickupAddress,
        destinationLat: destinationLat,
        destinationLon: destinationLon,
        destinationAddress: destinationAddress,
        paymentMethod: paymentMethod,
        notes: notes,
        scheduledFor: scheduledFor,
      );

      // 2. Récupérer les détails du trajet créé
      final rideData = await SupabaseService.getRideById(rideId);
      if (rideData != null) {
        currentRide.value = RideModel.fromJson(rideData);
      }

      // 3. Afficher le message de confirmation
      Get.snackbar(
        'Recherche lancée', 
        '${nearbyDrivers.length} chauffeurs ont été notifiés. En attente d\'acceptation...',
        duration: const Duration(seconds: 3),
      );

      print('🚀 Trajet créé avec ID: $rideId');
      print('📱 ${nearbyDrivers.length} chauffeurs notifiés');

    } catch (e) {
      Get.snackbar('Erreur', 'Impossible de créer le trajet: $e');
      isSearchingDriver.value = false;
    } finally {
      isLoading.value = false;
    }
  }

  // Calculer la distance entre deux points
  double calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    const double earthRadius = 6371; // Rayon de la Terre en km
    
    double dLat = _degreesToRadians(lat2 - lat1);
    double dLon = _degreesToRadians(lon2 - lon1);
    
    double a = sin(dLat / 2) * sin(dLat / 2) +
        cos(_degreesToRadians(lat1)) * cos(_degreesToRadians(lat2)) *
        sin(dLon / 2) * sin(dLon / 2);
    
    double c = 2 * atan2(sqrt(a), sqrt(1 - a));
    
    return earthRadius * c;
  }

  double _degreesToRadians(double degrees) {
    return degrees * (pi / 180);
  }

  // Mettre à jour un trajet dans l'historique
  void updateRideInHistory(RideModel updatedRide) {
    final index = rideHistory.indexWhere((ride) => ride.id == updatedRide.id);
    if (index != -1) {
      rideHistory[index] = updatedRide;
    } else {
      rideHistory.insert(0, updatedRide);
    }
  }

  // Mettre à jour la position d'un chauffeur
  void updateDriverLocation(DriverLocation driverLocation) {
    final index = nearbyDrivers.indexWhere((driver) => driver.driverId == driverLocation.driverId);
    if (index != -1) {
      nearbyDrivers[index] = driverLocation;
      print('📍 Position du chauffeur ${driverLocation.driverId} mise à jour');
    } else {
      nearbyDrivers.add(driverLocation);
    }
  }

  // Annuler un trajet
  Future<void> cancelRide() async {
    if (currentRide.value != null) {
      try {
        await RealtimeService.updateRideStatus(currentRide.value!.id, 'cancelled');
        currentRide.value = null;
        isSearchingDriver.value = false;
        nearbyDrivers.clear();
        Get.snackbar('Trajet annulé', 'Votre trajet a été annulé');
      } catch (e) {
        Get.snackbar('Erreur', 'Impossible d\'annuler le trajet: $e');
      }
    }
  }

  // Démarrer un trajet (pour les chauffeurs)
  Future<void> startRide() async {
    if (currentRide.value != null) {
      try {
        await RealtimeService.updateRideStatus(currentRide.value!.id, 'in_progress');
      } catch (e) {
        Get.snackbar('Erreur', 'Impossible de démarrer le trajet: $e');
      }
    }
  }

  // Terminer un trajet (pour les chauffeurs)
  Future<void> completeRide() async {
    if (currentRide.value != null) {
      try {
        await RealtimeService.updateRideStatus(currentRide.value!.id, 'completed');
        currentRide.value = null;
        isSearchingDriver.value = false;
        nearbyDrivers.clear();
      } catch (e) {
        Get.snackbar('Erreur', 'Impossible de terminer le trajet: $e');
      }
    }
  }

  void clearCurrentRide() {
    currentRide.value = null;
    isSearchingDriver.value = false;
    nearbyDrivers.clear();
  }

  String getStatusText(RideStatus status) {
    switch (status) {
      case RideStatus.pending:
        return 'En attente';
      case RideStatus.searching:
        return 'Recherche d\'un chauffeur...';
      case RideStatus.accepted:
        return 'Chauffeur trouvé';
      case RideStatus.inProgress:
        return 'En cours';
      case RideStatus.completed:
        return 'Terminé';
      case RideStatus.cancelled:
        return 'Annulé';
    }
  }

  Color getStatusColor(RideStatus status) {
    switch (status) {
      case RideStatus.pending:
        return Get.theme.colorScheme.secondary;
      case RideStatus.searching:
        return Get.theme.colorScheme.primary;
      case RideStatus.accepted:
        return const Color(0xFF4CAF50);
      case RideStatus.inProgress:
        return const Color(0xFF2196F3);
      case RideStatus.completed:
        return const Color(0xFF4CAF50);
      case RideStatus.cancelled:
        return const Color(0xFFF44336);
    }
  }
}