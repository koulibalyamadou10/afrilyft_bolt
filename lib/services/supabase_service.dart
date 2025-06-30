import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:geolocator/geolocator.dart';

class SupabaseService {
  static final SupabaseClient _client = Supabase.instance.client;
  
  static SupabaseClient get client => _client;
  
  // Authentification
  static Future<AuthResponse> signUp({
    required String email,
    required String password,
    required String fullName,
    required String phone,
    String role = 'customer',
  }) async {
    final response = await _client.auth.signUp(
      email: email,
      password: password,
      data: {
        'full_name': fullName,
        'phone': phone,
        'role': role,
      },
    );
    
    return response;
  }
  
  static Future<AuthResponse> signIn({
    required String email,
    required String password,
  }) async {
    return await _client.auth.signInWithPassword(
      email: email,
      password: password,
    );
  }
  
  static Future<void> signOut() async {
    await _client.auth.signOut();
  }
  
  // Profil utilisateur
  static Future<Map<String, dynamic>?> getCurrentUserProfile() async {
    final user = _client.auth.currentUser;
    if (user == null) return null;
    
    final response = await _client
        .from('profiles')
        .select()
        .eq('id', user.id)
        .single();
    
    return response;
  }
  
  static Future<void> updateProfile(Map<String, dynamic> updates) async {
    final user = _client.auth.currentUser;
    if (user == null) throw Exception('User not authenticated');
    
    await _client
        .from('profiles')
        .update(updates)
        .eq('id', user.id);
  }
  
  // Gestion des trajets
  static Future<String> createRide({
    required double pickupLat,
    required double pickupLon,
    required String pickupAddress,
    required double destinationLat,
    required double destinationLon,
    required String destinationAddress,
    String paymentMethod = 'cash',
    String? notes,
    DateTime? scheduledFor,
  }) async {
    final user = _client.auth.currentUser;
    if (user == null) throw Exception('User not authenticated');
    
    final response = await _client.rpc('create_ride_and_notify_drivers', params: {
      'p_customer_id': user.id,
      'p_pickup_lat': pickupLat,
      'p_pickup_lon': pickupLon,
      'p_pickup_address': pickupAddress,
      'p_destination_lat': destinationLat,
      'p_destination_lon': destinationLon,
      'p_destination_address': destinationAddress,
      'p_payment_method': paymentMethod,
      'p_notes': notes,
      'p_scheduled_for': scheduledFor?.toIso8601String(),
    });
    
    return response as String;
  }
  
  static Future<List<Map<String, dynamic>>> getUserRides() async {
    final user = _client.auth.currentUser;
    if (user == null) throw Exception('User not authenticated');
    
    final response = await _client
        .from('rides')
        .select('''
          *,
          driver:profiles!rides_driver_id_fkey(full_name, phone)
        ''')
        .eq('customer_id', user.id)
        .order('created_at', ascending: false);
    
    return List<Map<String, dynamic>>.from(response);
  }
  
  static Future<Map<String, dynamic>?> getRideById(String rideId) async {
    final response = await _client
        .from('rides')
        .select('''
          *,
          customer:profiles!rides_customer_id_fkey(full_name, phone),
          driver:profiles!rides_driver_id_fkey(full_name, phone)
        ''')
        .eq('id', rideId)
        .single();
    
    return response;
  }

  // NOUVEAU: Fonction pour récupérer un trajet par ID de demande
  static Future<Map<String, dynamic>?> getRideByRequestId(String requestId) async {
    final response = await _client
        .from('ride_requests')
        .select('''
          ride_id,
          rides!inner(
            *,
            customer:profiles!rides_customer_id_fkey(full_name, phone),
            driver:profiles!rides_driver_id_fkey(full_name, phone)
          )
        ''')
        .eq('id', requestId)
        .single();
    
    return response['rides'];
  }
  
  // Recherche de chauffeurs (AMÉLIORÉE - exclut ceux en course)
  static Future<List<Map<String, dynamic>>> findNearbyDrivers({
    required double pickupLat,
    required double pickupLon,
    double radiusKm = 5.0,
    int maxDrivers = 10,
  }) async {
    final response = await _client.rpc('find_nearby_drivers', params: {
      'pickup_lat': pickupLat,
      'pickup_lon': pickupLon,
      'radius_km': radiusKm,
      'max_drivers': maxDrivers,
    });
    
    return List<Map<String, dynamic>>.from(response);
  }

  // NOUVEAU: Fonctions pour l'app chauffeur
  static Future<List<Map<String, dynamic>>> getDriverRideRequests() async {
    final user = _client.auth.currentUser;
    if (user == null) throw Exception('User not authenticated');
    
    final response = await _client
        .from('ride_requests')
        .select('''
          *,
          rides!inner(
            *,
            customer:profiles!rides_customer_id_fkey(full_name, phone)
          )
        ''')
        .eq('driver_id', user.id)
        .eq('status', 'sent')
        .gt('expires_at', DateTime.now().toIso8601String())
        .order('sent_at', ascending: false);
    
    return List<Map<String, dynamic>>.from(response);
  }

  static Future<bool> acceptRideRequest(String requestId) async {
    final user = _client.auth.currentUser;
    if (user == null) throw Exception('User not authenticated');

    // Récupérer les détails de la demande
    final requestData = await _client
        .from('ride_requests')
        .select('ride_id')
        .eq('id', requestId)
        .eq('driver_id', user.id)
        .single();

    final rideId = requestData['ride_id'];

    // Utiliser la fonction accept_ride
    final result = await _client.rpc('accept_ride', params: {
      'p_ride_id': rideId,
      'p_driver_id': user.id,
    });
    
    return result as bool;
  }

  static Future<void> declineRideRequest(String requestId) async {
    final user = _client.auth.currentUser;
    if (user == null) throw Exception('User not authenticated');

    await _client
        .from('ride_requests')
        .update({
          'status': 'declined',
          'responded_at': DateTime.now().toIso8601String(),
        })
        .eq('id', requestId)
        .eq('driver_id', user.id);
  }

  static Future<void> updateDriverAvailability(bool isAvailable) async {
    final user = _client.auth.currentUser;
    if (user == null) throw Exception('User not authenticated');

    await _client
        .from('driver_locations')
        .upsert({
          'driver_id': user.id,
          'is_available': isAvailable,
          'last_updated': DateTime.now().toIso8601String(),
        });
  }
  
  // Géolocalisation
  static Future<Position> getCurrentLocation() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw Exception('Location services are disabled.');
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        throw Exception('Location permissions are denied');
      }
    }
    
    if (permission == LocationPermission.deniedForever) {
      throw Exception('Location permissions are permanently denied');
    }

    return await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );
  }
  
  // Calcul de distance
  static double calculateDistance(
    double startLatitude,
    double startLongitude,
    double endLatitude,
    double endLongitude,
  ) {
    return Geolocator.distanceBetween(
      startLatitude,
      startLongitude,
      endLatitude,
      endLongitude,
    ) / 1000; // Retourne en kilomètres
  }
}