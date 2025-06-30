import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../theme/app_colors.dart';
import '../../controllers/auth_controller.dart';
import 'edit_profile_page.dart';
import 'payment_methods_page.dart';
import 'notification_settings_page.dart';
import 'promo_codes_page.dart';
import 'ride_history_page.dart';
import 'saved_locations_page.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final AuthController authController = Get.find<AuthController>();
    
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: AppColors.secondary,
        elevation: 0,
        title: const Text('Settings', style: TextStyle(color: AppColors.white)),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Profil utilisateur
            Container(
              margin: const EdgeInsets.fromLTRB(16, 20, 16, 20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Obx(() {
                final profile = authController.userProfile.value;
                final initials = profile?.fullName.isNotEmpty == true
                    ? profile!.fullName.split(' ').map((e) => e.isNotEmpty ? e[0] : '').join().toUpperCase()
                    : 'U';
                
                return ListTile(
                  contentPadding: const EdgeInsets.all(16),
                  leading: CircleAvatar(
                    radius: 30,
                    backgroundColor: const Color(0xFFFF6B5B),
                    child: Text(
                      initials,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                  ),
                  title: Text(
                    profile?.fullName ?? 'Utilisateur',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  subtitle: Text(
                    profile?.phone ?? '',
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.black54,
                    ),
                  ),
                  trailing: const Icon(
                    Icons.chevron_right,
                    color: Colors.black54,
                  ),
                  onTap: () => Get.to(() => const EditProfilePage()),
                );
              }),
            ),
            
            // Section Compte
            _buildSectionTitle('Account'),
            
            _buildSettingCard(
              icon: Icons.person_outline,
              iconColor: Colors.red,
              iconBackground: Colors.red.withOpacity(0.1),
              title: 'Edit Profile',
              subtitle: 'Update your personal information',
              onTap: () => Get.to(() => const EditProfilePage()),
            ),
            
            _buildSettingCard(
              icon: Icons.credit_card,
              iconColor: Colors.orange,
              iconBackground: Colors.orange.withOpacity(0.1),
              title: 'Payment Methods',
              subtitle: 'Manage your payment options',
              onTap: () => Get.to(() => const PaymentMethodsPage()),
            ),
            
            _buildSettingCard(
              icon: Icons.location_on_outlined,
              iconColor: Colors.red,
              iconBackground: Colors.red.withOpacity(0.1),
              title: 'Saved Locations',
              subtitle: 'Manage your saved addresses',
              onTap: () => Get.to(() => const SavedLocationsPage()),
            ),
            
            _buildSettingCard(
              icon: Icons.history,
              iconColor: Colors.blue,
              iconBackground: Colors.blue.withOpacity(0.1),
              title: 'Ride History',
              subtitle: 'View your past rides',
              onTap: () => Get.to(() => const RideHistoryPage()),
            ),
            
            _buildSettingCard(
              icon: Icons.local_offer_outlined,
              iconColor: Colors.red,
              iconBackground: Colors.red.withOpacity(0.1),
              title: 'Promo Codes',
              subtitle: 'Manage your promotional offers',
              onTap: () => Get.to(() => const PromoCodesPage()),
            ),
            
            // Section Préférences
            _buildSectionTitle('Preferences'),
            
            _buildSettingCard(
              icon: Icons.notifications_outlined,
              iconColor: Colors.red,
              iconBackground: Colors.red.withOpacity(0.1),
              title: 'Notifications',
              subtitle: 'Manage your notification preferences',
              onTap: () => Get.to(() => const NotificationSettingsPage()),
            ),
            
            _buildSettingCard(
              icon: Icons.shield_outlined,
              iconColor: Colors.red,
              iconBackground: Colors.red.withOpacity(0.1),
              title: 'Privacy',
              subtitle: 'Control your privacy settings',
              onTap: () {
                // Navigation vers la page de confidentialité
              },
            ),
            
            _buildSettingCard(
              icon: Icons.language,
              iconColor: Colors.blue,
              iconBackground: Colors.blue.withOpacity(0.1),
              title: 'Language',
              subtitle: 'Change your preferred language',
              onTap: () {
                // Navigation vers la page de langue
              },
            ),
            
            // Section Support
            _buildSectionTitle('Support'),
            
            _buildSettingCard(
              icon: Icons.help_outline,
              iconColor: Colors.blue,
              iconBackground: Colors.blue.withOpacity(0.1),
              title: 'Help & Support',
              subtitle: 'Get assistance with the app',
              onTap: () {
                // Navigation vers la page d'aide
              },
            ),
            
            _buildSettingCard(
              icon: Icons.chat_bubble_outline,
              iconColor: Colors.red,
              iconBackground: Colors.red.withOpacity(0.1),
              title: 'Send Feedback',
              subtitle: 'Help us improve our service',
              onTap: () {
                // Navigation vers la page de feedback
              },
            ),
            
            _buildSettingCard(
              icon: Icons.info_outline,
              iconColor: Colors.red,
              iconBackground: Colors.red.withOpacity(0.1),
              title: 'About',
              subtitle: 'App version and information',
              onTap: () {
                // Navigation vers la page À propos
              },
            ),
            
            // Section Logout
            _buildSectionTitle('Account'),
            
            _buildSettingCard(
              icon: Icons.logout,
              iconColor: Colors.red,
              iconBackground: Colors.red.withOpacity(0.1),
              title: 'Logout',
              subtitle: 'Sign out from your account',
              onTap: () {
                _showLogoutConfirmation(context, authController);
              },
            ),
            
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
  
  void _showLogoutConfirmation(BuildContext context, AuthController authController) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Déconnexion'),
        content: const Text('Êtes-vous sûr de vouloir vous déconnecter ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              authController.signOut();
            },
            child: const Text(
              'Déconnexion',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: Colors.black87,
        ),
      ),
    );
  }
  
  Widget _buildSettingCard({
    required IconData icon,
    required Color iconColor,
    required Color iconBackground,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 4, 16, 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: Container(
          width: 46,
          height: 46,
          decoration: BoxDecoration(
            color: iconBackground,
            shape: BoxShape.circle,
          ),
          child: Icon(
            icon,
            color: iconColor,
            size: 24,
          ),
        ),
        title: Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: Colors.black87,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: const TextStyle(
            fontSize: 14,
            color: Colors.black54,
          ),
        ),
        trailing: const Icon(
          Icons.chevron_right,
          color: Colors.black54,
        ),
        onTap: onTap,
      ),
    );
  }
}