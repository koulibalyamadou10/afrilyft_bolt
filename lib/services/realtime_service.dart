import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:get/get.dart';
import '../models/ride_model.dart';
import '../controllers/ride_controller.dart';
import '../controllers/auth_controller.dart';

class RealtimeService {
  static final SupabaseClient _client = Supabase.instance.client;
  static RealtimeChannel? _ridesChannel;
  static RealtimeChannel? _driverLocationsChannel;
  static RealtimeChannel? _rideRequestsChannel;
  static RealtimeChannel? _notificationsChannel;

  // Initialiser les abonnements temps réel
  static Future<void> initialize() async {
    final authController = Get.find<AuthController>();
    
    if (authController.isAuthenticated.value) {
      await _subscribeToRides();
      await _subscribeToDriverLocations();
      await _subscribeToRideRequests();
      await _subscribeToNotifications();
    }
  }

  // Nettoyer les abonnements
  static Future<void> cleanup() async {
    await _ridesChannel?.unsubscribe();
    await _driverLocationsChannel?.unsubscribe();
    await _rideRequestsChannel?.unsubscribe();
    await _notificationsChannel?.unsubscribe();
    
    _ridesChannel = null;
    _driverLocationsChannel = null;
    _rideRequestsChannel = null;
    _notificationsChannel = null;
  }

  // Écouter les changements sur les trajets
  static Future<void> _subscribeToRides() async {
    final authController = Get.find<AuthController>();
    final userId = authController.user.value?.id;
    
    if (userId == null) return;

    _ridesChannel = _client
        .channel('rides_channel')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'rides',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: authController.isCustomer ? 'customer_id' : 'driver_id',
            value: userId,
          ),
          callback: (payload) {
            _handleRideChange(payload);
          },
        )
        .subscribe();

    print('✅ Abonné aux changements de trajets');
  }

  // Écouter les positions des chauffeurs
  static Future<void> _subscribeToDriverLocations() async {
    final authController = Get.find<AuthController>();
    
    if (!authController.isCustomer) return;

    _driverLocationsChannel = _client
        .channel('driver_locations_channel')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'driver_locations',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'is_available',
            value: true,
          ),
          callback: (payload) {
            _handleDriverLocationChange(payload);
          },
        )
        .subscribe();

    print('✅ Abonné aux positions des chauffeurs');
  }

  // Écouter les demandes de trajet (pour les chauffeurs)
  static Future<void> _subscribeToRideRequests() async {
    final authController = Get.find<AuthController>();
    final userId = authController.user.value?.id;
    
    if (userId == null || !authController.isDriver) return;

    _rideRequestsChannel = _client
        .channel('ride_requests_channel')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'ride_requests',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'driver_id',
            value: userId,
          ),
          callback: (payload) {
            _handleRideRequestChange(payload);
          },
        )
        .subscribe();

    print('✅ Abonné aux demandes de trajet');
  }

  // Écouter les notifications
  static Future<void> _subscribeToNotifications() async {
    final authController = Get.find<AuthController>();
    final userId = authController.user.value?.id;
    
    if (userId == null) return;

    _notificationsChannel = _client
        .channel('notifications_channel')
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'notifications',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'user_id',
            value: userId,
          ),
          callback: (payload) {
            _handleNotificationChange(payload);
          },
        )
        .subscribe();

    print('✅ Abonné aux notifications');
  }

  // Gérer les changements de trajet
  static void _handleRideChange(PostgresChangePayload payload) {
    try {
      final rideController = Get.find<RideController>();
      
      switch (payload.eventType) {
        case PostgresChangeEvent.insert:
        case PostgresChangeEvent.update:
          final rideData = payload.newRecord;
          if (rideData != null) {
            final ride = RideModel.fromJson(rideData);
            
            // Mettre à jour le trajet actuel si c'est le bon
            if (rideController.currentRide.value?.id == ride.id) {
              rideController.currentRide.value = ride;
              print('🔄 Trajet mis à jour: ${ride.status}');
              
              // Afficher une notification selon le statut
              _showRideStatusNotification(ride);
              
              // IMPORTANT: Si accepté, arrêter la recherche
              if (ride.status == RideStatus.accepted) {
                rideController.isSearchingDriver.value = false;
              }
            }
            
            // Mettre à jour l'historique
            rideController.updateRideInHistory(ride);
          }
          break;
          
        case PostgresChangeEvent.delete:
          final oldRecord = payload.oldRecord;
          if (oldRecord != null) {
            final rideId = oldRecord['id'];
            if (rideController.currentRide.value?.id == rideId) {
              rideController.currentRide.value = null;
            }
          }
          break;
        default:
          // Gérer les autres types d'événements si nécessaire
          print('📨 Événement de trajet non géré: ${payload.eventType}');
          break;
      }
    } catch (e) {
      print('❌ Erreur lors du traitement du changement de trajet: $e');
    }
  }

  // Gérer les changements de position des chauffeurs
  static void _handleDriverLocationChange(PostgresChangePayload payload) {
    try {
      final rideController = Get.find<RideController>();
      
      if (payload.eventType == PostgresChangeEvent.insert ||
          payload.eventType == PostgresChangeEvent.update) {
        final locationData = payload.newRecord;
        if (locationData != null) {
          final driverLocation = DriverLocation.fromJson(locationData);
          rideController.updateDriverLocation(driverLocation);
          print('📍 Position chauffeur mise à jour: ${driverLocation.driverId}');
        }
      }
    } catch (e) {
      print('❌ Erreur lors du traitement de la position: $e');
    }
  }

  // Gérer les demandes de trajet (pour les chauffeurs)
  static void _handleRideRequestChange(PostgresChangePayload payload) {
    try {
      if (payload.eventType == PostgresChangeEvent.insert) {
        final requestData = payload.newRecord;
        if (requestData != null) {
          print('🚗 Nouvelle demande de trajet reçue');
          
          // Afficher une notification push locale
          Get.snackbar(
            '🚗 Nouvelle demande',
            'Un client souhaite effectuer un trajet près de vous',
            duration: const Duration(seconds: 5),
            backgroundColor: Get.theme.primaryColor,
            colorText: Get.theme.colorScheme.onPrimary,
          );
        }
      }
    } catch (e) {
      print('❌ Erreur lors du traitement de la demande: $e');
    }
  }

  // Gérer les notifications
  static void _handleNotificationChange(PostgresChangePayload payload) {
    try {
      if (payload.eventType == PostgresChangeEvent.insert) {
        final notificationData = payload.newRecord;
        if (notificationData != null) {
          final title = notificationData['title'] as String;
          final message = notificationData['message'] as String;
          
          print('🔔 Nouvelle notification: $title');
          
          // Afficher la notification
          Get.snackbar(
            title,
            message,
            duration: const Duration(seconds: 4),
            backgroundColor: Get.theme.primaryColor,
            colorText: Get.theme.colorScheme.onPrimary,
          );
        }
      }
    } catch (e) {
      print('❌ Erreur lors du traitement de la notification: $e');
    }
  }

  // Afficher une notification selon le statut du trajet
  static void _showRideStatusNotification(RideModel ride) {
    String title = '';
    String message = '';
    
    switch (ride.status) {
      case RideStatus.accepted:
        title = '🚗 Chauffeur trouvé !';
        message = 'Un chauffeur a accepté votre demande et arrive vers vous';
        break;
      case RideStatus.inProgress:
        title = '🛣️ Trajet commencé';
        message = 'Votre trajet a commencé, bon voyage !';
        break;
      case RideStatus.completed:
        title = '✅ Trajet terminé';
        message = 'Merci d\'avoir utilisé AfriLyft !';
        break;
      case RideStatus.cancelled:
        title = '❌ Trajet annulé';
        message = 'Votre trajet a été annulé';
        break;
      default:
        return;
    }
    
    if (title.isNotEmpty) {
      Get.snackbar(
        title,
        message,
        duration: const Duration(seconds: 4),
        backgroundColor: Get.theme.primaryColor,
        colorText: Get.theme.colorScheme.onPrimary,
      );
    }
  }

  // Envoyer la position du chauffeur (pour l'app chauffeur)
  static Future<void> updateDriverLocation({
    required double latitude,
    required double longitude,
    double? heading,
    double? speed,
    bool isAvailable = true,
  }) async {
    try {
      final authController = Get.find<AuthController>();
      final userId = authController.user.value?.id;
      
      if (userId == null || !authController.isDriver) return;

      await _client.from('driver_locations').upsert({
        'driver_id': userId,
        'latitude': latitude,
        'longitude': longitude,
        'heading': heading,
        'speed': speed,
        'is_available': isAvailable,
        'last_updated': DateTime.now().toIso8601String(),
      });
      
      print('📍 Position mise à jour: $latitude, $longitude');
    } catch (e) {
      print('❌ Erreur lors de la mise à jour de position: $e');
    }
  }

  // Accepter un trajet (pour l'app chauffeur)
  static Future<bool> acceptRide(String requestId) async {
    try {
      final authController = Get.find<AuthController>();
      final userId = authController.user.value?.id;
      
      if (userId == null || !authController.isDriver) return false;

      final result = await _client.rpc('accept_ride', params: {
        'p_request_id': requestId,
        'p_driver_id': userId,
      });
      
      return result as bool;
    } catch (e) {
      print('❌ Erreur lors de l\'acceptation du trajet: $e');
      return false;
    }
  }

  // Mettre à jour le statut d'un trajet
  static Future<bool> updateRideStatus(String rideId, String newStatus) async {
    try {
      final authController = Get.find<AuthController>();
      final userId = authController.user.value?.id;
      
      if (userId == null) return false;

      // Appeler la fonction Edge pour mettre à jour le statut
      final response = await _client.functions.invoke('ride-status', {
        body: {
          rideId: rideId,
          status: newStatus,
          userId: userId,
        },
      });
      
      if (response.error) {
        throw Exception(response.error?.message);
      }
      
      return true;
    } catch (e) {
      print('❌ Erreur lors de la mise à jour du statut: $e');
      return false;
    }
  }

  // NOUVEAU: Fonction pour s'abonner aux mises à jour de trajets
  static void subscribeToRideUpdates(Function(Map<String, dynamic>) onRideUpdate) {
    // Cette fonction sera appelée par le RideController
    // pour écouter spécifiquement les mises à jour de trajets
  }

  // NOUVEAU: Fonction pour s'abonner aux demandes de trajet
  static void subscribeToRideRequests(Function(Map<String, dynamic>) onRideRequest) {
    // Cette fonction sera appelée par le DriverController
    // pour écouter spécifiquement les nouvelles demandes de trajet
  }
}