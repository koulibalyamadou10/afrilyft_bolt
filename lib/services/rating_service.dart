import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/rating_model.dart';

class RatingService {
  static final SupabaseClient _client = Supabase.instance.client;

  // Submit a rating for a completed ride
  static Future<bool> submitRating({
    required String rideId,
    required String ratedUserId,
    required int rating,
    String? review,
  }) async {
    try {
      final user = _client.auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      await _client.from('ride_ratings').insert({
        'ride_id': rideId,
        'rater_id': user.id,
        'rated_id': ratedUserId,
        'rating': rating,
        'review': review,
      });

      return true;
    } catch (e) {
      print('Error submitting rating: $e');
      return false;
    }
  }

  // Get ratings for a specific user
  static Future<List<RatingModel>> getUserRatings(String userId) async {
    try {
      final response = await _client
          .from('ride_ratings')
          .select('''
            *,
            rater:profiles!ride_ratings_rater_id_fkey(full_name, avatar_url),
            ride:rides!ride_ratings_ride_id_fkey(pickup_address, destination_address, created_at)
          ''')
          .eq('rated_id', userId)
          .order('created_at', ascending: false);

      return response.map((json) => RatingModel.fromJson(json)).toList();
    } catch (e) {
      print('Error fetching user ratings: $e');
      return [];
    }
  }

  // Get average rating for a user
  static Future<double> getUserAverageRating(String userId) async {
    try {
      final response = await _client
          .from('ride_ratings')
          .select('rating')
          .eq('rated_id', userId);

      if (response.isEmpty) return 0.0;

      final ratings = response.map((r) => r['rating'] as int).toList();
      final average = ratings.reduce((a, b) => a + b) / ratings.length;
      
      return double.parse(average.toStringAsFixed(1));
    } catch (e) {
      print('Error calculating average rating: $e');
      return 0.0;
    }
  }

  // Check if user can rate a specific ride
  static Future<bool> canRateRide(String rideId) async {
    try {
      final user = _client.auth.currentUser;
      if (user == null) return false;

      // Check if ride is completed and user hasn't rated yet
      final rideResponse = await _client
          .from('rides')
          .select('status, customer_id, driver_id')
          .eq('id', rideId)
          .single();

      if (rideResponse['status'] != 'completed') return false;

      final isParticipant = rideResponse['customer_id'] == user.id || 
                           rideResponse['driver_id'] == user.id;
      
      if (!isParticipant) return false;

      // Check if already rated
      final existingRating = await _client
          .from('ride_ratings')
          .select('id')
          .eq('ride_id', rideId)
          .eq('rater_id', user.id)
          .maybeSingle();

      return existingRating == null;
    } catch (e) {
      print('Error checking if can rate ride: $e');
      return false;
    }
  }

  // Get rating statistics for a user
  static Future<Map<String, dynamic>> getRatingStats(String userId) async {
    try {
      final response = await _client
          .from('ride_ratings')
          .select('rating')
          .eq('rated_id', userId);

      if (response.isEmpty) {
        return {
          'average': 0.0,
          'total': 0,
          'distribution': {1: 0, 2: 0, 3: 0, 4: 0, 5: 0},
        };
      }

      final ratings = response.map((r) => r['rating'] as int).toList();
      final average = ratings.reduce((a, b) => a + b) / ratings.length;
      
      final distribution = <int, int>{1: 0, 2: 0, 3: 0, 4: 0, 5: 0};
      for (final rating in ratings) {
        distribution[rating] = (distribution[rating] ?? 0) + 1;
      }

      return {
        'average': double.parse(average.toStringAsFixed(1)),
        'total': ratings.length,
        'distribution': distribution,
      };
    } catch (e) {
      print('Error fetching rating stats: $e');
      return {
        'average': 0.0,
        'total': 0,
        'distribution': {1: 0, 2: 0, 3: 0, 4: 0, 5: 0},
      };
    }
  }
}