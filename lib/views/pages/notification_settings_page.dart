import 'package:flutter/material.dart';

class NotificationSettingsPage extends StatefulWidget {
  const NotificationSettingsPage({Key? key}) : super(key: key);

  @override
  State<NotificationSettingsPage> createState() => _NotificationSettingsPageState();
}

class _NotificationSettingsPageState extends State<NotificationSettingsPage> {
  // État des interrupteurs pour les notifications générales
  Map<String, bool> _generalNotifications = {
    'All Notifications': true,
    'In-App Notifications': true,
    'Push Notifications': true,
    'Email Notifications': false,
    'SMS Notifications': true,
  };

  // État des interrupteurs pour les notifications de trajet
  Map<String, bool> _rideNotifications = {
    'Ride Updates': true,
    'Driver Assigned': true,
    'Driver Arrived': true,
  };

  // Fonction pour mettre à jour l'état des interrupteurs
  void _updateSwitchState(String key, bool value, Map<String, bool> notificationMap) {
    setState(() {
      notificationMap[key] = value;
      
      // Si "All Notifications" est désactivé, désactiver toutes les notifications générales
      if (key == 'All Notifications' && notificationMap == _generalNotifications) {
        if (!value) {
          _generalNotifications.forEach((k, v) {
            if (k != 'All Notifications') {
              _generalNotifications[k] = false;
            }
          });
        }
      }
      
      // Si "All Notifications" est activé mais que certaines notifications sont désactivées,
      // ne pas les activer automatiquement
      
      // Si une notification spécifique est désactivée, vérifier si toutes sont désactivées
      // pour mettre à jour "All Notifications"
      if (key != 'All Notifications' && notificationMap == _generalNotifications) {
        bool allDisabled = true;
        _generalNotifications.forEach((k, v) {
          if (k != 'All Notifications' && v) {
            allDisabled = false;
          }
        });
        
        if (allDisabled) {
          _generalNotifications['All Notifications'] = false;
        } else if (value) {
          _generalNotifications['All Notifications'] = true;
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black54),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Notification Settings',
          style: TextStyle(color: Colors.black87),
        ),
        centerTitle: true,
        actions: [
          TextButton(
            onPressed: () {
              // Action pour sauvegarder les paramètres
              Navigator.pop(context);
            },
            child: const Text(
              'Save',
              style: TextStyle(
                color: Color(0xFFFF6B5B),
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Description
              Text(
                'Control which notifications you receive from AfriLyft.',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
              ),
              
              const SizedBox(height: 24.0),
              
              // Section des notifications générales
              _buildSectionTitle('General Notifications'),
              Text(
                'Control how you receive notifications',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
              ),
              
              const SizedBox(height: 16.0),
              
              // Liste des notifications générales
              ..._generalNotifications.entries.map((entry) => 
                _buildNotificationSwitch(
                  title: entry.key,
                  subtitle: _getNotificationSubtitle(entry.key),
                  value: entry.value,
                  onChanged: (value) => _updateSwitchState(entry.key, value, _generalNotifications),
                ),
              ),
              
              const SizedBox(height: 24.0),
              
              // Section des notifications de trajet
              _buildSectionTitle('Ride Notifications'),
              Text(
                'Updates about your rides',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
              ),
              
              const SizedBox(height: 16.0),
              
              // Liste des notifications de trajet
              ..._rideNotifications.entries.map((entry) => 
                _buildNotificationSwitch(
                  title: entry.key,
                  subtitle: _getRideNotificationSubtitle(entry.key),
                  value: entry.value,
                  onChanged: (value) => _updateSwitchState(entry.key, value, _rideNotifications),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w500,
          color: Colors.black87,
        ),
      ),
    );
  }

  Widget _buildNotificationSwitch({
    required String title,
    required String subtitle,
    required bool value,
    required Function(bool) onChanged,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8.0),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12.0),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
        title: Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey[600],
          ),
        ),
        trailing: Switch(
          value: value,
          onChanged: onChanged,
          activeColor: const Color(0xFFFF6B5B),
          activeTrackColor: const Color(0xFFFFECEA),
          inactiveThumbColor: Colors.grey[400],
          inactiveTrackColor: Colors.grey[300],
        ),
      ),
    );
  }

  String _getNotificationSubtitle(String key) {
    switch (key) {
      case 'All Notifications':
        return 'Enable or disable all notifications';
      case 'In-App Notifications':
        return 'Receive notifications within the app';
      case 'Push Notifications':
        return 'Receive notifications on your device';
      case 'Email Notifications':
        return 'Receive notifications via email';
      case 'SMS Notifications':
        return 'Receive notifications via SMS';
      default:
        return '';
    }
  }

  String _getRideNotificationSubtitle(String key) {
    switch (key) {
      case 'Ride Updates':
        return 'General updates about your rides';
      case 'Driver Assigned':
        return 'When a driver accepts your ride request';
      case 'Driver Arrived':
        return 'When your driver arrives at pickup location';
      default:
        return '';
    }
  }
} 