class WeatherData {
  final String city;
  final String country;
  final double temperature;
  final double windSpeed;
  final double rainfall;
  final List<double> hourlyTemperatures;
  final List<String> hourlyTimes;

  WeatherData({
    required this.city,
    required this.country,
    required this.temperature,
    required this.windSpeed,
    required this.rainfall,
    required this.hourlyTemperatures,
    required this.hourlyTimes,
  });
}
