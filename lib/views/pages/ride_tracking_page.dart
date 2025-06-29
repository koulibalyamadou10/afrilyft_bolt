import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controllers/ride_controller.dart';
import '../../models/ride_model.dart';
import '../../theme/app_colors.dart';

class RideTrackingPage extends StatefulWidget {
  const RideTrackingPage({Key? key}) : super(key: key);

  @override
  State<RideTrackingPage> createState() => _RideTrackingPageState();
}

class _RideTrackingPageState extends State<RideTrackingPage> {
  final RideController rideController = Get.find<RideController>();

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
            // Carte (simulée)
            Container(
              color: Colors.grey[300],
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.map,
                      size: 100,
                      color: Colors.grey[600],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Carte interactive',
                      style: TextStyle(
                        fontSize: 18,
                        color: Colors.grey[600],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Intégration Google Maps à venir',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[500],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Overlay des chauffeurs à proximité
            if (rideController.isSearchingDriver.value)
              ...rideController.nearbyDrivers.map((driver) => Positioned(
                top: 200 + (driver.lat * 10).toInt() % 200,
                left: 100 + (driver.lon * 10).toInt() % 200,
                child: _buildDriverMarker(),
              )),

            // En-tête
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.only(top: 50, left: 16, right: 16, bottom: 16),
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
          ],
        );
      }),
    );
  }

  Widget _buildDriverMarker() {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: AppColors.primary,
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
      child: const Icon(
        Icons.directions_car,
        color: Colors.white,
        size: 20,
      ),
    );
  }

  Widget _buildRideInfo(RideModel ride) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Statut
        Container(
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

        // Recherche en cours
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
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
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
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
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
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
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
    return Obx(() => Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Row(
            children: [
              const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'Recherche d\'un chauffeur...',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '${rideController.nearbyDrivers.length} chauffeurs trouvés à proximité',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    ));
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
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Non'),
          ),
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
}