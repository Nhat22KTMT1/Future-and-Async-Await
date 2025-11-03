import 'package:flutter/material.dart';
import '../services/weather_service.dart';
import '../models/weather_model.dart';

class WeatherHomePage extends StatefulWidget {
  const WeatherHomePage({super.key});

  @override
  State<WeatherHomePage> createState() => _WeatherHomePageState();
}

class _WeatherHomePageState extends State<WeatherHomePage> {
  final TextEditingController _controller = TextEditingController();
  Future<WeatherData?>? _futureWeather;

  void _getWeather() {
    setState(() {
      _futureWeather = WeatherService.fetchWeather(_controller.text);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          '🌤 Thời tiết hôm nay',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        backgroundColor: Colors.blueAccent,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              // Ô nhập tên thành phố
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: TextField(
                  controller: _controller,
                  decoration: InputDecoration(
                    hintText: 'Nhập tên thành phố...',
                    suffixIcon: IconButton(
                      icon: const Icon(Icons.search),
                      onPressed: _getWeather,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onSubmitted: (_) => _getWeather(),
                ),
              ),

              const SizedBox(height: 20),

              // FutureBuilder hiển thị kết quả
              if (_futureWeather != null)
                FutureBuilder<WeatherData?>(
                  future: _futureWeather,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Column(
                        children: [
                          CircularProgressIndicator(),
                          SizedBox(height: 16),
                          Text("Đang tải..."),
                        ],
                      );
                    }

                    // Nếu có lỗi
                    if (snapshot.hasError) {
                      String errorMessage = snapshot.error.toString();
                      if (errorMessage.contains("Exception: ")) {
                        errorMessage = errorMessage.replaceFirst(
                          "Exception: ",
                          "",
                        );
                      }
                      return Text(
                        errorMessage,
                        style: const TextStyle(color: Colors.red),
                      );
                    }

                    // Nếu có dữ liệu
                    if (snapshot.hasData && snapshot.data != null) {
                      final weather = snapshot.data!;
                      return Column(
                        children: [
                          Container(
                            width: double.infinity,
                            height: 125,
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Color(0xFF74ebd5), Color(0xFFACB6E5)],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  "${weather.city} - ${weather.country}",
                                  style: const TextStyle(
                                    fontSize: 22,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 10),
                                Text(
                                  "🌡️${weather.temperature}°C",
                                  style: const TextStyle(fontSize: 25),
                                ),
                                Text("💨 Gió: ${weather.windSpeed} km/h"),
                                Text("🌧️ Mưa: ${weather.rainfall} mm"),
                              ],
                            ),
                          ),
                          const SizedBox(height: 20),
                          const Text(
                            "Nhiệt độ 12 giờ tới:",
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 10),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: List.generate(
                              weather.hourlyTemperatures.length,
                              (i) {
                                final t = weather.hourlyTemperatures[i];
                                final time = DateTime.parse(
                                  weather.hourlyTimes[i],
                                );
                                return Container(
                                  width: 85,
                                  height: 40,
                                  alignment: Alignment.center,
                                  decoration: BoxDecoration(
                                    color: Colors.blue[400],
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Text(
                                    "${time.hour}h: ${t.toStringAsFixed(1)}°C",
                                    style: const TextStyle(color: Colors.white),
                                  ),
                                );
                              },
                            ),
                          ),
                        ],
                      );
                    }

                    // Trạng thái chưa có dữ liệu
                    return const Text("Nhập tên thành phố để xem thời tiết");
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }
}
