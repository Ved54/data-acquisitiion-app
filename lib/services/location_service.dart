import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:data_acquisition_app/utils/exceptions.dart';

class LocationService {
  static Future<Position> getCurrentPosition() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw Exception('Location services are disabled.');
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      throw LocationPermissionNotGrantedException(
        'Location permission is denied. Please grant permission in the app settings.',
      );
    }

    if (permission == LocationPermission.deniedForever) {
      throw LocationPermissionNotGrantedException(
        'Location permission is permanently denied. Please grant permission in the app settings.',
      );
    }

    return await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );
  }

  static Future<String> getAddressFromPosition(Position position) async {
    final placemarks = await placemarkFromCoordinates(
      position.latitude,
      position.longitude,
    );
    final place = placemarks.first;
    return '${place.locality}, ${place.administrativeArea}';
  }

  static Future<Map<String, dynamic>> getWeatherData(Position position) async {
  final url =
      "https://api.open-meteo.com/v1/forecast?latitude=${position.latitude}&longitude=${position.longitude}&hourly=temperature_2m,relativehumidity_2m&current_weather=true&timezone=auto";

  final response = await http.get(Uri.parse(url));
  if (response.statusCode != 200) {
    throw Exception('Failed to fetch weather data');
  }

  final data = jsonDecode(response.body);
  final currentTemp = data['current_weather']['temperature'];
  final currentTime = data['current_weather']['time'];

  final hourlyTimes = List<String>.from(data['hourly']['time']);
  final humidities = (data['hourly']['relativehumidity_2m'] as List)
      .map((e) => (e as num).toDouble())
      .toList();

  final current = DateTime.parse(currentTime);
  final times = hourlyTimes.map((t) => DateTime.parse(t)).toList();

  int closestIndex = 0;
  Duration minDiff = current.difference(times[0]).abs();
  for (int i = 1; i < times.length; i++) {
    final diff = current.difference(times[i]).abs();
    if (diff < minDiff) {
      minDiff = diff;
      closestIndex = i;
    }
  }

  final humidity = humidities[closestIndex];

  return {
    'temperature': currentTemp,
    'humidity': humidity,
  };
}

}
