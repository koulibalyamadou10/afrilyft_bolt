import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:get/get.dart';
import '../models/ride_model.dart';
import '../controllers/driver_controller.dart';
import '../controllers/auth_controller.dart';
import 'package:flutter/material.dart';
import 'dart:math';

class RealtimeService {
  static final SupabaseClient _client = Supabase.instance.client;
  static RealtimeChannel? _rideRequestsChannel;
  static RealtimeChannel? _ridesChannel;
  static RealtimeChannel? _notificationsChannel;
  static bool _isInitialized = false;

  // Initialiser les abonnements temps réel
  static Future<void> initialize() async {
    if (_isInitialized) return;

    final authController = Get.find<AuthController>();

    if (authController.isAuthenticated.value) {
      await _subscribeToRideRequests();
      await _subscribeToRides();
      await _subscribeToNotifications();
      _isInitialized = true;
      print('✅ Service temps réel initialisé pour le chauffeur');
    }
  }

  // Nettoyer les abonnements
  static Future<void> cleanup() async {
    await _rideRequestsChannel?.unsubscribe();
    await _ridesChannel?.unsubscribe();
    await _notificationsChannel?.unsubscribe();

    _rideRequestsChannel = null;
    _ridesChannel = null;
    _notificationsChannel = null;
    _isInitialized = false;
  }

  // Écouter les nouvelles demandes de trajet
  static Future<void> _subscribeToRideRequests() async {
    final authController = Get.find<AuthController>();
    final userId = authController.user.value?.id;

    if (userId == null) return;

    // Écouter seulement les nouvelles demandes destinées à ce chauffeur
    _rideRequestsChannel =
        _client
            .channel('driver_ride_requests_channel')
            .onPostgresChanges(
              event: PostgresChangeEvent.insert,
              schema: 'public',
              table: 'ride_requests',
              filter: PostgresChangeFilter(
                type: PostgresChangeFilterType.eq,
                column: 'driver_id',
                value: userId,
              ),
              callback: (payload) {
                _handleNewRideRequest(payload);
              },
            )
            .subscribe();

    print('✅ Chauffeur abonné aux nouvelles demandes de trajet (ID: $userId)');
  }

  // Écouter les changements sur les trajets
  static Future<void> _subscribeToRides() async {
    final authController = Get.find<AuthController>();
    final userId = authController.user.value?.id;

    if (userId == null) return;

    _ridesChannel =
        _client
            .channel('driver_rides_channel')
            .onPostgresChanges(
              event: PostgresChangeEvent.all,
              schema: 'public',
              table: 'rides',
              filter: PostgresChangeFilter(
                type: PostgresChangeFilterType.eq,
                column: 'driver_id',
                value: userId,
              ),
              callback: (payload) {
                _handleRideChange(payload);
              },
            )
            .subscribe();

    print('✅ Chauffeur abonné aux changements de trajets');
  }

  // Écouter les notifications
  static Future<void> _subscribeToNotifications() async {
    final authController = Get.find<AuthController>();
    final userId = authController.user.value?.id;

    if (userId == null) return;

    _notificationsChannel =
        _client
            .channel('driver_notifications_channel')
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

    print('✅ Chauffeur abonné aux notifications');
  }

  // Gérer les nouvelles demandes de trajet
  static void _handleNewRideRequest(PostgresChangePayload payload) {
    try {
      if (payload.eventType == PostgresChangeEvent.insert) {
        final requestData = payload.newRecord;
        if (requestData != null) {
          print('🚗 Nouvelle demande de trajet reçue: $requestData');

          // Vérifier si cette demande est pertinente pour ce chauffeur
          _checkAndAddRideRequest(requestData['id']);
        }
      }
    } catch (e) {
      print('❌ Erreur lors du traitement de la nouvelle demande: $e');
    }
  }

  // Vérifier si une demande est pertinente et l'ajouter si oui
  static Future<void> _checkAndAddRideRequest(String requestId) async {
    try {
      final driverController = Get.find<DriverController>();

      // Vérifier si le chauffeur est en ligne
      if (!driverController.isOnline.value) {
        print('🚫 Chauffeur hors ligne, demande ignorée');
        return;
      }

      // Vérifier si la demande n'a pas expiré
      final now = DateTime.now();

      // Récupérer les détails de la demande
      final response =
          await _client
              .from('ride_requests')
              .select('''
            *,
            rides!inner(
              *,
              customer:profiles!rides_customer_id_fkey(full_name, phone)
            )
          ''')
              .eq('id', requestId)
              .single();

      if (response != null) {
        final expiresAt = DateTime.parse(response['expires_at']);

        // Vérifier si la demande n'a pas expiré
        if (now.isAfter(expiresAt)) {
          print('⏰ Demande expirée, ignorée');
          return;
        }

        final rideData = response['rides'];
        final customerData = rideData['customer'];

        final rideRequest = RideRequest(
          id: response['id'],
          rideId: response['ride_id'],
          customerName: customerData?['full_name'] ?? 'Client inconnu',
          pickupAddress: rideData['pickup_address'],
          destinationAddress: rideData['destination_address'],
          sentAt: DateTime.parse(response['sent_at']),
          expiresAt: expiresAt,
        );

        // Ajouter à la liste des demandes en attente
        driverController.addPendingRequest(rideRequest);

        // Afficher une notification push locale avec plus de détails
        Get.snackbar(
          '🚗 Nouvelle demande',
          '${rideRequest.customerName} - ${rideRequest.pickupAddress}',
          duration: const Duration(seconds: 6),
          backgroundColor: Get.theme.primaryColor,
          colorText: Get.theme.colorScheme.onPrimary,
          snackPosition: SnackPosition.TOP,
          icon: const Icon(Icons.directions_car, color: Colors.white),
          mainButton: TextButton(
            onPressed: () {
              Get.back(); // Fermer le snackbar
              // Naviguer vers la page des demandes
              Get.toNamed('/ride-requests');
            },
            child: const Text(
              'Voir',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        );

        print(
          '✅ Demande ajoutée pour le chauffeur: ${rideRequest.customerName}',
        );
        print('📍 De: ${rideRequest.pickupAddress}');
        print('🎯 Vers: ${rideRequest.destinationAddress}');
      }
    } catch (e) {
      print('❌ Erreur lors de la vérification de la demande: $e');
    }
  }

  // Calculer la distance entre deux points (formule de Haversine)
  static double _calculateDistance(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    const double earthRadius = 6371; // Rayon de la Terre en km

    double dLat = _degreesToRadians(lat2 - lat1);
    double dLon = _degreesToRadians(lon2 - lon1);

    double a =
        sin(dLat / 2) * sin(dLat / 2) +
        cos(_degreesToRadians(lat1)) *
            cos(_degreesToRadians(lat2)) *
            sin(dLon / 2) *
            sin(dLon / 2);

    double c = 2 * atan2(sqrt(a), sqrt(1 - a));

    return earthRadius * c;
  }

  static double _degreesToRadians(double degrees) {
    return degrees * (pi / 180);
  }

  // Gérer les changements de trajet
  static void _handleRideChange(PostgresChangePayload payload) {
    try {
      final driverController = Get.find<DriverController>();

      switch (payload.eventType) {
        case PostgresChangeEvent.insert:
        case PostgresChangeEvent.update:
          final rideData = payload.newRecord;
          if (rideData != null) {
            final ride = RideModel.fromJson(rideData);

            // Mettre à jour le trajet actuel si c'est le bon
            if (driverController.currentRide.value?.id == ride.id) {
              driverController.currentRide.value = ride;
              print('🔄 Trajet mis à jour: ${ride.status}');

              // Afficher une notification selon le statut
              _showRideStatusNotification(ride);
            }
          }
          break;

        case PostgresChangeEvent.delete:
          final oldRecord = payload.oldRecord;
          if (oldRecord != null) {
            final rideId = oldRecord['id'];
            if (driverController.currentRide.value?.id == rideId) {
              driverController.currentRide.value = null;
            }
          }
          break;
        default:
          print('📨 Événement de trajet non géré: ${payload.eventType}');
          break;
      }
    } catch (e) {
      print('❌ Erreur lors du traitement du changement de trajet: $e');
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
      case RideStatus.inProgress:
        title = '🛣️ Trajet commencé';
        message = 'Le trajet a commencé, bonne route !';
        break;
      case RideStatus.completed:
        title = '✅ Trajet terminé';
        message = 'Trajet terminé avec succès !';
        break;
      case RideStatus.cancelled:
        title = '❌ Trajet annulé';
        message = 'Le trajet a été annulé par le client';
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

  // Accepter un trajet
  static Future<bool> acceptRide(String requestId) async {
    try {
      final authController = Get.find<AuthController>();
      final userId = authController.user.value?.id;

      if (userId == null) return false;

      final result = await _client.rpc(
        'accept_ride',
        params: {'p_request_id': requestId, 'p_driver_id': userId},
      );

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

      // Mettre à jour directement dans la base de données
      await _client
          .from('rides')
          .update({
            'status': newStatus,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', rideId)
          .eq('driver_id', userId);

      return true;
    } catch (e) {
      print('❌ Erreur lors de la mise à jour du statut: $e');
      return false;
    }
  }

  // Envoyer la position du chauffeur
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

      if (userId == null) return;

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

  static void dispose() {
    cleanup();
  }
}
