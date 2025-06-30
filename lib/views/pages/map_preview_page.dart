import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../controllers/ride_controller.dart';
import '../../theme/app_colors.dart';
import 'ride_tracking_page.dart';

class MapPreviewPage extends StatefulWidget {
  final double pickupLat;
  final double pickupLon;
  final String pickupAddress;
  final double destinationLat;
  final double destinationLon;
  final String destinationAddress;
  final String paymentMethod;
  final String? notes;
  final DateTime? scheduledFor;

  const MapPreviewPage({
    Key? key,
    required this.pickupLat,
    required this.pickupLon,
    required this.pickupAddress,
    required this.destinationLat,
    required this.destinationLon,
    required this.destinationAddress,
    required this.paymentMethod,
    this.notes,
    this.scheduledFor,
  }) : super(key: key);

  @override
  State<MapPreviewPage> createState() => _MapPreviewPageState();
}

class _MapPreviewPageState extends State<MapPreviewPage> {
  final RideController rideController = Get.find<RideController>();
  bool _showingDrivers = false;
  bool _mapError = false;
  bool _isCreatingRide = false;
  GoogleMapController? _mapController;
  Set<Marker> _markers = {};
  Set<Polyline> _polylines = {};

  @override
  void initState() {
    super.initState();
    _initializeMap();
    _loadNearbyDrivers();
  }

  void _initializeMap() {
    try {
      // Créer les marqueurs pour le point de départ et d'arrivée
      _markers = {
        Marker(
          markerId: const MarkerId('pickup'),
          position: LatLng(widget.pickupLat, widget.pickupLon),
          icon: BitmapDescriptor.defaultMarkerWithHue(
            BitmapDescriptor.hueGreen,
          ),
          infoWindow: InfoWindow(
            title: 'Point de départ',
            snippet: widget.pickupAddress,
          ),
        ),
        Marker(
          markerId: const MarkerId('destination'),
          position: LatLng(widget.destinationLat, widget.destinationLon),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
          infoWindow: InfoWindow(
            title: 'Destination',
            snippet: widget.destinationAddress,
          ),
        ),
      };

      // Créer une ligne entre le point de départ et d'arrivée
      _polylines = {
        Polyline(
          polylineId: const PolylineId('route'),
          points: [
            LatLng(widget.pickupLat, widget.pickupLon),
            LatLng(widget.destinationLat, widget.destinationLon),
          ],
          color: AppColors.primary,
          width: 3,
        ),
      };
    } catch (e) {
      print('Erreur lors de l\'initialisation de la carte: $e');
      setState(() {
        _mapError = true;
      });
    }
  }

  Future<void> _loadNearbyDrivers() async {
    setState(() {
      _showingDrivers = true;
    });

    try {
      // Charger les chauffeurs à proximité pour prévisualisation
      await rideController.findNearbyDriversPreview(
        widget.pickupLat,
        widget.pickupLon,
      );

      // Ajouter les marqueurs des chauffeurs
      _addDriverMarkers();
    } catch (e) {
      print('Erreur lors du chargement des chauffeurs: $e');
    } finally {
      setState(() {
        _showingDrivers = false;
      });
    }
  }

  void _addDriverMarkers() {
    try {
      final driverMarkers =
          rideController.nearbyDrivers.map((driver) {
            return Marker(
              markerId: MarkerId('driver_${driver.id}'),
              position: LatLng(driver.lat, driver.lon),
              icon: BitmapDescriptor.defaultMarkerWithHue(
                BitmapDescriptor.hueBlue,
              ),
              infoWindow: InfoWindow(
                title: 'Chauffeur disponible',
                snippet: 'ID: ${driver.driverId}',
              ),
            );
          }).toSet();

      setState(() {
        _markers.addAll(driverMarkers);
      });
    } catch (e) {
      print('Erreur lors de l\'ajout des marqueurs des chauffeurs: $e');
    }
  }

  Future<void> _startRideSearch() async {
    if (_isCreatingRide) return;
    
    setState(() {
      _isCreatingRide = true;
    });
    
    try {
      // Créer le trajet et démarrer la recherche
      await rideController.createRide(
        pickupLat: widget.pickupLat,
        pickupLon: widget.pickupLon,
        pickupAddress: widget.pickupAddress,
        destinationLat: widget.destinationLat,
        destinationLon: widget.destinationLon,
        destinationAddress: widget.destinationAddress,
        paymentMethod: widget.paymentMethod,
        notes: widget.notes,
        scheduledFor: widget.scheduledFor,
      );

      if (rideController.currentRide.value != null) {
        // Naviguer vers la page de suivi
        Get.off(() => const RideTrackingPage());
      }
    } catch (e) {
      Get.snackbar(
        'Erreur',
        'Impossible de créer le trajet: $e',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    } finally {
      setState(() {
        _isCreatingRide = false;
      });
    }
  }

  double _calculateDistance() {
    return rideController.calculateDistance(
      widget.pickupLat,
      widget.pickupLon,
      widget.destinationLat,
      widget.destinationLon,
    );
  }

  void _onMapCreated(GoogleMapController controller) {
    _mapController = controller;

    // Ajuster la caméra pour afficher tous les marqueurs
    _fitBounds();
  }

  void _fitBounds() {
    if (_mapController == null) return;

    try {
      final bounds = LatLngBounds(
        southwest: LatLng(
          [
            widget.pickupLat,
            widget.destinationLat,
          ].reduce((a, b) => a < b ? a : b),
          [
            widget.pickupLon,
            widget.destinationLon,
          ].reduce((a, b) => a < b ? a : b),
        ),
        northeast: LatLng(
          [
            widget.pickupLat,
            widget.destinationLat,
          ].reduce((a, b) => a > b ? a : b),
          [
            widget.pickupLon,
            widget.destinationLon,
          ].reduce((a, b) => a > b ? a : b),
        ),
      );

      _mapController!.animateCamera(CameraUpdate.newLatLngBounds(bounds, 50));
    } catch (e) {
      print('Erreur lors de l\'ajustement de la caméra: $e');
    }
  }

  Widget _buildMapWidget() {
    if (_mapError) {
      return _buildMapErrorWidget();
    }

    return GoogleMap(
      onMapCreated: _onMapCreated,
      initialCameraPosition: CameraPosition(
        target: LatLng(
          (widget.pickupLat + widget.destinationLat) / 2,
          (widget.pickupLon + widget.destinationLon) / 2,
        ),
        zoom: 12,
      ),
      markers: _markers,
      polylines: _polylines,
      myLocationEnabled: true,
      myLocationButtonEnabled: true,
      zoomControlsEnabled: false,
      mapToolbarEnabled: false,
      onCameraMove: (position) {
        // Gérer les erreurs de carte ici
      },
    );
  }

  Widget _buildMapErrorWidget() {
    return Container(
      color: Colors.grey[300],
      child: Stack(
        children: [
          // Carte statique de base
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.map, size: 100, color: Colors.grey[600]),
                const SizedBox(height: 16),
                Text(
                  'Carte temporairement indisponible',
                  style: TextStyle(
                    fontSize: 18,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Vérifiez votre connexion internet',
                  style: TextStyle(fontSize: 14, color: Colors.grey[500]),
                ),
              ],
            ),
          ),

          // Marqueurs simulés sur la carte statique
          Positioned(
            bottom: 300,
            left: 100,
            child: _buildStaticMarker(
              Icons.radio_button_checked,
              AppColors.primary,
              'Départ',
            ),
          ),

          Positioned(
            top: 150,
            right: 80,
            child: _buildStaticMarker(Icons.location_on, Colors.red, 'Arrivée'),
          ),

          // Ligne de trajet simulée
          Positioned(
            top: 200,
            left: 120,
            child: Container(
              width: 200,
              height: 2,
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(1),
              ),
            ),
          ),

          // Bouton de réessai
          Positioned(
            bottom: 100,
            left: 0,
            right: 0,
            child: Center(
              child: ElevatedButton(
                onPressed: () {
                  setState(() {
                    _mapError = false;
                    _initializeMap();
                  });
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                ),
                child: const Text('Réessayer Google Maps'),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStaticMarker(IconData icon, Color color, String label) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 6,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Icon(icon, color: Colors.white, size: 20),
        ),
        const SizedBox(height: 4),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Text(
            label,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final distance = _calculateDistance();
    final estimatedTime = (distance * 2.5).round(); // 2.5 min par km
    final estimatedPrice = (distance * 1500).round(); // 1500 GNF par km

    return Scaffold(
      backgroundColor: AppColors.secondary,
      body: Stack(
        children: [
          // Carte Google Maps
          _buildMapWidget(),

          // Indicateur de chargement des chauffeurs
          if (_showingDrivers)
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
                        'Recherche de chauffeurs...',
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
                  const Expanded(
                    child: Text(
                      'Aperçu du trajet',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(width: 48), // Pour équilibrer le bouton retour
                ],
              ),
            ),
          ),

          // Panneau d'informations en bas
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Informations du trajet
                  Row(
                    children: [
                      Expanded(
                        child: _buildInfoCard(
                          'Distance',
                          '${distance.toStringAsFixed(1)} km',
                          Icons.straighten,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildInfoCard(
                          'Temps estimé',
                          '${estimatedTime} min',
                          Icons.access_time,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildInfoCard(
                          'Prix estimé',
                          '${estimatedPrice} GNF',
                          Icons.attach_money,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Adresses
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      children: [
                        _buildAddressRow(
                          'Départ',
                          widget.pickupAddress,
                          Icons.radio_button_checked,
                          AppColors.primary,
                        ),
                        const SizedBox(height: 12),
                        _buildAddressRow(
                          'Destination',
                          widget.destinationAddress,
                          Icons.location_on,
                          Colors.red,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Bouton de confirmation
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isCreatingRide ? null : _startRideSearch,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: _isCreatingRide
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  Colors.white,
                                ),
                                strokeWidth: 2,
                              ),
                            )
                          : const Text(
                              'Confirmer le trajet',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard(String title, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Icon(icon, color: AppColors.primary, size: 20),
          const SizedBox(height: 4),
          Text(title, style: const TextStyle(fontSize: 12, color: Colors.grey)),
          const SizedBox(height: 2),
          Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.primary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAddressRow(
    String title,
    String address,
    IconData icon,
    Color color,
  ) {
    return Row(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 12,
                  color: Colors.grey,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                address,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }
}