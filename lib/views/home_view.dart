import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../controllers/navigation_controller.dart';
import '../controllers/ride_controller.dart';
import '../theme/app_colors.dart';
import 'components/bottom_navigation.dart';
import 'pages/carpool_page.dart';
import 'pages/settings_page.dart';
import 'pages/create_ride_page.dart';
import 'pages/ride_history_page.dart';
import 'pages/ride_tracking_page.dart';
import 'pages/map_test_page.dart';

class HomeView extends StatelessWidget {
  const HomeView({super.key});

  @override
  Widget build(BuildContext context) {
    // Initialiser les contrôleurs
    final NavigationController navigationController = Get.put(
      NavigationController(),
    );
    final RideController rideController = Get.put(RideController());

    // Liste des pages à afficher
    final List<Widget> pages = [
      const RidesPage(),
      const CarpoolPage(),
      const SettingsPage(),
    ];

    return Scaffold(
      body: Obx(() => pages[navigationController.currentIndex.value]),
      bottomNavigationBar: Obx(
        () => BottomNavigation(
          currentIndex: navigationController.currentIndex.value,
          onTap: (index) => navigationController.changePage(index),
        ),
      ),
    );
  }
}

class RidesPage extends StatelessWidget {
  const RidesPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final RideController rideController = Get.find<RideController>();

    return Scaffold(
      backgroundColor: AppColors.secondary,
      appBar: AppBar(
        backgroundColor: AppColors.secondary,
        elevation: 0,
        title: const Text(
          'AfriLyft',
          style: TextStyle(color: AppColors.white, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.history, color: Colors.white),
            onPressed: () => Get.to(() => const RideHistoryPage()),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Trajet en cours (si existant)
                Obx(() {
                  final currentRide = rideController.currentRide.value;
                  if (currentRide != null) {
                    return Container(
                      margin: const EdgeInsets.only(bottom: 16),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(
                                Icons.directions_car,
                                color: Colors.white,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                rideController.getStatusText(
                                  currentRide.status,
                                ),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '${currentRide.pickupAddress} → ${currentRide.destinationAddress}',
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 14,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 12),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed:
                                  () => Get.to(() => const RideTrackingPage()),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.white,
                                foregroundColor: AppColors.primary,
                              ),
                              child: const Text('Voir le trajet'),
                            ),
                          ),
                        ],
                      ),
                    );
                  }
                  return const SizedBox.shrink();
                }),

                // Barre de recherche principale
                GestureDetector(
                  onTap: () => Get.to(() => const CreateRidePage()),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.search, color: Colors.grey),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Text(
                            'Où allez-vous ?',
                            style: TextStyle(color: Colors.grey, fontSize: 16),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppColors.primary,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(
                            Icons.arrow_forward,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                // Bannière de bienvenue
                Container(
                  height: 180,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    image: const DecorationImage(
                      image: AssetImage('assets/images/guinea_background.jpg'),
                      fit: BoxFit.cover,
                    ),
                  ),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Colors.black.withOpacity(0.7),
                        ],
                      ),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Bienvenue sur AfriLyft Guinée',
                          style: TextStyle(
                            color: AppColors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Des trajets sûrs et fiables dans toute la Guinée. Explorez Conakry, Kindia et au-delà avec des chauffeurs locaux de confiance.',
                          style: TextStyle(
                            color: AppColors.lightGrey,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: const [
                            Text(
                              'En savoir plus',
                              style: TextStyle(
                                color: AppColors.primary,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            SizedBox(width: 4),
                            Icon(
                              Icons.arrow_forward,
                              color: AppColors.primary,
                              size: 16,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                // Section Suggestions
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Services',
                      style: TextStyle(
                        color: AppColors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    TextButton(
                      onPressed: () {},
                      child: const Text(
                        'Voir tout',
                        style: TextStyle(color: AppColors.mediumGrey),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // Options de trajet
                Row(
                  children: [
                    _buildOptionCard(
                      icon: Icons.directions_car,
                      label: 'Trajet',
                      isPromo: true,
                      onTap: () => Get.to(() => const CreateRidePage()),
                    ),
                    const SizedBox(width: 12),
                    _buildOptionCard(
                      icon: Icons.access_time,
                      label: 'Programmer',
                      onTap: () => Get.to(() => const CreateRidePage()),
                    ),
                    const SizedBox(width: 12),
                    _buildOptionCard(
                      icon: Icons.route,
                      label: 'Longue distance',
                      onTap: () => Get.to(() => const CreateRidePage()),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildOptionCard({
    required IconData icon,
    required String label,
    bool isPromo = false,
    VoidCallback? onTap,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          height: 100,
          decoration: BoxDecoration(
            color: Colors.grey[900],
            borderRadius: BorderRadius.circular(12),
          ),
          child: Stack(
            children: [
              if (isPromo)
                Positioned(
                  top: 8,
                  left: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.success,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Text(
                      'Promo',
                      style: TextStyle(
                        color: AppColors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(icon, color: AppColors.white, size: 28),
                    const SizedBox(height: 8),
                    Text(
                      label,
                      style: const TextStyle(
                        color: AppColors.white,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
