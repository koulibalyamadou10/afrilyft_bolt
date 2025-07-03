import 'package:afrilyft/models/ride_model.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:afrilyft/views/pages/create_ride_page.dart';
import 'package:afrilyft/controllers/ride_controller.dart';
import '../../theme/app_colors.dart';
import 'ride_detail_page.dart';

class DriverSearchPage extends StatefulWidget {
  const DriverSearchPage({Key? key}) : super(key: key);

  @override
  State<DriverSearchPage> createState() => _DriverSearchPageState();
}

class _DriverSearchPageState extends State<DriverSearchPage>
    with TickerProviderStateMixin {
  final RideController rideController = Get.put(RideController());
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

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

    // Démarrer le timer de recherche quand on arrive sur cette page
    final currentRide = rideController.currentRide.value;
    if (currentRide != null && rideController.isSearchingDriver.value) {
      print(
        '⏰ Démarrage du timer de recherche pour le trajet: ${currentRide.id}',
      );
      rideController.startSearchTimer();
    }

    // Écouter les changements du trajet actuel
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
      } else if (ride.status == RideStatus.accepted) {
        // Naviguer vers la page détail
        Get.offAll(() => RideDetailPage(rideId: ride.id));
      }
    });
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.secondary,
      body: SafeArea(
        child: Column(
          children: [
            // En-tête
            Container(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.white),
                    onPressed: () => Get.back(),
                  ),
                  const Expanded(
                    child: Text(
                      'Recherche de chauffeur',
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

            // Contenu principal
            Expanded(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Loader animé
                    AnimatedBuilder(
                      animation: _pulseAnimation,
                      builder: (context, child) {
                        return Transform.scale(
                          scale: _pulseAnimation.value,
                          child: Container(
                            width: 120,
                            height: 120,
                            decoration: BoxDecoration(
                              color: AppColors.primary.withOpacity(0.1),
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: AppColors.primary,
                                width: 3,
                              ),
                            ),
                            child: const Center(
                              child: Icon(
                                Icons.directions_car,
                                color: AppColors.primary,
                                size: 60,
                              ),
                            ),
                          ),
                        );
                      },
                    ),

                    const SizedBox(height: 40),

                    // Texte principal
                    const Text(
                      'Nous sommes en train d\'alerter les chauffeurs',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                      ),
                      textAlign: TextAlign.center,
                    ),

                    const SizedBox(height: 16),

                    // Texte secondaire
                    const Text(
                      'Celui qui acceptera viendra vous chercher',
                      style: TextStyle(color: Colors.white70, fontSize: 16),
                      textAlign: TextAlign.center,
                    ),

                    const SizedBox(height: 40),

                    // Timer
                    Obx(() {
                      final remaining = rideController.timeRemaining.value;
                      final minutes = remaining ~/ 60;
                      final seconds = remaining % 60;

                      return Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          color:
                              remaining <= 30
                                  ? Colors.red.withOpacity(0.2)
                                  : Colors.white.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color:
                                remaining <= 30
                                    ? Colors.red
                                    : Colors.white.withOpacity(0.3),
                            width: 1,
                          ),
                        ),
                        child: Text(
                          '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: remaining <= 30 ? Colors.red : Colors.white,
                          ),
                        ),
                      );
                    }),

                    const SizedBox(height: 20),

                    // Nombre de chauffeurs notifiés
                    Obx(() {
                      final driverCount = rideController.nearbyDrivers.length;
                      return Text(
                        '$driverCount chauffeur${driverCount > 1 ? 's' : ''} notifié${driverCount > 1 ? 's' : ''}',
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 14,
                        ),
                      );
                    }),
                  ],
                ),
              ),
            ),

            // Bouton d'annulation en bas
            Container(
              padding: const EdgeInsets.all(20),
              child: SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: _showCancelDialog,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white,
                    side: const BorderSide(color: Colors.white),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Annuler la recherche',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showCancelDialog() {
    Get.dialog(
      AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Annuler la recherche',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        content: const Text(
          'Êtes-vous sûr de vouloir annuler la recherche de chauffeur ?',
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Non', style: TextStyle(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () {
              Get.back();
              rideController.cancelRide();
              // Retourner a la page de creation de trajet avec le nom classe de la page
              Get.offAll(() => const CreateRidePage());
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
