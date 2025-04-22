import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import 'package:get/get.dart';
import 'reserve_ride_page.dart';

class ReservePage extends StatelessWidget {
  const ReservePage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.secondary,
      appBar: AppBar(
        backgroundColor: AppColors.secondary,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Reserve', style: TextStyle(color: Colors.white)),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image en haut
            Container(
              width: double.infinity,
              height: 180,
              decoration: const BoxDecoration(
                image: DecorationImage(
                  image: AssetImage('assets/images/everyone_can_code.webp'),
                  fit: BoxFit.cover,
                ),
              ),
            ),
            
            // Titre principal
            const Padding(
              padding: EdgeInsets.fromLTRB(20, 20, 20, 20),
              child: Text(
                'Reserve in Guinea',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            
            // Liste des avantages
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    _buildFeatureItem(
                      icon: Icons.calendar_today,
                      iconColor: const Color(0xFFFF6B5B),
                      text: 'Schedule rides between Conakry, Kindia, and other cities up to 3 days in advance',
                    ),
                    
                    _buildFeatureItem(
                      icon: Icons.access_time,
                      iconColor: const Color(0xFFFF6B5B),
                      text: 'Extra wait time included for your convenience when traveling in Guinea',
                    ),
                    
                    _buildFeatureItem(
                      icon: Icons.account_balance_wallet,
                      iconColor: const Color(0xFFFF6B5B),
                      text: 'Pay with Guinean Franc (GNF) or mobile money when your ride arrives',
                    ),
                    
                    _buildFeatureItem(
                      icon: Icons.cancel,
                      iconColor: const Color(0xFFFF6B5B),
                      text: 'Free cancellation up to 60 minutes before your scheduled pickup',
                    ),
                    
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
            
            // Bouton de réservation
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 10, 20, 10),
              child: SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: () {
                    Get.to(() => const ReserveRidePage(), transition: Transition.rightToLeft);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFF6B5B),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text(
                    'Reserve a ride in Guinea',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
            
            // // Indicateur en bas
            // Center(
            //   child: Container(
            //     width: 120,
            //     height: 5,
            //     margin: const EdgeInsets.only(bottom: 10, top: 5),
            //     decoration: BoxDecoration(
            //       color: Colors.grey[600],
            //       borderRadius: BorderRadius.circular(10),
            //     ),
            //   ),
            // ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildFeatureItem({
    required IconData icon,
    required Color iconColor,
    required String text,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            color: iconColor,
            size: 24,
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 15,
                height: 1.3,
              ),
            ),
          ),
        ],
      ),
    );
  }
} 