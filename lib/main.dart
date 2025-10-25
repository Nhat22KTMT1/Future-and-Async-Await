import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

void main() {
  runApp(const WeatherApp());
}

class WeatherApp extends StatelessWidget {
  const WeatherApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Open-Meteo Weather',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: Colors.blueAccent,
        scaffoldBackgroundColor: Colors.grey[100],
      ),
      home: const WeatherHomePage(),
    );
  }
}

class WeatherHomePage extends StatefulWidget {
  const WeatherHomePage({super.key});

  @override
  State<WeatherHomePage> createState() => _WeatherHomePageState();
}

class _WeatherHomePageState extends State<WeatherHomePage> {
  final TextEditingController _controller = TextEditingController();
  Future<Map<String, dynamic>>? _weatherFuture;

  Future<Map<String, dynamic>> fetchWeather(String city) async {
    try {
      if (city.trim().isEmpty) {
        throw Exception("Vui lòng nhập tên thành phố!");
      }

      final geoUrl = Uri.parse(
        'https://geocoding-api.open-meteo.com/v1/search?name=$city&count=1',
      );
      final geoResponse = await http.get(geoUrl);

      if (geoResponse.statusCode != 200) {
        throw Exception('Không thể lấy dữ liệu vị trí.');
      }

      final geoData = jsonDecode(geoResponse.body);
      if (geoData['results'] == null || geoData['results'].isEmpty) {
        throw Exception('Không tìm thấy thành phố.');
      }

      final lat = geoData['results'][0]['latitude'];
      final lon = geoData['results'][0]['longitude'];
      final name = geoData['results'][0]['name'];
      final country = geoData['results'][0]['country'];

      final currentUrl = Uri.parse(
        'https://api.open-meteo.com/v1/forecast?latitude=$lat&longitude=$lon&current_weather=true',
      );
      final forecastUrl = Uri.parse(
        'https://api.open-meteo.com/v1/forecast?latitude=$lat&longitude=$lon&hourly=temperature_2m',
      );

      final responses = await Future.wait([
        http.get(currentUrl),
        http.get(forecastUrl),
      ]);

      final currentData = jsonDecode(responses[0].body);
      final forecastData = jsonDecode(responses[1].body);

      return {
        "city": name,
        "country": country,
        "temp": currentData['current_weather']['temperature'],
        "wind": currentData['current_weather']['windspeed'],
        "hourly": forecastData['hourly']['temperature_2m'].take(12).toList(),
      };
    } catch (e) {
      throw Exception("Lỗi khi tải dữ liệu: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "⛅Thời tiết hôm nay ☁️",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Ô nhập thành phố
            TextField(
              controller: _controller,
              decoration: InputDecoration(
                labelText: "Nhập tên thành phố...",
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.search),
                  onPressed: () {
                    FocusScope.of(context).unfocus();
                    setState(() {
                      _weatherFuture = fetchWeather(_controller.text.trim());
                    });
                  },
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Hiển thị kết quả
            Expanded(
              child: _weatherFuture == null
                  ? const Center(
                      child: Text(
                        "Nhập tên thành phố để xem thời tiết",
                        style: TextStyle(fontSize: 16),
                      ),
                    )
                  : FutureBuilder<Map<String, dynamic>>(
                      future: _weatherFuture,
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const Center(
                            child: CircularProgressIndicator(),
                          );
                        } else if (snapshot.hasError) {
                          return Center(
                            child: Text(
                              "❌ ${snapshot.error}",
                              style: const TextStyle(
                                color: Colors.red,
                                fontSize: 16,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          );
                        } else if (snapshot.hasData) {
                          final data = snapshot.data!;
                          return SingleChildScrollView(
                            child: Column(
                              children: [
                                Card(
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  elevation: 5,
                                  child: Container(
                                    width: double.infinity,
                                    padding: const EdgeInsets.all(20),
                                    decoration: const BoxDecoration(
                                      gradient: LinearGradient(
                                        colors: [
                                          Color(0xFF74ebd5),
                                          Color(0xFFACB6E5),
                                        ],
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                      ),
                                    ),
                                    child: Column(
                                      children: [
                                        Text(
                                          "${data['city']}, ${data['country']}",
                                          style: const TextStyle(
                                            fontSize: 22,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.white,
                                          ),
                                        ),
                                        const SizedBox(height: 10),
                                        Text(
                                          "${data['temp']}°C",
                                          style: const TextStyle(
                                            fontSize: 48,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.white,
                                          ),
                                        ),
                                        const SizedBox(height: 10),
                                        Text(
                                          "💨 Gió: ${data['wind']} km/h",
                                          style: const TextStyle(
                                            color: Colors.white,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 20),
                                const Text(
                                  "🌡 Nhiệt độ 12 giờ tới:",
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 10),
                                Wrap(
                                  spacing: 8,
                                  runSpacing: 8,
                                  children: data['hourly']
                                      .map<Widget>(
                                        (t) => Chip(
                                          label: Text("$t°C"),
                                          backgroundColor:
                                              Colors.blueAccent.shade100,
                                        ),
                                      )
                                      .toList(),
                                ),
                              ],
                            ),
                          );
                        } else {
                          return const Center(
                            child: Text("Không có dữ liệu để hiển thị."),
                          );
                        }
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
