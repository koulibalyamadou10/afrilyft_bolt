import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controllers/driver_controller.dart';
import '../../theme/app_colors.dart';

class DriverHomePage extends StatelessWidget {
  const DriverHomePage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final DriverController driverController = Get.put(DriverController());

    return Scaffold(
      backgroundColor: AppColors.driverPrimary,
      appBar: AppBar(
        backgroundColor: AppColors.driverPrimary,
        elevation: 0,
        title: const Text('AfriLyft Driver', style: TextStyle(color: Colors.white)),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings, color: Colors.white),
            onPressed: () => Get.toNamed('/driver-settings'),
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              // Statut en ligne/hors ligne
              Obx(() => _buildStatusCard(driverController)),
              
              const SizedBox(height: 20),
              
              // Statistiques du jour
              _buildStatsCard(),
              
              const SizedBox(height: 20),
              
              // Demandes en attente
              Expanded(
                child: Obx(() => _buildPendingRequests(driverController)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusCard(DriverController controller) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    controller.isOnline.value ? 'En ligne' : 'Hors ligne',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: controller.isOnline.value ? Colors.green : Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    controller.isOnline.value 
                        ? 'Prêt à recevoir des demandes'
                        : 'Vous ne recevez pas de demandes',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
              Switch(
                value: controller.isOnline.value,
                onChanged: (_) => controller.toggleOnlineStatus(),
                activeColor: Colors.green,
              ),
            ],
          ),
          
          if (controller.isOnline.value) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(Icons.location_on, color: Colors.green, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Position partagée en temps réel',
                      style: TextStyle(
                        color: Colors.green[700],
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStatsCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
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
          const Text(
            'Statistiques du jour',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStatItem('Trajets', '12', Icons.directions_car),
              _buildStatItem('Revenus', '45,000 GNF', Icons.monetization_on),
              _buildStatItem('Temps', '6h 30m', Icons.access_time),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: AppColors.driverPrimary, size: 24),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
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

  Widget _buildPendingRequests(DriverController controller) {
    if (controller.pendingRequests.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.inbox,
                size: 64,
                color: Colors.grey[400],
              ),
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
                controller.isOnline.value 
                    ? 'Les nouvelles demandes apparaîtront ici'
                    : 'Activez le mode en ligne pour recevoir des demandes',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[500],
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.all(16),
            child: Text(
              'Demandes en attente',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: controller.pendingRequests.length,
              itemBuilder: (context, index) {
                final request = controller.pendingRequests[index];
                return _buildRequestCard(request, controller);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRequestCard(RideRequest request, DriverController controller) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
                  color: Colors.orange.withOpacity(0.1),
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
                  onPressed: () => controller.declineRideRequest(request.id),
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
                  onPressed: () => controller.acceptRideRequest(request.id),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.driverPrimary,
                  ),
                  child: const Text('Accepter', style: TextStyle(color: Colors.white)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// Modèle pour les demandes de trajet
class RideRequest {
  final String id;
  final String rideId;
  final String? customerName;
  final String pickupAddress;
  final String destinationAddress;
  final DateTime sentAt;
  final DateTime expiresAt;

  RideRequest({
    required this.id,
    required this.rideId,
    this.customerName,
    required this.pickupAddress,
    required this.destinationAddress,
    required this.sentAt,
    required this.expiresAt,
  });

  factory RideRequest.fromJson(Map<String, dynamic> json) {
    return RideRequest(
      id: json['id'],
      rideId: json['ride_id'],
      customerName: json['customer_name'],
      pickupAddress: json['pickup_address'] ?? '',
      destinationAddress: json['destination_address'] ?? '',
      sentAt: DateTime.parse(json['sent_at']),
      expiresAt: DateTime.parse(json['expires_at']),
    );
  }

  int get timeRemaining {
    final now = DateTime.now();
    final remaining = expiresAt.difference(now).inSeconds;
    return remaining > 0 ? remaining : 0;
  }
}