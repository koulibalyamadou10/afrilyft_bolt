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
    try {
      print('🔍 Début de l\'inscription avec les données:');
      print('📧 Email: $email');
      print('👤 Nom: $fullName');
      print('📱 Téléphone: $phone');
      print('🎭 Rôle: $role');

      final response = await _client.auth.signUp(
        email: email,
        password: password,
        data: {'full_name': fullName, 'phone': phone, 'role': role},
      );

      print('✅ Réponse de Supabase Auth:');
      print('👤 Utilisateur créé: ${response.user != null}');
      print('📧 Email confirmé: ${response.user?.emailConfirmedAt != null}');
      print('🔑 Session: ${response.session != null}');

      if (response.user != null) {
        print('✅ Utilisateur créé avec succès, ID: ${response.user!.id}');

        // Vérifier si le profil a été créé automatiquement
        try {
          final profile = await getCurrentUserProfile();
          if (profile != null) {
            print('✅ Profil créé automatiquement');
          } else {
            print('⚠️ Profil non trouvé, création manuelle nécessaire');
            // Créer le profil manuellement si le trigger n'a pas fonctionné
            await _createProfileManually(response.user!, fullName, phone, role);
          }
        } catch (e) {
          print('❌ Erreur lors de la vérification du profil: $e');
          // Créer le profil manuellement
          await _createProfileManually(response.user!, fullName, phone, role);
        }
      } else {
        print('❌ Aucun utilisateur créé dans la réponse');
      }

      return response;
    } catch (e) {
      print('❌ Erreur lors de l\'inscription: $e');
      print('🔍 Type d\'erreur: ${e.runtimeType}');

      // Gérer les erreurs spécifiques
      if (e.toString().contains('User already registered')) {
        throw Exception('Un compte avec cet email existe déjà');
      } else if (e.toString().contains('Invalid email')) {
        throw Exception('Format d\'email invalide');
      } else if (e.toString().contains('Password should be at least')) {
        throw Exception('Le mot de passe doit contenir au moins 6 caractères');
      } else if (e.toString().contains('phone')) {
        throw Exception('Numéro de téléphone invalide ou déjà utilisé');
      }

      rethrow;
    }
  }

  // Méthode pour créer le profil manuellement si le trigger échoue
  static Future<void> _createProfileManually(
    User user,
    String fullName,
    String phone,
    String role,
  ) async {
    try {
      print('🔧 Création manuelle du profil pour l\'utilisateur: ${user.id}');

      final profileData = {
        'id': user.id,
        'email': user.email,
        'full_name': fullName,
        'phone': phone,
        'role': role,
        'is_active': true,
        'is_verified': false,
      };

      await _client.from('profiles').insert(profileData);
      print('✅ Profil créé manuellement avec succès');
    } catch (e) {
      print('❌ Erreur lors de la création manuelle du profil: $e');
      throw Exception('Erreur lors de la création du profil: $e');
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
      final response =
          await _client.from('profiles').select().eq('id', user.id).single();

      return response;
    } catch (e) {
      print('Erreur lors de la récupération du profil: $e');
      return null;
    }
  }

  static Future<void> updateProfile(Map<String, dynamic> updates) async {
    final user = _client.auth.currentUser;
    if (user == null) throw Exception('User not authenticated');

    await _client.from('profiles').update(updates).eq('id', user.id);
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
    if (user == null) {
      print('❌ Erreur: Utilisateur non authentifié');
      throw Exception('Vous devez être connecté pour créer un trajet');
    }

    print('👤 Utilisateur connecté: ${user.email}');
    print('🆔 User ID: ${user.id}');

    // VALIDATION COMPLÈTE DES DONNÉES
    print('🔍 Validation des données du trajet...');

    // Validation des coordonnées de départ
    if (pickupLat == null || pickupLat.isNaN || pickupLat.isInfinite) {
      throw Exception('Latitude de départ invalide: $pickupLat');
    }
    if (pickupLon == null || pickupLon.isNaN || pickupLon.isInfinite) {
      throw Exception('Longitude de départ invalide: $pickupLon');
    }

    // Validation des coordonnées de destination
    if (destinationLat == null ||
        destinationLat.isNaN ||
        destinationLat.isInfinite) {
      throw Exception('Latitude de destination invalide: $destinationLat');
    }
    if (destinationLon == null ||
        destinationLon.isNaN ||
        destinationLon.isInfinite) {
      throw Exception('Longitude de destination invalide: $destinationLon');
    }

    // Validation des adresses
    if (pickupAddress.isEmpty || pickupAddress.trim().isEmpty) {
      throw Exception('Adresse de départ vide');
    }
    if (destinationAddress.isEmpty || destinationAddress.trim().isEmpty) {
      throw Exception('Adresse de destination vide');
    }

    // Validation de la méthode de paiement
    if (paymentMethod.isEmpty || paymentMethod.trim().isEmpty) {
      paymentMethod = 'cash'; // Valeur par défaut
      print(
        '⚠️ Méthode de paiement vide, utilisation de la valeur par défaut: $paymentMethod',
      );
    }

    // Validation des notes (optionnelles)
    if (notes != null && notes.trim().isEmpty) {
      notes = null;
      print('⚠️ Notes vides, définies à null');
    }

    // Validation de la date programmée (optionnelle)
    if (scheduledFor != null && scheduledFor.isBefore(DateTime.now())) {
      throw Exception('La date programmée ne peut pas être dans le passé');
    }

    print('✅ Validation des données réussie');
    print('📍 Départ: $pickupAddress ($pickupLat, $pickupLon)');
    print(
      '🎯 Destination: $destinationAddress ($destinationLat, $destinationLon)',
    );
    print('💳 Paiement: $paymentMethod');
    print('📝 Notes: ${notes ?? "Aucune"}');
    print(
      '📅 Programmé pour: ${scheduledFor?.toIso8601String() ?? "Immédiat"}',
    );

    try {
      print('📝 Création du trajet dans la base de données...');

      // Préparer les données pour l'insertion (SANS jointures)
      final rideData = {
        'customer_id': user.id,
        'pickup_latitude': pickupLat,
        'pickup_longitude': pickupLon,
        'pickup_address': pickupAddress.trim(),
        'destination_latitude': destinationLat,
        'destination_longitude': destinationLon,
        'destination_address': destinationAddress.trim(),
        'status': 'searching',
        'payment_method': paymentMethod.trim(),
        'notes': notes?.trim(),
        'scheduled_for': scheduledFor?.toIso8601String(),
      };

      print('📊 Données à insérer: $rideData');

      // Créer d'abord le trajet (SANS jointures)
      final rideResponse =
          await _client.from('rides').insert(rideData).select('id').single();

      final rideId = rideResponse['id'] as String;
      print('✅ Trajet créé avec ID: $rideId');

      // Trouver des chauffeurs à proximité (séparément)
      print('🔍 Recherche de chauffeurs à proximité...');

      // Affihcer le pickuplat et pickuplon
      print('🚗 pickupLat: $pickupLat');
      print('🚗 pickupLon: $pickupLon');

      final nearbyDrivers = await findNearbyDrivers(
        pickupLat: pickupLat,
        pickupLon: pickupLon,
        radiusKm: 10,
        maxDrivers: 10,
      );

      print('🚗 ${nearbyDrivers.length} chauffeurs trouvés à proximité');

      // Créer des demandes de trajet pour les chauffeurs à proximité
      if (nearbyDrivers.isNotEmpty) {
        print('📨 Envoi des demandes aux chauffeurs...');
        final rideRequests =
            nearbyDrivers
                .map(
                  (driver) => ({
                    'ride_id': rideId,
                    'driver_id': driver['driver_id'],
                    'status': 'sent',
                  }),
                )
                .toList();

        await _client.from('ride_requests').insert(rideRequests);
        print('✅ Demandes envoyées aux chauffeurs');
      } else {
        print('⚠️ Aucun chauffeur trouvé à proximité');
      }

      return rideId;
    } catch (e) {
      print('❌ Erreur lors de la création du trajet: $e');
      print('🔍 Détails de l\'erreur: ${e.toString()}');
      rethrow;
    }
  }

  static Future<List<Map<String, dynamic>>> getUserRides() async {
    final user = _client.auth.currentUser;
    if (user == null) throw Exception('User not authenticated');

    try {
      // Récupérer les trajets sans jointures
      final response = await _client
          .from('rides')
          .select('*')
          .eq('customer_id', user.id)
          .order('created_at', ascending: false);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('Erreur lors de la récupération des trajets: $e');
      return [];
    }
  }

  static Future<Map<String, dynamic>?> getRideById(String rideId) async {
    try {
      print('🔍 Récupération du trajet avec ID: $rideId');

      // Récupérer d'abord le trajet sans jointures
      final rideResponse =
          await _client.from('rides').select('*').eq('id', rideId).single();

      if (rideResponse == null) {
        print('❌ Trajet non trouvé');
        return null;
      }

      print('✅ Trajet récupéré: $rideResponse');
      return rideResponse;
    } catch (e) {
      print('❌ Erreur lors de la récupération du trajet: $e');
      return null;
    }
  }

  // Fonction pour récupérer un trajet par ID de demande
  static Future<Map<String, dynamic>?> getRideByRequestId(
    String requestId,
  ) async {
    try {
      final response =
          await _client
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

  // NOUVELLE: Fonction pour vérifier et annuler un trajet expiré
  static Future<bool> checkAndCancelExpiredRide(String rideId) async {
    try {
      final result = await _client.rpc(
        'check_and_cancel_ride_if_expired',
        params: {'p_ride_id': rideId},
      );

      return result as bool;
    } catch (e) {
      print('Erreur lors de la vérification d\'expiration du trajet: $e');
      return false;
    }
  }

  // NOUVELLE: Fonction pour obtenir le temps restant avant expiration
  static Future<int?> getRideTimeRemaining(String rideId) async {
    try {
      final response =
          await _client
              .from('rides')
              .select('created_at')
              .eq('id', rideId)
              .eq('status', 'searching')
              .single();

      if (response != null) {
        final createdAt = DateTime.parse(response['created_at']);
        final now = DateTime.now();
        final elapsed = now.difference(createdAt);
        final remaining = const Duration(minutes: 2) - elapsed;

        return remaining.inSeconds > 0 ? remaining.inSeconds : 0;
      }

      return null;
    } catch (e) {
      print('Erreur lors du calcul du temps restant: $e');
      return null;
    }
  }

  // Recherche de chauffeurs
  static Future<List<Map<String, dynamic>>> findNearbyDrivers({
    required double pickupLat,
    required double pickupLon,
    double radiusKm = 5.0,
    int maxDrivers = 10,
  }) async {
    try {
      final response = await _client.rpc(
        'find_nearby_drivers',
        params: {
          'pickup_lat': pickupLat,
          'pickup_lon': pickupLon,
          'radius_km': radiusKm,
          'max_drivers': maxDrivers,
        },
      );

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('Erreur lors de la recherche de chauffeurs: $e');
      return [];
    }
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
      final requestData =
          await _client
              .from('ride_requests')
              .select('ride_id')
              .eq('id', requestId)
              .eq('driver_id', user.id)
              .single();

      final rideId = requestData['ride_id'];

      // Utiliser la fonction accept_ride
      final result = await _client.rpc(
        'accept_ride',
        params: {'p_ride_id': rideId, 'p_driver_id': user.id},
      );

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
      await _client.from('driver_locations').upsert({
        'driver_id': user.id,
        'is_available': isAvailable,
        'last_updated': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      print('Erreur lors de la mise à jour de disponibilité: $e');
      rethrow;
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
        ) /
        1000; // Retourne en kilomètres
  }

  // Envoyer une notification
  static Future<void> sendNotification({
    required String userId,
    required String title,
    required String message,
    required String type,
    Map<String, dynamic>? data,
  }) async {
    try {
      await _client.from('notifications').insert({
        'user_id': userId,
        'title': title,
        'message': message,
        'type': type,
        'data': data,
      });
    } catch (e) {
      print('Erreur lors de l\'envoi de notification: $e');
      rethrow;
    }
  }

  // NOUVELLE: Fonction pour supprimer complètement un trajet après timeout
  static Future<bool> deleteExpiredRide(String rideId) async {
    try {
      print('🗑️ Suppression du trajet expiré: $rideId');

      // Supprimer d'abord les demandes de trajet associées
      await _client.from('ride_requests').delete().eq('ride_id', rideId);

      print('✅ Demandes de trajet supprimées');

      // Supprimer ensuite le trajet lui-même
      await _client.from('rides').delete().eq('id', rideId);

      print('✅ Trajet supprimé de la base de données');
      return true;
    } catch (e) {
      print('❌ Erreur lors de la suppression du trajet: $e');
      return false;
    }
  }

  // NOUVELLE: Fonction pour vérifier et supprimer un trajet expiré
  static Future<bool> checkAndDeleteExpiredRide(String rideId) async {
    try {
      print('🔍 Vérification de l\'expiration du trajet: $rideId');

      // Vérifier si le trajet existe et est en statut 'searching'
      final rideResponse =
          await _client
              .from('rides')
              .select('created_at, status')
              .eq('id', rideId)
              .eq('status', 'searching')
              .single();

      if (rideResponse == null) {
        print('⚠️ Trajet non trouvé ou déjà traité');
        return false;
      }

      final createdAt = DateTime.parse(rideResponse['created_at']);
      final now = DateTime.now();
      final elapsed = now.difference(createdAt);

      // Vérifier si plus de 2 minutes se sont écoulées
      if (elapsed.inMinutes >= 2) {
        print('⏰ Trajet expiré, suppression en cours...');
        return await deleteExpiredRide(rideId);
      } else {
        print('✅ Trajet encore valide');
        return false;
      }
    } catch (e) {
      print('❌ Erreur lors de la vérification d\'expiration: $e');
      return false;
    }
  }
}
