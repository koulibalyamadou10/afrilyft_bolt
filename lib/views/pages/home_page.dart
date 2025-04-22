import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../theme/app_colors.dart';
import '../../controllers/navigation_controller.dart';
import '../components/bottom_navigation.dart';

import '../components/reserve_button.dart';
import '../components/welcome_banner.dart';
import '../components/suggestion_card.dart';

class HomePage extends StatelessWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Initialiser le contrôleur de navigation
    final NavigationController navigationController = Get.put(NavigationController());

    // Liste des pages à afficher
    final List<Widget> pages = [
      const HomeContent(),
      const SearchPage(),
      const HistoryPage(),
      const ProfilePage(),
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

// Pages temporaires pour la démonstration
class HomeContent extends StatelessWidget {
  const HomeContent({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.secondary,
      appBar: AppBar(
        backgroundColor: AppColors.secondary,
        elevation: 0,
        title: const Text('Rides', style: TextStyle(color: AppColors.white)),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Barre de recherche
              const SearchBar(),
              
              const SizedBox(height: 16),
              
              // Bouton "Reserve for Later"
              const ReserveButton(),
              
              const SizedBox(height: 24),
              
              // Bannière de bienvenue
              const WelcomeBanner(),
              
              const SizedBox(height: 24),
              
              // Section Suggestions
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Suggestions',
                    style: TextStyle(
                      color: AppColors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  TextButton(
                    onPressed: () {},
                    child: const Text(
                      'See all',
                      style: TextStyle(
                        color: AppColors.mediumGrey,
                      ),
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 16),
              
              // Options de trajet
              Row(
                children: const [
                  SuggestionCard(
                    icon: Icons.directions_car,
                    label: 'Ride',
                    isPromo: true,
                  ),
                  SizedBox(width: 12),
                  SuggestionCard(
                    icon: Icons.access_time,
                    label: 'Reserve',
                  ),
                  SizedBox(width: 12),
                  SuggestionCard(
                    icon: Icons.route,
                    label: 'Long Distance',
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {},
        backgroundColor: AppColors.primary,
        child: const Icon(Icons.menu, color: AppColors.white),
      ),
    );
  }
}

class SearchPage extends StatelessWidget {
  const SearchPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return const Center(child: Text('Page de recherche'));
  }
}

class HistoryPage extends StatelessWidget {
  const HistoryPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return const Center(child: Text('Page d\'historique'));
  }
}

class ProfilePage extends StatelessWidget {
  const ProfilePage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return const Center(child: Text('Page de profil'));
  }
} 