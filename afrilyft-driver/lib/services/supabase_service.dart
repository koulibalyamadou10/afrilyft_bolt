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
    String role = 'driver',
  }) async {
    try {
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
    } catch (e) {
      print('Erreur lors de l\'inscription: $e');
      rethrow;
    }
  }
  
  static Future<AuthResponse> signIn({
    required String email,
    required String password,
  }) async {
    try {
      return await _client.auth.signInWithPassword(
        email: email,
        password: password,
      );
    } catch (e) {
      print('Erreur lors de la connexion: $e');
      rethrow;
    }
  }
  
  static Future<void> signOut() async {
    await _client.auth.signOut();
  }
  
  // Profil utilisateur
  static Future<Map<String, dynamic>?> getCurrentUserProfile() async {
    final user = _client.auth.currentUser;
    if (user == null) return null;
    
    try {
      final response = await _client
          .from('profiles')
          .select()
          .eq('id', user.id)
          .single();
      
      return response;
    } catch (e) {
      print('Erreur lors de la récupération du profil: $e');
      return null;
    }
  }
  
  static Future<void> updateProfile(Map<String, dynamic> updates) async {
    final user = _client.auth.currentUser;
    if (user == null) throw Exception('User not authenticated');
    
    await _client
        .from('profiles')
        .update(updates)
        .eq('id', user.id);
  }

  // Fonctions pour l'app chauffeur
  static Future<List<Map<String, dynamic>>> getDriverRideRequests() async {
    final user = _client.auth.currentUser;
    if (user == null) throw Exception('User not authenticated');
    
    try {
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
    } catch (e) {
      print('Erreur lors de la récupération des demandes: $e');
      return [];
    }
  }

  static Future<bool> acceptRideRequest(String requestId) async {
    final user = _client.auth.currentUser;
    if (user == null) throw Exception('User not authenticated');

    try {
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
    } catch (e) {
      print('Erreur lors de l\'acceptation: $e');
      return false;
    }
  }

  static Future<void> declineRideRequest(String requestId) async {
    final user = _client.auth.currentUser;
    if (user == null) throw Exception('User not authenticated');

    try {
      await _client
          .from('ride_requests')
          .update({
            'status': 'declined',
            'responded_at': DateTime.now().toIso8601String(),
          })
          .eq('id', requestId)
          .eq('driver_id', user.id);
    } catch (e) {
      print('Erreur lors du refus: $e');
      rethrow;
    }
  }

  static Future<void> updateDriverAvailability(bool isAvailable) async {
    final user = _client.auth.currentUser;
    if (user == null) throw Exception('User not authenticated');

    try {
      await _client
          .from('driver_locations')
          .upsert({
            'driver_id': user.id,
            'is_available': isAvailable,
            'last_updated': DateTime.now().toIso8601String(),
          });
    } catch (e) {
      print('Erreur lors de la mise à jour de disponibilité: $e');
      rethrow;
    }
  }

  // Fonction pour récupérer un trajet par ID de demande
  static Future<Map<String, dynamic>?> getRideByRequestId(String requestId) async {
    try {
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
    } catch (e) {
      print('Erreur lors de la récupération du trajet par demande: $e');
      return null;
    }
  }

  static Future<Map<String, dynamic>?> getRideById(String rideId) async {
    try {
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
    } catch (e) {
      print('Erreur lors de la récupération du trajet: $e');
      return null;
    }
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