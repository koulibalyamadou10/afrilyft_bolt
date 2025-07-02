import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import '../../controllers/ride_controller.dart';
import '../../models/ride_model.dart';
import '../../theme/app_colors.dart';
import '../../config/maps_config.dart';
import 'driver_search_page.dart';

class RideTrackingPage extends StatefulWidget {
  const RideTrackingPage({Key? key}) : super(key: key);

  @override
  State<RideTrackingPage> createState() => _RideTrackingPageState();
}

class _RideTrackingPageState extends State<RideTrackingPage>
    with TickerProviderStateMixin {
  final RideController rideController = Get.put(RideController());
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  GoogleMapController? _mapController;
  Set<Marker> _markers = {};
  Set<Polyline> _polylines = {};
  Position? _currentPosition;
  bool _isLoadingLocation = true;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat();
    _pulseAnimation = Tween<double>(begin: 0.8, end: 1.2).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _getCurrentLocation();
    _initializeMap();

    // Écouter les changements de chauffeurs
    ever(rideController.nearbyDrivers, (_) {
      _addDriverMarkers();
    });

    // NOUVEAU: Écouter les changements du trajet actuel
    ever(rideController.currentRide, (ride) {
      if (ride == null) {
        // Le trajet a été supprimé, retourner à la page précédente
        print('🔄 Trajet supprimé, retour à la page précédente');
        Future.delayed(const Duration(seconds: 1), () {
          try {
            Get.back();
          } catch (e) {
            Get.offAllNamed('/home');
          }
        });
      } else {
        // Réafficher le trajet et les marqueurs
        setState(() {
          _markers.clear();
          _polylines.clear();
          _initializeMap();
          _updateMapWithCurrentLocation();
        });
      }
    });

    // NOUVEAU: Écouter les changements du statut de recherche
    ever(rideController.isSearchingDriver, (isSearching) {
      if (!isSearching &&
          rideController.currentRide.value?.status == RideStatus.searching) {
        // La recherche s'est arrêtée mais le trajet est toujours en statut 'searching'
        // Cela peut indiquer une expiration
        print('🔄 Recherche arrêtée, vérification du statut du trajet');
      }
    });
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _mapController?.dispose();
    super.dispose();
  }

  Future<void> _getCurrentLocation() async {
    try {
      setState(() {
        _isLoadingLocation = true;
      });

      print('🔍 Obtention de la position actuelle...');

      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 10),
      );

      print('✅ Position obtenue: ${position.latitude}, ${position.longitude}');

      setState(() {
        _currentPosition = position;
        _isLoadingLocation = false;
        // Mettre à jour la carte avec la nouvelle position
        _markers.removeWhere(
          (marker) => marker.markerId.value == 'current_location',
        );
        _updateMapWithCurrentLocation();
      });

      // Centrer immédiatement la carte sur la position actuelle
      //_updateMapWithCurrentLocation(); // déjà appelé dans setState ci-dessus
    } catch (e) {
      print('❌ Erreur lors de l\'obtention de la position: $e');
      setState(() {
        _isLoadingLocation = false;
      });

      // En cas d'erreur, centrer sur Conakry par défaut
      if (_mapController != null) {
        _mapController!.animateCamera(
          CameraUpdate.newLatLngZoom(
            const LatLng(9.5370, -13.6785), // Conakry
            12,
          ),
        );
      }
    }
  }

  void _initializeMap() {
    final ride = rideController.currentRide.value;
    if (ride == null) return;

    // Réinitialiser les marqueurs et polylignes
    _markers.clear();
    _polylines.clear();

    // Marqueur de départ (vert)
    _markers.add(
      Marker(
        markerId: const MarkerId('pickup'),
        position: LatLng(ride.pickupLat, ride.pickupLon),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
        infoWindow: InfoWindow(
          title: 'Point de départ',
          snippet: ride.pickupAddress,
        ),
      ),
    );

    // Marqueur de destination (rouge)
    _markers.add(
      Marker(
        markerId: const MarkerId('destination'),
        position: LatLng(ride.destinationLat, ride.destinationLon),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
        infoWindow: InfoWindow(
          title: 'Destination',
          snippet: ride.destinationAddress,
        ),
      ),
    );

    // Marqueur de position actuelle du client (bleu)
    if (_currentPosition != null) {
      _markers.add(
        Marker(
          markerId: const MarkerId('current_location'),
          position: LatLng(
            _currentPosition!.latitude,
            _currentPosition!.longitude,
          ),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
          infoWindow: const InfoWindow(
            title: 'Votre position',
            snippet: 'Position actuelle',
          ),
        ),
      );
    }

    // Ligne de trajet
    _polylines.add(
      Polyline(
        polylineId: const PolylineId('route'),
        points: [
          LatLng(ride.pickupLat, ride.pickupLon),
          LatLng(ride.destinationLat, ride.destinationLon),
        ],
        color: AppColors.primary,
        width: 3,
      ),
    );
  }

  void _updateMapWithCurrentLocation() {
    if (_currentPosition == null || _mapController == null) return;

    final currentLatLng = LatLng(
      _currentPosition!.latitude,
      _currentPosition!.longitude,
    );

    // Ajouter ou mettre à jour le marqueur de position actuelle
    _markers.removeWhere(
      (marker) => marker.markerId.value == 'current_location',
    );
    _markers.add(
      Marker(
        markerId: const MarkerId('current_location'),
        position: currentLatLng,
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
        infoWindow: const InfoWindow(
          title: 'Votre position',
          snippet: 'Position actuelle',
        ),
      ),
    );

    // Centrer la carte sur la position actuelle avec animation
    _mapController!.animateCamera(
      CameraUpdate.newLatLngZoom(currentLatLng, 16), // Zoom plus proche
    );

    print(
      '📍 Carte centrée sur la position actuelle: ${_currentPosition!.latitude}, ${_currentPosition!.longitude}',
    );
  }

  void _onMapCreated(GoogleMapController controller) {
    _mapController = controller;

    // Toujours centrer sur la position actuelle si disponible
    if (_currentPosition != null) {
      _updateMapWithCurrentLocation();
    } else {
      // Si pas encore de position, attendre et centrer dès qu'elle est disponible
      _getCurrentLocation().then((_) {
        if (_currentPosition != null) {
          _updateMapWithCurrentLocation();
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.secondary,
      body: Obx(() {
        final ride = rideController.currentRide.value;
        if (ride == null) {
          return const Center(
            child: Text(
              'Aucun trajet en cours',
              style: TextStyle(color: Colors.white, fontSize: 18),
            ),
          );
        }

        return Stack(
          children: [
            // Carte Google Maps
            _buildMapWidget(),

            // Indicateur de chargement de position
            if (_isLoadingLocation)
              Positioned(
                top: 100,
                left: 0,
                right: 0,
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.7),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            valueColor: AlwaysStoppedAnimation<Color>(
                              AppColors.primary,
                            ),
                            strokeWidth: 2,
                          ),
                        ),
                        SizedBox(width: 8),
                        Text(
                          'Localisation en cours...',
                          style: TextStyle(color: Colors.white, fontSize: 14),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

            // En-tête
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.only(
                  top: 50,
                  left: 16,
                  right: 16,
                  bottom: 16,
                ),
                decoration: BoxDecoration(
                  color: AppColors.secondary.withOpacity(0.9),
                ),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back, color: Colors.white),
                      onPressed: () => Get.back(),
                    ),
                    Expanded(
                      child: Text(
                        _getStatusTitle(ride.status),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    if (ride.status == RideStatus.searching)
                      IconButton(
                        icon: const Icon(Icons.close, color: Colors.white),
                        onPressed: _showCancelDialog,
                      ),
                  ],
                ),
              ),
            ),

            // Panneau d'informations
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(24),
                    topRight: Radius.circular(24),
                  ),
                ),
                child: _buildRideInfo(ride),
              ),
            ),

            // Bouton de localisation
            if (_currentPosition != null)
              Positioned(
                bottom: 200,
                right: 16,
                child: FloatingActionButton(
                  onPressed: _updateMapWithCurrentLocation,
                  backgroundColor: AppColors.primary,
                  child: const Icon(Icons.my_location, color: Colors.white),
                ),
              ),
          ],
        );
      }),
    );
  }

  Widget _buildDriverMarker({
    bool isSearching = false,
    bool isAssigned = false,
  }) {
    Color markerColor = AppColors.primary;
    if (isAssigned) markerColor = Colors.green;
    if (isSearching) markerColor = Colors.orange;

    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: markerColor,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: const Icon(Icons.directions_car, color: Colors.white, size: 20),
    );
  }

  Widget _buildRideInfo(RideModel ride) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Statut avec animation
        AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: rideController.getStatusColor(ride.status).withOpacity(0.1),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: rideController.getStatusColor(ride.status),
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                rideController.getStatusText(ride.status),
                style: TextStyle(
                  color: rideController.getStatusColor(ride.status),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 20),

        // Informations du trajet
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildLocationRow(
                    Icons.radio_button_checked,
                    AppColors.primary,
                    ride.pickupAddress,
                  ),
                  const SizedBox(height: 12),
                  _buildLocationRow(
                    Icons.location_on,
                    Colors.grey[600]!,
                    ride.destinationAddress,
                  ),
                ],
              ),
            ),
          ],
        ),

        const SizedBox(height: 20),

        // Détails
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            if (ride.distanceKm != null)
              _buildDetailItem(
                Icons.straighten,
                '${ride.distanceKm!.toStringAsFixed(1)} km',
                'Distance',
              ),
            if (ride.estimatedDurationMinutes != null)
              _buildDetailItem(
                Icons.access_time,
                '${ride.estimatedDurationMinutes} min',
                'Durée estimée',
              ),
            _buildDetailItem(
              Icons.payment,
              _getPaymentMethodText(ride.paymentMethod),
              'Paiement',
            ),
          ],
        ),

        // Informations du chauffeur (si assigné)
        if (ride.driver != null) ...[
          const SizedBox(height: 20),
          const Divider(),
          const SizedBox(height: 16),
          _buildDriverInfo(ride.driver!),
        ],

        // Recherche en cours avec compteur de chauffeurs
        if (rideController.isSearchingDriver.value) ...[
          const SizedBox(height: 20),
          _buildSearchingInfo(),
        ],
      ],
    );
  }

  Widget _buildLocationRow(IconData icon, Color color, String address) {
    return Row(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            address,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
          ),
        ),
      ],
    );
  }

  Widget _buildDetailItem(IconData icon, String value, String label) {
    return Column(
      children: [
        Icon(icon, color: AppColors.primary, size: 24),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
        Text(label, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
      ],
    );
  }

  Widget _buildDriverInfo(UserProfile driver) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 25,
            backgroundColor: AppColors.primary,
            child: Text(
              driver.fullName.substring(0, 1).toUpperCase(),
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  driver.fullName,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  driver.phone,
                  style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                ),
              ],
            ),
          ),
          Row(
            children: [
              IconButton(
                onPressed: () {
                  // Appeler le chauffeur
                },
                icon: const Icon(Icons.phone, color: AppColors.primary),
              ),
              IconButton(
                onPressed: () {
                  // Envoyer un message
                },
                icon: const Icon(Icons.message, color: AppColors.primary),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSearchingInfo() {
    return Obx(() {
      final driverCount = rideController.nearbyDrivers.length;

      // Déterminer la couleur et l'icône selon le nombre de chauffeurs
      Color containerColor;
      Color iconColor;
      IconData icon;
      String message;

      if (driverCount == 0) {
        containerColor = Colors.orange.withOpacity(0.1);
        iconColor = Colors.orange;
        icon = Icons.directions_car_outlined;
        message = 'Aucun chauffeur disponible';
      } else if (driverCount == 1) {
        containerColor = Colors.green.withOpacity(0.1);
        iconColor = Colors.green;
        icon = Icons.directions_car;
        message = '1 chauffeur disponible';
      } else {
        containerColor = Colors.green.withOpacity(0.1);
        iconColor = Colors.green;
        icon = Icons.directions_car;
        message = '$driverCount chauffeurs disponibles';
      }

      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: containerColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: iconColor.withOpacity(0.3), width: 1),
        ),
        child: Column(
          children: [
            Row(
              children: [
                Icon(icon, color: iconColor, size: 24),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    message,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: iconColor,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  if (rideController.nearbyDrivers.isNotEmpty) {
                    Get.to(() => const DriverSearchPage());
                  } else {
                    Get.snackbar(
                      'Aucun chauffeur',
                      'Aucun chauffeur n\'est disponible pour le moment.',
                      backgroundColor: Colors.orange,
                      colorText: Colors.white,
                    );
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: iconColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text(
                  'Continuer',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
              ),
            ),
          ],
        ),
      );
    });
  }

  String _getStatusTitle(RideStatus status) {
    switch (status) {
      case RideStatus.searching:
        return 'Recherche d\'un chauffeur';
      case RideStatus.accepted:
        return 'Chauffeur en route';
      case RideStatus.inProgress:
        return 'Trajet en cours';
      default:
        return 'Trajet';
    }
  }

  String _getPaymentMethodText(String method) {
    switch (method) {
      case 'cash':
        return 'Espèces';
      case 'card':
        return 'Carte';
      case 'mobile':
        return 'Mobile Money';
      default:
        return method;
    }
  }

  void _showCancelDialog() {
    Get.dialog(
      AlertDialog(
        title: const Text('Annuler le trajet'),
        content: const Text('Êtes-vous sûr de vouloir annuler ce trajet ?'),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text('Non')),
          TextButton(
            onPressed: () {
              Get.back();
              rideController.cancelRide();
              Get.back();
            },
            child: const Text(
              'Oui, annuler',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMapWidget() {
    final ride = rideController.currentRide.value;
    if (ride == null) {
      return Container(
        color: Colors.grey[300],
        child: const Center(child: Text('Aucun trajet en cours')),
      );
    }

    // Position initiale de la carte - toujours centrée sur la position actuelle
    LatLng initialPosition;
    if (_currentPosition != null) {
      initialPosition = LatLng(
        _currentPosition!.latitude,
        _currentPosition!.longitude,
      );
    } else {
      // Position par défaut en Guinée (Conakry) en attendant la géolocalisation
      initialPosition = const LatLng(9.5370, -13.6785);
    }

    return GoogleMap(
      initialCameraPosition: CameraPosition(
        target: initialPosition,
        zoom: 16, // Zoom plus proche pour voir la position actuelle
      ),
      onMapCreated: _onMapCreated,
      myLocationEnabled: false,
      myLocationButtonEnabled: false,
      zoomControlsEnabled: false,
      mapToolbarEnabled: false,
      markers: _markers,
      polylines: _polylines,
    );
  }

  // Méthode pour ajouter les marqueurs des chauffeurs
  void _addDriverMarkers() {
    if (!rideController.isSearchingDriver.value) return;

    // Supprimer les anciens marqueurs de chauffeurs
    _markers.removeWhere(
      (marker) => marker.markerId.value.startsWith('driver_'),
    );

    // Ajouter les nouveaux marqueurs
    for (final driver in rideController.nearbyDrivers) {
      _markers.add(
        Marker(
          markerId: MarkerId('driver_${driver.id}'),
          position: LatLng(driver.lat, driver.lon),
          icon: BitmapDescriptor.defaultMarkerWithHue(
            BitmapDescriptor.hueOrange,
          ),
          infoWindow: InfoWindow(
            title: 'Chauffeur disponible',
            snippet: 'ID: ${driver.driverId}',
          ),
        ),
      );
    }
  }
}
