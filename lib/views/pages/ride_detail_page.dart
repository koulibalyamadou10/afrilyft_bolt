import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../controllers/ride_controller.dart';
import '../../theme/app_colors.dart';

class RideDetailPage extends StatefulWidget {
  final String rideId;
  const RideDetailPage({Key? key, required this.rideId}) : super(key: key);

  @override
  State<RideDetailPage> createState() => _RideDetailPageState();
}

class _RideDetailPageState extends State<RideDetailPage> {
  final RideController rideController = Get.find<RideController>();
  Map<String, dynamic>? rideData;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadRideDetail();
  }

  Future<void> _loadRideDetail() async {
    final data = await rideController.getRideDetail(widget.rideId);
    setState(() {
      rideData = data;
      isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading || rideData == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final pickupLat = (rideData!['pickup_latitude'] as num).toDouble();
    final pickupLon = (rideData!['pickup_longitude'] as num).toDouble();
    final destLat = (rideData!['destination_latitude'] as num).toDouble();
    final destLon = (rideData!['destination_longitude'] as num).toDouble();
    final driverLocation = rideData!['driver_location'];
    final customer = rideData!['customer'];
    final driver = rideData!['driver'];

    Set<Marker> markers = {
      Marker(
        markerId: const MarkerId('pickup'),
        position: LatLng(pickupLat, pickupLon),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
        infoWindow: InfoWindow(
          title: 'Client',
          snippet: rideData!['pickup_address'],
        ),
      ),
      Marker(
        markerId: const MarkerId('destination'),
        position: LatLng(destLat, destLon),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
        infoWindow: InfoWindow(
          title: 'Destination',
          snippet: rideData!['destination_address'],
        ),
      ),
    };

    if (driverLocation != null) {
      markers.add(
        Marker(
          markerId: const MarkerId('driver'),
          position: LatLng(
            (driverLocation['latitude'] as num).toDouble(),
            (driverLocation['longitude'] as num).toDouble(),
          ),
          icon: rideController.carMarkerIcon,
          infoWindow: InfoWindow(
            title: 'Chauffeur',
            snippet: driver?['full_name'] ?? '',
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Détail du trajet'),
        backgroundColor: AppColors.primary,
      ),
      body: Column(
        children: [
          // Carte
          SizedBox(
            height: 300,
            child: GoogleMap(
              initialCameraPosition: CameraPosition(
                target: LatLng(pickupLat, pickupLon),
                zoom: 13,
              ),
              markers: markers,
              myLocationEnabled: true,
              myLocationButtonEnabled: true,
            ),
          ),
          // Infos client et chauffeur
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                _buildUserInfo('Client', customer),
                const SizedBox(height: 12),
                _buildUserInfo('Chauffeur', driver),
                const SizedBox(height: 12),
                Row(
                  children: [
                    const Icon(Icons.location_on, color: Colors.green),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text('Départ : ${rideData!['pickup_address']}'),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.flag, color: Colors.red),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Arrivée : ${rideData!['destination_address']}',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    const Icon(Icons.info, color: Colors.blue),
                    const SizedBox(width: 8),
                    Text('Statut : ${rideData!['status']}'),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUserInfo(String label, Map<String, dynamic>? user) {
    if (user == null) return const SizedBox();
    return Row(
      children: [
        CircleAvatar(
          backgroundImage:
              user['avatar_url'] != null
                  ? NetworkImage(user['avatar_url'])
                  : null,
          child: user['avatar_url'] == null ? const Icon(Icons.person) : null,
        ),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '$label : ${user['full_name'] ?? ''}',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            if (user['phone'] != null) Text('Téléphone : ${user['phone']}'),
          ],
        ),
      ],
    );
  }
}
