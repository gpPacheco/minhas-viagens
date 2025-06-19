import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';

class GeocodingService {
  static const nominatimUrl = 'https://nominatim.openstreetmap.org/reverse';

  static Future<Map<String, dynamic>> getAddressFromCoordinates(
      LatLng coords) async {
    final response = await http.get(
      Uri.parse(
          '$nominatimUrl?format=jsonv2&lat=${coords.latitude}&lon=${coords.longitude}'),
      headers: {'User-Agent': 'YourAppName/1.0'}, // Necessário para Nominatim
    );

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Falha ao obter endereço');
    }
  }

  static Future<Map<String, dynamic>> getGoogleAddress(
      LatLng coords, String apiKey) async {
    final response = await http.get(
      Uri.parse('https://maps.googleapis.com/maps/api/geocode/json?'
          'latlng=${coords.latitude},${coords.longitude}&key=$apiKey'),
    );

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Falha ao obter endereço do Google');
    }
  }
}
