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
  WeatherData? _weather;
  bool _loading = false;

  Future<void> _getWeather() async {
    setState(() => _loading = true);
    try {
      final data = await WeatherService.fetchWeather(_controller.text);
      setState(() => _weather = data);
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.toString())));
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          '🌤 Open - Meteo Weather',
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
                  onSubmitted: (value) => _getWeather(),
                ),
              ),
              const SizedBox(height: 20),
              if (_loading) const CircularProgressIndicator(),
              if (_weather != null && !_loading) ...[
                Container(
                  width: double.infinity,
                  height: 120,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
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
                        "${_weather!.city}, ${_weather!.country}",
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        "🌡️ ${_weather!.temperature}°C",
                        style: const TextStyle(fontSize: 28),
                      ),
                      Text("💨 Gió: ${_weather!.windSpeed} km/h"),
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
                  children: List.generate(_weather!.hourlyTemperatures.length, (
                    i,
                  ) {
                    final t = _weather!.hourlyTemperatures[i];
                    final time = DateTime.parse(_weather!.hourlyTimes[i]);
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
                  }),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
