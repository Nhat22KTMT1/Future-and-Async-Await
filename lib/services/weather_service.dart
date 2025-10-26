import 'dart:io';
import 'dart:convert';
import 'dart:async';
import 'package:http/http.dart' as http;
import '../models/weather_model.dart';

class WeatherService {
  static Future<WeatherData> fetchWeather(String city) async {
    try {
      final geoUrl = Uri.parse(
        'https://geocoding-api.open-meteo.com/v1/search?name=$city&count=1',
      );
      final geoResponse = await http.get(geoUrl);
      final geoData = jsonDecode(geoResponse.body);

      if (geoData['results'] == null || geoData['results'].isEmpty) {
        throw Exception("Không tìm thấy thành phố");
      }

      final lat = geoData['results'][0]['latitude'];
      final lon = geoData['results'][0]['longitude'];
      final name = geoData['results'][0]['name'];
      final country = geoData['results'][0]['country'];

      final currentWeather = Uri.parse(
        'https://api.open-meteo.com/v1/forecast?latitude=$lat&longitude=$lon&current_weather=true',
      );
      final temp12hour = Uri.parse(
        'https://api.open-meteo.com/v1/forecast?latitude=$lat&longitude=$lon&hourly=temperature_2m',
      );

      final currentRain = Uri.parse(
        'https://api.open-meteo.com/v1/forecast?latitude=$lat&longitude=$lon&current=rain',
      );

      final response = await Future.wait([
        http.get(currentWeather).timeout(const Duration(seconds: 60)),
        http.get(temp12hour).timeout(const Duration(seconds: 60)),
        http.get(currentRain).timeout(const Duration(seconds: 60)),
      ]).timeout(Duration(seconds: 20));
      final currentData = jsonDecode(response[0].body);
      final data = jsonDecode(response[1].body);
      final rainData = jsonDecode(response[2].body);

      // Parse data: hourly temperatures and times
      final times = List<String>.from(data['hourly']['time']);
      final temps = List<double>.from(
        data['hourly']['temperature_2m'].map((t) => t.toDouble()),
      );

      final now = DateTime.now();
      int index = times.indexWhere(
        (t) =>
            DateTime.parse(t).isAfter(now) ||
            DateTime.parse(t).isAtSameMomentAs(now),
      );

      if (index == -1) index = 0;
      final next12Temps = temps.skip(index).take(12).toList();
      final next12Times = times.skip(index).take(12).toList();

      return WeatherData(
        city: name,
        country: country,
        temperature: currentData['current_weather']['temperature'].toDouble(),
        windSpeed: currentData['current_weather']['windspeed'].toDouble(),
        rainfall: rainData['current']['rain'].toDouble(),
        hourlyTemperatures: next12Temps,
        hourlyTimes: next12Times,
      );
    } on SocketException {
      throw Exception("Không thể kết nối Internet. Vui lòng kiểm tra mạng.");
    } on http.ClientException {
      throw Exception("Không thể kết nối tới máy chủ. Vui lòng thử lại sau.");
    } on TimeoutException {
      throw Exception("Yêu cầu mất quá nhiều thời gian. Vui lòng thử lại sau.");
    } on FormatException catch (e) {
      throw Exception("Dữ liệu nhận được không hợp lệ: $e");
    } catch (e) {
      throw Exception("Lỗi khi tải dữ liệu: $e");
    }
  }
}
