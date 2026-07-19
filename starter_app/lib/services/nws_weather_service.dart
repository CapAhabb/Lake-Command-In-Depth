import 'dart:convert';

import 'package:http/http.dart' as http;

class NwsWeatherService {
  NwsWeatherService({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;

  void close() => _client.close();

  Future<NwsHourlySummary?> fetchHourlySummary({
    required double latitude,
    required double longitude,
  }) async {
    try {
      final pointsResponse = await _client
          .get(
            Uri.https('api.weather.gov', '/points/$latitude,$longitude'),
            headers: _headers,
          )
          .timeout(const Duration(seconds: 8));
      if (pointsResponse.statusCode != 200) return null;

      final pointsDecoded =
          jsonDecode(pointsResponse.body) as Map<String, dynamic>;
      final points = pointsDecoded['properties'] as Map<String, dynamic>?;
      final hourlyUrl = points?['forecastHourly'] as String?;
      if (hourlyUrl == null) return null;

      final forecastResponse = await _client
          .get(Uri.parse(hourlyUrl), headers: _headers)
          .timeout(const Duration(seconds: 8));
      if (forecastResponse.statusCode != 200) return null;

      final forecastDecoded =
          jsonDecode(forecastResponse.body) as Map<String, dynamic>;
      final forecastProps =
          forecastDecoded['properties'] as Map<String, dynamic>?;
      final periods = forecastProps?['periods'] as List<dynamic>?;
      if (periods == null || periods.isEmpty) return null;

      final first = periods.first as Map<String, dynamic>;
      return NwsHourlySummary(
        validAt: DateTime.tryParse(first['startTime'] as String? ?? ''),
        temperatureF: (first['temperature'] as num?)?.toDouble(),
        windSpeedMph: _parseWindSpeed(first['windSpeed'] as String?),
        windDirection: first['windDirection'] as String?,
        shortForecast: first['shortForecast'] as String?,
      );
    } on Exception {
      return null;
    }
  }

  Map<String, String> get _headers => const {
    'User-Agent': 'LakeIntelligencePro/1.0 (support@example.com)',
    'Accept': 'application/geo+json',
  };

  double? _parseWindSpeed(String? value) {
    if (value == null) return null;
    final match = RegExp(r'(\d+(?:\.\d+)?)').firstMatch(value);
    if (match == null) return null;
    return double.tryParse(match.group(1)!);
  }
}

class NwsHourlySummary {
  const NwsHourlySummary({
    required this.validAt,
    required this.temperatureF,
    required this.windSpeedMph,
    required this.windDirection,
    required this.shortForecast,
  });

  final DateTime? validAt;
  final double? temperatureF;
  final double? windSpeedMph;
  final String? windDirection;
  final String? shortForecast;
}
