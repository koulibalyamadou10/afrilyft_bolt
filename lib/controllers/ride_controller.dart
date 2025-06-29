import 'package:get/get.dart';
import 'package:geolocator/geolocator.dart';
import '../models/ride_model.dart';
import '../services/supabase_service.dart';

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
    _watchCurrentRide();
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
    } catch (e) {
      Get.snackbar('Erreur', 'Impossible de charger l\'historique: $e');
    } finally {
      isLoading.value = false;
    }
  }

  void _watchCurrentRide() {
    // Écouter les changements sur le trajet en cours
    if (currentRide.value != null) {
      SupabaseService.watchRide(currentRide.value!.id).listen((rideData) {
        if (rideData != null) {
          currentRide.value = RideModel.fromJson(rideData);
        }
      });
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

      // Récupérer les détails du trajet créé
      final rideData = await SupabaseService.getRideById(rideId);
      if (rideData != null) {
        currentRide.value = RideModel.fromJson(rideData);
        _watchCurrentRide();
      }

      // Rechercher les chauffeurs à proximité
      await _findNearbyDrivers(pickupLat, pickupLon);

      Get.snackbar(
        'Trajet créé', 
        'Recherche d\'un chauffeur en cours...',
        duration: const Duration(seconds: 3),
      );

    } catch (e) {
      Get.snackbar('Erreur', 'Impossible de créer le trajet: $e');
      isSearchingDriver.value = false;
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> _findNearbyDrivers(double pickupLat, double pickupLon) async {
    try {
      final drivers = await SupabaseService.findNearbyDrivers(
        pickupLat: pickupLat,
        pickupLon: pickupLon,
        radiusKm: 5.0,
        maxDrivers: 10,
      );

      // Convertir en DriverLocation (simulation)
      nearbyDrivers.value = drivers.map((driver) => DriverLocation(
        id: driver['driver_id'],
        driverId: driver['driver_id'],
        lat: driver['location_lat'],
        lon: driver['location_lon'],
        isAvailable: true,
        lastUpdated: DateTime.parse(driver['last_updated']),
      )).toList();

      print('${nearbyDrivers.length} chauffeurs trouvés à proximité');
    } catch (e) {
      print('Erreur lors de la recherche de chauffeurs: $e');
    }
  }

  void cancelRide() {
    if (currentRide.value != null) {
      // TODO: Implémenter l'annulation côté Supabase
      currentRide.value = null;
      isSearchingDriver.value = false;
      nearbyDrivers.clear();
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