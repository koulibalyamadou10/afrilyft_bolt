import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import '../../controllers/driver_controller.dart';
import '../../models/ride_model.dart';
import '../../theme/app_colors.dart';

class RideRequestsPage extends StatefulWidget {
  const RideRequestsPage({Key? key}) : super(key: key);

  @override
  State<RideRequestsPage> createState() => _RideRequestsPageState();
}

class _RideRequestsPageState extends State<RideRequestsPage> {
  final DriverController driverController = Get.find<DriverController>();
  GoogleMapController? _mapController;
  Set<Marker> _markers = {};
  Position? _currentPosition;
  bool _isLoadingLocation = true;

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
    _initializeMap();
  }

  @override
  void dispose() {
    _mapController?.dispose();
    super.dispose();
  }

  Future<void> _getCurrentLocation() async {
    try {
      setState(() {
        _isLoadingLocation = true;
      });

      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      setState(() {
        _currentPosition = position;
        _isLoadingLocation = false;
      });

      _updateMapWithCurrentLocation();
    } catch (e) {
      print('Erreur lors de l\'obtention de la position: $e');
      setState(() {
        _isLoadingLocation = false;
      });
    }
  }

  void _initializeMap() {
    // Marqueur de la position actuelle du chauffeur
    if (_currentPosition != null) {
      _markers.add(
        Marker(
          markerId: const MarkerId('driver_location'),
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
  }

  void _updateMapWithCurrentLocation() {
    if (_currentPosition == null || _mapController == null) return;

    final currentLatLng = LatLng(
      _currentPosition!.latitude,
      _currentPosition!.longitude,
    );

    // Mettre à jour le marqueur de position
    _markers.removeWhere(
      (marker) => marker.markerId.value == 'driver_location',
    );
    _markers.add(
      Marker(
        markerId: const MarkerId('driver_location'),
        position: currentLatLng,
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
        infoWindow: const InfoWindow(
          title: 'Votre position',
          snippet: 'Position actuelle',
        ),
      ),
    );

    // Centrer la carte sur la position actuelle
    _mapController!.animateCamera(
      CameraUpdate.newLatLngZoom(currentLatLng, 15),
    );
  }

  void _onMapCreated(GoogleMapController controller) {
    _mapController = controller;

    if (_currentPosition != null) {
      _updateMapWithCurrentLocation();
    }
  }

  void _addRideRequestMarkers() {
    // Supprimer les anciens marqueurs de demandes
    _markers.removeWhere(
      (marker) => marker.markerId.value.startsWith('request_'),
    );

    // Ajouter les marqueurs pour chaque demande
    for (final request in driverController.pendingRequests) {
      // Ici, vous devrez récupérer les coordonnées du point de départ
      // Pour l'instant, on utilise des coordonnées par défaut
      final pickupLatLng = const LatLng(9.5370, -13.6785); // Conakry par défaut

      _markers.add(
        Marker(
          markerId: MarkerId('request_${request.id}'),
          position: pickupLatLng,
          icon: BitmapDescriptor.defaultMarkerWithHue(
            BitmapDescriptor.hueOrange,
          ),
          infoWindow: InfoWindow(
            title: 'Demande de trajet',
            snippet:
                'De ${request.pickupAddress} vers ${request.destinationAddress}',
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.driverPrimary,
      appBar: AppBar(
        backgroundColor: AppColors.driverPrimary,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Get.back(),
        ),
        title: const Text(
          'Demandes de trajet',
          style: TextStyle(color: Colors.white),
        ),
        centerTitle: true,
      ),
      body: Obx(() {
        return Stack(
          children: [
            // Carte Google Maps
            _buildMapWidget(),

            // Indicateur de chargement
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
                      color: Colors.black.withValues(alpha: 0.7),
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
                              Colors.white,
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

            // Panneau des demandes en bas
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
                child: _buildRequestsPanel(),
              ),
            ),

            // Bouton de localisation
            if (_currentPosition != null)
              Positioned(
                bottom: 200,
                right: 16,
                child: FloatingActionButton(
                  onPressed: _updateMapWithCurrentLocation,
                  backgroundColor: AppColors.driverPrimary,
                  child: const Icon(Icons.my_location, color: Colors.white),
                ),
              ),
          ],
        );
      }),
    );
  }

  Widget _buildMapWidget() {
    // Position initiale de la carte
    LatLng initialPosition;
    if (_currentPosition != null) {
      initialPosition = LatLng(
        _currentPosition!.latitude,
        _currentPosition!.longitude,
      );
    } else {
      initialPosition = const LatLng(9.5370, -13.6785); // Conakry par défaut
    }

    return GoogleMap(
      initialCameraPosition: CameraPosition(target: initialPosition, zoom: 15),
      onMapCreated: _onMapCreated,
      myLocationEnabled: false,
      myLocationButtonEnabled: false,
      zoomControlsEnabled: false,
      mapToolbarEnabled: false,
      markers: _markers,
    );
  }

  Widget _buildRequestsPanel() {
    if (driverController.pendingRequests.isEmpty) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.inbox, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            'Aucune demande en attente',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            driverController.isOnline.value
                ? 'Les nouvelles demandes apparaîtront ici'
                : 'Activez le mode en ligne pour recevoir des demandes',
            style: TextStyle(fontSize: 14, color: Colors.grey[500]),
            textAlign: TextAlign.center,
          ),
        ],
      );
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text(
              'Demandes en attente',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.orange.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '${driverController.pendingRequests.length}',
                style: const TextStyle(
                  color: Colors.orange,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 200,
          child: ListView.builder(
            itemCount: driverController.pendingRequests.length,
            itemBuilder: (context, index) {
              final request = driverController.pendingRequests[index];
              return _buildRequestCard(request);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildRequestCard(RideRequest request) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[300]!),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.person, color: AppColors.driverPrimary),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  request.customerName ?? 'Client',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.orange.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${request.timeRemaining}s',
                  style: const TextStyle(
                    color: Colors.orange,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          Row(
            children: [
              const Icon(Icons.location_on, color: Colors.green, size: 16),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  request.pickupAddress,
                  style: const TextStyle(fontSize: 14),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),

          const SizedBox(height: 4),

          Row(
            children: [
              const Icon(Icons.flag, color: Colors.red, size: 16),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  request.destinationAddress,
                  style: const TextStyle(fontSize: 14),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed:
                      () => driverController.declineRideRequest(request.id),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.red,
                    side: const BorderSide(color: Colors.red),
                  ),
                  child: const Text('Refuser'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed:
                      () => driverController.acceptRideRequest(request.id),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.driverPrimary,
                  ),
                  child: const Text(
                    'Accepter',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
