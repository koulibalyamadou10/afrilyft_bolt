import 'dart:async';
import 'package:geolocator/geolocator.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'supabase_service.dart';

class LocationService {
  static bool _isTracking = false;
  static StreamSubscription<Position>? _positionSubscription;

  static Future<void> initialize() async {
    try {
      await _requestPermissions();
      print('📍 LocationService initialisé avec succès');
    } catch (e) {
      print('❌ Erreur lors de l\'initialisation de LocationService: $e');
      rethrow;
    }
  }

  static Future<void> _requestPermissions() async {
    print('📍 Demande des permissions de localisation...');

    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      print('❌ Services de localisation désactivés');
      throw Exception('Les services de localisation sont désactivés');
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      print('📍 Demande de permission de localisation...');
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        print('❌ Permission de localisation refusée');
        throw Exception('Permissions de localisation refusées');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      print('❌ Permission de localisation refusée définitivement');
      throw Exception('Permissions de localisation refusées définitivement');
    }

    print('✅ Permissions de localisation accordées');
  }

  static Future<Position> getCurrentLocation() async {
    try {
      print('📍 Récupération de la position actuelle...');

      // Vérifier les permissions d'abord
      await _requestPermissions();

      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 15), // Augmenter le timeout
      );

      print(
        '✅ Position actuelle récupérée: ${position.latitude}, ${position.longitude}',
      );
      return position;
    } catch (e) {
      print('❌ Erreur lors de la récupération de la position: $e');

      // Gérer les erreurs spécifiques
      if (e.toString().contains('Location services are disabled')) {
        throw Exception(
          'Les services de localisation sont désactivés. Activez le GPS.',
        );
      } else if (e.toString().contains('Location permissions are denied')) {
        throw Exception(
          'Permissions de localisation refusées. Activez-les dans les paramètres.',
        );
      } else if (e.toString().contains('timeout')) {
        throw Exception(
          'Délai d\'attente dépassé. Vérifiez votre connexion GPS.',
        );
      } else {
        throw Exception('Erreur de localisation: $e');
      }
    }
  }

  // Démarrer le suivi de position en temps réel
  static Future<void> startLocationTracking() async {
    if (_isTracking) {
      print('📍 Suivi de position déjà en cours');
      return;
    }

    try {
      print('📍 Démarrage du suivi de position...');
      _isTracking = true;

      const LocationSettings locationSettings = LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 10, // Mise à jour tous les 10 mètres
      );

      _positionSubscription = Geolocator.getPositionStream(
        locationSettings: locationSettings,
      ).listen(
        (Position position) {
          _updateDriverLocation(position);
        },
        onError: (error) {
          print('❌ Erreur dans le stream de position: $error');
          _isTracking = false;
        },
      );

      print('✅ Suivi de position démarré avec succès');
    } catch (e) {
      print('❌ Erreur lors du démarrage du suivi: $e');
      _isTracking = false;
      rethrow;
    }
  }

  // Arrêter le suivi de position
  static Future<void> stopLocationTracking() async {
    if (!_isTracking) {
      print('📍 Suivi de position déjà arrêté');
      return;
    }

    try {
      print('📍 Arrêt du suivi de position...');
      _isTracking = false;
      await _positionSubscription?.cancel();
      _positionSubscription = null;
      print('✅ Suivi de position arrêté avec succès');
    } catch (e) {
      print('❌ Erreur lors de l\'arrêt du suivi: $e');
      rethrow;
    }
  }

  // Mettre à jour la position du chauffeur
  static void _updateDriverLocation(Position position) {
    try {
      // Calculer la vitesse et la direction
      final speed = position.speed * 3.6; // Convertir m/s en km/h
      final heading = position.heading;

      // Mettre à jour via Supabase Service
      _updateDriverLocationInDatabase(
        latitude: position.latitude,
        longitude: position.longitude,
        heading: heading,
        speed: speed,
        isAvailable: true,
      );

      print(
        '📍 Position mise à jour: ${position.latitude}, ${position.longitude}',
      );
    } catch (e) {
      print('❌ Erreur lors de la mise à jour de position: $e');
    }
  }

  // Mettre à jour la position dans la base de données
  static Future<void> _updateDriverLocationInDatabase({
    required double latitude,
    required double longitude,
    double? heading,
    double? speed,
    required bool isAvailable,
  }) async {
    try {
      final supabase = Supabase.instance.client;
      final user = supabase.auth.currentUser;

      if (user == null) {
        print('❌ Utilisateur non authentifié');
        return;
      }

      print('📍 Mise à jour de la position en base de données...');

      // Vérifier si une entrée existe déjà pour ce chauffeur
      final existingLocation =
          await supabase
              .from('driver_locations')
              .select('id')
              .eq('driver_id', user.id)
              .maybeSingle();

      if (existingLocation != null) {
        // Mettre à jour l'entrée existante
        await supabase
            .from('driver_locations')
            .update({
              'latitude': latitude,
              'longitude': longitude,
              'heading': heading,
              'speed': speed,
              'is_available': isAvailable,
              'last_updated': DateTime.now().toIso8601String(),
            })
            .eq('driver_id', user.id);
      } else {
        // Créer une nouvelle entrée
        await supabase.from('driver_locations').insert({
          'driver_id': user.id,
          'latitude': latitude,
          'longitude': longitude,
          'heading': heading,
          'speed': speed,
          'is_available': isAvailable,
          'last_updated': DateTime.now().toIso8601String(),
        });
      }

      print('✅ Position mise à jour en base de données');
    } catch (e) {
      print('❌ Erreur lors de la mise à jour en base: $e');
      rethrow;
    }
  }

  static bool get isTracking => _isTracking;
}
