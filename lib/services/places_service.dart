import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/maps_config.dart';

class PlacesService {
  static const String _baseUrl = 'https://maps.googleapis.com/maps/api/place';

  /// Obtient des suggestions d'adresses basées sur le texte saisi
  static Future<List<Map<String, dynamic>>> getPlaceSuggestions(
    String input,
  ) async {
    try {
      if (input.isEmpty || input.length < 2) {
        return [];
      }

      final url = Uri.parse(
        '$_baseUrl/autocomplete/json?'
        'input=${Uri.encodeComponent(input)}'
        '&components=country:gn'
        '&language=fr'
        '&types=geocode|establishment'
        '&key=${MapsConfig.androidApiKey}',
      );

      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data['status'] == 'OK') {
          final predictions = data['predictions'] as List;
          return predictions.map((prediction) {
            return {
              'placeId': prediction['place_id'],
              'name':
                  prediction['structured_formatting']?['main_text'] ??
                  prediction['description'],
              'address': prediction['description'],
              'secondaryText':
                  prediction['structured_formatting']?['secondary_text'] ?? '',
            };
          }).toList();
        } else {
          print(
            'Erreur Google Places: ${data['status']} - ${data['error_message']}',
          );
          return [];
        }
      } else {
        print('Erreur HTTP: ${response.statusCode}');
        return [];
      }
    } catch (e) {
      print('Erreur lors de la recherche de suggestions: $e');
      return [];
    }
  }

  /// Obtient les détails d'un lieu à partir de son place_id
  static Future<Map<String, double>?> getPlaceDetails(String placeId) async {
    try {
      final url = Uri.parse(
        '$_baseUrl/details/json?'
        'place_id=$placeId'
        '&fields=geometry'
        '&key=${MapsConfig.androidApiKey}',
      );

      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data['status'] == 'OK') {
          final result = data['result'];
          final geometry = result['geometry'];
          final location = geometry['location'];

          return {
            'lat': location['lat'].toDouble(),
            'lng': location['lng'].toDouble(),
          };
        } else {
          print('Erreur lors de l\'obtention des détails: ${data['status']}');
          return null;
        }
      } else {
        print('Erreur HTTP: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      print('Erreur lors de l\'obtention des détails du lieu: $e');
      return null;
    }
  }
}
