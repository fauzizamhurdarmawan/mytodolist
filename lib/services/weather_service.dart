import 'package:http/http.dart' as http;
import 'dart:convert';

class WeatherService {
  final String apiKey =
      '3aff00349d739f1524eea6a35bffea07'; // Gantilah dengan API Key Anda
  final String baseUrl = 'https://api.openweathermap.org/data/2.5/weather';

  Future<String> getWeather(String city) async {
    final url = Uri.parse('$baseUrl?q=$city&appid=$apiKey&units=metric');
    final response = await http.get(url);

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final weatherDescription = data['weather'][0]['description'];
      final temperature = data['main']['temp'];

      return 'Cuaca: $weatherDescription, $temperature°C';
    } else {
      throw Exception('Failed to load weather data');
    }
  }
}
