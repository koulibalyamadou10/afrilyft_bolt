import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';
import 'supabase_service.dart';
import 'realtime_service.dart';

class LocationService {
  static bool _isTracking = false;
  static StreamSubscription<Position>? _positionSubscription;

  static Future<void> initialize() async {
    await _requestPermissions();
  }

  static Future<void> _requestPermissions() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw Exception('Les services de localisation sont désactivés');
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        throw Exception('Permissions de localisation refusées');
      }
    }
    
    if (permission == LocationPermission.deniedForever) {
      throw Exception('Permissions de localisation refusées définitivement');
    }
  }

  static Future<Position> getCurrentLocation() async {
    return await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );
  }

  // Démarrer le suivi de position en temps réel
  static Future<void> startLocationTracking() async {
    if (_isTracking) return;

    _isTracking = true;
    
    const LocationSettings locationSettings = LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 10, // Mise à jour tous les 10 mètres
    );

    _positionSubscription = Geolocator.getPositionStream(
      locationSettings: locationSettings,
    ).listen((Position position) {
      _updateDriverLocation(position);
    });

    print('📍 Suivi de position démarré');
  }

  // Arrêter le suivi de position
  static Future<void> stopLocationTracking() async {
    if (!_isTracking) return;

    _isTracking = false;
    await _positionSubscription?.cancel();
    _positionSubscription = null;

    print('📍 Suivi de position arrêté');
  }

  // Mettre à jour la position du chauffeur
  static void _updateDriverLocation(Position position) {
    try {
      // Calculer la vitesse et la direction
      final speed = position.speed * 3.6; // Convertir m/s en km/h
      final heading = position.heading;

      // Mettre à jour via Realtime Service
      RealtimeService.updateDriverLocation(
        latitude: position.latitude,
        longitude: position.longitude,
        heading: heading,
        speed: speed,
        isAvailable: true,
      );

      print('📍 Position mise à jour: ${position.latitude}, ${position.longitude}');
    } catch (e) {
      print('Erreur lors de la mise à jour de position: $e');
    }
  }

  static bool get isTracking => _isTracking;
}