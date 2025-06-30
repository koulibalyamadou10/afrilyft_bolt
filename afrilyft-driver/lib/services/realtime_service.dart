import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:get/get.dart';

class RealtimeService {
  static bool _isInitialized = false;

  static void initialize() {
    if (_isInitialized) return;

    // Pour l'instant, on utilise une approche simplifiée
    // Le temps réel sera implémenté plus tard
    print('Service de temps réel initialisé');
    _isInitialized = true;
  }

  static Future<bool> acceptRide(String requestId) async {
    try {
      final supabase = Supabase.instance.client;

      // Mettre à jour le statut de la demande
      await supabase
          .from('ride_requests')
          .update({'status': 'accepted'})
          .eq('id', requestId);

      // Récupérer l'ID du trajet associé
      final requestData =
          await supabase
              .from('ride_requests')
              .select('ride_id')
              .eq('id', requestId)
              .single();

      final rideId = requestData['ride_id'];

      // Mettre à jour le trajet avec l'ID du chauffeur
      final user = supabase.auth.currentUser;
      if (user != null) {
        await supabase
            .from('rides')
            .update({
              'driver_id': user.id,
              'status': 'accepted',
              'accepted_at': DateTime.now().toIso8601String(),
            })
            .eq('id', rideId);
      }

      return true;
    } catch (e) {
      print('Erreur lors de l\'acceptation du trajet: $e');
      return false;
    }
  }

  static Future<bool> updateRideStatus(String rideId, String status) async {
    try {
      final supabase = Supabase.instance.client;

      Map<String, dynamic> updateData = {'status': status};

      // Ajouter le timestamp approprié selon le statut
      switch (status) {
        case 'in_progress':
          updateData['started_at'] = DateTime.now().toIso8601String();
          break;
        case 'completed':
          updateData['completed_at'] = DateTime.now().toIso8601String();
          break;
      }

      await supabase.from('rides').update(updateData).eq('id', rideId);

      return true;
    } catch (e) {
      print('Erreur lors de la mise à jour du statut: $e');
      return false;
    }
  }

  static void dispose() {
    _isInitialized = false;
  }
}
