import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../controllers/ride_controller.dart';
import '../../theme/app_colors.dart';
import 'ride_tracking_page.dart';
import '../../services/supabase_service.dart';

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

    // Vérifier l'état d'authentification
    final user = SupabaseService.client.auth.currentUser;
    if (user == null) {
      print('⚠️ Utilisateur non connecté sur la page d\'aperçu');
      Get.snackbar(
        'Connexion requise',
        'Vous devez être connecté pour créer un trajet',
        backgroundColor: Colors.orange,
        colorText: Colors.white,
        duration: const Duration(seconds: 3),
      );
      // Rediriger vers la page de connexion
      Future.delayed(const Duration(seconds: 2), () {
        Get.offAllNamed('/login'); // ou la route appropriée
      });
      return;
    }

    print('✅ Utilisateur connecté: ${user.email}');
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
                BitmapDescriptor
                    .hueGreen, // Couleur verte pour les chauffeurs disponibles
              ),
              // Rendre le marqueur plus visible
              zIndex: 1000,
              visible: true,
              infoWindow: InfoWindow(
                title: '🚗 Chauffeur disponible',
                snippet:
                    'Distance: ${_calculateDriverDistance(driver).toStringAsFixed(1)} km\nCliquez pour plus d\'informations',
              ),
              // Animation pour attirer l'attention
              flat: true,
              rotation: 0,
              onTap: () => _showDriverPopup(driver), // NOUVEAU: Gestion du clic
              // Effet de pulsation pour attirer l'attention
              consumeTapEvents: true,
            );
          }).toSet();

      setState(() {
        _markers.addAll(driverMarkers);
      });
    } catch (e) {
      print('Erreur lors de l\'ajout des marqueurs des chauffeurs: $e');
    }
  }

  // Calculer la distance entre le point de départ et un chauffeur
  double _calculateDriverDistance(dynamic driver) {
    return rideController.calculateDistance(
      widget.pickupLat,
      widget.pickupLon,
      driver.lat,
      driver.lon,
    );
  }

  // NOUVELLE: Afficher le popup avec les informations du chauffeur
  void _showDriverPopup(dynamic driver) {
    final distance = _calculateDriverDistance(driver);

    Get.dialog(
      Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // En-tête avec icône de voiture
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.green,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.directions_car,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Chauffeur disponible',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.green[700],
                            ),
                          ),
                          Text(
                            'ID: ${driver.driverId.substring(0, 8)}...',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // Informations détaillées
              _buildDriverInfoRow(
                Icons.location_on,
                'Position',
                '${driver.lat.toStringAsFixed(4)}, ${driver.lon.toStringAsFixed(4)}',
              ),

              const SizedBox(height: 12),

              _buildDriverInfoRow(
                Icons.straighten,
                'Distance',
                '${distance.toStringAsFixed(1)} km de votre position',
              ),

              const SizedBox(height: 12),

              _buildDriverInfoRow(
                Icons.access_time,
                'Dernière mise à jour',
                _formatLastUpdated(driver.lastUpdated),
              ),

              if (driver.heading != null) ...[
                const SizedBox(height: 12),
                _buildDriverInfoRow(
                  Icons.compass_calibration,
                  'Direction',
                  '${driver.heading.toStringAsFixed(0)}°',
                ),
              ],

              if (driver.speed != null) ...[
                const SizedBox(height: 12),
                _buildDriverInfoRow(
                  Icons.speed,
                  'Vitesse',
                  '${driver.speed.toStringAsFixed(1)} km/h',
                ),
              ],

              const SizedBox(height: 20),

              // Boutons d'action
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Get.back(),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        side: BorderSide(color: Colors.grey[300]!),
                      ),
                      child: Text(
                        'Fermer',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        Get.back();
                        _startRideSearch();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'Choisir ce chauffeur',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
      barrierDismissible: true,
    );
  }

  // NOUVELLE: Construire une ligne d'information du chauffeur
  Widget _buildDriverInfoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, color: Colors.grey[600], size: 20),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[500],
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // NOUVELLE: Formater la dernière mise à jour
  String _formatLastUpdated(DateTime lastUpdated) {
    final now = DateTime.now();
    final difference = now.difference(lastUpdated);

    if (difference.inMinutes < 1) {
      return 'À l\'instant';
    } else if (difference.inMinutes < 60) {
      return 'Il y a ${difference.inMinutes} min';
    } else if (difference.inHours < 24) {
      return 'Il y a ${difference.inHours} h';
    } else {
      return 'Il y a ${difference.inDays} jour(s)';
    }
  }

  Future<void> _startRideSearch() async {
    if (_isCreatingRide) return;

    setState(() {
      _isCreatingRide = true;
    });

    try {
      // Vérifier si l'utilisateur est connecté
      final user = SupabaseService.client.auth.currentUser;
      if (user == null) {
        throw Exception('Vous devez être connecté pour créer un trajet');
      }

      print('🚀 Début de création du trajet...');
      print(
        '📍 Départ: ${widget.pickupAddress} (${widget.pickupLat}, ${widget.pickupLon})',
      );
      print(
        '🎯 Destination: ${widget.destinationAddress} (${widget.destinationLat}, ${widget.destinationLon})',
      );
      print('💳 Paiement: ${widget.paymentMethod}');

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

      print('✅ Trajet créé avec succès!');

      if (rideController.currentRide.value != null) {
        // Naviguer vers la page de suivi
        Get.off(() => const RideTrackingPage());
      } else {
        throw Exception('Le trajet a été créé mais n\'a pas pu être récupéré');
      }
    } catch (e) {
      print('❌ Erreur lors de la création du trajet: $e');
      Get.snackbar(
        'Erreur',
        'Impossible de créer le trajet: $e',
        backgroundColor: Colors.red,
        colorText: Colors.white,
        duration: const Duration(seconds: 5),
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

  // NOUVELLE: Méthode pour construire un élément de légende
  Widget _buildLegendItem(IconData icon, Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: color, size: 16),
        const SizedBox(width: 6),
        Text(label, style: TextStyle(fontSize: 11, color: Colors.grey[600])),
      ],
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
                  Expanded(
                    child: Column(
                      children: [
                        const Text(
                          'Aperçu du trajet',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 4),
                        Obx(() {
                          final driverCount =
                              rideController.nearbyDrivers.length;
                          if (driverCount > 0) {
                            return Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.green.withOpacity(0.8),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(
                                    Icons.directions_car,
                                    color: Colors.white,
                                    size: 12,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    '$driverCount disponible${driverCount > 1 ? 's' : ''}',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 10,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }
                          return const SizedBox.shrink();
                        }),
                      ],
                    ),
                  ),
                  const SizedBox(width: 48), // Pour équilibrer le bouton retour
                ],
              ),
            ),
          ),

          // Légende des marqueurs
          Positioned(
            top: 120,
            right: 16,
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.95),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Légende',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey[700],
                    ),
                  ),
                  const SizedBox(height: 8),
                  _buildLegendItem(
                    Icons.radio_button_checked,
                    Colors.green,
                    'Départ',
                  ),
                  const SizedBox(height: 4),
                  _buildLegendItem(
                    Icons.location_on,
                    Colors.red,
                    'Destination',
                  ),
                  const SizedBox(height: 4),
                  _buildLegendItem(
                    Icons.directions_car,
                    Colors.green,
                    'Chauffeur',
                  ),
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
                  topLeft: Radius.circular(24),
                  topRight: Radius.circular(24),
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
                  const SizedBox(height: 16),

                  // Section des chauffeurs disponibles
                  Obx(() => _buildAvailableDriversSection()),
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
                      child:
                          _isCreatingRide
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

  // NOUVELLE: Section des chauffeurs disponibles
  Widget _buildAvailableDriversSection() {
    final drivers = rideController.nearbyDrivers;

    if (drivers.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.orange.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.orange.withOpacity(0.3)),
        ),
        child: Row(
          children: [
            Icon(Icons.directions_car, color: Colors.orange, size: 24),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Aucun chauffeur disponible',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.orange[700],
                    ),
                  ),
                  Text(
                    'Nous chercherons des chauffeurs quand vous confirmerez',
                    style: TextStyle(fontSize: 12, color: Colors.orange[600]),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.green.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.green.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.directions_car, color: Colors.green, size: 24),
              const SizedBox(width: 8),
              Text(
                '${drivers.length} chauffeur${drivers.length > 1 ? 's' : ''} disponible${drivers.length > 1 ? 's' : ''}',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.green[700],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Liste des chauffeurs (limité à 3 pour l'aperçu)
          ...drivers.take(3).map((driver) {
            final distance = _calculateDriverDistance(driver);
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: Colors.green,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.directions_car,
                      color: Colors.white,
                      size: 16,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Chauffeur ${driver.driverId.substring(0, 8)}...',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        Text(
                          'À ${distance.toStringAsFixed(1)} km',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.green,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      'Disponible',
                      style: const TextStyle(
                        fontSize: 10,
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }).toList(),

          // Message si plus de 3 chauffeurs
          if (drivers.length > 3)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                'Et ${drivers.length - 3} autre${drivers.length - 3 > 1 ? 's' : ''} chauffeur${drivers.length - 3 > 1 ? 's' : ''} à proximité',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.green[600],
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
