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
      if (geoResponse.statusCode != 200) {
        throw Exception("Lỗi khi lấy tọa độ: ${geoResponse.statusCode}");
      }
      // Giải mã phản hồi JSON và chuyển thành 1 Map với key "results" và values là một List<Map>
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
        'https://api.open-meteo.com/v1/forecast?latitude=$lat&longitude=$lon&current=precipitation',
      );

      final response = await Future.wait([
        http.get(currentWeather),
        http.get(temp12hour),
        http.get(currentRain),
      ]).timeout(Duration(seconds: 60));

      for (var res in response) {
        if (res.statusCode != 200) {
          throw Exception("Lỗi khi lấy dữ liệu thời tiết: ${res.statusCode}");
        }
      }

      final currentData = jsonDecode(response[0].body);
      final data = jsonDecode(response[1].body);
      final rainData = jsonDecode(response[2].body);

      // Parse data: hourly temperatures and times
      final times = List<String>.from(data['hourly']['time']);
      final temps = List<double>.from(
        data['hourly']['temperature_2m'].map((t) => t.toDouble()),
      );

      if (times.length != temps.length) throw Exception('Data length mismatch');

      final now = DateTime.now().toUtc();
      int index = times.indexWhere(
        (t) =>
            DateTime.parse(t).toUtc().isAfter(now) ||
            DateTime.parse(t).toUtc().isAtSameMomentAs(now),
      ); // Find the index of the current time or the next hour

      // If no future time found -> return -1 so start from beginning
      if (index == -1) index = 0;

      // Skip index values to get next 12 hours/temperatures
      final next12Temps = temps.skip(index).take(12).toList();
      final next12Times = times.skip(index).take(12).toList();

      return WeatherData(
        city: name,
        country: country,
        temperature: currentData['current_weather']['temperature'].toDouble(),
        windSpeed: currentData['current_weather']['windspeed'].toDouble(),
        rainfall: rainData['current']['precipitation'].toDouble(),
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
